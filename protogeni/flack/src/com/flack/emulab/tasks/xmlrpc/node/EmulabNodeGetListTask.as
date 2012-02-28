package com.flack.emulab.tasks.xmlrpc.node
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.physical.PhysicalNode;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.docs.RspecVersion;
	import com.flack.shared.resources.sites.FlackManager;
	import com.flack.shared.tasks.TaskError;
	
	import flash.utils.Dictionary;
	
	public class EmulabNodeGetListTask extends EmulabXmlrpcTask
	{
		// proj, class, type, nodes
		private var nodeType:String = "";
		private var nodeClass:String = "";
		// "https://boss.emulab.net:3069/usr/testbed"
		public function EmulabNodeGetListTask(newType:String = "", newClass:String="")
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_NODE,
				EmulabXmlrpcTask.METHOD_GETLIST,
				"List nodes @ " + EmulabMain.manager.url,
				"Getting list of nodes at " + EmulabMain.manager.url,
				"List nodes"
			);
			nodeType = newType;
			nodeClass = newClass;
			relatedTo.push(EmulabMain.manager);
			EmulabMain.manager.Status = FlackManager.STATUS_INPROGRESS;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				EmulabMain.manager
			);
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			if(nodeType.length > 0)
				args["type"] = nodeType;
			if(nodeClass.length > 0)
				args["class"] = nodeClass;
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				EmulabMain.manager.advertisement = new Rspec(output, new RspecVersion(RspecVersion.TYPE_EMULAB, EmulabMain.manager.api.version), new Date(), new Date(), Rspec.TYPE_ADVERTISEMENT);
				
				for(var nodeId:String in data)
				{
					var nodeObject:Object = data[nodeId];
					
					var node:PhysicalNode = new PhysicalNode(EmulabMain.manager, nodeId);
					node.available = nodeObject.free;
					if(nodeObject.type != null)
						node.hardwareType = nodeObject.type;
					if(nodeObject.auxtypes != null)
					{
						var auxTypes:Array = nodeObject.auxtypes.split(',');
						for each(var auxType:String in auxTypes)
							node.auxTypes.push(auxType);
					}
					EmulabMain.manager.nodes.add(node);
				}
				
				EmulabMain.manager.Status = FlackManager.STATUS_VALID;
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_MANAGER,
					EmulabMain.manager,
					FlackEvent.ACTION_STATUS
				);
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_MANAGER,
					EmulabMain.manager,
					FlackEvent.ACTION_POPULATED
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
		
		override protected function afterError(taskError:TaskError):void
		{
			EmulabMain.manager.Status = FlackManager.STATUS_FAILED;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				EmulabMain.manager,
				FlackEvent.ACTION_STATUS
			);
			
			super.afterError(taskError);
		}
		
		override protected function runCancel():void
		{
			EmulabMain.manager.Status = FlackManager.STATUS_FAILED;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				EmulabMain.manager,
				FlackEvent.ACTION_STATUS
			);
		}
	}
}