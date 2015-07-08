//
// Start a Parameterized Profile
//
define(['underscore', 'js/quickvm_sup', 'js/JacksEditor',
       	'js/lib/text!template/ppform-wizard.html',
       	'js/lib/text!template/ppform-wizard-body.html',
       	'js/lib/text!template/choose-am.html',
       ],
function(_, sup, JacksEditor, ppmodalString, ppbodyString, chooserString)
    {
	'use strict';

	var bodyTemplate  = null;
	var chooseTemplate= null;
	var editor        = null;
	var editorLarge   = null;
	var defaults      = null;
	var uuid          = "";
	var registered    = true;
	var multisite     = 0;
	var RSPEC	  = null;
	var configuredone_callback = null;

	//
	// Moved into a separate function since we want to regen the form
	// after each submit, which happens via ajax on this page. 
	//
	function GenerateModalBody(formfields, errors){
	    // Generate the template.
	    var html = bodyTemplate({
		formfields:		formfields,
	    });
	
	    html = formatter(html, errors).html();
	    $('#ppmodal-body').html(html);
	    if (!registered) {
		$('#pp_form :input').attr('readonly', true);
		// This is the only way to disable selects
		$('#pp_form :input').attr('disabled', true);
		// Have to renable the buttons after disabling selects
		$('#pp_form :button').attr('disabled', false);
		$('#pp_form :button').attr('readonly', false);
	    }
	    
	    //
	    // Handle submit button.
	    //
	    $('#modal_profile_continue_button').click(function (event) {
		event.preventDefault();
		HandleSubmit();
	    });
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

		    var outerdiv = $("<div class='form-group' " +
				     "     style='margin-bottom: " + margin +
				     "px;'></div>");

		    if ($(item).attr('data-label')) {
			var label_text =
			    "<label for='" + key + "' " +
			    " class='col-sm-4 control-label'> " +
			    item.dataset['label'];
		    
			if ($(item).attr('data-help')) {
			    label_text = label_text +
				"<a href='#' class='btn btn-xs' " +
				" data-toggle='popover' " +
				" data-html='true' " +
				" data-delay='{\"hide\":1000}' " +
				" data-content='" +
				item.dataset['help'] + "'>" +
				"<span class='glyphicon " +
				"glyphicon-question-sign'>" +
				" </span></a>";
			}
			label_text = label_text + "</label>";
			outerdiv.append($(label_text));
			colsize = 6;
		    }
		    var innerdiv = $("<div class='col-sm-" +
				     colsize + "'></div>");
		    innerdiv.html($(item).clone());
		
		    if (errors && _.has(errors, key)) {
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

	function HandleSubmit(callback)
	{
	    /*
	     * If not a registered user, then continue takes them back.
	     */
	    if (!registered) {
		sup.HideModal('#ppmodal');
		configuredone_callback(null);
		return;
	    }
	      
	    // Submit with check only at first, since this will return
	    // very fast, so no need to throw up a waitwait.
	    SubmitForm(1, callback);
	}

	//
	// Configuration is done, we have the new rspec.
	//
	function ConfigureDone()
	{
	    configuredone_callback(RSPEC);

	    // Handler for instantiate submit button, which is in the page.
	    $('#stepsContainer .actions a[href="#finish"]')
		.click(function (event) {
		event.preventDefault();
		$('#instantiate_submit').click();
	    });
	}

	//
	// Submit the form. If no errors, we get back the rspec. Throw that
	// up in a Jack editor window. 
	//
	function SubmitForm(checkonly, steps_callback)
	{
	    // Current form contents as formfields array.
	    var formfields  = {};
	
 	    var callback = function(json) {
		if (!checkonly) {
		    sup.HideModal("#waitwait-modal");
		}
		if (json.code) {
		    if (checkonly && json.code == 2) {
			// Regenerate page with errors.
			GenerateModalBody(formfields, json.value);
		    }
		    else {
			sup.SpitOops("oops", json.value);
		    }
		    steps_callback(false);
		    return;
		}
		if (checkonly) {
		    // Form checked out okay, submit again to generate rspec.
		    SubmitForm(0, steps_callback);
		}
		else {
		    RSPEC = json.value.rspec;
		    ConfigureDone();
		    // Must be after the callback, so that any changes to
		    // the aggregate selector is reflected in the final tab
		    steps_callback(true);
		    ShowEditor();
		}
	    }
	    // Convert form data into formfields array, like all our
	    // form handler pages expect.
	    var fields = $('#pp_form').serializeArray();
	    $.each(fields, function(i, field) {
		formfields[field.name] = field.value;
	    });
	    // This clears any errors before new submit. Needs more thought.
	    GenerateModalBody(formfields, null);

	    // Not in checkform mode, this will take time.
	    if (!checkonly) {
		sup.ShowModal("#waitwait-modal");
	    }
	    var xmlthing =
		sup.CallServerMethod(null, "manage_profile",
				     "BindParameters",
				     {"formfields" : formfields,
				      "uuid"       : uuid,
				      "checkonly"  : checkonly});
	    xmlthing.done(callback);
	}

	function StartPP(args) {
	    uuid = args.uuid;
	    registered = args.registered;
	    multisite = args.multisite;
	    
	    if (bodyTemplate) {
		GenerateModalBody(defaults, null);
		//sup.ShowModal('#ppmodal');
		return;
	    }
	    // Caller might already have an editor instance.
	    editor = new JacksEditor($('#inline_jacks'), true, true,
				     true, true, !multisite);
	    configuredone_callback = args.callback;
	    
	    /*
	     * Need to ask for the profile parameter form fragment and
	     * the initial values.
	     */
	    var callback = function(json) {
		if (json.code) {
		    sup.SpitOops("oops", json.value);
		}
		defaults = json.value.defaults;
		// This is the modal.
		$('#stepsContainer-p-1').html(ppmodalString);
		// This is the form inside the modal
		bodyTemplate = _.template(ppbodyString);
		// This is the aggregate selector modal.
		chooseTemplate = _.template(chooserString);
		
		// Build a new template by inserting the form fragment, which
		// itself will refer to templated variables. 
		var html = bodyTemplate({
		    registered:         registered,
		    formfrag:		_.unescape(json.value.formfrag),
		});
		bodyTemplate = _.template(html);
		GenerateModalBody(defaults, null);
		//sup.ShowModal('#ppmodal');
		if (args.rspec) {
		    RSPEC = args.rspec;
		    ConfigureDone();
		    ShowEditor();
		}
	    }
	    var xmlthing = sup.CallServerMethod(null, "instantiate",
						"GetParameters",
						{"uuid"       : uuid});
	    xmlthing.done(callback);
	}

	function ChangeJacksRoot(root, selectionPane) {
	    editor = new JacksEditor(root, true, true, selectionPane, true);
	    editor.show(RSPEC);
	}
	function ShowEditor() {
	    editor.show(RSPEC);
	}

	return {
		HandleSubmit: HandleSubmit,
		StartPP: StartPP,
		ChangeJacksRoot: ChangeJacksRoot,
	};
    }
);
