/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group.
* All rights reserved.
*
* Permission to use, copy, modify and distribute this software is hereby
* granted provided that (1) source code retains these copyright, permission,
* and disclaimer notices, and (2) redistributions including binaries
* reproduce the notices in supporting documentation.
*
* THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
* CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
* FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
*/

package com.flack.geni
{
	import com.flack.geni.display.mapping.GeniMap;
	import com.flack.geni.display.mapping.GeniMapHandler;
	import com.flack.geni.display.mapping.mapproviders.esriprovider.EsriMap;
	import com.flack.geni.display.mapping.mapproviders.googlemapsprovider.GoogleMap;
	import com.flack.geni.display.windows.StartWindow;
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.example.Example;
	import com.flack.geni.plugins.instools.Instools;
	import com.flack.geni.plugins.ontime.Ontime;
	import com.flack.geni.tasks.groups.GetCertBundlesTaskGroup;
	import com.flack.geni.tasks.http.PublicListAuthoritiesTask;
	import com.flack.shared.SharedMain;
	import com.flack.shared.display.areas.MapContent;
	import com.flack.shared.resources.docs.RspecVersion;
	import com.flack.shared.resources.docs.RspecVersionCollection;
	
	import mx.core.FlexGlobals;
	import mx.core.IVisualElement;
	
	/**
	 * Global container for things we use
	 * 
	 * @author mstrum
	 * 
	 */
	public class GeniMain
	{
		public static const becomeUserUrl:String = "http://www.protogeni.net/trac/protogeni/wiki/FlackManual#BecomingaUser";
		public static const manualUrl:String = "http://www.protogeni.net/trac/protogeni/wiki/FlackManual";
		public static const tutorialUrl:String = "https://www.protogeni.net/trac/protogeni/wiki/FlackTutorial";
		public static const sshKeysSteps:String = "http://www.protogeni.net/trac/protogeni/wiki/Tutorial#UploadingSSHKeys";
		
		public static function preinitMode():void
		{
			GeniMain.geniUniverse = new GeniUniverse();
		}
		
		public static var mapper:GeniMapHandler;
		public static function initMode():void
		{
			var map:GeniMap = new GoogleMap();
			var mapContent:MapContent = new MapContent();
			FlexGlobals.topLevelApplication.contentAreaGroup.Root = mapContent;
			mapContent.addElement(map as IVisualElement);
			
			mapper = new GeniMapHandler(map);
		}
		
		public static function initPlugins():void
		{
			plugins = new Vector.<Plugin>();
			plugins.push(new Instools());
			plugins.push(new Example());
			// Add new plugins
			for each(var plugin:Plugin in plugins)
				plugin.init();
		}
		
		public static function runFirst():void
		{
			// Initial tasks
			if(SharedMain.Bundle.length == 0)
				SharedMain.tasker.add(new GetCertBundlesTaskGroup());
			if(GeniMain.geniUniverse.authorities.length == 0)
				SharedMain.tasker.add(new PublicListAuthoritiesTask());
			
			// Load initial window
			var startWindow:StartWindow = new StartWindow();
			startWindow.showWindow(true, true);
		}
		
		[Bindable]
		/**
		 * 
		 * @return GENI Universe containing everything GENI related
		 * 
		 */
		public static var geniUniverse:GeniUniverse;
		
		/**
		 * Plugins which are loaded
		 */
		public static var plugins:Vector.<Plugin>;
		
		/**
		 * RSPEC versions Flack knows how to parse or generate
		 */
		public static var usableRspecVersions:RspecVersionCollection = new RspecVersionCollection(
			[
				new RspecVersion(RspecVersion.TYPE_PROTOGENI, 0.1),
				new RspecVersion(RspecVersion.TYPE_PROTOGENI, 0.2),
				new RspecVersion(RspecVersion.TYPE_PROTOGENI, 2),
				new RspecVersion(RspecVersion.TYPE_GENI, 3)
			]
		);
		
		public static function get MapKey():String
		{
			try
			{
				if(FlexGlobals.topLevelApplication.parameters.mapkey != null)
					return FlexGlobals.topLevelApplication.parameters.mapkey;
			}
			catch(all:Error)
			{
			}
			return "";
		}
		
		public static function preloadParams():void
		{
			/*
			try{
			if(FlexGlobals.topLevelApplication.parameters.mapkey != null)
			{
			Main.Application().forceMapKey = FlexGlobals.topLevelApplication.parameters.mapkey;
			}
			} catch(all:Error) {
			}
			
			try{
			if(FlexGlobals.topLevelApplication.parameters.debug != null)
			{
			Main.debugMode = FlexGlobals.topLevelApplication.parameters.debug == "1";
			}
			} catch(all:Error) {
			}
			
			try{
			if(FlexGlobals.topLevelApplication.parameters.pgonly != null)
			{
			Main.protogeniOnly = FlexGlobals.topLevelApplication.parameters.pgonly == "1";
			}
			} catch(all:Error) {
			}
			*/
		}
		
		public static function loadParams():void
		{
			/*
			try{
			if(FlexGlobals.topLevelApplication.parameters.mode != null)
			{
			var input:String = FlexGlobals.topLevelApplication.parameters.mode;
			
			Main.Application().allowAuthenticate = input != "publiconly";
			Main.geniHandler.unauthenticatedMode = input != "authenticate";
			}
			} catch(all:Error) {
			}
			try{
			if(FlexGlobals.topLevelApplication.parameters.saurl != null)
			{
			for each(var sa:ProtogeniSliceAuthority in Main.geniHandler.GeniAuthorities.source) {
			if(sa.Url == FlexGlobals.topLevelApplication.parameters.saurl) {
			Main.geniHandler.forceAuthority = sa;
			break;
			}
			}
			}
			} catch(all:Error) {
			}
			try{
			if(FlexGlobals.topLevelApplication.parameters.publicurl != null)
			{
			Main.geniHandler.publicUrl = FlexGlobals.topLevelApplication.parameters.publicurl;
			}
			} catch(all:Error) {
			}
			*/
		}
	}
}
