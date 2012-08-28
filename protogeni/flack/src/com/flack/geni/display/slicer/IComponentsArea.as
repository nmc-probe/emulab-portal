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

package com.flack.geni.display.slicer
{
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.VirtualComponent;
	import com.flack.geni.resources.virtual.VirtualNode;

	public interface IComponentsArea
	{
		function get SliceEditing():Slice;
		function set SliceEditing(s:Slice):void;
		
		function get SelectedNode():VirtualNode;
		function set SelectedNode(node:VirtualNode):void;
		
		function load(s:Slice):void;
		function clear():void;
		
		function updateInterface():void;
		function clearStatus():void;
		
		function toggleEditable(editable:Boolean):void;
		
		function addCloneOf(virtualComponent:VirtualComponent):void;
	}
}