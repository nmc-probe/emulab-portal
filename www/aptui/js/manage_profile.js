require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'filesize', 'js/image',
	 'js/lib/text!template/manage-profile.html',
	 'js/lib/text!template/waitwait-modal.html',
	 'js/lib/text!template/renderer-modal.html',
	 'js/lib/text!template/showtopo-modal.html',
	 'js/lib/text!template/oops-modal.html',
	 'js/lib/text!template/rspectextview-modal.html',
	 'js/lib/text!template/guest-instantiate.html',
	 'js/lib/text!template/publish-modal.html',
	 'js/lib/text!template/instantiate-modal.html',
	 // jQuery modules
	 'filestyle','marked','jquery-ui','jquery-grid'],
function (_, sup, filesize, ShowImagingModal,
	  manageString, waitwaitString, 
	  rendererString, showtopoString, oopsString, rspectextviewString,
	  guestInstantiateString, publishString, instantiateString)
{
    'use strict';
    var profile_uuid = null;
    var version_uuid = null;
    var snapping     = 0;
    var gotrspec     = 0;
    var ajaxurl      = "";
    var amlist       = null;
    var modified     = false;
    var manageTemplate    = _.template(manageString);
    var waitwaitTemplate  = _.template(waitwaitString);
    var rendererTemplate  = _.template(rendererString);
    var showtopoTemplate  = _.template(showtopoString);
    var rspectextTemplate = _.template(rspectextviewString);
    var oopsTemplate      = _.template(oopsString);
    var guestInstTemplate = _.template(guestInstantiateString);
    var InstTemplate      = _.template(instantiateString);

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	snapping      = window.SNAPPING;
	version_uuid  = window.VERSION_UUID;
	profile_uuid  = window.PROFILE_UUID;
	ajaxurl       = window.AJAXURL;

	var fields   = JSON.parse(_.unescape($('#form-json')[0].textContent));
	var errors   = JSON.parse(_.unescape($('#error-json')[0].textContent));
	var projlist = JSON.parse(_.unescape($('#projects-json')[0].textContent));
	amlist = JSON.parse(_.unescape($('#amlist-json')[0].textContent));

	// Notice if we have an rspec in the formfields, to start from.
	if (_.has(fields, "profile_rspec")) {
	    gotrspec = 1;
	}

	// Warn user if they have not saved changes.
	window.onbeforeunload = function() {
	    if (! modified)
		return null;
	    return "You have unsaved changes!";
	}

	// Generate the templates.
	var manage_html   = manageTemplate({
	    formfields:		fields,
	    projects:		projlist,
	    title:		window.TITLE,
	    notifyupdate:	window.UPDATED,
	    viewing:		window.VIEWING,
	    gotrspec:		gotrspec,
	    action:		window.ACTION,
	    button_label:       window.BUTTONLABEL,
	    version_uuid:	window.VERSION_UUID,
	    profile_uuid:	window.PROFILE_UUID,
	    candelete:		window.CANDELETE,
	    canmodify:		window.CANMODIFY,
	    canpublish:		window.CANPUBLISH,
	    history:		window.HISTORY,
	    activity:		window.ACTIVITY,
	    snapuuid:		(window.SNAPUUID || null),
	    general_error:      (errors.error || ''),
	});
	manage_html = formatter(manage_html, errors).html();
	$('#manage-body').html(manage_html);
	
    	var waitwait_html = waitwaitTemplate({});
	$('#waitwait_div').html(waitwait_html);
    	var showtopo_html = showtopoTemplate({});
	$('#showtopomodal_div').html(showtopo_html);
    	var renderer_html = rendererTemplate({});
	$('#renderer_div').html(renderer_html);
    	var rspectext_html = rspectextTemplate({});
	$('#rspectext_div').html(rspectext_html);
    	var oops_html = oopsTemplate({});
	$('#oops_div').html(oops_html);
    	var guest_html = guestInstTemplate({});
	$('#guest_div').html(guest_html);
	$('#publish_div').html(publishString);
    	var instantiate_html = InstTemplate({ amlist: amlist });
	$('#instantiate_div').html(instantiate_html);
	
	//
	// Fix for filestyle problem; not a real class I guess, it
	// runs at page load, and so the filestyle'd button in the
	// form is not as it should be.
	//
	$('#rspecfile').each(function() {
	    $(this).filestyle({input      : false,
			       buttonText : $(this).attr('data-buttonText'),
			       classButton: $(this).attr('data-classButton')});
	});

	// This activates the popover subsystem.
	$('[data-toggle="popover"]').popover({
	    trigger: 'hover',
	    container: 'body'
	});
	$('body').show();

	//
	// File upload handler.
	// 
	$('#rspecfile').change(function() {
		var reader = new FileReader();
		reader.onload = function(event) {
		    var newrspec = event.target.result;

		    // Allow editing the boxes now that we have an rspec.
		    $('#profile_instructions').prop("disabled", false);
		    $('#profile_description').prop("disabled", false);

		    // Show the hidden buttons (in new profile mode)
		    $('#showtopo_modal_button').removeClass("invisible");
		    $('#show_rspec_modal_button').removeClass("invisible");

		    //
		    // We do not throw away the old rspec until we parse
		    // and confirm that the tour section has not been
		    // lost. We have to do that as a continuation.
		    //
		    if (newrspec != $('#profile_rspec_textarea').val()) {
			NewRspecHandler(newrspec,
					$('#profile_rspec_textarea').val());
		    }
		};
		reader.readAsText(this.files[0]);
	});

	$('#showtopo_modal_button').click(function (event) {
	    event.preventDefault();
	    // The rspec is taken from the text area.
	    ShowRspecTopo($('#profile_rspec_textarea').val());
	});
	$('#show_rspec_modal_button').click(function (event) {
	    // Sync up the steps when toggling the edit button.
	    SyncSteps();
	    $('#modal_profile_rspec_textarea').val(
		$('#profile_rspec_textarea').val());
	    $('#rspec_modal').modal({'backdrop':'static','keyboard':false});
	    $('#rspec_modal').modal('show');
	});
	$('#collapse_rspec_modal_button').click(function (event) {
	    $('#rspec_modal').modal('hide');

	    //
	    // We do not throw away the old rspec until we parse and
	    // confirm that the tour section has not been lost. We have
	    // to do that as a continuation.
	    //
	    if ($('#modal_profile_rspec_textarea').val() !=
		$('#profile_rspec_textarea').val()) {
		NewRspecHandler($('#modal_profile_rspec_textarea').val(),
				$('#profile_rspec_textarea').val());
	    }
	    $('#modal_profile_rspec_textarea').val("");
	});
	// Auto select the URL if the user clicks in the box.
	$('#profile_url').click(function() {
	    $(this).focus();
	    $(this).select();
	});

	//
	// Delete confirmed.
	//
	$('#delete-confirm').click(function (event) {
	    event.preventDefault();
	    DeleteProfile();
	});

	//
	// Perform actions on the rspec before submit.
	//
	$('#profile_submit_button').click(function (event) {
	    // Prevent submit if the description is empty.
	    var description = $('#profile_description').val();
	    if (description === "") {
		event.preventDefault();
		alert("Please provide a description. Its handy!");
		return false;
	    }
	    // Add steps to the tour.
	    if (SyncSteps()) {
		event.preventDefault();
		return false;
	    }
	    // Disable the Stay on Page alert above.
	    window.onbeforeunload = null;
	    WaitWait();
	    return true;
	});

	/*
	 * If the description/instructions textarea are edited, copy
	 * the text back into the rspec since that is what actually
	 * gets submitted; the rspec is authoritative.
	 */
	$('#profile_instructions').change(function() {
	    ChangeHandlerAux("instructions");
	    ProfileModified();
	});
	$('#profile_description').change(function() {
	    ChangeHandlerAux("description");
	    ProfileModified();
	});

	// Change handlers for the checkboxes to enable the submit button.
	$('#profile_listed').change(function() { ProfileModified(); });
	$('#profile_who_public').change(function() { ProfileModified(); });
	$('#profile_who_registered').change(function() { ProfileModified(); });
	$('#profile_who_private').change(function() { ProfileModified(); });
	
	/*
	 * A double click handler that will render the instructions
	 * in a modal.
	 */
	$('#profile_instructions').dblclick(function() {
	    var text = $(this).val();
	    var marked = require("marked");
	    $('#renderer_modal_div').html(marked(text));
	    sup.ShowModal("#renderer_modal");
	});
	// Ditto the description.
	$('#profile_description').dblclick(function() {
	    var text = $(this).val();
	    var marked = require("marked");
	    $('#renderer_modal_div').html(marked(text));
	    sup.ShowModal("#renderer_modal");
	});
	// Handler for guest instantiate submit button, which is in
	// the modal.
	$('#guest_instantiate_submit_button').click(function (event) {
	    event.preventDefault();
	    InstantiateAsGuest();
	});
	// Handler for normal instantiate submit button, which is in
	// the modal.
	$('#instantiate_submit_button').click(function (event) {
	    event.preventDefault();
	    Instantiate();
	});
	// Handler for publish submit button, which is in the modal.
	$('#publish_submit_button').click(function (event) {
	    event.preventDefault();
	    PublishProfile();
	});

	/*
	 * If we were given an rspec, suck the description and instructions
	 * out of the rspec and put them into the text boxes. But
	 * watch for some already in the description box, it is an old
	 * one and we want to use it if no description in the rspec.
	 */
	if (gotrspec) {
	    var old_text = $('#profile_description').val();
	    if (old_text != "") {
		ChangeHandlerAux("description");
	    }
	    ExtractFromRspec($('#profile_rspec_textarea').val());
	}
	else {
	    /*
	     * Not editing, so disable the text boxes until we get
	     * an rspec via the file chooser. 
	     */
	    DisableButton('profile_instructions');
	    DisableButton('profile_description');
	}
	//
	// Show/Hide the Update Successful animation.
	//
	function hideNotifyUpdate() {
	    $('#notifyupdate').fadeOut();
	}
	function showNotifyUpdate() {
	    $("#notifyupdate").addClass("fade in").show();
	    setTimeout(function () {
		hideNotifyUpdate();
	    }, 2000);
	}
	// Schedule to flash on one second after page loaded.
	function initNotifyUpdate() {
	    setTimeout(function () {
		showNotifyUpdate();
	    }, 1000);
	}
	//
	// If taking a disk image, throw up the modal that tracks progress.
	//
	if (snapping) {
	    DisableButtons();
	    ShowProgressModal();
	}
	else {
	    EnableButtons();
	    modified = false;
	    DisableButton("profile_submit_button");
	    if (window.UPDATED) {
		initNotifyUpdate();
	    }
	}
    }

    //
    // Gack, initializing the steps table causes the ProfileModified
    // callbacks to get triggered, which is fine except that when the
    // page is first loaded, it happens AFTER the above initialize()
    // function has finished. How the hell is that? Anyway, this kludge
    // makes sure we start with the profile not appearin modified.
    //
    var initialized = false;
    function StepsTableLoaded()
    {
	if (!initialized) {
	    modified = false;
	    DisableButton("profile_submit_button");
	}
	initialized = true;
    }

    // Formatter for the form. This did not work out nicely at all!
    function formatter(fieldString, errors)
    {
	var root   = $(fieldString);
	var list   = root.find('.format-me');
	list.each(function (index, item) {
	    if (item.dataset) {
		var key     = item.dataset['key'];
		var margin  = 15;
		var colsize = 12;

		if ($(item).attr('data-compact')) {
		    margin = 5;
		}
		var outerdiv = $("<div class='form-group' " +
				 "     style='margin-bottom: " + margin +
				 "px;'></div>");

		if ($(item).attr('data-label')) {
		    var label_text =
			"<label for='" + key + "' " +
			" class='col-sm-2 control-label'> " +
			item.dataset['label'];
		    
		    if ($(item).attr('data-help')) {
			label_text = label_text +
			    "<a href='#' class='btn btn-xs' " +
			    " data-toggle='popover' " +
			    " data-html='true' " +
			    " data-delay='{\"hide\":1000}' " +
			    " data-content='" + item.dataset['help'] + "'>" +
			    "<span class='glyphicon glyphicon-question-sign'>" +
			    " </span></a>";
		    }
		    label_text = label_text + "</label>";
		    outerdiv.append($(label_text));
		    colsize = 10;
		}
		var innerdiv = $("<div class='col-sm-" + colsize + "'></div>");
		innerdiv.html($(item).clone());
		
		if (_.has(errors, key)) {
		    outerdiv.addClass('has-error');
		    innerdiv.append('<label class="control-label" ' +
				    'for="inputError">' +
				    _.escape(errors[key]) + '</label>');
		}
		outerdiv.append(innerdiv);
		$(item).after(outerdiv);
		$(item).remove();
	    }
	});
	return root;
    }

    /*
     * Yank the steps out of the xml and create the editable table.
     * Before the form is submitted, we have to convert (update the
     * table data into steps section of the rspec.
     */
    function InitStepsTable(xml)
    {
	var steps = [];
	var count = 0;
	
	$(xml).find("rspec_tour").each(function() {
	    $(this).find("steps").each(function() {
		$(this).find("step").each(function() {
		    var desc = $(this).find("description").text();
		    var id   = $(this).attr("point_id");
		    var type = $(this).attr("point_type");
		    steps[count++] = {
			'Type' : type,
			'ID'   : id,
			'Description': desc,
		    };
		});
	    });
	});

	$(function () {
	    // Initialize appendGrid
	    $('#profile_steps').appendGrid('init', {
		// We rewrite these to formfields variables before submit.
		idPrefix: "StepsTable",
		caption: null,
		initRows: 0,
		hideButtons: {
		    removeLast: true
		},
		dataLoaded: function (caller) { StepsTableLoaded(); },
		columns: [
                    { name: 'Type', display: 'Type', type: 'select',
		      ctrlAttr: { maxlength: 100 },
		      ctrlCss: { width: '80px'},
		      ctrlOptions: ["node", "link"],
		      onChange: function (evt, rowIndex) { ProfileModified(); },
		    },
                    { name: 'ID', display: 'ID', type: 'text',
		      ctrlAttr: { maxlength: 100,
				},
		      ctrlCss: { width: '100px' },
		      onChange: function (evt, rowIndex) { ProfileModified(); },
		    },
                    { name: 'Description', display: 'Description', type: 'text',
		      ctrlAttr: { maxlength: 100 },
		      onChange: function (evt, rowIndex) { ProfileModified(); },
		    },
		],
		afterRowAppended: function (evt, rowIndex) { ProfileModified(); },
		afterRowInserted: function (evt, rowIndex) { ProfileModified(); },
		afterRowRemoved:  function (evt, rowIndex) { ProfileModified(); },
		afterRowSwapped:  function (evt, rowIndex) { ProfileModified(); },
		initData: steps
	    });
	});
	
	// Show the steps area.
	$('#profile_steps_div').removeClass("hidden");
    }

    //
    // Sync the steps table to the rspec textarea.
    //
    function SyncSteps()
    {
	var rspec   = $('#profile_rspec_textarea').val();
	if (rspec === "") {
	    return;
	}
	var xmlDoc = $.parseXML(rspec);
	var xml    = $(xmlDoc);

	// Add the tour section and the subsection (if needed).
	xml = AddTourSection(xml);

	// Kill existing steps, we create new ones.
	var tour  = $(xml).find("rspec_tour");
	var sub   = $(tour).find("steps");
	$(sub).remove();
	xml = AddTourSubSection(xml, "steps");

	if ($('#profile_steps').appendGrid('getRowCount')) {
	    // Get all data rows from the steps table
	    var data = $('#profile_steps').appendGrid('getAllValue');

	    // And create each step.
	    for (var i = 0; i < data.length; i++) {
		var desc = data[i].Description;
		var id   = data[i].ID;
		var type = data[i].Type;

		// Skip completely empty rows.
		if (desc == "" && id == "" && type == "") {
		    continue;
		}
		// But error on partially empty rows.
		if (desc == "" || id == "" || type == "") {
		    alert("Partial step data in step " + i);
		    return -1;
		}
		var newdoc = $.parseXML('<step point_type="' + type + '" ' +
					'point_id="' + id + '">' +
					'<description type="text">' + desc +
					'</description>' +
					'</step>');
		$(tour).find("steps").append($(newdoc).find("step"));
	    }
	}
	// Write it back to the text area.
	var s = new XMLSerializer();
	var str = s.serializeToString(xml[0]);
	console.log(str);
	$('#profile_rspec_textarea').val(str);
	return 0;
    }

    // See if we need to add the tour section to top level.
    function AddTourSection(xml)
    {
	var tour = $(xml).find("rspec_tour");
	if (! tour.length) {
	    var newdoc = $.parseXML('<rspec_tour xmlns=' +
                 '"http://www.protogeni.net/resources/rspec/ext/apt-tour/1">' +
				    '</rspec_tour>');
	    $(xml).find("rspec").prepend($(newdoc).find("rspec_tour"));
	}
	return xml;
    }
    // See if we need to add the tour sub section.
    function AddTourSubSection(xml, which)
    {
	// Add the tour section (if needed).
	xml = AddTourSection(xml);

	var tour = $(xml).find("rspec_tour");
	var sub  = $(tour).find(which);
	if (!sub.length) {
	    var text;
	    
	    if (which == "description") {
		text = "<description type='markdown'></description>";
	    }
	    else if (which == "instructions") {
		text = "<instructions type='markdown'></instructions>";
	    }
	    else if (which == "steps") {
		text = "<steps></steps>";
	    }
	    var newdoc = $.parseXML(text);
	    $(xml).find("rspec_tour").append($(newdoc).find(which));
	}

	return xml;
    }
    //
    // Helper function for instructions/description change handler above.
    //
    function ChangeHandlerAux(which)
    {
	var text    = $('#profile_' + which).val();
	var rspec   = $('#profile_rspec_textarea').val();
	if (rspec === "") {
	    return;
	}
	console.log(text);
	var xmlDoc = $.parseXML(rspec);
	var xml    = $(xmlDoc);

	// Add the tour section and the subsection (if needed).
	xml = AddTourSection(xml);
	xml = AddTourSubSection(xml, which);

	var tour = $(xml).find("rspec_tour");
	var sub  = $(tour).find(which);
	$(sub).text(text);

	console.log(xml);
	var s = new XMLSerializer();
	var str = s.serializeToString(xml[0]);
	console.log(str);
	$('#profile_rspec_textarea').val(str);
    }

    /*
     * Before updating the rspec with a new one, make sure that the new
     * has a tour section, and if not ask the user if it is okay to
     * use the original tour section. Once we get confirmation, we can
     * continue with the update.
     */
    function NewRspecHandler(newrspec, oldrspec)
    {
	newrspec = $.trim(newrspec);
	var newxmlDoc = $.parseXML(newrspec);
	var newxml    = $(newxmlDoc);
	var newtour   = $(newxml).find("rspec_tour");
	
	var continuation = function (reuse) {
	    sup.HideModal('#reuse_tour_modal');
	    if (reuse) {
	       $(newxml).find("rspec").prepend($(oldxmlDoc).find("rspec_tour"));
	       var s = new XMLSerializer();
	       newrspec = s.serializeToString(newxml[0]);
	    }
	    $('#profile_rspec_textarea').val(newrspec);
	    ExtractFromRspec(newrspec);
	    ProfileModified();
	};

	// No old rspec, use new one.
	oldrspec = $.trim(oldrspec);
	if (oldrspec == "") {
	    continuation(false);
	    return;
	}
	
	var oldxmlDoc = $.parseXML(oldrspec);
	var oldxml    = $(oldxmlDoc);
	var oldtour   = $(oldxml).find("rspec_tour");
	
	if (!newtour.length && oldtour.length) {
	    $('#remove_tour_button').click(function (event) {
		continuation(false);
	    });
	    $('#reuse_tour_button').click(function (event) {
		continuation(true);
	    });
	    sup.ShowModal('#reuse_tour_modal');
	    return;
	}
	// Continue with new rspec. 
	continuation(false);
    }

    /*
     * We want to look for and pull out the introduction and overview text,
     * and put them into the text boxes. The user can edit them in the
     * boxes. More likely, they will not be in the rspec, and we have to
     * add them to the rspec_tour section.
     */
    function ExtractFromRspec(rspec)
    {
	var xmlDoc;

	try {
	    xmlDoc = $.parseXML(rspec);
	}
	catch(err) {
	    alert("Could not parse XML!");
	    return -1;
	}
	var xml    = $(xmlDoc);
	
	$('#profile_description').val("");
	$(xml).find("rspec_tour > description").each(function() {
	    var text = $(this).text();
	    $('#profile_description').val(text);
	});
	$('#profile_instructions').val("");
	$(xml).find("rspec_tour > instructions").each(function() {
	    var text = $(this).text();
	    $('#profile_instructions').val(text);
	});
	InitStepsTable(xml);
    }

    //
    // Show the rspec text in the modal.
    //
    function ShowRspecTopo(xml)
    {
	sup.ShowModal("#quickvm_topomodal");
        $('#quickvm_topomodal').one('shown.bs.modal', function() {
	    sup.maketopmap("#showtopo_nopicker", xml, null);
        });
    }

    //
    // Instantiate a profile as a guest User.
    //
    function InstantiateAsGuest()
    {
	var callback = function(json) {
	    sup.HideModal("#waitwait-modal");
	
	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    //
	    // Need to set the cookies we get back so that we can
	    // redirect to the status page.
	    //
	    document.cookie =
		'quickvm_user=' + json.value.quickvm_user +
		'; max-age=86400; path=/; secure';
	    document.cookie =
		'quickvm_authkey=' + json.value.quickvm_authkey +
		'; max-age=86400; path=/; secure';

	    var url = "status.php?uuid=" + json.value.quickvm_uuid;
	    window.location.replace(url);
	}
	sup.HideModal("#guest_instantiate_modal");
	sup.ShowModal("#waitwait-modal");
	var xmlthing = sup.CallServerMethod(ajaxurl,
					    "manage_profile",
					    "InstantiateAsGuest",
					    {"uuid"   : version_uuid});
	xmlthing.done(callback);
    }

    //
    // Instantiate a profile.
    //
    function Instantiate()
    {
	var callback = function(json) {
	    sup.HideModal("#waitwait-modal");
	    
	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    var url = "status.php?uuid=" + json.value.quickvm_uuid;
	    window.location.replace(url);
	}
	sup.HideModal("#instantiate_modal");

	var blob = {"uuid" : version_uuid};
	if (amlist.length) {
	    blob.where = $('#instantiate_where').val();
	}
	sup.ShowModal("#waitwait-modal");
	var xmlthing = sup.CallServerMethod(ajaxurl,
					    "manage_profile",
					    "Instantiate", blob);
	xmlthing.done(callback);
    }

    //
    // Progress Modal
    //
    function ShowProgressModal()
    {
	ShowImagingModal(function()
			 {
			     return sup.CallServerMethod(ajaxurl,
							 "manage_profile",
							 "CloneStatus",
							 {"uuid" : version_uuid});
			 },
			 function(failed)
			 {
			     if (failed) {
				 EnableButton("profile_delete_button");
			     }
			     else {
				 EnableButtons();
			     }
			 });
    }

    //
    // Show the waitwait modal.
    //
    function WaitWait()
    {
	sup.ShowModal('#waitwait-modal');
    }

    //
    // Enable/Disable buttons. 
    //
    function EnableButtons()
    {
	EnableButton("profile_delete_button");
	EnableButton("profile_instantiate_button");
	EnableButton("profile_submit_button");
	EnableButton("guest_instantiate_button");
	EnableButton("profile_publish_button");
    }
    function DisableButtons()
    {
	DisableButton("profile_delete_button");
	DisableButton("profile_instantiate_button");
	DisableButton("profile_submit_button");
	DisableButton("guest_instantiate_button");
	DisableButton("profile_publish_button");
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
	if (enable) {
	    $('#' + button).removeAttr("disabled");
	}
	else {
	    $('#' + button).attr("disabled", "disabled");
	}
    }
    function HideButton(button)
    {
	$(button).addClass("hidden");
    }
    function ProfileModified()
    {
	modified = true;
	EnableButton("profile_submit_button");
    }

    //
    // Delete profile.
    //
    function DeleteProfile()
    {
	var callback = function(json) {
	    sup.HideModal("#waitwait-modal");
	    console.info(json.value);

	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    window.location.replace(json.value);
	}
	sup.HideModal('#delete_modal');
	sup.ShowModal("#waitwait-modal");
	var xmlthing = sup.CallServerMethod(ajaxurl,
					    "manage_profile",
					    "DeleteProfile",
					    {"uuid"   : version_uuid});
	xmlthing.done(callback);
    }

    //
    // Publish profile.
    //
    function PublishProfile()
    {
	var callback = function(json) {
	    sup.HideModal("#waitwait-modal");
	    console.info(json.value);

	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    // No longer allowed to delete/publish. But maybe we need
	    // an unpublish button? Also update the published field.
	    HideButton('#profile_delete_button');
	    HideButton('#profile_publish_button');
	    $('#profile_published').html(json.value.published);
	}
	sup.HideModal('#publish_modal');
	sup.ShowModal("#waitwait-modal");
	var xmlthing = sup.CallServerMethod(ajaxurl,
					    "manage_profile",
					    "PublishProfile",
					    {"uuid"   : version_uuid});
	xmlthing.done(callback);
    }

    $(document).ready(initialize);
});
