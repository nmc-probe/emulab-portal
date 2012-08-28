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

package com.flack.emulab.resources.physical
{
	import com.flack.emulab.resources.NamedObject;

	/**
	 * Disk image used for a resource
	 * 
	 * @author mstrum
	 * 
	 */
	public class Osid extends NamedObject
	{
		public var os:String;
		public var description:String;
		public var pid:String;
		public var version:String;
		public var creator:String;
		public var created:Date;
		// new?
		public var osfeatures:Vector.<String> = new Vector.<String>();
		//public var fullosid:String;
		//public var shared:Boolean;
		
		public function Osid(newName:String = "",
								  newOs:String = "",
								  newVersion:String = "",
								  newDescription:String = "",
								  newPid:String = "",
								  newCreator:String = "",
								  newCreated:Date = null)
		{
			super(newName);
			os = newOs;
			version = newVersion;
			description = newDescription;
			pid = newPid;
			creator = newCreator;
			created = newCreated;
		}
	}
}