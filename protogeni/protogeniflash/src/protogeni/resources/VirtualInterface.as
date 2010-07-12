/* GENIPUBLIC-COPYRIGHT
 * Copyright (c) 2009 University of Utah and the Flux Group.
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
 
 package protogeni.resources
{
	import mx.collections.ArrayCollection;
	
	// Interface on a virtual node
	public class VirtualInterface
	{
		public function VirtualInterface(own:VirtualNode)
		{
			virtualNode = own;
		}
		
		[Bindable]
		public var virtualNode:VirtualNode;
		
		[Bindable]
		public var id:String;
		public var role:int;

		[Bindable]
		public var virtualLinks:ArrayCollection = new ArrayCollection();
		
		public var physicalNodeInterface:PhysicalNodeInterface;
		public var isVirtual:Boolean;
		public var name : String;
		public var bandwidth:int = 0;
		
		public function getXml():XML
		{
			var result : XML = <interface_ref />;
			/*
			result.@virtual_node_id = virtualNode.name;
			if (isTunnel())
			{
				result.@tunnel_ip = ipToString(tunnelIp + ipOffset);
				result.@virtual_interface_id = "control";
			}
			else
			{
				result.@virtual_interface_id = interfaceName;
			}
			*/
			return result;
		}
	}
}