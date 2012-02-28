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

package com.flack.shared.logging 
{
	import com.flack.shared.SharedMain;

	/**
	 * Handles collections of log messages
	 * 
	 * @author mstrum
	 * 
	 */
	public class LogMessageCollection
	{
		public var collection:Vector.<LogMessage>;
		public function LogMessageCollection()
		{
			collection = new Vector.<LogMessage>();
		}
		
		public function add(msg:LogMessage):void
		{
			collection.push(msg);
		}
		
		public function remove(msg:LogMessage):void
		{
			var idx:int = collection.indexOf(msg);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(msg:LogMessage):Boolean
		{
			return collection.indexOf(msg) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function get Important():LogMessageCollection
		{
			var results:LogMessageCollection = new LogMessageCollection();
			for each(var msg:LogMessage in collection)
			{
				if(msg.importance == LogMessage.IMPORTANCE_HIGH)
					results.add(msg);
			}
			return results;
		}
		
		/**
		 * Returns log messages related to anything in related,
		 * can be a task to get a task's logs or an entity like a manager
		 * 
		 * @param related Items for which log messages should be related to
		 * @return Messages related to 'related'
		 * 
		 */
		public function getRelatedTo(related:Array):LogMessageCollection
		{
			var relatedLogs:LogMessageCollection = new LogMessageCollection();
			for each(var msg:LogMessage in collection)
			{
				for each(var relatedTo:* in related)
				{
					if(msg.relatedTo.indexOf(relatedTo) != -1)
					{
						relatedLogs.add(msg);
						break;
					}
				}
			}
			return relatedLogs;
		}
		
		public function toString():String
		{
			var output:String = "******* Messages *******\n" + SharedMain.ClientString+"\n************************\n";
			for each(var msg:LogMessage in collection)
				output +=  msg.toString(false) + "\n";
			return output;
		}
	}
}