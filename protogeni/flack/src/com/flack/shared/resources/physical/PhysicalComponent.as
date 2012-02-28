package protogeni.resources
{
	public class PhysicalComponent
	{
		[Bindable]
		public var name:String;
		
		[Bindable]
		public var id:String;
		
		[Bindable]
		public var manager:GeniManager;
		
		public var advertisement:XML;
		
		public function PhysicalComponent(newManager:GeniManager = null)
		{
			manager = newManager;
		}
	}
}