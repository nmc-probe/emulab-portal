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

package com.flack.geni.tasks.xmlrpc.am
{
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.tasks.TaskGroup;
	import com.flack.shared.tasks.xmlrpc.XmlrpcTask;
	
	import flash.events.Event;

	/**
	 * Supports the syntax for XML-RPC calls with GENI AM v1-2
	 * 
	 * @author mstrum
	 * 
	 */
	public class AmXmlrpcTask extends XmlrpcTask
	{
		// Methods
		public static const METHOD_CREATESLIVER:String = "CreateSliver";
		public static const METHOD_DELETESLIVER:String = "DeleteSliver";
		public static const METHOD_RENEWSLIVER:String = "RenewSliver";
		public static const METHOD_GETVERSION:String = "GetVersion";
		public static const METHOD_LISTRESOURCES:String = "ListResources";
		public static const METHOD_SLIVERSTATUS:String = "SliverStatus";
		
		// GENI response codes
		public static const GENICODE_SUCCESS:int = 0;
		public static const GENICODE_BADARGS:int  = 1;
		public static const GENICODE_ERROR:int = 2;
		public static const GENICODE_FORBIDDEN:int = 3;
		public static const GENICODE_BADVERSION:int = 4;
		public static const GENICODE_SERVERERROR:int = 5;
		public static const GENICODE_TOOBIG:int = 6;
		public static const GENICODE_REFUSED:int = 7;
		public static const GENICODE_TIMEDOUT:int = 8;
		public static const GENICODE_DBERROR:int = 9;
		public static const GENICODE_RPCERROR:int = 10;
		public static const GENICODE_UNAVAILABLE:int = 11;
		public static const GENICODE_SEARCHFAILED:int = 12;
		public static const GENICODE_UNSUPPORTED:int = 13;
		public static const GENICODE_BUSY:int = 14;
		public static const GENICODE_EXPIRED:int = 15;
		public static const GENICODE_INPROGRESS:int = 16;
		public static const GENICODE_ALREADYEXISTS:int = 17;
		public static function GeniresponseToString(value:int):String
		{
			switch(value)
			{
				case GENICODE_SUCCESS:return "Success";
				case GENICODE_BADARGS:return "Bad Arguments";
				case GENICODE_ERROR:return "Error";
				case GENICODE_FORBIDDEN:return "Operation Forbidden";
				case GENICODE_BADVERSION:return "Bad Version";
				case GENICODE_SERVERERROR:return "Server Error";
				case GENICODE_TOOBIG:return "Too Big";
				case GENICODE_REFUSED:return "Operation Refused";
				case GENICODE_TIMEDOUT:return "Operation Timed Out";
				case GENICODE_DBERROR:return "Database Error";
				case GENICODE_RPCERROR:return "RPC Error";
				case GENICODE_UNAVAILABLE:return "Unavailable";
				case GENICODE_SEARCHFAILED:return "Search Failed";
				case GENICODE_UNSUPPORTED:return "Operation Unsupported";
				case GENICODE_BUSY:return "Busy";
				case GENICODE_EXPIRED:return "Expired";
				case GENICODE_INPROGRESS:return "In progress";
				case GENICODE_INPROGRESS:return "Already Exists";
				default:return "Other error";
			}
		}
		
		/**
		 * API version to use, NaN means we don't know
		 */
		public var apiVersion:Number = NaN;
		
		/**
		 * Code as specified in a GENI XML-RPC result
		 */
		public var genicode:int;
		
		/**
		 * Output string specified in a GENI XML-RPC result
		 */
		public var output:String;
		
		/**
		 * Initializes a GENI AM XML-RPC call
		 * 
		 * @param taskUrl Base URL of the XML-RPC server
		 * @param taskMethodXML-RPC method being called (METHOD_*)
		 * @param taskApiVersion Version of the API to use
		 * @param taskName
		 * @param taskDescription
		 * @param taskShortName
		 * @param taskParent
		 * @param taskRetryWhenPossible
		 * 
		 */
		public function AmXmlrpcTask(taskUrl:String,
											taskMethod:String,
											taskApiVersion:Number,
											taskName:String = "GENI XML-RPC Task",
											taskDescription:String = "Communicates with a GENI XML-RPC service",
											taskShortName:String = "",
											taskParent:TaskGroup = null,
											taskRetryWhenPossible:Boolean = true)
		{
			super(
				taskUrl,
				taskMethod,
				taskName,
				taskDescription,
				taskShortName,
				taskParent,
				taskRetryWhenPossible
			);
			apiVersion = taskApiVersion;
		}
		
		/**
		 * Saves GENI AM API variables
		 * 
		 * @param event
		 * 
		 */
		override public function callSuccess(event:Event):void
		{
			cancelTimers();
			
			var response:Object = server.getResponse();
			
			// GetVersion doesn't specify, so the api version is in the response
			if(!apiVersion && response.geni_api != null)
				apiVersion = Number(response.geni_api);
			
			switch(this.apiVersion)
			{
				case 1:
					data = response;
					addMessage(
						"Received response",
						server._response.data
					);
					break;
				case 2:
				default:
					genicode = int(response.code.geni_code);
					// code.am_type
					// code.am_code
					output = response.output;
					
					// Restart if busy
					if(genicode == GENICODE_BUSY)
					{
						addMessage(
							"Server is busy",
							"GENI XML-RPC server reported busy. " + output,
							LogMessage.LEVEL_WARNING
						);
						runTryRetry();
						return;
					}
					else
					{
						data = response.value;
						
						var responseMsg:String = "Code = "+GeniresponseToString(genicode);
						if(output != null && output.length > 0)
							responseMsg += ",\nOutput = "+output;
						responseMsg += ",\nRaw Response:\n"+server._response.data
						addMessage(
							"Received response",
							responseMsg
						);
					}
					break;
			}
			
			afterComplete(false);
		}
		
		/**
		 * Recieved a code which wasn't expected, therefore an error
		 * 
		 */
		public function faultOnSuccess():void
		{
			var errorMessage:String = GeniresponseToString(genicode);
			if(output != null && output.length > 0)
				errorMessage += ": " + output;
			afterError(
				new TaskError(
					errorMessage,
					TaskError.FAULT
				)
			);
		}
	}
}