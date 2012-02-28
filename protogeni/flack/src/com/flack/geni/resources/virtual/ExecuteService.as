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

	/**
	 * Script to run on a resource post-create
	 * 
	 * @author mstrum
	 * 
	 */
	public class ExecuteService
	{
		public var shell:String;
		public var command:String;
		public var extensions:Extensions = new Extensions();
		
		/**
		 * 
		 * @param newCommand Command to execute
		 * @param newShell Shell to run on
		 * 
		 */
		public function ExecuteService(newCommand:String = "",
									   newShell:String = "sh")
		{
			shell = newShell;
			command = newCommand;
		}
	}
}