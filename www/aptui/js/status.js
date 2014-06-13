require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'moment', 'js/image',
	 'js/lib/text!template/status.html',
	 'js/lib/text!template/waitwait-modal.html',
	 'js/lib/text!template/oops-modal.html',
	 'js/lib/text!template/register-modal.html',
	 'js/lib/text!template/terminate-modal.html',
	 'js/lib/text!template/extend-modal.html',
	 'js/lib/text!template/clone-help.html',
	 'js/lib/text!template/snapshot-help.html',
	 'tablesorter', 'tablesorterwidgets'],
function (_, sup, moment, ShowImagingModal,
	  statusString, waitwaitString, oopsString,
	  registerString, terminateString, extendString,
	  cloneHelpString, snapshotHelpString)
{
    'use strict';
    var nodecount   = 0;
    var ajaxurl     = null;
    var uuid        = null;
    var status_collapsed  = false;
    var status_message    = "";
    var statusTemplate    = _.template(statusString);
    var waitwaitTemplate  = _.template(waitwaitString);
    var oopsTemplate      = _.template(oopsString);
    var registerTemplate  = _.template(registerString);
    var terminateTemplate = _.template(terminateString);
    var extendTemplate    = _.template(extendString);

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	ajaxurl = window.APT_OPTIONS.AJAXURL;
	uuid    = window.APT_OPTIONS.uuid;
	var instanceStatus = window.APT_OPTIONS.instanceStatus;

	// Generate the templates.
	var template_args = {
	    uuid:		uuid,
	    profileName:	window.APT_OPTIONS.profileName,
	    sliceURN:		window.APT_OPTIONS.sliceURN,
	    sliceExpires:	window.APT_OPTIONS.sliceExpires,
	    sliceExpiresText:	window.APT_OPTIONS.sliceExpiresText,
	    creatorUid:		window.APT_OPTIONS.creatorUid,
	    creatorEmail:	window.APT_OPTIONS.creatorEmail,
	    registered:		window.APT_OPTIONS.registered,
	    // The status panel starts out collapsed.
	    status_panel_show:  (instanceStatus == "ready" ? false : true),
	};
	var status_html   = statusTemplate(template_args);
	$('#status-body').html(status_html);
    	var waitwait_html = waitwaitTemplate(template_args);
	$('#waitwait_div').html(waitwait_html);
    	var oops_html = oopsTemplate(template_args);
	$('#oops_div').html(oops_html);
    	var register_html = registerTemplate(template_args);
	$('#register_div').html(register_html);
    	var extend_html = extendTemplate(template_args);
	$('#extend_div').html(extend_html);
    	var terminate_html = terminateTemplate(template_args);
	$('#terminate_div').html(terminate_html);

	//
	// Look at initial status to determine if we show the progress bar.
	//
	var spinwidth = 0;
	if (instanceStatus == "created") {
	    spinwidth = "33";
	}
	else if (instanceStatus == "provisioned") {
	    spinwidth = "66";
	}
	if (spinwidth) {
	    $("#status_progress_bar").width(spinwidth + "%");
	    $('#status_progress_outerdiv').removeClass("hidden");
	}
	
	// This activates the popover subsystem.
	$('[data-toggle="popover"]').popover({
	    trigger: 'hover',
	    'placement': 'top'
	});

	// Use an unload event to terminate any shells.
	$(window).bind("unload", function() {
//	    console.info("Unload function called");
	
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

	// Setup the extend modal.
	$('button#extend_button').click(function (event) {
	    event.preventDefault();
	    $('#why_extend').val('');
	    // Countdown characters needed for a good story.
	    $('#why_extend').on('focus keyup', function (e) {
		var len   = $('#why_extend').val().length;
		var left  = 120 - len;
		var msg   = "You need at least " + left + " more characters";
		$('#extend_counter_msg').html(msg);
	    });
	    sup.ShowModal('#extend_modal');
	});
	
	// Handler for the Clone button.
	$('button#clone_button').click(function (event) {
	    event.preventDefault();
	    window.location.replace('manage_profile.php?action=clone' +
				    '&snapuuid=' + uuid);
	});

	// Handler for the Snapshot confirm button.
	$('button#snapshot_confirm').click(function (event) {
	    event.preventDefault();
	    sup.HideModal('#snapshot_modal');
	    StartSnapshot();
	});

	//
	// Attach a hover popover to explain what Clone means. We need
	// the hover action delayed by our own code, since we want to
	// use a manual trigger to close the popover, or else the user
	// will not have enough time to read the content. 
	//
	var popover_timer;

	$("button#clone_button").mouseenter(function(){
	    popover_timer = setTimeout(function() {
		$('button#clone_button').popover({
		    html:     true,
		    content:  cloneHelpString,
		    trigger:  'manual',
		    placement:'left',
		    container:'body',
		});
		$('button#clone_button').popover('show');
		$('#clone_popover_close').on('click', function(e) {
		    $('button#clone_button').popover('hide');
		});
	    },1000)
	}).mouseleave(function(){
	    clearTimeout(popover_timer);
	}).click(function(){
	    clearTimeout(popover_timer);
	});
	
	$("button#snapshot_button").mouseenter(function(){
	    popover_timer = setTimeout(function() {
		$('button#snapshot_button').popover({
		    html:     true,
		    content:  snapshotHelpString,
		    trigger:  'manual',
		    placement:'left',
		    container:'body',
		});
		$('button#snapshot_button').popover('show');
		$('#snapshot_popover_close').on('click', function(e) {
		    $('button#snapshot_button').popover('hide');
		});
		// Kill popover if user clicks through. 
		$('button#snapshot_button').on('click', function(e) {
		    $('button#snapshot_button').popover('hide');
		});
	    },1000)
	}).mouseleave(function(){
	    clearTimeout(popover_timer);
	}).click(function(){
	    clearTimeout(popover_timer);
	});
	
	$('button#request-extension').click(function (event) {
	    event.preventDefault();
	    RequestExtension(uuid);
	});

	// Terminate an experiment.
	$('button#terminate').click(function (event) {
	    event.preventDefault();
	    
	    sup.HideModal('#terminate_modal');
	    DisableButtons();

	    var callback = function(json) {
		// This is considered the home page, for now.
		window.location.replace('instantiate.php');
	    }
	    sup.ShowModal("#waitwait-modal");

	    var xmlthing = sup.CallServerMethod(ajaxurl,
						"status",
						"TerminateInstance",
						{"uuid" : uuid});
	    xmlthing.done(callback);
	});

	/*
	 * Attach an event handler to the profile status collapse.
	 * We want to change the text inside the collapsed view
	 * to the expiration countdown, but remove it when expanded.
	 * In other words, user always sees the expiration.
	 */
	$('#profile_status_collapse').on('hide.bs.collapse', function () {
	    status_collapsed = true;
	    // Copy the current expiration over.
	    var current_expiration = $("#instance_expiration").html();
	    $('#status_message').html("Profile Expires: " +
				      current_expiration);
	});
	$('#profile_status_collapse').on('show.bs.collapse', function () {
	    status_collapsed = false;
	    // Reset to status message.
	    $('#status_message').html(status_message);
	});
	if (instanceStatus == "ready") {
 	    $('#profile_status_collapse').trigger('hide.bs.collapse');
	}

	StartCountdownClock(window.APT_OPTIONS.sliceExpires);
	GetStatus(uuid);
	if (window.APT_OPTIONS.snapping) {
	    ShowProgressModal();
	}
    }

    // Periodically ask the server for the status and update the display.
    function GetStatus(uuid)
    {
	var callback = function(json) {
	    StatusWatchCallBack(uuid, json);
	}
	var xmlthing = sup.CallServerMethod(ajaxurl,
					    "status",
					    "GetInstanceStatus",
					     {"uuid" : uuid});
	xmlthing.done(callback);
    }

    // Call back for above.
    function StatusWatchCallBack(uuid, json)
    {
	// Flag to indicate that we have seen ready and do not
	// need to do initial stuff. We need this cause the
	// the staus can change later, back to busy for a while.
	if (typeof StatusWatchCallBack.active == 'undefined') {
            // It has not... perform the initilization
            StatusWatchCallBack.active = 0;
	}
	// Flag so we know status has changed since last check.
	if (typeof StatusWatchCallBack.laststatus == 'undefined') {
            // It has not... perform the initilization
            StatusWatchCallBack.laststatus = "";
	}
	var status = json.value;
	if (json.code) {
	    alert("The server has returned an error: " + json.value);
	    status = "unknown";
	}
	var status_html = "";
    
	if (status != StatusWatchCallBack.laststatus) {
	    status_html = status;

	    var bgtype = "panel-info";
	    status_message = "Please wait while we get your experiment ready";
	    
	    if (status == 'provisioned') {
		$("#status_progress_bar").width("66%");
		status_html = "booting";
	    }
	    else if (status == 'ready') {
		bgtype = "panel-success";
		status_message = "Your experiment is ready!";
		status_html = "<font color=green>ready</font>";
		if ($("#status_progress_div").length) {
		    $("#status_progress_div").removeClass("progress-striped");
		    $("#status_progress_div").removeClass("active");
		    $("#status_progress_div").addClass("progress-bar-success");
		    $("#status_progress_bar").width("100%");
		}
		if (! StatusWatchCallBack.active) {
		    ShowTopo(uuid);
		    StatusWatchCallBack.active = 1;
		}
		EnableButtons();
	    }
	    else if (status == 'failed') {
		bgtype = "panel-danger";
		status_message = "Something went wrong, sorry! " +
		    "We've been notified.";
		status_html = "<font color=red>failed</font>";
		if ($("#status_progress_div").length) {
		    $("#status_progress_div").removeClass("progress-striped");
		    $("#status_progress_div").removeClass("active");
		    $("#status_progress_div").addClass("progress-bar-danger");
		    $("#status_progress_bar").width("100%");
		}
		DisableButtons();
		EnableButton("terminate");
	    }
	    else if (status == 'imaging') {
		bgtype = "panel-warning";
		status_message = "Your experiment is busy while we  " +
		    "copy your disk";
		status_html = "<font color=red>imaging</font>";
		DisableButtons();
	    }
	    else if (status == 'terminating' || status == 'terminated') {
		status_html = "<font color=red>" + status + "</font>";
		bgtype = "panel-danger";
		status_message = "Your experiment has been terminated!";
		DisableButtons();
		StartCountdownClock.stop = 1;
	    }
	    if (!status_collapsed) {
		$("#status_message").html(status_message);
	    }
	    $("#status_panel")
		.removeClass('panel-success panel-danger ' +
			     'panel-warning panel-default panel-info')
		.addClass(bgtype);
	    $("#quickvm_status").html(status_html);
	} 
	StatusWatchCallBack.laststatus = status;
	if (! (status == 'terminating' || status == 'terminated' ||
	       status == 'unknown')) {
	    setTimeout(function f() { GetStatus(uuid) }, 5000);
	}
    }

    //
    // Enable/Disable buttons. 
    //
    function EnableButtons()
    {
	EnableButton("terminate");
	EnableButton("extend");
	EnableButton("clone");
	EnableButton("snapshot");
    }
    function DisableButtons()
    {
	DisableButton("terminate");
	DisableButton("extend");
	DisableButton("clone");
	DisableButton("snapshot");
    }
    function EnableButton(button)
    {
	ButtonState(button, 1);
    }
    function DisableButton(button)
    {
	ButtonState(button, 0);
    }
    function ButtonState(button, enable)
    {
	if (button == "terminate")
	    button = "#terminate_button";
	else if (button == "extend")
	    button = "#extend_button";
	else if (button == "clone" && nodecount == 1)
	    button = "#clone_button";
	else if (button == "snapshot" && nodecount == 1)
	    button = "#snapshot_button";
	else
	    return;

	if (enable) {
	    $(button).removeAttr("disabled");
	}
	else {
	    $(button).attr("disabled", "disabled");
	}
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
	var updater = setInterval(function () {
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
		statusbg   = "panel-danger";
		statustext = "Extend your experiment before it expires!";
	    }	    
	    else if (seconds_left < 2 * 3600) {
		newcolor   = "text-warning";
		statusbg   = "panel-warning";
		statustext = "Your experiment is going to expire soon!";
	    }
	    else {
		newcolor = "";
		statusbg = "";
	    }
	    if (newcolor != color) {
		$("#quickvm_countdown")
		    .removeClass("text-warning text-danger")
		    .addClass(newcolor);

		if (status_collapsed) {
		    // Save for when user "shows" the status panel.
		    status_message = statustext;
		    // And update the panel header with new expiration.
		    $('#status_message').html("Profile Expires: " +
			$("#instance_expiration").html());
		}
		else {
		    $("#status_message").html(statustext);
		}
		$("#status_panel")
		    .removeClass('panel-success panel-danger ' +
				 'panel-info panel-default panel-info')
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
//	console.info(reason);
	if (reason.length < 30) {
	    alert("Your reason is too short! Say more please.");
	    return;
	}
	var callback = function(json) {
	    sup.HideModal("#waitwait-modal");
	    
//	    console.info(json.value);
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
	sup.ShowModal("#waitwait-modal");
	var xmlthing = sup.CallServerMethod(ajaxurl,
					    "status",
					    "RequestExtension",
					    {"uuid"   : uuid,
					      "reason" : reason});
	xmlthing.done(callback);
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
//            console.info(url);
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
//			       console.info("killssh: " + e.data.url);
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
//	    console.info(json.value);

	    if (json.code) {
		alert("Failed to gain authentication for ssh.");
	    }
	    else {
		StartSSH(tabname, json.value);
	    }
	}
	var xmlthing = sup.CallServerMethod(ajaxurl,
					    "status",
					    "GetSSHAuthObject",
					    {"uuid" : uuid,
					     "hostport" : hostport});
	xmlthing.done(callback);
    }

    var hostportList = {};

    //
    // Show the topology inside the topo container. Called from the status
    // watchdog and the resize wachdog. Replaces the current topo drawing.
    //    
    function ShowTopo(uuid)
    {
	var callback = function(json) {
	    if ($("#manifest_textarea").length) {
		$("#manifest_textarea").html(json.value);
		$("#manifest_textarea").css("height", "300");
	    }

	    var xmlDoc = $.parseXML(json.value);
	    var xml = $(xmlDoc);

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
//		    console.info(url);
		
		    var hostport  = host + ":" + port;
		    hostportList[node] = hostport;
		    ssh = "<button class='btn btn-primary btn-sm' " +
			"    id='" + "sshbutton_" + node + "' " +
			"    type='button'>" +
			"   <span class='glyphicon glyphicon-log-in'><span>" +
			"  </button>";
//		    console.info(ssh);
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

	    $("#showtopo_container").removeClass("invisible");
	    $('#quicktabs a[href="#profile"]').tab('show');
	    sup.maketopmap('#showtopo_statuspage', json.value,
			   function(ssh, clientId) {
			       NewSSHTab(hostportList[clientId], clientId);
	    });

	    /*
	     * If a single node, show the clone button and maybe the
	     * the snapshot; the user must own the profile it was
	     * created from in order to do a snapshot. 
	     */
	    if (nodecount == 1) {
		$("#clone_button").removeClass("hidden");
		EnableButton("clone");
		if (window.APT_OPTIONS.cansnap) {
		    $("#snapshot_button").removeClass("hidden");
		    EnableButton("snapshot");
		}
	    }

	    // And start up ssh for single node topologies.
	    if (nodecount == 1 && nodehostport && 0) {
		NewSSHTab(nodehostport, nodename);
	    }
	}
	var xmlthing = sup.CallServerMethod(ajaxurl,
					    "status",
					    "GetInstanceManifest",
					    {"uuid" : uuid});
	xmlthing.done(callback);
    }

    function ShowProgressModal()
    {
	ShowImagingModal(function()
			 {
			     return sup.CallServerMethod(ajaxurl,
							 "status",
							 "SnapshotStatus",
							 {"uuid" : uuid});
			 },
			 function(failed)
			 {
			     if (failed) {
				 EnableButtons();
			     }
			     else {
				 EnableButtons();
			     }
			 });
    }

    //
    // Request to start a snapshot. This assumes a single node of course.
    //
    function StartSnapshot()
    {
	sup.ShowModal('#waitwait-modal');

	var callback = function(json) {
	    sup.HideModal('#waitwait-modal');
	    
	    if (json.code) {
		sup.SpitOops("oops", "Could not start snapshot: " + json.value);
		return;
	    }
	    ShowProgressModal();
	}
	var xmlthing = sup.CallServerMethod(ajaxurl,
					    "status",
					    "SnapShot",
					    {"uuid" : uuid});
	xmlthing.done(callback);
    }

    $(document).ready(initialize);
});
