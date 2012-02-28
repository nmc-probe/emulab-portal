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

package com.flack.geni.resources.docs
{
	import com.flack.shared.resources.IdentifiableObject;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.utils.DateUtil;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Credential for a GENI object
	 * 
	 * @author mstrum
	 * 
	 */
	public class GeniCredential
	{
		// Types
		public static const TYPE_USER:int = 0;
		public static const TYPE_SLICE:int = 1;
		public static const TYPE_SLIVER:int = 2;
		
		private var _xml:XML = null;
		private var _raw:String = "";
		[Bindable]
		public function get Raw():String
		{
			return _raw;
		}
		public function set Raw(value:String):void
		{
			if(value == null || value.length == 0)
			{
				_raw = "";
				_xml = null;
				return;
			}
			_raw = value;
			if(_raw.length == 0)
				_xml = null;
			try
			{
				_xml = new XML(_raw);
				if(_xml.toXMLString().length == 0)
					_xml = null;
			}
			catch(e:Error)
			{
				_xml = null;
			}
		}
		public function get Xml():XML
		{
			return _xml;
		}
		
		public function get OwnerId():IdnUrn
		{
			try
			{
				return new IdnUrn(_xml.credential.owner_urn)
			}
			catch(e:Error)
			{
			}
			
			return null;
		}
		
		public function get TargetId():IdnUrn
		{
			try
			{
				return new IdnUrn(_xml.credential.target_urn)
			}
			catch(e:Error)
			{
			}
			return null;
		}
		
		public function get Expires():Date
		{
			try
			{
				// XXX everything should end with Z but some don't.  This will break non-UTC times if they have offsets.
				return DateUtil.parseRFC3339(StringUtil.makeSureEndsWith(_xml.credential.expires, "Z"));
			}
			catch(e:Error)
			{
			}
			return null;
		}
		
		/**
		 * What type of object is this a credential for?
		 */
		public var type:int;
		/**
		 * What gave us this credential?
		 */
		public var source:IdentifiableObject;
		
		/**
		 * 
		 * @param stringRepresentation Credential in string form
		 * @param newType What is this a credential for?
		 * @param newSource Where did this credential come from?
		 * 
		 */
		public function GeniCredential(stringRepresentation:String = "",
									   newType:int = TYPE_USER,
									   newSource:IdentifiableObject = null)
		{
			Raw = stringRepresentation;
			type = newType;
			source = newSource;
		}
	}
}