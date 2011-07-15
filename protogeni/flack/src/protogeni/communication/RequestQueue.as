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

package protogeni.communication
{
	/**
	 * Queue of requests
	 * 
	 * @author mstrum
	 * 
	 */
	public class RequestQueue
	{
		public var head:RequestQueueNode;
		public var tail:RequestQueueNode;
		public var nextRequest:RequestQueueNode;
		private var pushEvents:Boolean;
		
		public function RequestQueue(shouldPushEvents:Boolean = false) : void
		{
			head = null;
			nextRequest = null;
			tail = null;
			pushEvents = shouldPushEvents;
		}
		
		public function isEmpty() : Boolean
		{
			return head == null;
		}
		
		public function contains(item:*):Boolean
		{
			var parseNode:RequestQueueNode = head;
			if(item is RequestQueueNode)
			{
				while(parseNode != null)
				{
					if(parseNode == item)
						return true;
					parseNode = parseNode.next;
				}
			} else {
				while(parseNode != null)
				{
					if(parseNode.item == item)
						return true;
					parseNode = parseNode.next;
				}
			}
			return false;
		}
		
		/**
		 * Adds a new item onto the queue.  If a request, just pushes.  If a
		 * node, adds all all requests in the queue node's queue
		 * @param newItem
		 * 
		 */
		public function push(newItem:*) : void
		{
			var newNode:RequestQueueNode = null;
			var newTail:RequestQueueNode = null;
			
			// Set the new node and tail for the group which will be pushed
			if(newItem is RequestQueueNode)
			{
				newNode = newItem;
				newTail = newNode;
				while(newTail.next != null)
					newTail = newTail.next;
			}
			else
			{
				newNode = new RequestQueueNode(newItem);
				newTail = newNode;
			}
			
			// Queue isn't empty
			if (tail != null)
			{
				// Force this request to be called before nextRequest
				if(newNode.item.forceNext && nextRequest != null)
				{
					if(head == nextRequest)
						head = newNode;
					else {
						var parseNode:RequestQueueNode = head;
						while(parseNode.next != nextRequest)
							parseNode = parseNode.next;
						parseNode.next = newNode;
					}
					
					newTail.next = nextRequest;
					nextRequest = newNode;
				}
				// Tag on the end
				else
				{
					tail.next = newNode;
					if(nextRequest == null)
						nextRequest = newNode;
					tail = newTail;
				}
			}
			// Queue is currently empty
			else
			{
				head = newNode;
				nextRequest = newNode;
				tail = newTail;
			}
			
			if(pushEvents)
				Main.geniDispatcher.dispatchQueueChanged();
		}
		
		public function remove(removeNode:RequestQueueNode):void
		{
			// No node to add
			if(removeNode == null)
				return;
			
			// Removing the head
			if(head == removeNode)
			{
				// Move the next request back if it was the head
				if(nextRequest == head)
					nextRequest = head.next;
				head = head.next;
				// Update the tail if needed
				if(head == null)
					tail = null;
			}
			// Removing after the head
			else
			{
				// Start the search after the head
				var previousNode:RequestQueueNode = head;
				var currentNode:RequestQueueNode = head.next;
				
				// Keep looking until currentNode is the node to remove
				while(currentNode != null)
				{
					// Found our node to remove
					if(currentNode == removeNode)
					{
						// Was the next request, move to next
						if(nextRequest == currentNode)
							nextRequest = currentNode.next;
						// Have the previous node skip over this one
						previousNode.next = currentNode.next;
						// Update the tail if needed
						if(previousNode.next == null)
							tail = previousNode;
						if(pushEvents)
							Main.geniDispatcher.dispatchQueueChanged();
						return;
					}
					previousNode = previousNode.next;
					currentNode = currentNode.next;
				}
			}
			if(pushEvents)
				Main.geniDispatcher.dispatchQueueChanged();
		}
		
		public function working():Boolean
		{
			return head != null && nextRequest != head;
		}
		
		public function workingCount():int
		{
			var count:int = 0;
			var n:RequestQueueNode = head;
			
			while(n != null && n != nextRequest)
			{
				if((n.item as Request).running)
					count++;
				n = n.next;
			}
			
			return count;
		}
		
		public function waitingCount():int
		{
			var count:int = 0;
			var n:RequestQueueNode = head;
			
			while(n != null)
			{
				if(!(n.item as Request).running)
					count++;
				n = n.next;
			}
			
			return count;
		}
		
		public function readyToStart():Boolean
		{
			return head != null &&
				nextRequest != null &&
				(nextRequest == head || nextRequest.item.startImmediately == true);
		}
		
		public function front():*
		{
			if (head != null)
				return head.item;
			else
				return null;
		}
		
		public function nextAndProgress():*
		{
			var val:Object = next();
			if(val != null)
				nextRequest = nextRequest.next;
			return val;
		}
		
		public function next():*
		{
			if (nextRequest != null)
				return nextRequest.item;
			else
				return null;
		}
		
		/*
		public function pop() : void
		{
		if (head != null)
		{
		if(nextRequest == head)
		nextRequest = head.next;
		head = head.next;
		if(pushEvents)
		Main.geniDispatcher.dispatchQueueChanged();
		}
		if (head == null)
		{
		tail = null;
		nextRequest = null;
		}
		}
		*/
		
		public function getRequestQueueNodeFor(item:Request):RequestQueueNode
		{
			var parseNode:RequestQueueNode = head;
			while(parseNode != null)
			{
				if(parseNode.item == item)
					return parseNode;
				parseNode = parseNode.next;
			}
			return null;
		}
	}
}
