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
	 * Holds extension information for a parent object
	 * 
	 * @author mstrum
	 * 
	 */
	public class Extensions
	{
		public var spaces:ExtensionSpaceCollection;
		
		public function Extensions()
		{
			spaces = null;
		}
		
		public function get Clone():Extensions
		{
			var newExtensions:Extensions = new Extensions();
			if(spaces != null)
			{
				for each(var existingSpace:ExtensionSpace in spaces.collection)
				newExtensions.spaces.add(existingSpace.Clone);
			}
			return newExtensions;
		}
		
		static public function buildFromChildren(searchChildren:XMLList, ignoreNamespaces:Array):Extensions
		{
			var extensions:Extensions = new Extensions();
			var space:ExtensionSpace;
			
			for each(var searchChild:XML in searchChildren)
			{
				if(searchChild.name().uri.length == 0 || ignoreNamespaces.indexOf(searchChild.name().uri) != -1)
					continue;
				
				space = extensions.spaces.getForNamespace(searchChild.namespace());
				if(space == null)
				{
					space = new ExtensionSpace();
					space.namespace = searchChild.namespace();
					extensions.spaces.add(space);
				}
				
				space.children.push(searchChild);
			}
			return extensions;
		}
		
		public function buildFromOriginal(source:XML, ignoreNamespaces:Array):void
		{
			spaces = new ExtensionSpaceCollection();
			var space:ExtensionSpace;
			
			var searchAttributes:XMLList = source.attributes();
			for each(var searchAttribute:XML in searchAttributes)
			{
				if(searchAttribute.name().uri.length == 0 || ignoreNamespaces.indexOf(searchAttribute.name().uri) != -1)
					continue;
				
				if(spaces != null)
					space = spaces.getForNamespace(searchAttribute.namespace());
				if(space == null)
				{
					space = new ExtensionSpace();
					space.namespace = searchAttribute.namespace();
					spaces.add(space);
				}
				
				var newAttribute:ExtensionAttribute = new ExtensionAttribute();
				newAttribute.namespace = searchAttribute.namespace();
				newAttribute.name = searchAttribute.name().localName;
				newAttribute.value = searchAttribute.toString();
				space.attributes.push(newAttribute);
			}
			
			if(source.hasComplexContent())
			{
				var searchChildren:XMLList = source.children();
				for each(var searchChild:XML in searchChildren)
				{
					if(searchChild.name().uri.length == 0 || ignoreNamespaces.indexOf(searchChild.name().uri) != -1)
						continue;
					
					if(spaces != null)
						space = spaces.getForNamespace(searchChild.namespace());
					if(space == null)
					{
						space = new ExtensionSpace();
						space.namespace = searchChild.namespace();
						spaces.add(space);
					}
					
					space.children.push(searchChild);
				}
			}
		}
		
		public function createAndApply(name:String):XML
		{
			var namespaceString:String = "";
			var attributeString:String = "";
			var childString:String = "";
			if(spaces != null)
			{
				for each(var space:ExtensionSpace in spaces.collection)
				{
					if(space.namespace.prefix != null && space.namespace.prefix.length > 0)
						namespaceString += "xmlns:" + space.namespace.prefix + "=\"" + space.namespace.uri + "\" ";
					attributeString += space.attributesToString();
					childString += space.childrenToString();
				}
			}
			return new XML("<"+name+" "+namespaceString+" "+attributeString+">"+childString+"</"+name+">");
		}
		
		public function toString():String
		{
			var result:String = "";
			if(spaces != null)
			{
				for each(var space:ExtensionSpace in spaces.collection)
				{
					result += space.childrenToString();
				}
			}
			return result;
		}
	}
}