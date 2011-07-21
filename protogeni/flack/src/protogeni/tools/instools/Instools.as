package protogeni.tools.instools
{
	import com.adobe.crypto.SHA1;
	
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.utils.Dictionary;
	
	import protogeni.GeniEvent;
	import protogeni.resources.Slice;
	import protogeni.resources.Sliver;

	/**
	 * INSTOOLS support
	 * 
	 * @author jreed
	 * 
	 */
	public class Instools
	{
		// Communication stuff
		public static const instoolsModule:String = "instools";
		public static var instoolsGetVersion:Array = [instoolsModule, "GetINSTOOLSVersion"];
		public static var instoolsAddMCNode:Array = [instoolsModule, "AddMCNode"];
		public static var instoolsGetInstoolsStatus:Array = [instoolsModule, "getInstoolsStatus"];
		public static var instoolsInstrumentize:Array = [instoolsModule, "Instrumentize"];
		
		// State stuff
		public static var devel_version:Dictionary = new Dictionary();
		public static var stable_version:Dictionary = new Dictionary();
		
		public static var updated_rspec:Dictionary = new Dictionary();
		public static var rspec_version:Dictionary = new Dictionary();
		
		public static var instools_status:Dictionary = new Dictionary();
		public static var portal_url:Dictionary = new Dictionary();
		public static var started_instrumentize:Dictionary = new Dictionary();
		public static var started_MC:Dictionary = new Dictionary();

		public static function Clear(s:Sliver):void
		{
			devel_version[s.manager.Urn.full] = "";
			stable_version[s.manager.Urn.full] = "";
			updated_rspec[s.manager.Urn.full] = "";
			rspec_version[s.manager.Urn.full] = "";
			instools_status[s.manager.Urn.full] = "";
			portal_url[s.manager.Urn.full] = "";
			started_instrumentize[s.manager.Urn.full] = "";
			started_MC[s.manager.Urn.full] = "";
		}
		
		/**
		 * Attempts to instrumentize the slice
		 * 
		 * @param slice
		 * 
		 */
		public static function instrumentizeSlice(slice:Slice):void
		{
			// Gets the queue ready to start if it's paused and clears the slice status
			Main.geniHandler.requestHandler.isPaused = false;
			Main.geniHandler.requestHandler.forceStop = false;
			slice.clearState();
			var old:Slice = Main.geniHandler.CurrentUser.slices.getByUrn(slice.urn.full);
			if(old != null)
				old.clearState();
			Main.geniDispatcher.dispatchSliceChanged(slice, GeniEvent.ACTION_STATUS);
			
			for each(var sliver:Sliver in slice.slivers.collection)
			{
				Clear(sliver);
				Main.geniHandler.requestHandler.pushRequest(new RequestInstoolsVersion(sliver));
			}
		}
		
		public static function hasAnyPortal(slice:Slice):Boolean {
			for each(var sliver:Sliver in slice.slivers.collection) {
				if(portal_url[sliver.manager.Urn.full] != null
					&& portal_url[sliver.manager.Urn.full].length > 0)
					return true;
			}
			return false;
		}
		
		/**
		 * Opens a browser to the instools portal site
		 * 
		 * @param slice
		 * 
		 */
		public static function goToPortal(slice:Slice):void
		{
			var data:String = Main.geniHandler.CurrentUser.passwd;
			var out:String = SHA1.hash(data);
			//var boo:String = "secretkey";
			//var out:String = Util.rc4encrypt(boo,data);
			//out = encodeURI(out);
			var userinfo:Array = Main.geniHandler.CurrentUser.hrn.split(".");
			var portalURL:String = "https://portal.uky.emulab.net/geni/portal/log_on_slice.php";
			var portalVars:URLVariables = new URLVariables();
			portalVars.user = userinfo[1];
			portalVars.cert = userinfo[0];
			portalVars.slice = slice.Name;
			portalVars.pass = out;
			var req:URLRequest = new URLRequest(portalURL);
			req.data = portalVars;
			navigateToURL(req, "_blank");
		}
	}
}