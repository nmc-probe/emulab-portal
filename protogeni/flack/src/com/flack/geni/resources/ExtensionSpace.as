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

package com.flack.geni.resources
{
	/**
	 * All extensions under one namespace for a parent extended object
	 * 
	 * @author mstrum
	 * 
	 */
	public class ExtensionSpace
	{
		public var namespace:Namespace;
		public var attributes:Vector.<ExtensionAttribute> = new Vector.<ExtensionAttribute>();
		public var children:Vector.<XML> = new Vector.<XML>();
		
		public function ExtensionSpace()
		{
		}
		
		public function get Clone():ExtensionSpace
		{
			var newSpace:ExtensionSpace = new ExtensionSpace();
			newSpace.namespace = namespace;
			for each(var ea:ExtensionAttribute in attributes)
			{
				var newEa:ExtensionAttribute = new ExtensionAttribute();
				newEa.name = ea.name;
				newEa.namespace = ea.namespace;
				newEa.value = ea.value;
				newSpace.attributes.push(newEa);
			}
			for each(var child:XML in children)
			{
				newSpace.children.push(child.copy());
			}
			return newSpace;
		}
		
		public function attributesToString():String
		{
			var value:String = "";
			for each(var attribute:ExtensionAttribute in attributes)
				value += attribute.namespace.prefix + ":" + attribute.name + "=\""+attribute.value+"\" ";
			return value;
		}
		
		public function childrenToString():String
		{
			var value:String = "";
			for each(var child:XML in children)
				value += child.toXMLString();
			return value;
		}
	}
}