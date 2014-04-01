window.APT_OPTIONS.config();

require(['jquery', 'js/quickvm_sup', 'moment',
	 'tablesorter', 'tablesorterwidgets', 'bootstrap' ],
function ($, sup, moment)
{
    'use strict';
    var CurrentTopo = null;

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	// This activates the popover subsystem.
	$('[data-toggle="popover"]').popover({
	    trigger: 'hover',
	    'placement': 'top'
	});

	// Use an unload event to terminate any shells.
	$(window).bind("unload", function() {
	    console.info("Unload function called");
	
	    $('#quicktabs_content div').each(function () {
		var $this = $(this);
		// Skip the main profile tab
		if ($this.attr("id") == "profile") {
		    return;
		}
		var tabname = $this.attr("id");
	    
		// Trigger the custom event.
		$("#" + tabname).trigger("killssh");
	    });
	});

	// Take the user to the registration page.
	$('button#register-account').click(function (event) {
	    event.preventDefault();
	    sup.HideModal('#register_modal');
	    var uid   = window.APT_OPTIONS.creatorUid;
	    var email = window.APT_OPTIONS.creatorEmail;
	    var url   = "signup.php?uid=" + uid + "&email=" + email + "";
	    var win   = window.open(url, '_blank');
	    win.focus();
	});
	
	$('button#request-extension').click(function (event) {
	    event.preventDefault();
	    RequestExtension(window.APT_OPTIONS.uuid);
	});

	// Terminate an experiment.
	$('button#terminate').click(function (event) {
	    event.preventDefault();
	    
	    sup.HideModal('#terminate_modal');
	    // Disable buttons.
	    $("#terminate_button").prop("disabled", true);
	    $("#extend_button").prop("disabled", true);

	    var callback = function(json) {
		// This is considered the home page, for now.
		window.location.replace('instantiate.php');
	    }
	    sup.ShowModal("#waitwait");

	    var $xmlthing = sup.CallMethod("terminate", null,
					   window.APT_OPTIONS.uuid, null);
	    $xmlthing.done(callback);
	});

	StartCountdownClock(window.APT_OPTIONS.sliceExpires);
	GetStatus(window.APT_OPTIONS.uuid);
    }

    // Periodically ask the server for the status and update the display.
    function GetStatus(uuid)
    {
	var callback = function(json) {
	    StatusWatchCallBack(uuid, json);
	}
	var $xmlthing = sup.CallMethod("status", null, uuid, null);
	$xmlthing.done(callback);
    }

    // Call back for above.
    function StatusWatchCallBack(uuid, json)
    {
	// Check to see if the static variable has been initialized
	if (typeof StatusWatchCallBack.laststatus == 'undefined') {
            // It has not... perform the initilization
            StatusWatchCallBack.laststatus = "";
	}
	var status = json.value;
	if (json.code) {
	    status = "terminated";
	}
	var status_html = "";
    
	if (status != StatusWatchCallBack.laststatus) {
	    status_html = status;

	    var bgtype = "";
	    var statustext = "Please wait while we get your experiment ready";
	    
	    if (status == 'provisioned') {
		$("#quickvm_progress_bar").width("66%");
		status_html = "booting";
	    }
	    else if (status == 'ready') {
		bgtype = "bg-success";
		statustext = "Your experiment is ready!";
		status_html = "<font color=green>ready</font>";
		if ($("#quickvm_progress").length) {
		    $("#quickvm_progress").removeClass("progress-striped");
		    $("#quickvm_progress").removeClass("active");
		    $("#quickvm_progress").addClass("progress-bar-success");
		    $("#quickvm_progress_bar").width("100%");
		}
		$("#terminate_button").prop("disabled", false);
		$("#extend_button").prop("disabled", false);
		ShowTopo(uuid);
		StartResizeWatchdog()
	    }
	    else if (status == 'failed') {
		bgtype = "bg-danger";
		statustext = "Something went wrong, sorry! " +
		    "We've been notified.";
		status_html = "<font color=red>failed</font>";
		if ($("#quickvm_progress").length) {
		    $("#quickvm_progress").removeClass("progress-striped");
		    $("#quickvm_progress").removeClass("active");
		    $("#quickvm_progress").addClass("progress-bar-danger");
		    $("#quickvm_progress_bar").width("100%");
		}
		$("#terminate_button").prop("disabled", false);
	    }
	    else if (status == 'terminating' || status == 'terminated') {
		status_html = "<font color=red>" + status + "</font>";
		bgtype = "bg-danger";
		statustext = "Your experiment has been terminated!";
		$("#terminate_button").prop("disabled", true);
		$("#extend_button").prop("disabled", true);
		StartCountdownClock.stop = 1;
	    }
	    $("#statusmessage").html(statustext);
	    $("#statusmessage-container")
		.removeClass('bg-success bg-danger')
		.addClass(bgtype);
	    $("#quickvm_status").html(status_html);
	} 
	StatusWatchCallBack.laststatus = status;
	if (! (status == 'terminating' || status == 'terminated')) {    
	    setTimeout(function f() { GetStatus(uuid) }, 5000);
	}
    }

    //
    // Install a window resize handler to redraw the topomap.
    //
    function StartResizeWatchdog()
    {
	var resizeTimer;

	//
	// This does the actual work, called from the timer.
	//
	function resizeFunction() {
	    console.info("resizing topo");
	    // Must clear the div for the D3 library.
	    $("#showtopo_statuspage").html("<div></div>");
	    $("#showtopo_statuspage").removeClass("invisible");
	    ReDrawTopoMap();
	}

	//
	// When we get (the first of a series) of resize events,
	// we want to throw away the current topograph and set a
	// timer that will run a little while later, to redraw
	// it in the newly sized container. But, resize events might
	// come pouring in as the user moves the moouse, so we just
	// kill the old one each time, and eventually it will fire
	// after the user stops dinking around.
	//
	$(window).resize(function() {
	    $("#showtopo_statuspage").addClass("invisible");
	
	    clearTimeout(resizeTimer);
	    resizeTimer = setTimeout(resizeFunction, 250);
	});
    }

    //
    // Found this with a Google search; countdown till the expiration time,
    // updating the display. Watch for extension via the reset variable.
    //
    function StartCountdownClock(when)
    {
	// Use this static variable to force clock reset.
	StartCountdownClock.reset = when;

	// Force init below
	when = null;
    
	// Use this static variable to force clock stop
	StartCountdownClock.stop = 0;
    
	// date counting down to
	var target_date;

	// text color.
	var color = "";
    
	// update the tag with id "countdown" every 1 second
	var updaer = setInterval(function () {
	    // Clock stop
	    if (StartCountdownClock.stop) {
		// Amazing that this works!
		clearInterval(updater);
	    }
	
	    // Clock reset
	    if (StartCountdownClock.reset != when) {
		when = StartCountdownClock.reset;
		if (when === "n/a") {
		    StartCountdownClock.stop = 1;
		    return;
		}

		// Reformat in local time and show the user.
		var local_date = new Date(when);

		$("#quickvm_expires").html(moment(when).calendar());

		// Countdown also based on local time. 
		target_date = local_date.getTime();
	    }
	
	    // find the amount of "seconds" between now and target
	    var current_date = new Date().getTime();
	    var seconds_left = (target_date - current_date) / 1000;

	    if (seconds_left <= 0) {
		// Amazing that this works!
		clearInterval(updater);
		return;
	    }

	    var newcolor   = "";
	    var statusbg   = "";
	    var statustext = "Your experiment is ready";

	    $("#quickvm_countdown").html(moment(when).fromNow());

	    if (seconds_left < 3600) {
		newcolor   = "text-danger";
		statusbg   = "bg-danger";
		statustext = "Extend your experiment before it expires!";
	    }	    
	    else if (seconds_left < 2 * 3600) {
		newcolor   = "text-warning";
		statusbg   = "bg-warning";
		statustext = "Your experiment is going to expire soon!";
	    }
	    else {
		newcolor = "";
		statusbg = "hidden";
	    }
	    if (newcolor != color) {
		$("#quickvm_countdown")
		    .removeClass("text-warning text-danger")
		    .addClass(newcolor);

		$("#statusmessage").html(statustext);
		$("#statusmessage-container")
		    .removeClass('bg-success bg-danger hidden')
		    .addClass(statusbg);

		color = newcolor;
	    }
	}, 1000);
    }

    //
    // Request experiment extension. Not well named; we always grant the
    // extension. Might need more work later if people abuse it.
    //
    function RequestExtension(uuid)
    {
	var reason = $("#why_extend").val();
	console.info(reason);
	if (reason.length < 30) {
	    alert("Your reason is too short! Say more please.");
	    return;
	}
	var callback = function(json) {
	    sup.HideModal("#waitwait");
	    
	    console.info(json.value);
	    var message;
	
	    if (json.code) {
		if (json.code < 0) {
		    message = "Could not extend experiment. " +
			"Please try again later";
		}
		else {
		    message = "Could not extend experiment: " + json.value;
		}
		sup.SpitOops("oops", message);
		return;
	    }
	    $("#quickvm_expires").html(moment(json.value).calendar());
	
	    // Reset the countdown clock.
	    StartCountdownClock.reset = json.value;
	}
	sup.HideModal('#extend_modal');
	sup.ShowModal("#waitwait");
	var $xmlthing = sup.CallMethod("request_extension", null, uuid, reason);
	$xmlthing.done(callback);
    }
	
    //
    // Fire up the backend of the ssh tab.
    //
    function StartSSH(id, authobject)
    {
	var jsonauth = $.parseJSON(authobject);
	
	var callback = function(stuff) {
            var split   = stuff.split(':');
            var session = split[0];
    	    var port    = split[1];

            var url   = jsonauth.baseurl + ':' + port + '/' + '#' +
		encodeURIComponent(document.location.href) + ',' + session;
            console.info(url);
	    var iwidth = "100%";
            var iheight = 400;

            $('#' + id).html('<iframe id="' + id + '_iframe" ' +
			     'width=' + iwidth + ' ' +
                             'height=' + iheight + ' ' +
                             'src=\'' + url + '\'>');
	    
	    //
	    // Setup a custom event handler so we can kill the connection.
	    //
	    $('#' + id).on("killssh",
			   { "url": jsonauth.baseurl + ':' + port + '/quit' +
			     '?session=' + session },
			   function(e) {
			       console.info("killssh: " + e.data.url);
			       $.ajax({
     				   url: e.data.url,
				   type: 'GET',
			       });
			   });
	}
	var xmlthing = $.ajax({
	    // the URL for the request
     	    url: jsonauth.baseurl + '/d77e8041d1ad',
	    
     	    // the data to send (will be converted to a query string)
	    data: {
		auth: authobject,
	    },
 
 	    // Needs to be a POST to send the auth object.
	    type: 'POST',
 
    	    // Ask for plain text for easier parsing. 
	    dataType : 'text',
	});
	xmlthing.done(callback);
    }

    //
    // User clicked on a node, so we want to create a tab to hold
    // the ssh tab with a panel in it, and then call StartSSH above
    // to get things going.
    //
    function NewSSHTab(hostport, client_id)
    {
	var pair = hostport.split(":");
	var host = pair[0];
	var port = pair[1];

	//
	// Need to create the tab before we can create the topo, since
	// we need to know the dimensions of the tab.
	//
	var tabname = client_id + "_tab";
	if (! $("#" + tabname).length) {
	    // The tab.
	    var html = "<li><a href='#" + tabname + "' data-toggle='tab'>" +
		client_id + "" +
		"<button class='close' type='button' " +
		"        id='" + tabname + "_kill'>x</button>" +
		"</a>" +
		"</li>";	

	    // Append to end of tabs
	    $("#quicktabs_div ul").append(html);

	    // Install a click handler for the X button.
	    $("#" + tabname + "_kill").click(function(e) {
		e.preventDefault();
		// Trigger the custom event.
		$("#" + tabname).trigger("killssh");
		// remove the li from the ul.
		$(this).parent().remove();
		// Remove the content div.
		$("#" + tabname).remove();
		// Activate the "profile" tab.
		$('#quicktabs a[href="#profile"]').tab('show');
	    });

	    // The content div.
	    html = "<div class='tab-pane' id='" + tabname + "'></div>";

	    $("#quicktabs_content").append(html);

	    // And make it active
	    $('#quicktabs a:last').tab('show') // Select last tab
	}
	else {
	    // Switch back to it.
	    $('#quicktabs a[href="#' + tabname + '"]').tab('show');
	    return;
	}

	// Ask the server for an authentication object that allows
	// to start an ssh shell.
	var callback = function(json) {
	    console.info(json.value);

	    if (json.code) {
		alert("Failed to gain authentication for ssh.");
	    }
	    else {
		StartSSH(tabname, json.value);
	    }
	}
	var xmlthing = sup.CallMethod("ssh_authobject", null,
				      window.APT_OPTIONS.uuid, hostport);
	xmlthing.done(callback);
    }
    //
    // Show the topology inside the topo container. Called from the status
    // watchdog and the resize wachdog. Replaces the current topo drawing.
    //    
    function ShowTopo(uuid)
    {
	var callback = function(json) {
	    console.info(json.value);
	    var xmlDoc = $.parseXML(json.value);
	    var xml    = $(xmlDoc);
	    var topo   = sup.ConvertManifestToJSON(null, xml);

	    console.info(json.value);

	    // Suck the instructions out of the tour and put them into
	    // the Usage area.
	    $(xml).find("rspec_tour").each(function() {
		$(this).find("instructions").each(function() {
		    var marked = require('marked');
		    marked.setOptions({"sanitize" : true});
		
		    var text = $(this).text();
		    // Stick the text in
		    $('#instructions_text').html(marked(text));
		    // Make the div visible.
		    $('#instructions_panel').removeClass("hidden");
		});
	    });
	    // Find all of the nodes, and put them into the list tab.
	    // Clear current table.
	    //
	    // Special case for a topology of a single node; start the
	    // ssh tab right away.
	    //
	    var nodecount = 0;
	    var nodehostport = null;
	    var nodename = null;
	    
            $('#listview_table > tbody').html("");
	    $(xml).find("node").each(function() {
		var node   = $(this).attr("client_id");
		var login  = $(this).find("login");
		var href   = "n/a";
		var ssh    = "n/a";
	    
		if (login.length) {
		    var user   = login.attr("username");
		    var host   = login.attr("hostname");
		    var port   = login.attr("port");
		    var url    = "ssh://" + user + "@" + host + ":" + port +"/";
		    var sshcmd = "ssh -p " + port + " " + user + "@" + host;
		    href       = "<a href='" + url + "'><kbd>" + sshcmd + "</kbd></a>";
		    console.info(url);
		
		    var hostport  = host + ":" + port;
		    ssh = "<button class='btn btn-primary btn-sm' " +
			"    id='" + "sshbutton_" + node + "' " +
			"    type='button'>" +
			"   <span class='glyphicon glyphicon-log-in'><span>" +
			"  </button>";
		    console.info(ssh);
		    nodehostport = hostport;
		    nodename = node;
			
		    // Use this to attach handlers to things that do not
		    // exist in the dom yet.
		    $('#listview_table').off('click', '#sshbutton_' + node);
		    $('#listview_table').on('click',
					    '#sshbutton_' + node, function () {
						NewSSHTab(hostport, node);
					    });
		}
		$('#listview_table > tbody:last').append(
		    '<tr><td>' + node + '</td><td>' + ssh + '</td><td>' +
			href + '</td></tr>'
		);
		nodecount++;
	    });

	    // Stash this for resize watchdog redraw.
	    CurrentTopo = topo;
	    ReDrawTopoMap();
	    $("#showtopo_container").removeClass("invisible");

	    // And start up ssh for single node topologies.
	    if (nodecount == 1 && nodehostport) {
		NewSSHTab(nodehostport, nodename);
	    }
	}
	var $xmlthing = sup.CallMethod("manifest", null, uuid, null);
	$xmlthing.done(callback);
    }

    function ReDrawTopoMap()
    {
	// Activate the "profile" tab or else the map has no size.
	$('#quicktabs a[href="#profile"]').tab('show');
	
	// Subtract -2 cause of the border. 
	sup.maketopmap("#showtopo_statuspage",
		       $("#showtopo_statuspage").outerWidth() - 2,
		       300, CurrentTopo,
		       // Callback for ssh.
		       function(arg1, arg2) { NewSSHTab(arg1, arg2); });
    }

    $(document).ready(initialize);
});
