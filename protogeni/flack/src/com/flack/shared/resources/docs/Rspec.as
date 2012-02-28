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

package com.flack.shared.resources.docs
{
	/**
	 * Holds a resource-description document as well as some meta info
	 * 
	 * @author mstrum
	 * 
	 */
	public class Rspec
	{
		// Types
		static public const TYPE_ADVERTISEMENT:String = "advertisement";
		static public const TYPE_REQUEST:String = "request";
		static public const TYPE_MANIFEST:String = "manifest";
		
		/**
		 * Full RSPEC as a string
		 */
		public var document:String = "";
		
		/**
		 * Version information
		 */
		public var info:RspecVersion;
		/**
		 * When the document was generated
		 */
		public var generated:Date;
		/**
		 * When the document will expire
		 */
		public var expires:Date;
		/**
		 * What type is the document
		 */
		public var type:String;
		
		/**
		 * 
		 * @param newDocument String representation
		 * @param newVersion Version information
		 * @param newGenerated When was this generated?
		 * @param newExpires When does it expire?
		 * @param newType What type of RSPEC is this?
		 * 
		 */
		public function Rspec(newDocument:String = "",
							  newVersion:RspecVersion = null,
							  newGenerated:Date = null,
							  newExpires:Date = null,
							  newType:String = "")
		{
			if(newDocument != null)
				document = newDocument;
			info = newVersion;
			generated = newGenerated;
			expires = newExpires;
			type = newType;
		}
	}
}