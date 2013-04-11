package com.flack.geni.resources.virt.extensions.stitching
{
	public class RequestStitching
	{
		public var lastUpdateTime:Date;
		public var paths:StitchingPathCollection;
		public var dependencies:StitchingDependencyCollection;
		public function RequestStitching(newLastUpdateTime:Date=null, newPaths:StitchingPathCollection=null)
		{
			lastUpdateTime = newLastUpdateTime;
			if (newPaths != null) {
				paths = newPaths;
			} else {
				paths = new StitchingPathCollection();
			}
			dependencies = new StitchingDependencyCollection();
		}
	}
}