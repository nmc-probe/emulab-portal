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

package com.flack.shared.resources
{
	/**
	 * Unique resource identifier in the form: urn:publicid:IDN+authority+type+name
	 * 
	 * @author mstrum
	 * 
	 */
	public class IdnUrn
	{
		// Common types
		static public const TYPE_USER:String = "user";
		static public const TYPE_SLICE:String = "slice";
		static public const TYPE_SLIVER:String = "sliver";
		static public const TYPE_AUTHORITY:String = "authority";
		static public const TYPE_NODE:String = "node";
		static public const TYPE_INTERFACE:String = "interface";
		static public const TYPE_LINK:String = "link";
		
		/**
		 * 
		 * @return String representation including everything
		 * 
		 */
		[Bindable]
		public var full:String;
		
		public function get authority():String
		{
			if(full.length > 0)
				return full.split("+")[1];
			else
				return "";
		}
		
		public function get type():String
		{
			if(full.length > 0)
				return full.split("+")[2];
			else
				return "";
		}
		
		public function get name():String
		{
			if(full.length > 0)
				return full.split("+")[3];
			else
				return "";
		}
		
		public function IdnUrn(urn:String = "")
		{
			if(urn == null)
				full = "";
			else
				full = urn;
		}
		
		public function toString():String
		{
			return full;
		}
		
		public static function getAuthorityFrom(urn:String):String
		{
			return urn.split("+")[1];
		}
		
		public static function getTypeFrom(urn:String):String
		{
			return urn.split("+")[2];
		}
		
		public static function getNameFrom(urn:String):String
		{
			return urn.split("+")[3];
		}
		
		/**
		 * 
		 * @param newAuthority Authority portion of a IDN-URN
		 * @param newType Type portion of a IDN-URN
		 * @param newName Name portion of a IDN-URN
		 * @return 
		 * 
		 */
		public static function makeFrom(newAuthority:String,
										newType:String,
										newName:String):IdnUrn
		{
			return new IdnUrn("urn:publicid:IDN+" + newAuthority + "+" + newType + "+" + newName);
		}
		
		/**
		 * 
		 * @param testString String to see if it is a valid IDN-URN
		 * @return TRUE if a valid IDN-URN
		 * 
		 */
		public static function isIdnUrn(testString:String):Boolean
		{
			try
			{
				var array:Array = testString.split("+");
				if(array[0] != "urn:publicid:IDN")
					return false;
				if(array.length != 4)
					return false;
			}
			catch(e:Error)
			{
				return false;
			}
			return true;
		}
		
		/**
		 * Splits things like plc:princeton:mstrum into an array. This is commonly used for hierarchical elements
		 * 
		 * @param element Element to get subelements
		 * @return 
		 * 
		 */
		public static function splitElement(element:String):Array
		{
			return element.split(':');
		}
	}
}