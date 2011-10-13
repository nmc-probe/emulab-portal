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
	import com.mattism.http.xmlrpc.MethodFault;
	
	import flash.events.ErrorEvent;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	import protogeni.NetUtil;
	import protogeni.Util;
	import protogeni.display.DisplayUtil;
	import protogeni.resources.GeniManager;
	import protogeni.resources.IdnUrn;
	import protogeni.resources.ProtogeniComponentManager;
	import protogeni.resources.Slice;
	import protogeni.resources.Sliver;
	import protogeni.resources.SliverCollection;

	/**
	 * Handles all XML-RPC and HTTP requests
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GeniRequestHandler
	{
		public var queue:RequestQueue = new RequestQueue(true);
		public var forceStop:Boolean = false;
		public var isPaused:Boolean = false;
		
		[Bindable]
		public var maxRunning:int = 5;
		
		public function GeniRequestHandler()
		{
		}

		/**
		 * Starts the sequence to get all GENI information
		 * 
		 * @param tryAuthenticate Does the user want to authenticate?
		 * 
		 */
		public function startInitiationSequence(tryAuthenticate:Boolean = false):void
		{
			if(Main.geniHandler.unauthenticatedMode && !tryAuthenticate) {
				pushRequest(new RequestListComponentsPublic());
				Main.Application().showAuthenticate();
			} else if(Main.geniHandler.unauthenticatedMode
				|| Main.geniHandler.CurrentUser.authority == null) {
				DisplayUtil.viewInitialUserWindow();
			} else {
				startAuthenticatedInitiationSequence(true);
			}
		}
		
		/**
		 * Starts authenticated GENI calls
		 * 
		 */
		public function startAuthenticatedInitiationSequence(getSlices:Boolean = true, getManager:GeniManager = null):void
		{
			if(Main.geniHandler.unauthenticatedMode) {
				DisplayUtil.viewInitialUserWindow();
				return;
			}
			this.isPaused = false;
			this.forceStop = false;
			if(Main.geniHandler.CurrentUser.Credential.length == 0) {
				pushRequest(new RequestGetCredential());
				pushRequest(new RequestGetKeys());
			}
			
			if(getManager != null) {
				if(getManager.isAm)
					pushRequest(new RequestGetVersionAm(getManager));
				else
					pushRequest(new RequestGetVersion(getManager as ProtogeniComponentManager));
			} else
				loadListAndComponentManagers(getSlices);
			Main.Application().hideAuthenticate();
		}
		
		/**
		 * Adds calls to get the list of component managers
		 * 
		 */
		public function loadListAndComponentManagers(getSlices:Boolean = false):void
		{
			/*var newCm:ProtogeniComponentManager = new ProtogeniComponentManager();
			newCm.isAm = true;
			newCm.Hrn = "beelab.cm";
			newCm.Url = "https://myboss.geelab.geni.emulab.net/protogeni/xmlrpc/am";
			newCm.Urn = new IdnUrn("urn:publicid:IDN+geelab.geni.emulab.net+authority+cm");
			Main.geniHandler.GeniManagers.add(newCm);
			newCm.Status = GeniManager.STATUS_INPROGRESS;
			this.pushRequest(new RequestGetVersionAm(newCm));*/
			
			if(!Main.useCache) {
				if(Main.geniHandler.unauthenticatedMode)
					pushRequest(new RequestListComponentsPublic());
				else
					pushRequest(new RequestListComponents(true, getSlices));
			} else {
				FlackCache.applyOffline(false, loadUserAndSlices);
			}
		}
		
		public function loadUserAndSlices():void
		{
			if(Main.geniHandler.CurrentUser.userCredential.length > 0)
				this.pushRequest(new RequestUserResolve());
			else if(Main.geniHandler.CurrentUser.sliceCredential.length > 0) {
				for each(var slice:Slice in Main.geniHandler.CurrentUser.slices) {
					if(slice.credential == Main.geniHandler.CurrentUser.sliceCredential) {
						Main.geniHandler.requestHandler.discoverSliceAllocatedResources(slice);
						break;
					}
				}
			}
		}
		
		/**
		 * Adds calls to get advertisements from all of the managers
		 * 
		 */
		public function loadComponentManagers():void
		{
			for each(var cm:ProtogeniComponentManager in Main.geniHandler.GeniManagers)
			{
				if(Main.geniHandler.unauthenticatedMode) {
					cm.Status = GeniManager.STATUS_INPROGRESS;
					Main.geniDispatcher.dispatchGeniManagerChanged(cm);
					pushRequest(new RequestDiscoverResourcesPublic(cm));
				}
				else
					pushRequest(new RequestGetVersion(cm));
			}
		}
		
		public function discoverSliceAllocatedResources(slice:Slice):void {
			for each(var manager:GeniManager in Main.geniHandler.GeniManagers) {
				if(manager.Status != GeniManager.STATUS_VALID)
					continue;
				var newSliver:Sliver = new Sliver(slice, manager);
				if(manager.isAm)
					this.pushRequest(new RequestSliverListResourcesAm(newSliver));
				else
					this.pushRequest(new RequestSliverGet(newSliver));
			}
		}
		
		/**
		 * Creates a blank slice for the user to use
		 * 
		 * @param name
		 * 
		 */
		public function createSlice(name:String):void
		{
			this.isPaused = false;
			this.forceStop = false;
			
			var newSlice:Slice = new Slice();
			newSlice.hrn = name;
			newSlice.urn = IdnUrn.makeFrom(Main.geniHandler.CurrentUser.authority.Urn.authority, "slice", name);
			newSlice.creator = Main.geniHandler.CurrentUser;
			pushRequest(new RequestSliceResolve(newSlice, true));
		}
		
		/**
		 * Takes a slice that has been prepared and tries to allocate all of the resources
		 * 
		 * @param slice Slice with everything the user wants to allocate
		 * 
		 */
		public function submitSlice(slice:Slice):void
		{
			this.isPaused = false;
			this.forceStop = false;
			
			// Invalidate the slice
			slice.clearState();
			var old:Slice = Main.geniHandler.CurrentUser.slices.getByUrn(slice.urn.full);
			if(old != null)
				old.clearState();
			Main.geniDispatcher.dispatchSliceChanged(slice);
			
			var sliver:Sliver;
			if(old != null && old.slivers.AllocatedAnyResources)
			{
				var newSlivers:SliverCollection = new SliverCollection();
				var deleteSlivers:SliverCollection = new SliverCollection();
				var updateSlivers:SliverCollection = new SliverCollection();
				for each(var oldSliver:Sliver in old.slivers.collection) {
					if(slice.slivers.getByManager(oldSliver.manager) == null)
						deleteSlivers.add(oldSliver);
				}
				for each(var newSliver:Sliver in slice.slivers.collection) {
					if(old.slivers.getByManager(newSliver.manager) == null)
						newSlivers.add(newSliver);
					else
						updateSlivers.add(newSliver);
				}
				Main.geniHandler.CurrentUser.slices.addOrReplace(slice);
				
				// Delete
				for each(sliver in deleteSlivers.collection) {
					if(sliver.manager.isAm)
						pushRequest(new RequestSliverDeleteAm(sliver));
					else
						pushRequest(new RequestSliverDelete(sliver));
				}
				
				for each(sliver in updateSlivers.collection) {
					if(sliver.manager.isAm) {
						// Don't do for now
						//pushRequest(new RequestSliverDeleteAm(sliver));
						//pushRequest(new RequestSliverCreateAm(sliver));
					} else
						pushRequest(new RequestSliverUpdate(sliver));
				}
				
				// Create
				for each(sliver in newSlivers.collection) {
					if(sliver.manager.isAm)
						pushRequest(new RequestSliverCreateAm(sliver));
					else
						pushRequest(new RequestSliverCreate(sliver));
				}
			} else {
				// Create
				if(slice.slivers.length > 0) {
					Main.geniHandler.CurrentUser.slices.addOrReplace(slice);
					for each(sliver in slice.slivers.collection) {
						if(sliver.manager.isAm)
							pushRequest(new RequestSliverCreateAm(sliver));
						else
							pushRequest(new RequestSliverCreate(sliver));
					}
				}
			}
		}
		
		/**
		 * Gets the status for all of the slivers in the slice
		 * 
		 * @param slice Slice to get the status from
		 * @param skipDone Skip slivers which are ready
		 * 
		 */
		public function refreshSlice(slice:Slice, skipDone:Boolean = false):void
		{
			this.isPaused = false;
			this.forceStop = false;
			
			if(slice.slivers.length > 0) {
				Main.geniHandler.CurrentUser.slices.addOrReplace(slice);
				for each(var sliver:Sliver in slice.slivers.collection) {
					if((skipDone && sliver.StatusFinalized) || !sliver.processed)
						continue;
					if(sliver.manager.isAm)
						pushRequest(new RequestSliverStatusAm(sliver));
					else if(sliver.manager is ProtogeniComponentManager)
						pushRequest(new RequestSliverStatus(sliver));
				}
			}
		}
		
		/**
		 * Redownloads everything for a slice
		 * 
		 * @param slice Slice to redownload everything
		 * 
		 */
		public function regetSlice(slice:Slice):void
		{
			this.isPaused = false;
			this.forceStop = false;
			
			slice.clearState();
			for each(var sliver:Sliver in slice.slivers.collection) {
				sliver.removeOutsideReferences();
			}
			slice.slivers = new SliverCollection();
			Main.geniHandler.CurrentUser.slices.addOrReplace(slice);
			
			// User only has a slice credential
			if(Main.geniHandler.CurrentUser.userCredential.length == 0) {
				this.discoverSliceAllocatedResources(slice);
			}
			// User has user credential
			else
				this.pushRequest(new RequestSliceCredential(slice, true));
		}
		
		
		/**
		 * Re-loads all of the slices from scratch
		 * 
		 */
		public function regetSlices():void
		{
			this.isPaused = false;
			this.forceStop = false;
			
			// User only has a slice credential
			if(Main.geniHandler.CurrentUser.userCredential.length == 0) {
				for each(var slice:Slice in Main.geniHandler.CurrentUser.slices)
					this.regetSlice(slice);
			} else
				this.pushRequest(new RequestUserResolve());
		}
		
		/**
		 * Deallocate all resources in the slice
		 * 
		 * @param slice Slice to release resources from
		 * 
		 */
		public function deleteSlice(slice:Slice):void
		{
			this.isPaused = false;
			this.forceStop = false;
			
			// Cancel remaining calls
			var tryDeleteNode:RequestQueueNode = this.queue.head;
			while(tryDeleteNode != null)
			{
				var testSlice:Slice = null;
				if(tryDeleteNode.item.sliver != null)
					testSlice = tryDeleteNode.item.sliver.slice;
				else if(tryDeleteNode.item.slice != null)
					testSlice = tryDeleteNode.item.slice;
				if(testSlice != null && testSlice.urn.full == slice.urn.full)
					this.remove(tryDeleteNode.item, false);
				tryDeleteNode = tryDeleteNode.next;
			}
			
			if(slice.slivers.length > 0) {
				Main.geniHandler.CurrentUser.slices.addOrReplace(slice);
				// SliceRemove doesn't work because the slice hasn't expired yet...
				for each(var sliver:Sliver in slice.slivers.collection)
				{
					if(sliver.manager.isAm)
						this.pushRequest(new RequestSliverDeleteAm(sliver));
					else if(sliver.manager is ProtogeniComponentManager)
						this.pushRequest(new RequestSliverDelete(sliver));
				}
				Main.geniDispatcher.dispatchSliceChanged(slice);
			}
		}
		
		/**
		 * Renews a slice and/or slivers to the minimum times needed to use
		 * the new expiration date
		 *  
		 * @param slice Slice to renew
		 * @param newExpiresDate Date to ensure slice and slivers don't expire until
		 * 
		 */
		public function renewSlice(slice:Slice, newExpiresDate:Date):void {
			this.isPaused = false;
			this.forceStop = false;
			
			if(newExpiresDate.time < slice.expires.time) {
				for each(var sliver:Sliver in slice.slivers.collection) {
					if(sliver.expires.time < newExpiresDate.time) {
						if(sliver.manager.isAm)
							this.pushRequest(new RequestSliverRenewAm(sliver, newExpiresDate));
						else
							this.pushRequest(new RequestSliverRenew(sliver, newExpiresDate));
					}
				}
			} else
				this.pushRequest(new RequestSliceRenew(slice, newExpiresDate, true));
			Main.geniDispatcher.dispatchSliceChanged(slice);
		}
		
		/**
		 * Bind unbound nodes in a slice
		 * 
		 * @param slice Slice which to bind all nodes
		 * 
		 */
		public function embedSlice(slice:Slice):void {
			for each(var sliver:Sliver in slice.slivers.collection)
			{
				pushRequest(new RequestSliceEmbedding(sliver));
			}
		}
		
		/**
		 * Starts all of the resources in a slice
		 * 
		 * @param slice Slice which to start resources
		 * 
		 */
		public function startSlice(slice:Slice):void
		{
			if(slice.slivers.length > 0) {
				Main.geniHandler.CurrentUser.slices.addOrReplace(slice);
				for each(var sliver:Sliver in slice.slivers.collection)
				pushRequest(new RequestSliverStart(sliver));
			}
		}
		
		/**
		 * Stops a slice
		 * 
		 * @param slice Slice to stop
		 * 
		 */
		public function stopSlice(slice:Slice):void
		{
			if(slice.slivers.length > 0) {
				Main.geniHandler.CurrentUser.slices.addOrReplace(slice);
				for each(var sliver:Sliver in slice.slivers.collection)
					pushRequest(new RequestSliverStop(sliver));
			}
		}
		
		/**
		 * Restarts a slice
		 * 
		 * @param slice Slice to restart
		 * 
		 */
		public function restartSlice(slice:Slice):void
		{
			if(slice.slivers.length > 0) {
				Main.geniHandler.CurrentUser.slices.addOrReplace(slice);
				for each(var sliver:Sliver in slice.slivers.collection)
				{
					pushRequest(new RequestSliverRestart(sliver));
				}
			}
		}
		
		/**
		 * Adds a request to be called to the request queue
		 * 
		 * @param newRequest Request to add to the queue
		 * @param forceStart Start the queue immediately?
		 * 
		 */
		public function pushRequest(newRequest:Request, forceStart:Boolean = true):void
		{
			if (newRequest != null)
			{
				queue.push(newRequest);
				if (queue.readyToStart() && forceStart && !isPaused)
				{
					start();
				}
			}
		}
		
		/**
		 * Start the request queue
		 * 
		 * @param continuous Continue making calls?
		 * 
		 */
		public function start(continuous:Boolean = true):void
		{
			isPaused = false;
			forceStop = false;
			if(!queue.readyToStart())
				return;
			
			if(queue.workingCount() < maxRunning) {
				var start:Request = queue.nextAndProgress();
				start.running = true;
				var op:Operation = start.start();
				if(op == null) {
					start.running = false;
					this.remove(start);
				} else {
					start.numTries++;
					op.call(complete, failure);
					Main.Application().setStatus(start.name, false);
					var delayNotice:String = "";
					if(op.delaySeconds > 0)
						delayNotice = "Delayed for " + op.delaySeconds + " seconds...\n\n";
					LogHandler.appendMessage(new LogMessage(op.getUrl(),
						start.name,
						delayNotice + start.getSent(),
						LogMessage.ERROR_NONE,
						LogMessage.TYPE_START));
					
					Main.geniDispatcher.dispatchQueueChanged();
				}
				
				if(continuous)
					this.start();
				else
					pause();
			}
		}
		
		/**
		 * Stop the queue from making any new requests until the user flags to start again
		 * 
		 */
		public function pause():void
		{
			isPaused = true;
		}
		
		/**
		 * Pauses and removes all requests in the queue
		 * 
		 */
		public function stop():void
		{
			pause();
			removeAll();
		}
		
		/**
		 * Removes all requests in the queue
		 * 
		 */
		public function removeAll():void {
			while(queue.head != null) {
				remove(queue.head.item as Request, true);
			}
		}
		
		/**
		 * Removes a request from the queue
		 * @param request Request to add
		 * @param showAction Show the action in the logs?
		 * 
		 */
		public function remove(request:Request, showAction:Boolean = true):void
		{
			if(request.running)
			{
				Main.Application().setStatus(request.name + " canceled!", false);
				request.cancel();
				request.running = false;
			}
			queue.remove(queue.getRequestQueueNodeFor(request));
			if(showAction)
			{
				var url:String = request.op.getUrl();
				var name:String = request.name;
				LogHandler.appendMessage(new LogMessage(url,
														name + " removed",
														"Request removed",
														LogMessage.ERROR_NONE,
														LogMessage.TYPE_OTHER));
				if(!queue.working())
					tryNext();
			}
			Main.geniDispatcher.dispatchQueueChanged();
		}
		
		/**
		 * Called after request failures
		 * 
		 * @param node Request which failed
		 * @param event Related event
		 * @param fault Related fault
		 * 
		 */
		private function failure(request:Request, event:ErrorEvent, fault:MethodFault):void
		{
			// Ignore if it isn't running anymore
			if(!request.running)
				return;
			
			request.running = false;
			remove(request, false);
			
			var next:*;
			
			// Timeout
			if(event.errorID == CommunicationUtil.TIMEOUT && request.retryOnTimeout) {
				// backoff using the first number as the basic unit of seconds
				request.op.delaySeconds = Util.randomNumberBetween(20, 40+request.numTries*10);
				request.forceNext = !request.startImmediately;
				next = request;
				LogHandler.appendMessage(new LogMessage(request.op.getUrl(),
					request.name + " timeout",
					"Preparing to retry in " + request.op.delaySeconds  + " seconds",
					LogMessage.ERROR_WARNING,
					LogMessage.TYPE_END ));
			// Server not currently working
			} else if(fault != null && fault.getFaultCode() == CommunicationUtil.XMLRPC_CURRENTLYNOTAVAILABLE && request.retryOnError){
				// backoff using the first number as the basic unit of seconds
				request.op.delaySeconds = Util.randomNumberBetween(40, 60+request.numTries*20);
				request.forceNext = !request.startImmediately;
				next = request;
				LogHandler.appendMessage(new LogMessage(request.op.getUrl(),
					"Server currently not available",
					"Preparing to retry in " + request.op.delaySeconds  + " seconds",
					LogMessage.ERROR_WARNING,
					LogMessage.TYPE_END ));
			// Get and give general info for the failure
			} else {
				var failMessage:String = "";
				var msg:String = "";
				var showAlert:Boolean = false;
				var alertText:String = "";
				if (fault != null)
				{
					msg = fault.toString();
					failMessage += "\nFAILURE fault: " + request.name + ": " + msg;
				}
				else
				{
					msg = event.toString();
					failMessage += "\nFAILURE event: " + request.name + ": " + msg;
					if(msg.search("#2048") > -1)
						failMessage += "\nStream error, possibly due to server error\n\n****Very possible that this server has not added a Flash socket security policy server****";
					else if(msg.search("#2032") > -1) {
						if(Main.geniHandler.unauthenticatedMode)
							failMessage += "\nIO Error, possibly due to server problems";
						else
							failMessage += "\nIO Error, possibly due to server problems or you have no SSL certificate";
					}
					else if(msg.search("Certificate revoked") > -1)
					{
						showAlert = true;
						alertText = "Certificate no longer valid, please make sure your are using your newest certificate!";
					}
					
				}
				failMessage += "\nURL: " + request.op.getUrl();
				LogHandler.appendMessage(new LogMessage(request.op.getUrl(),
					request.name,
					failMessage,
					LogMessage.ERROR_FAIL,
					LogMessage.TYPE_END));
				Main.Application().setStatus(request.name + " failed!", true);
				
				if(!request.continueOnError) {
					this.pause();
					LogHandler.viewConsole();
				} else
					next = request.fail(event, fault);
				
				if(showAlert)
					Alert.show(alertText);
			}
			
			// Find out what to do next
			request.cleanup();
			if (next != null)
				queue.push(next);
			
			tryNext();
			
			/*if(msg.search("#2048") > -1 || msg.search("#2032") > -1)
			{
				if(!Main.geniHandler.unauthenticatedMode
					&& Main.geniHandler.CurrentUser.Credential.length == 0)
				{
					Alert.show("It appears that you may have never run this program before.  In order to run correctly, you will need to follow the steps at https://www.protogeni.net/trac/protogeni/wiki/FlashClientSetup.  Would you like to visit now?", "Set up", Alert.YES | Alert.NO, Main.Application(),
						function runSetup(e:CloseEvent):void
						{
							if(e.detail == Alert.YES)
							{
								NetUtil.showBecomingAUser();
							}
						});
				}
			}*/
		}
		
		/**
		 * Called after successful request
		 * 
		 * @param request
		 * @param code ProtoGENI response code
		 * @param response
		 * 
		 */
		private function complete(request:Request, code:Number, response:Object):void
		{
			// Ignore if it isn't running anymore
			if(!request.running)
				return;
			
			if(request.removeImmediately)
			{
				request.running = false;
				remove(request, false);
			}
			
			var next:* = null;
			try
			{
				if(code == CommunicationUtil.GENIRESPONSE_BUSY) {
					Main.Application().setStatus(request.name + " busy", true);
					// exponential backoff using the first number as the basic unit of seconds
					request.op.delaySeconds = Math.min(60, Util.randomNumberBetween(10, 10 + Math.pow(2,request.numTries)));
					request.forceNext = !request.startImmediately;
					next = request;
					LogHandler.appendMessage(new LogMessage(request.op.getUrl(),
						request.name + " busy",
						"Preparing to retry in " + request.op.delaySeconds  + " seconds",
						LogMessage.ERROR_WARNING,
						LogMessage.TYPE_END ));
				} else {
					next = request.complete(code, response);
					if(code != CommunicationUtil.GENIRESPONSE_SUCCESS && !request.ignoreReturnCode)
					{
						Main.Application().setStatus(request.name + " done", true);
						LogHandler.appendMessage(new LogMessage(request.op.getUrl(),
																CommunicationUtil.GeniresponseToString(code),
							"------------------------\nResponse:\n" +
							request.getResponse() +
							"\n\n------------------------\nRequest:\n" + request.getSent(),
							LogMessage.ERROR_FAIL,
							LogMessage.TYPE_END));
					} else {
						Main.Application().setStatus(request.name + " done", false);
						LogHandler.appendMessage(new LogMessage(request.op.getUrl(),
																request.name,
																request.getResponse(),
																LogMessage.ERROR_NONE,
																LogMessage.TYPE_END));
					}
					
				}
			}
			catch (e:Error)
			{
				codeFailure(request.name, "Error caught in RPC-Handler Complete",
							e,
							!(queue.front() as Request).continueOnError);
				request.removeImmediately = true;
				if(request.running)
				{
					request.running = false;
					remove(request, false);
				}
				if(!request.continueOnError)
					return;
			}
			
			// Find out what to do next
			if(request.removeImmediately)
				request.cleanup();
			
			// Add any requests this request added
			if (next != null)
				queue.push(next);
			
			// Add post-requests
			if(request.addAfter != null) {
				// Don't add the next request if we are resending
				if(request is Request && request != next) {
					queue.push(request.addAfter);
				} else if(request is RequestQueueNode) {
					var testNode:RequestQueueNode = request as RequestQueueNode;
					var foundOld:Boolean = false;
					while(testNode != null) {
						if(testNode.item == request)
							foundOld = true;
					}
					if(!foundOld)
						queue.push(request.addAfter);
				}
			}
				
			
			tryNext();
		}
		
		/**
		 * Call one request
		 * 
		 */
		public function step():void {
			isPaused = false;
			forceStop = false;
			tryNext(false);
		}
		
		/**
		 * Trys to start the next request
		 * 
		 * @param continuous Continue making calls?
		 * 
		 */
		public function tryNext(continuous:Boolean = true):void
		{
			if(!forceStop && !isPaused)
				start(continuous);
			else
				forceStop = false;
		}
		
		/**
		 * Just sets the head of the queue to null instead of removing all requests
		 * 
		 */
		public function clearAll():void
		{
			// Should probably be different
			this.queue.head = null;
		}
		
		/**
		 * Something wrong happend in code instead of the request
		 * 
		 * @param name
		 * @param detail
		 * @param e
		 * @param stop
		 * 
		 */
		public function codeFailure(name:String,
									detail:String = "",
									e:Error = null,
									stop:Boolean = true):void
		{
			if(stop)
			{
				LogHandler.viewConsole();
				forceStop = true;
			}
			
			if(e != null)
				LogHandler.appendMessage(new LogMessage("",
														"Code Failure: " + name,detail + "\n\n" + e.toString() + "\n\n" + e.getStackTrace(),
														LogMessage.ERROR_FAIL,
														LogMessage.TYPE_END));
			else
				LogHandler.appendMessage(new LogMessage("",
														"Code Failure: " + name,
														detail,
														LogMessage.ERROR_FAIL,
														LogMessage.TYPE_END));
			
		}
	}
}