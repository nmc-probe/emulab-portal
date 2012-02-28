package com.flack.emulab.resources.sites
{
	import com.flack.emulab.resources.NamedObject;

	public class Subgroup extends NamedObject
	{
		public var project:Project;
		
		public function Subgroup(newName:String = "", parentProject:Project = null)
		{
			super(newName);
			project = parentProject;
		}
	}
}