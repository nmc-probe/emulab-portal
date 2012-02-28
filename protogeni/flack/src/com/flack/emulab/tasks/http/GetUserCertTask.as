package com.flack.emulab.tasks.http
{
	import com.flack.emulab.EmulabMain;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.tasks.http.HttpTask;
	import com.hurlant.util.der.PEM;
	import com.mstrum.Asn1Field;
	import com.mstrum.DER;
	import com.mstrum.Oids;
	
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	
	public class GetUserCertTask extends HttpTask
	{
		public function GetUserCertTask()
		{
			super(
				"https://www.emulab.net/getsslcert.php3",
				"Get user cert",
				"Gets the user certificate"
			);
			relatedTo.push(SharedMain.user);
			forceSerial = true;
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			var pem:String = data as String;
			if(pem.indexOf("-----BEGIN RSA PRIVATE KEY-----") > -1 && pem.indexOf("-----BEGIN CERTIFICATE-----") > -1)
			{
				// Get what we need from the cert
				//try
				//{
					var certArray:ByteArray = PEM.readCertIntoArray(pem);
					var cert:Asn1Field = DER.Parse(certArray);
					var comNames:Vector.<Asn1Field> = cert.getHoldersFor(Oids.COMMON_NAME);
					var urlString:String = comNames[0].getValue();
					EmulabMain.manager.api.url = "https://" + urlString + ":3069/usr/testbed";
					var orgNames:Vector.<Asn1Field> = cert.getHoldersFor(Oids.ORG_NAME);
					EmulabMain.manager.hrn = orgNames[0].getValue();
					var emails:Vector.<Asn1Field> = cert.getHoldersFor(Oids.EMAIL_ADDRESS);
					EmulabMain.user.email = emails[1].getValue();
					EmulabMain.user.name = EmulabMain.user.email.substring(0, EmulabMain.user.email.indexOf('@'));
					
					EmulabMain.user.sslCert = pem;
					
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_MANAGER,
						EmulabMain.manager,
						FlackEvent.ACTION_CREATED
					);
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_USER,
						SharedMain.user
					);
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_MANAGERS,
						EmulabMain.manager,
						FlackEvent.ACTION_POPULATED
					);
				/*}
				catch(e:Error)
				{
					Alert.show("bad");
					return;
				}*/
				
				if(SharedMain.user.setSecurity("", pem))
				{
					Alert.show("It appears that the password is incorrect, try again", "Incorrect password");
					return;
				}
				
				super.afterComplete(addCompletedMessage);
			}
			else
			{
				Alert.show("bad");
				afterError(new TaskError());
			}
		}
	}
}