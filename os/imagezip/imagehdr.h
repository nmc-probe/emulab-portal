/*
 * EMULAB-COPYRIGHT
 * Copyright (c) 2000-2004 University of Utah and the Flux Group.
 * All rights reserved.
 */

#include <inttypes.h>

/*
 * Magic number when image is compressed
 *
 * This magic number has been commandeered for use as a version number.
 * None of this wimpy start at version 1 stuff either, our first version
 * is 1,768,515,945!
 *
 *	V2 introduced the first and last sector fields as well
 *	as basic relocations.
 *
 *	V3 introduced LILO relocations for Linux partition images.
 *	Since an older imageunzip would still work, but potentially
 *	lay down an incorrect images, I bumped the version number.
 */
#define COMPRESSED_MAGIC_BASE		0x69696969
#define COMPRESSED_V1			(COMPRESSED_MAGIC_BASE+0)
#define COMPRESSED_V2			(COMPRESSED_MAGIC_BASE+1)
#define COMPRESSED_V3			(COMPRESSED_MAGIC_BASE+2)
#define COMPRESSED_V4			(COMPRESSED_MAGIC_BASE+3)

#define COMPRESSED_MAGIC_CURRENT	COMPRESSED_V4

/*
 * Each compressed block of the file has this little header on it.
 * Since each subblock is independently compressed, we need to know
 * its internal size (it will probably be shorter than 1MB) since we
 * have to know exactly how much to give the inflator.
 */
struct blockhdr_V1 {
	uint32_t	magic;
	uint32_t	size;		/* Size of compressed part */
	int32_t		blockindex;
	int32_t		blocktotal;
	int32_t		regionsize;
	int32_t		regioncount;
};

/*
 * Version 2 of the block descriptor adds a first and last sector value.
 * These are used to describe free space which is adjacent to the allocated
 * sector data.  This is needed in order to properly zero all free space.
 * Previously free space between regions that wound up in different
 * blocks could only be handled if the blocks were presented consecutively,
 * this was not the case in frisbee.
 */
struct blockhdr_V2 {
	uint32_t	magic;		/* magic/version */
	uint32_t	size;		/* Size of compressed part */
	int32_t		blockindex;	/* netdisk: which block we are */
	int32_t		blocktotal;	/* netdisk: total number of blocks */
	int32_t		regionsize;	/* sizeof header + regions */
	int32_t		regioncount;	/* number of regions */
	/* V2 follows */
	uint32_t	firstsect;	/* first sector described by block */
	uint32_t	lastsect;	/* last sector described by block */
	int32_t		reloccount;	/* number of reloc entries */
};

#define CHECKSUM_LEN_MAX 64
/* SIGNATURE_KEY_LENGTH must be greater than CHECKSUM_LEN_MAX + 41 */
#define SIGNATURE_KEY_LENGTH 256

/*
 * Version 3 of the block descriptor adds support for integrety protection
 * and encryption.
 * A checksum is now mandatory - otherwise, an attacker could modify
 * the header to just turn it off, and since we wouldn't check the checksum,
 * we'd never check! So, you MUST fill in the checksum. All implementations
 * are required to support SHA1, support for others are optional.
 */
struct blockhdr_V4 {
	uint32_t	magic;		/* magic/version */
	uint32_t	size;		/* Size of compressed part */
	int32_t		blockindex;	/* netdisk: which block we are */
	int32_t		blocktotal;	/* netdisk: total number of blocks */
	int32_t		regionsize;	/* sizeof header + regions */
	int32_t		regioncount;	/* number of regions */
	/* V2 follows */
	uint32_t	firstsect;	/* first sector described by block */
	uint32_t	lastsect;	/* last sector described by block */
	int32_t		reloccount;	/* number of reloc entries */
        /* V4 follows */
        uint32_t        enc_cipher;     /* Which cipher was used to encrypt */
        //uint32_t        enc_iv    ;     /* Initialization vector */
        int8_t          enc_iv[8];      /* Initialization vector */
        uint32_t        checksumtype;   /* Which checksum was used */
        unsigned char   checksum[SIGNATURE_KEY_LENGTH]; /* Checksum, leave room for 512 bits */
};

/*
 * Checksums supported
 */
/* Required to be supported by all versions */
#define CHECKSUM_SHA1   0

/*
 * Length of the checksum field (in bytes) for various checksum types
 */
#define CHECKSUM_LEN_SHA1 20

/*
 * Ciphers supported
 */
#define ENCRYPTION_NULL 0
#define ENCRYPTION_BLOWFISH_CBC 1

/*
 * Relocation descriptor.
 * Certain data structures like BSD disklabels and LILO boot blocks require
 * absolute block numbers.  This descriptor tells the unzipper what the
 * data structure is and where it is located in the block.
 *
 * Relocation descriptors follow the region descriptors in the header block.
 */
struct blockreloc {
	uint32_t	type;		/* relocation type (below) */
	uint32_t	sector;		/* sector it applies to */
	uint32_t	sectoff;	/* offset within the sector */
	uint32_t	size;		/* size of data affected */
};
#define RELOC_NONE		0
#define RELOC_FBSDDISKLABEL	1	/* FreeBSD disklabel */
#define RELOC_OBSDDISKLABEL	2	/* OpenBSD disklabel */
#define RELOC_LILOSADDR		3	/* LILO sector address */
#define RELOC_LILOMAPSECT	4	/* LILO map sector */
#define RELOC_LILOCKSUM		5	/* LILO descriptor block cksum */

/* XXX potential future alternatives to hard-wiring BSD disklabel knowledge */
#define RELOC_ADDPARTOFFSET	100	/* add partition offset to location */
#define RELOC_XOR16CKSUM	101	/* 16-bit XOR checksum */
#define RELOC_CKSUMRANGE	102	/* range of previous checksum */

typedef struct blockhdr_V4 blockhdr_t;

/*
 * This little struct defines the pair. Each number is in sectors. An array
 * of these come after the header above, and is padded to a 1K boundry.
 * The region says where to write the next part of the input file, which is
 * how we skip over parts of the disk that do not need to be written
 * (swap, free FS blocks).
 */
struct region {
	uint32_t	start;
	uint32_t	size;
};

/*
 * In the new model, each sub region has its own region header info.
 * But there is no easy way to tell how many regions before compressing.
 * Just leave a page, and hope that 512 regions is enough!
 *
 * This number must be a multiple of the NFS read size in netdisk.
 */
#define DEFAULTREGIONSIZE	(1024 * 4)

/*
 * Ah, the frisbee protocol. The new world order is to break up the
 * file into fixed 1MB chunks, with the region info prepended to each
 * chunk so that it can be layed down on disk independently of all the
 * chunks in the file. 
 */
#define SUBBLOCKSIZE		(1024 * 1024)
#define SUBBLOCKMAX		(SUBBLOCKSIZE - DEFAULTREGIONSIZE)

/*
 * Assumed sector (block) size
 */
#define SECSIZE			512
