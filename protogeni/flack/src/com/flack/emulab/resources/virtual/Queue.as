package com.flack.emulab.resources.virtual
{
	public class Queue
	{
		public var gentle:int = 0;
		public var red:int = 0;
		public var queueInBytes:int = 0;
		public var limit:int = 50; // max limit is 1 megabyte if bytes or 100 slots if slots
		public var maxThresh:int = 15;
		public var thresh:int = 5;
		public var linterm:int = 10;
		public var qWeight:Number = .002;
		
		public function Queue()
		{
		}
	}
}