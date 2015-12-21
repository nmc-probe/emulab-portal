require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'moment',
	 'js/lib/text!template/create-dataset.html',
	 'js/lib/text!template/dataset-help.html'],
function (_, sup, moment, mainString, helpString)
{
    'use strict';

    var mainTemplate = _.template(mainString);
    var fields       = null;
    var fstypes      = null;
    var projlist     = null;
    var instances    = null;
    var amlist       = null;
    var editing      = false;
    var isadmin      = false;
    var embedded     = 0;
    
    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	embedded = window.EMBEDDED;
	isadmin  = window.ISADMIN;
	editing  = window.EDITING;
	fields   = JSON.parse(_.unescape($('#form-json')[0].textContent));
	if (! editing) {
	    fstypes = JSON.parse(_.unescape($('#fstypes-json')[0].textContent));
	    projlist =
		JSON.parse(_.unescape($('#projects-json')[0].textContent));
	}
	if (!embedded) {
	    instances =
		JSON.parse(_.unescape($('#instances-json')[0].textContent));
	    if ($('#amlist-json').length) {
		amlist = JSON.parse(_.unescape($('#amlist-json')[0].textContent));
	    }
	}
	GeneratePageBody(fields, null);
    }

    //
    // Moved into a separate function since we want to regen the form
    // after each submit, which happens via ajax on this page. 
    //
    function GeneratePageBody(formfields, errors)
    {
	// Generate the template.
	var html = mainTemplate({
	    formfields:		formfields,
	    fstypes:		fstypes,
	    projects:           projlist,
	    instancelist:	instances,
	    amlist:		amlist,
	    title:		window.TITLE,
	    embedded:		window.EMBEDDED,
	    editing:		editing,
	    isadmin:		isadmin,
	});
	html = formatter(html, errors).html();
	$('#main-body').html(html);

	// This activates the popover subsystem.
	$('[data-toggle="popover"]').popover({
	    trigger: 'hover',
	    container: 'body'
	});
	$('#dataset_help_link').popover({
	    html:     true,
	    content:  helpString,
	    trigger:  'manual',
	    placement:'auto',
	    container:'body',
	});
	$("#dataset_help_link").click(function(event) {
	    event.preventDefault();
	    $('#dataset_help_link').popover('show');
	    $('#dataset_popover_close').on('click', function(e) {
		$('#dataset_help_link').popover('hide');
	    });
	});
	
	// stdatasets need ro show the expiration date.
	var needexpire = false;
	if (formfields["dataset_type"] == "stdataset") {
	    needexpire = true;
	    if (!editing) {
		// Insert datepicker after html inserted.
		$(function() {
		    $("#dataset_expires").datepicker({
			showButtonPanel: true,
			dateFormat: "M d yy 11:59 'PM'"
		    });
		});
	    }
	    else {
		// Format dates with moment before display.
		var date = $('#dataset_expires').val();
		$('#dataset_expires').val(moment(date).format("lll"));
	    }
	}
	if (!editing) {
	    $('#create_dataset_form [name=dataset_type]').change(function() {
		var val = $(this).val();
		if (val == "stdataset") {
		    $('#dataset_expires_div').removeClass("hidden");
		    $('#dataset_size_div').removeClass("hidden");
		    $('#dataset_fstype_div').removeClass("hidden");
		    $('#dataset_cluster_div').removeClass("hidden");
		    $('#dataset_imageonly_div').addClass("hidden");
		}
		else if (val == "ltdataset") {
		    $('#dataset_expires_div').addClass("hidden");
		    $('#dataset_size_div').removeClass("hidden");
		    $('#dataset_fstype_div').removeClass("hidden");
		    $('#dataset_cluster_div').removeClass("hidden");
		    $('#dataset_imageonly_div').addClass("hidden");
		}
		else {
		    $('#dataset_expires_div').addClass("hidden");
		    $('#dataset_size_div').addClass("hidden");
		    $('#dataset_fstype_div').addClass("hidden");
		    $('#dataset_cluster_div').addClass("hidden");
		    $('#dataset_imageonly_div').removeClass("hidden");
		}
	    });
	}
	if (needexpire) {
	    $('#dataset_expires_div').removeClass("hidden");
	}

	// Handler for project change.
	if (!editing) {
	    $('#dataset_pid').change(function (event) {
		$("span[name='project_name']")
		    .html("project " + $('#dataset_pid option:selected').val());
	    });
	    // Initialize the span with default project.
	    if (projlist.length == 1) {
		$("span[name='project_name']")
		    .html("project " + $('#dataset_pid').html());
	    }
	    else {
		$("span[name='project_name']")
		    .html("project " + $('#dataset_pid option:selected').val());
	    }
  	}
	// Handler for instance change.
	if (instances) {
	    $('#dataset_instance').change(function (event) {
		$("#dataset_instance option:selected" ).each(function() {
		    HandleInstanceChange($(this).val());
		    return;
		});
	    });
	    // After error, need to rebuild selections lists
	    if (formfields.dataset_instance) {
		HandleInstanceChange(formfields.dataset_instance,
				     formfields.dataset_node,
				     formfields.dataset_bsname);
	    }
	}
	
	//
	// Handle submit button.
	//
	$('#dataset_submit_button').click(function (event) {
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
			" class='col-sm-3 control-label'> " +
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
		    colsize = 6;
		}
		var innerdiv = $("<div class='col-sm-" + colsize + "'></div>");
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

    function HandleSubmit()
    {
	// Submit with check only at first, since this will return
	// very fast, so no need to throw up a waitwait.
	SubmitForm(1);
    }

    //
    // Submit the form.
    //
    function SubmitForm(checkonly)
    {
	// Current form contents as formfields array.
	var formfields  = {};
	
	var callback = function(json) {
	    console.info(json);
	    if (!checkonly) {
		sup.HideModal("#waitwait");
	    }
	    if (json.code) {
		if (checkonly && json.code == 2) {
		    // Regenerate page with errors.
		    GeneratePageBody(formfields, json.value);
		    return;
		}
		sup.SpitOops("oops", json.value);
		return;
	    }
	    // Now do the actual create.
	    if (checkonly) {
		sup.ShowModal("#waitwait");
		SubmitForm(0);
	    }
	    else {
		if (embedded) {
		    window.parent.location.replace("../" + json.value);
		}
		else {
		    window.location.replace(json.value);
		}
	    }
	}
	// Convert form data into formfields array, like all our
	// form handler pages expect.
	var fields = $('#create_dataset_form').serializeArray();
	$.each(fields, function(i, field) {
	    formfields[field.name] = field.value;
	});
	// This clears any errors before new submit. Needs more thought.
	GeneratePageBody(formfields, null);

	var xmlthing = sup.CallServerMethod(null, "dataset",
					    (editing ? "modify" : "create"),
					    {"formfields" : formfields,
					     "checkonly"  : checkonly,
					     "embedded"   : window.EMBEDDED});
	xmlthing.done(callback);
    }

    /*
     * When instance changes, need to get the manifest and find the a
     * node with a blockstore to offer the user. The node and bsname
     * args are optional, used for regenerating the form after an
     * error.
     */
    function HandleInstanceChange(uuid, selected_node, selected_bsname)
    {
	var EMULAB_NS = "http://www.protogeni.net/resources/rspec/ext/emulab/1";
	var noderefs  = {};

	// Clear old handler, set again below.
	$('#dataset_node').off("change");
	    
	var callback = function(json) {
	    /*
	     * Build up selection list of nodes in the instance that
	     * contain block stores.
	     */
	    var options = "";

	    _.each(json.value, function(manifest, aggregate_urn) {
		var xmlDoc = $.parseXML(manifest);
		var xml = $(xmlDoc);

		$(xml).find("node").each(function() {
		    var node   = $(this).attr("client_id");
		    var bslist = this.getElementsByTagNameNS(EMULAB_NS,
							     'blockstore');
		    var selected = (selected_node == node ? "selected" : "");

		    for (var i = 0; i < bslist.length; ++i) {
			var bsname   = $(bslist[i]).attr("name");
			var bsclass  = $(bslist[i]).attr("class");

			if (bsclass == "local") {
			    noderefs[node] = this;

			    options = options +
				"<option value='" + node +
				"' " + selected + " >" +
				node + "</option>";
			    return;
			}
		    }
		});
	    });
	    if (options == "") {
		$('#dataset_node')
		    .html("<option value=''>Please Select</option>");
		$('#dataset_bsname')
		    .html("<option value=''>Please Select</option>");
		
		sup.SpitOops("oops",
			     "The selected instance does not have any nodes " +
			     "that can be used to create an image backed dataset");
		return;
	    }
	    $('#dataset_node')
		    .html("<option value=''>Please Select</option>" + options);
	    $('#dataset_bsname')
		    .html("<option value=''>Please Select</option>");

	    $('#dataset_node').on("change", function (event) {
		$("#dataset_node option:selected").each(function() {
		    HandleInstanceNodeChange(noderefs[$(this).val()]);
		    return;
		});
	    });
	    if (selected_node && selected_bsname) {
		HandleInstanceNodeChange(noderefs[selected_node],
					 selected_bsname);
	    }
	};
	var xmlthing = sup.CallServerMethod(null, "status",
					    "GetInstanceManifest",
					    {"uuid" : uuid});
	xmlthing.done(callback);
    }

    function HandleInstanceNodeChange(noderef, selected_bsname)
    {
	var EMULAB_NS = "http://www.protogeni.net/resources/rspec/ext/emulab/1";

	/*
	 * Build up selection list of blockstores on the node.
	 */
	var options = "";
	var bslist  = noderef.getElementsByTagNameNS(EMULAB_NS, 'blockstore');

	for (var i = 0; i < bslist.length; ++i) {
	    var bsname   = $(bslist[i]).attr("name");
	    var bsclass  = $(bslist[i]).attr("class");
	    var selected = (selected_bsname == bsname ? "selected" : "");
	    
	    if (bsclass == "local") {
		options = options +
		    "<option value='" + bsname + "' " + selected + " >" +
		    bsname + "</option>";
	    }
	}
	$('#dataset_bsname')
	    .html("<option value=''>Please Select</option>" + options);
    }

    $(document).ready(initialize);
});


