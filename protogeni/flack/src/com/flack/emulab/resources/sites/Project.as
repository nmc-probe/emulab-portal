package com.flack.emulab.resources.sites
{
	import com.flack.emulab.resources.NamedObject;

	public class Project extends NamedObject
	{
		public var subGroups:SubgroupCollection;
		
		public function Project(newName:String = "")
		{
			super(newName);
			subGroups = new SubgroupCollection();
		}
	}
}