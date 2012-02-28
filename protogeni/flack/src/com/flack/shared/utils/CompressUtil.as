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

package com.flack.shared.utils
{
	import flash.utils.ByteArray;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;

	public class CompressUtil
	{
		public static function uncompress(base64Compressed:String):String
		{
			var decodor:Base64Decoder = new Base64Decoder();
			decodor.decode(base64Compressed);
			var bytes:ByteArray = decodor.toByteArray();
			bytes.uncompress();
			return bytes.toString();
		}
		
		// XXX needs to work...
		public static function compress(original:String):String
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes(original);
			bytes.compress();
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encodeBytes(bytes, 0, bytes.length);
			return encoder.toString();
		}
	}
}