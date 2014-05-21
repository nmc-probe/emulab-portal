window.APT_OPTIONS.config();

require(['underscore', 'js/quickvm_sup',
	 'js/lib/text!template/manage-profile.html',
	 'js/lib/text!template/waitwait-modal.html',
	 'js/lib/text!template/imaging-modal.html',
	 'js/lib/text!template/renderer-modal.html',
	 'js/lib/text!template/showtopo-modal.html',
	 'js/lib/text!template/rspectextview-modal.html',
	 // jQuery modules
	 'filestyle','marked','jquery-ui','jquery-grid'],
	function (_, sup,
		  manageString, waitwaitString, imagingString,
		  rendererString, showtopoString, rspectextviewString)
{
    'use strict';
    var editing = 0;
    var uuid    = null;
    var snapping= 0;
    var gotrspec = 0;
    var ajaxurl = "";
    var manageTemplate    = _.template(manageString);
    var waitwaitTemplate  = _.template(waitwaitString);
    var imagingTemplate   = _.template(imagingString);
    var rendererTemplate  = _.template(rendererString);
    var showtopoTemplate  = _.template(showtopoString);
    var rspectextTemplate = _.template(rspectextviewString);

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	editing  = window.EDITING;
	snapping = window.SNAPPING;
	uuid     = window.UUID;
	ajaxurl  = window.AJAXURL;

	var fields   = JSON.parse(_.unescape($('#form-json')[0].textContent));
	var errors   = JSON.parse(_.unescape($('#error-json')[0].textContent));
	var projlist = JSON.parse(_.unescape($('#projects-json')[0].textContent));

	// Notice if we have an rspec in the formfields, to start from.
	if (_.has(fields, "profile_rspec")) {
	    gotrspec = 1;
	}

	// Generate the templates.
	var manage_html   = manageTemplate({
	    formfields:		fields,
	    projects:		projlist,
	    title:		window.TITLE,
	    notifyupdate:	window.UPDATED,
	    editing:		editing,
	    gotrspec:		gotrspec,
	    action:		window.ACTION,
	    button_label:       window.BUTTONLABEL,
	    uuid:		window.UUID,
	    snapuuid:		(window.SNAPUUID || null),
	    general_error:      (errors.error || ''),
	});
	manage_html = formatter(manage_html, errors).html();
	$('#manage-body').html(manage_html);
	
    	var waitwait_html = waitwaitTemplate({});
	$('#waitwait_div').html(waitwait_html);
    	var imaging_html = imagingTemplate({});
	$('#imaging_div').html(imaging_html);
    	var showtopo_html = showtopoTemplate({});
	$('#showtopomodal_div').html(showtopo_html);
    	var renderer_html = rendererTemplate({});
	$('#renderer_div').html(renderer_html);
    	var rspectext_html = rspectextTemplate({});
	$('#rspectext_div').html(rspectext_html);

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

	$('#rspecfile').change(function() {
		var reader = new FileReader();
		reader.onload = function(event) {
		    var content = event.target.result;
		    var xmlDoc  = $.parseXML(content);
		    var xml     = $(xmlDoc);

		    // Allow editing the boxes now that we have an rspec.
		    $('#profile_instructions').prop("disabled", false);
		    $('#profile_description').prop("disabled", false);

		    // Show the hidden buttons (in new profile mode)
		    $('#showtopo_modal_button').removeClass("invisible");
		    $('#show_rspec_textarea_button').removeClass("invisible");

		    // Stick html into the textarea
		    $('#profile_rspec_textarea').val(content);

		    ExtractFromRspec(xml);
		};
		reader.readAsText(this.files[0]);
	});

	$.fn.animateBackgroundHighlight = function(highlightColor, duration) {
	    var highlightBg = highlightColor || "#FFFF9C";
	    var animateMs = duration || 1500;
	    var originalBg = this.css("backgroundColor");
	    console.log(originalBg);
	};

	$('#showtopo_modal_button').click(function (event) {
	    event.preventDefault();
	    // The rspec is taken from the text area.
	    var xmlDoc  = $.parseXML($('#profile_rspec_textarea').val());
	    var xml     = $(xmlDoc);
	    
	    ShowRspecTopo(xml);
	});
	$('#expand_rspec_modal_button').click(function (event) {
	    $('#modal_profile_rspec_textarea').val(
		$('#profile_rspec_textarea').val());
	    $('#rspec_modal').modal({'backdrop':'static','keyboard':false});
	    $('#rspec_modal').modal('show');
	});
	$('#collapse_rspec_modal_button').click(function (event) {
	    // Copy back to the plain textarea and kill the modal contents.
	    // The topo is drawn from the plain textarea. 
	    $('#profile_rspec_textarea').val(
		$('#modal_profile_rspec_textarea').val());
	    $('#rspec_modal').modal('hide');
	    $('#modal_profile_rspec_textarea').val("");	    
	    $('#profile_rspec_textarea').css({"opacity":"0.2"});
	    $('#profile_rspec_textarea').animate({"opacity":"1.0"}, 1500);
	});
	// Auto select the URL if the user clicks in the box.
	$('#profile_url').click(function() {
	    $(this).focus();
	    $(this).select();
	});

	//
	// Sync up the steps when toggling the edit button.
	//
	$('#show_rspec_textarea_button').click(function (event) {
	    SyncSteps();
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
	});
	$('#profile_description').change(function() {
	    ChangeHandlerAux("description");
	});

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
	    var xmlDoc  = $.parseXML($('#profile_rspec_textarea').val());
	    var xml     = $(xmlDoc);
	    ExtractFromRspec(xml);
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
	// If taking a disk image, throw up the modal that tracks progress.
	//
	if (snapping) {
	    DisableButtons();
	    ShowProgressModal();
	}
	else {
	    EnableButtons();
	}
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
		columns: [
                    { name: 'Type', display: 'Type', type: 'select',
		      ctrlAttr: { maxlength: 100 },
		      ctrlCss: { width: '80px'},
		      ctrlOptions: ["node", "link"],
		    },
                    { name: 'ID', display: 'ID', type: 'text',
		      ctrlAttr: { maxlength: 100,
				},
		      ctrlCss: { width: '100px' },
		    },
                    { name: 'Description', display: 'Description', type: 'text',
		      ctrlAttr: { maxlength: 100 },
		    },
		],
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
	    else if (which == "description") {
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
     * We want to look for and pull out the introduction and overview text,
     * and put them into the text boxes. The user can edit them in the
     * boxes. More likely, they will not be in the rspec, and we have to
     * add them to the rspec_tour section.
     */
    function ExtractFromRspec(xml)
    {
	$(xml).find("rspec_tour > description").each(function() {
	    var text = $(this).text();
	    $('#profile_description').val(text);
	});
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
	var topo   = sup.ConvertManifestToJSON(null, xml);
	console.info(topo);

	sup.ShowModal("#quickvm_topomodal");

	// Subtract -2 cause of the border. 
	sup.maketopmap("#showtopo_nopicker",
 		   ($("#showtopo_nopicker").outerWidth() - 2),
		       300, topo, null);
    }

    //
    // Progress Modal
    //
    var imaging_modal_display = true;
    var imaging_modal_active  = false;
	
    function ShowProgressModal()
    {
	//
	// Ask the server for information to populate the imaging modal. 
	//
	var callback = function(json) {
	    console.info(json);
	    var value = json.value;
	    
	    if (json.code) {
		if (imaging_modal_active) {
		    sup.HideModal("#imaging-modal");
		    imaging_modal_active = false;
		    $('#imaging_modal').off('hidden.bs.modal');
		}
		EnableButton("profile_delete_button");
		return;
	    }

	    if (! imaging_modal_active && imaging_modal_display) {
		sup.ShowModal("#imaging-modal");
		imaging_modal_active  = true;
		imaging_modal_display = false;

		// Handler so we know the user closed the modal.
		$('#imaging_modal').on('hidden.bs.modal', function (e) {
		    imaging_modal_active = false;
		    $('#imaging_modal').off('hidden.bs.modal');
		})		
	    }

	    //
	    // Fill in the details. 
	    //
	    if (! _.has(value, "node_status")) {
		value["node_status"] = "unknown";
	    }
	    if (! _.has(value, "image_size")) {
		value["image_size"] = "unknown";
	    }	    
	    $('#imaging_modal_node_status').html(value["node_status"]);
	    $('#imaging_modal_image_size').html(value["image_size"]);

	    if (_.has(value, "image_status")) {
		var status = value["image_status"];

		if (status == "imaging") {
		    $('#tracker-imaging').removeClass('progtrckr-todo');
		    $('#tracker-imaging').addClass('progtrckr-done');
		}
		if (status == "finishing") {
		    $('#tracker-imaging').removeClass('progtrckr-todo');
		    $('#tracker-imaging').addClass('progtrckr-done');
		    $('#tracker-finishing').removeClass('progtrckr-todo');
		    $('#tracker-finishing').addClass('progtrckr-done');
		}
		else if (status == "ready") {
		    $('#tracker-imaging').removeClass('progtrckr-todo');
		    $('#tracker-imaging').addClass('progtrckr-done');
		    $('#tracker-finishing').removeClass('progtrckr-todo');
		    $('#tracker-finishing').addClass('progtrckr-done');
		    $('#tracker-ready').removeClass('progtrckr-todo');
		    $('#tracker-ready').addClass('progtrckr-done');
		    $('#imaging-spinner').addClass("invisible");
		    EnableButtons();
		    return;
		}
		else if (status == "failed") {
		    $('#tracker-imaging').removeClass('progtrckr-todo');
		    $('#tracker-imaging').addClass('progtrckr-done');
		    $('#tracker-finishing').removeClass('progtrckr-todo');
		    $('#tracker-finishing').addClass('progtrckr-done');
		    $('#tracker-ready').removeClass('progtrckr-todo');
		    $('#tracker-ready').addClass('progtrckr-done');
		    $('#tracker-ready').html("Failed");
		    $('#imaging-spinner').addClass("invisible");
		    EnableButton("profile_delete_button");
		    return;
		}
	    }
	    //
	    // Done, we need to do something here if we exited before
	    // ready or failed above. 
	    //
	    if (_.has(value, "exited")) {
		$('#imaging-spinner').addClass("invisible");
		EnableButtons();
		return;
	    }
	    
	    // And check again in a little bit.
	    setTimeout(function f() { ShowProgressModal() }, 5000);
	}

	var $xmlthing = sup.CallServerMethod(ajaxurl,
					     "manage_profile",
					     "SnapShotStatus",
					     {"uuid" : uuid});
	$xmlthing.done(callback);
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
    }
    function DisableButtons()
    {
	DisableButton("profile_delete_button");
	DisableButton("profile_instantiate_button");
	DisableButton("profile_submit_button");
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

    $(document).ready(initialize);
});
