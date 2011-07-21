package protogeni.resources
{
	import protogeni.Util;

	public class GeniCredential
	{
		private var _raw:String = "";
		public function get Raw():String {
			return _raw;
		}
		public function set Raw(value:String):void {
			if(value == null || value.length == 0) {
				_raw = "";
				return;
			}
			_raw = value;
		}
		public function toXml():XML {
			if(_raw.length == 0)
				return null;
			try {
				var newXml:XML = new XML(_raw);
				if(newXml.toXMLString().length == 0)
					return null;
				return newXml;
			} catch(e:Error) {}
			return null;
		}
		
		static public function getOwnerUrn(credential:XML):IdnUrn {
			try {
				return new IdnUrn(credential.credential.owner_urn)
			} catch(e:Error) {}
			return null;
		}
		
		static public function getTargetUrn(credential:XML):IdnUrn {
			try {
				return new IdnUrn(credential.credential.target_urn)
			} catch(e:Error) {}
			return null;
		}
		
		static public function getExpires(credential:XML):Date {
			try {
				return Util.parseProtogeniDate(credential.credential.expires);
			} catch(e:Error) {}
			return null;
		}
		
		public function GeniCredential(stringRepresentation:String = "")
		{
			Raw = stringRepresentation;
		}
	}
}