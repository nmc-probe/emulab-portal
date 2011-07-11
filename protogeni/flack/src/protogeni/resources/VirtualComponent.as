package protogeni.resources
{
	public class VirtualComponent
	{
		public static const STATUS_CHANGING:String = "changing";
		public static const STATUS_READY:String = "ready";
		public static const STATUS_NOTREADY:String = "notready";
		public static const STATUS_FAILED:String = "failed";
		public static const STATUS_UNKOWN:String = "unknown";
		
		[Bindable]
		public var clientId:String;
		[Bindable]
		public var sliverId:String;
		
		public var manifest:XML;
		
		[Bindable]
		public var slivers:SliverCollection;
		public function get sliver():Sliver {
			if(slivers != null && slivers.length > 0)
				return slivers.collection[0];
			else
				return null;
		}
		
		[Bindable]
		public var error:String = "";
		[Bindable]
		public var state:String = "N/A";
		[Bindable]
		public var status:String = "N/A";
		
		public function VirtualComponent(owner:Sliver = null)
		{
			this.slivers = new SliverCollection();
			if(owner != null)
				slivers.add(owner);
		}
	}
}