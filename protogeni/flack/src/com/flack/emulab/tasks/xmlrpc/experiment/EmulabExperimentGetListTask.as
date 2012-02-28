package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.resources.virtual.ExperimentCollection;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentGetListTask extends EmulabXmlrpcTask
	{
		static public const FORMAT_BRIEF:String = "brief";
		static public const FORMAT_FULL:String = "full";
		
		// optional
		private var format:String;
		public function EmulabExperimentGetListTask(newFormat:String = FORMAT_FULL)
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_GETLIST,
				"Get number of used nodes @ " + EmulabMain.manager.api.url,
				"Getting node availability at " + EmulabMain.manager.api.url,
				"# Nodes Used"
			);
			format = newFormat;
			relatedTo.push(EmulabMain.user);
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			if(format.length > 0)
				args["format"] = format;
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				EmulabMain.user.experiments = new ExperimentCollection();
				for(var projName:String in data)
				{
					var projects:Object = data[projName];
					for(var subGroupName:String in projects)
					{
						var experiments:Array = projects[subGroupName];
						for each(var experimentObj:Object in experiments)
						{
							var userExperiment:Experiment = new Experiment(EmulabMain.manager);
							userExperiment.creator = EmulabMain.user;
							userExperiment.pid = projName;
							userExperiment.gid = subGroupName;
							userExperiment.manager = EmulabMain.manager;
							
							if(experimentObj is String)
								userExperiment.name = experimentObj as String;
							else
							{
								userExperiment.name = experimentObj["name"];
								userExperiment.description = experimentObj["description"];
							}
							EmulabMain.user.experiments.add(userExperiment);
							SharedMain.sharedDispatcher.dispatchChanged(
								FlackEvent.CHANGED_EXPERIMENT,
								userExperiment,
								FlackEvent.ACTION_CREATED
							);
							SharedMain.sharedDispatcher.dispatchChanged(
								FlackEvent.CHANGED_EXPERIMENTS,
								userExperiment,
								FlackEvent.ACTION_ADDED
							);
							
						}
					}
				}
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_USER,
					EmulabMain.user
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}