/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2011 University of Utah and the Flux Group.
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
	/**
	 * Link between two resources as described by a manager advertisement
	 * 
	 * @author mstrum
	 * 
	 */
	public class PhysicalLink extends PhysicalComponent
	{
		public var owner:PhysicalLinkGroup;
		
		[Bindable]
		public var linkTypes:Vector.<String> = new Vector.<String>();
		public var interfaceRefs:PhysicalNodeInterfaceCollection = new PhysicalNodeInterfaceCollection();
		
		// TODEPRECIATE
		[Bindable]
		public var capacity:Number;
		[Bindable]
		public var latency:Number;
		[Bindable]
		public var packetLoss:Number;
		
		public function PhysicalLink(own:PhysicalLinkGroup)
		{
			super();
			this.owner = own;
		}
		
		public function GetNodes():Vector.<PhysicalNode> {
			return this.interfaceRefs.Nodes();
		}
	}
}