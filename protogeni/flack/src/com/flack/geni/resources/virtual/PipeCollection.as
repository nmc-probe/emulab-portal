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
	/**
	 * Collection of pipes
	 * @author mstrum
	 * 
	 */
	public class PipeCollection
	{
		public var collection:Vector.<Pipe>;
		public function PipeCollection()
		{
			collection = new Vector.<Pipe>();
		}
		
		public function add(p:Pipe):void
		{
			collection.push(p);
		}
		
		public function remove(p:Pipe):void
		{
			var idx:int = collection.indexOf(p);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param source Source interface
		 * @param destination Destination interface
		 * @return Pipe matching the parameters
		 * 
		 */
		public function getFor(source:VirtualInterface, destination:VirtualInterface):Pipe
		{
			for each(var pipe:Pipe in collection)
			{
				if(pipe.src == source && pipe.dst == destination)
					return pipe;
			}
			return null;
		}
		
		/**
		 * 
		 * @param source Source interface
		 * @return Pipes with the given source
		 * 
		 */
		public function getForSource(source:VirtualInterface):PipeCollection
		{
			var result:PipeCollection = new PipeCollection();
			for each(var pipe:Pipe in collection)
			{
				if(pipe.src == source)
					result.add(pipe);
			}
			return result;
		}
		
		/**
		 * 
		 * @param destination Destination interface
		 * @return Pipes with the given destination
		 * 
		 */
		public function getForDestination(destination:VirtualInterface):PipeCollection
		{
			var result:PipeCollection = new PipeCollection();
			for each(var pipe:Pipe in collection)
			{
				if(pipe.dst == destination)
					result.add(pipe);
			}
			return result;
		}
		
		/**
		 * 
		 * @param test Interface
		 * @return Pipes with the source or destination as the given interface
		 * 
		 */
		public function getForAny(test:VirtualInterface):PipeCollection
		{
			var result:PipeCollection = new PipeCollection();
			for each(var pipe:Pipe in collection)
			{
				if(pipe.dst == test || pipe.src == test)
					result.add(pipe);
			}
			return result;
		}
	}
}