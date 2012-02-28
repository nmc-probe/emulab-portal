package com.flack.emulab.resources.virtual
{
	public class TarFile
	{
		public var directory:String;
		public var path:String;
		public function TarFile(newDirectory:String = "", newPath:String = "")
		{
			directory = newDirectory;
			path = newPath;
		}
	}
}