/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group.
* All rights reserved.
*
* Permission to use, copy, modify and distribute this software is hereby
* granted provided that (1) source code retains these copyright, permission,
* and disclaimer notices, and (2) redistributions including binaries
* reproduce the notices in supporting documentation.
*
* THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
* CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
* FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
*/

package com.flack.geni.resources.physical
{
	import com.flack.geni.resources.DiskImage;

	/**
	 * Collection of disk images
	 * @author mstrum
	 * 
	 */
	public class DiskImageCollection
	{
		public var collection:Vector.<DiskImage>;
		public function DiskImageCollection()
		{
			collection = new Vector.<DiskImage>();
		}
		
		public function add(image:DiskImage):void
		{
			for each(var existingImage:DiskImage in collection)
			{
				if(existingImage.ShortId == image.ShortId)
					return;
			}
			collection.push(image);
		}
		
		public function remove(image:DiskImage):void
		{
			var idx:int = collection.indexOf(image);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(image:DiskImage):Boolean
		{
			return collection.indexOf(image) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param shortId Short ID (e.g. emulab-ops//FC6-STD)
		 * @return Disk image with the same short ID
		 * 
		 */
		public function getByShortId(shortId:String):DiskImage
		{
			for each(var image:DiskImage in collection)
			{
				if(image.ShortId == shortId)
					return image;
			}
			return null;
		}
		
		/**
		 * 
		 * @param id Full IDN-URN
		 * @return Disk image matching the ID
		 * 
		 */
		public function getByLongId(id:String):DiskImage
		{
			for each(var image:DiskImage in collection)
			{
				if(image.id.full == id)
					return image;
			}
			return null;
		}
		
		/**
		 * 
		 * @return Default image
		 * 
		 */
		public function getDefault():DiskImage
		{
			for each(var image:DiskImage in collection)
			{
				if(image.isDefault)
					return image;
			}
			return null;
		}
	}
}