window.APT_OPTIONS.config();

require(['jquery', 'js/quickvm_sup', 
	 // jQuery modules
	 'bootstrap','filestyle','marked','jquery-ui','jquery-grid'],
function ($, sup)
{
    'use strict';
    var editing = 0;

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	editing = window.EDITING;
	
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
		    //ShowRspecTopo(xml);
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
	if (0) {
	// Enable the Modify button if the form changes.
        $('#quickvm_create_profile_form :input').each(function() {
	    // Need to use keyup since an input does not "change"
	    // until focus is lost.
	    $(this).keyup(function() {
		$('#profile_submit_button').prop('disabled', false);
	    });
	});
	// This one for the checkboxes.
        $('#quickvm_create_profile_form').change(function() {
	    $('#profile_submit_button').prop('disabled', false);
	});
	}
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

	/*
	 * If editing, need to suck the description and instructions
	 * out of the rspec and put them into the text boxes. But
	 * watch for some already in the description box, it is an old
	 * one and we want to use it if no description in the rspec.
	 */
	if (editing) {
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
	    $('#profile_instructions').prop("disabled", true);
	    $('#profile_description').prop("disabled", true);
	}
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
                    { name: 'Type', display: 'Type', type: 'text',
		      ctrlAttr: { maxlength: 100 },
		      ctrlCss: { width: '80px'}
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
	
	// Get all data rows from the steps tab;e
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
		text = "<description type='text'></description>";
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
		   300, topo);
    }

    $(document).ready(initialize);
});
