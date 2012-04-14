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

package com.flack.geni.resources.virtual
{
	import com.flack.geni.resources.Extensions;
	import com.flack.geni.resources.physical.PhysicalInterface;
	import com.flack.shared.resources.IdentifiableObject;
	import com.flack.shared.resources.IdnUrn;

	/**
	 * Interface on a resource used to connect to other resources through links
	 *  
	 * @author mstrum
	 * 
	 */	
	public class VirtualInterface extends IdentifiableObject
	{
		public static var tunnelSecond:int = 1;
		public static var tunnelFirst:int = 0;
		public static function startNextTunnel():void
		{
			tunnelSecond = 1;
			tunnelFirst++;
		}
		public static function getNextTunnel():String
		{
			var first:int = tunnelFirst & 0xff;
			var second:int = tunnelSecond & 0xff;
			tunnelSecond++;
			return "192.168." + String(first) + "." + String(second);
		}
		
		public var clientId:String = "";
		
		public var _owner:VirtualNode;
		[Bindable]
		public function get Owner():VirtualNode
		{
			return _owner;
		}
		public function set Owner(newOwner:VirtualNode):void
		{
			_owner = newOwner;
			if(_owner != null && clientId.length == 0)
				clientId = _owner.slice.getUniqueId(this, _owner.clientId + ":if");
		}
		
		public var physicalId:IdnUrn = new IdnUrn();
		public function get Physical():PhysicalInterface
		{
			if(physicalId.full.length > 0 && _owner.Physical != null)
				return _owner.Physical.interfaces.getById(physicalId.full);
			else
				return null;
		}
		public function set Physical(value:PhysicalInterface):void
		{
			if(value != null)
				physicalId = new IdnUrn(value.id.full);
			else
				physicalId = new IdnUrn();
		}
		public function get Bound():Boolean
		{
			return physicalId.full.length > 0;
		}
		
		public var macAddress:String = "";
		public var vmac:String = "";
		
		// tunnel stuff
		public var ip:Ip = new Ip();
		
		[Bindable]
		public var links:VirtualLinkCollection = new VirtualLinkCollection();

		public var capacity:Number;
		
		public var extensions:Extensions = new Extensions();
		
		/**
		 * 
		 * @param own Node where the interface will reside
		 * @param newId IDN-URN
		 * 
		 */
		public function VirtualInterface(own:VirtualNode,
										 newId:String = "")
		{
			super(newId);
			Owner = own;
		}
		
		override public function toString():String
		{
			return "[Interface SliverID="+id.full+", ClientID="+clientId+"]";
		}
	}
}