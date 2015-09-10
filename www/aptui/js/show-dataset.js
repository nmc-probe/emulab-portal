require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'moment',
	 'js/lib/text!template/show-dataset.html',
	 'js/lib/text!template/snapshot-dataset.html',
	 'js/image'],
function (_, sup, moment, mainString, snapshotString, ShowImagingModal)
{
    'use strict';
    var mainTemplate    = _.template(mainString);
    var snapTemplate    = _.template(snapshotString);
    var dataset_uuid    = null;
    var embedded        = 0;
    var canrefresh      = 0;
    var cansnapshot     = 0;
    var instances       = null;
    
    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	dataset_uuid = window.UUID;
	embedded     = window.EMBEDDED;
	canrefresh   = window.CANREFRESH;
	cansnapshot  = window.CANSNAPSHOT;

	var fields = JSON.parse(_.unescape($('#fields-json')[0].textContent));
	if (!embedded && cansnapshot) {
	    instances =
		JSON.parse(_.unescape($('#instances-json')[0].textContent));
	}
	
	// Generate the main template.
	var html   = mainTemplate({
	    formfields:		fields,
	    candelete:	        window.CANDELETE,
	    canapprove:	        window.CANAPPROVE,
	    canrefresh:	        window.CANREFRESH,
	    cansnapshot:        window.CANSNAPSHOT,
	    embedded:		embedded,
	    title:		window.TITLE,
	});
	$('#main-body').html(html);

	// Initialize the popover system.
	$('[data-toggle="popover"]').popover({
	    trigger: 'hover',
	    container: 'body',
	    placement: 'auto',
	});
	
	// Format dates with moment before display.
	$('.format-date').each(function() {
	    var date = $.trim($(this).html());
	    if (date != "") {
		$(this).html(moment($(this).html()).format("lll"));
	    }
	});

	//
	// When embedded, we want the links to go through the outer
	// frame not the inner iframe.
	//
	if (embedded) {
	    $('*[id*=embedded-anchors]').click(function (event) {
		event.preventDefault();
		var url = $(this).attr("href");
		console.info(url);
		window.parent.location.replace("../" + url);
		return false;
	    });
	}
	// Refresh.
	$('#dataset_refresh_button').click(function (event) {
	    event.preventDefault();
	    RefreshDataset();
	});
	
	// Snapshot for imdatasets
	if (cansnapshot) {
	    $('#dataset_snapshot_button').click(function (event) {
		event.preventDefault();
		ShowSnapshotModal(null, null);
	    });
	}
	
	// Confirm Delete
	$('#delete-confirm').click(function (event) {
	    event.preventDefault();
	    DeleteDataset();
	});
	// Confirm Approve
	$('#approve-confirm').click(function (event) {
	    event.preventDefault();
	    ApproveDataset();
	});
	// Confirm Extend
	$('#extend-confirm').click(function (event) {
	    event.preventDefault();
	    ExtendDataset();
	});

	/*
	 * If the state is busy, then lets poll watching for it to
	 * go valid.
	 */
	if (cansnapshot &&
	    fields.dataset_state == "busy" ||
	    fields.dataset_state == "allocating") {
	    ShowProgressModal();
	}
    }

    // Periodically ask the server for the status.
    function StateWatch()
    {
	var callback = function(json) {
	    console.info(json);
	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    if (! (json.value.state == "busy" ||
		   json.value.state == "allocating")) {
		window.location.reload(true);
		return;
	    }
	    if (json.size) {
		$('#dataset_size').html(json.size);
	    }
	    setTimeout(function f() { StateWatch() }, 5000);
	}
	var xmlthing = sup.CallServerMethod(null, "dataset",
					    "getinfo",
					    {"uuid" : dataset_uuid});
	xmlthing.done(callback);
    }
    
    function ShowProgressModal()
    {
	ShowImagingModal(
	    function()
	    {
		return sup.CallServerMethod(null,
					    "dataset",
					    "getinfo",
					    {"uuid" :
					     dataset_uuid});
	    },
	    function(failed)
	    {
		// Update the status/size.
		if (!failed) {
		    var callback = function(json) {
			if (!json.code) {
			    $('#dataset_state').html(json.value.state);
			    $('#dataset_size').html(json.value.size);
			}
		    };
		    var xmlthing = sup.CallServerMethod(null,
							"dataset",
							"getinfo",
							{"uuid" :
							 dataset_uuid});
		    xmlthing.done(callback);
		}
	    });
    }

    //
    // Delete dataset.
    //
    function DeleteDataset()
    {
	var callback = function(json) {
	    sup.HideModal('#waitwait');
	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    if (embedded) {
		window.parent.location.replace("../" + json.value);
	    }
	    else {
		window.location.replace(json.value);
	    }
	}
	sup.HideModal('#delete_modal');
	sup.ShowModal("#waitwait");
	var xmlthing = sup.CallServerMethod(null,
					    "dataset",
					    "delete",
					    {"uuid" : dataset_uuid,
					     "embedded" : embedded});
	xmlthing.done(callback);
    }
    //
    // Refresh
    //
    function RefreshDataset()
    {
	var callback = function(json) {
	    sup.HideModal('#waitwait');
	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    window.location.reload(true);
	}
	sup.ShowModal("#waitwait");
	var xmlthing = sup.CallServerMethod(null,
					    "dataset",
					    "refresh",
					    {"uuid" : dataset_uuid});
	xmlthing.done(callback);
    }
    //
    // Approve dataset.
    //
    function ApproveDataset()
    {
	var callback = function(json) {
	    sup.HideModal('#waitwait');
	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    if (embedded) {
		window.parent.location.replace("../" + json.value);
	    }
	    else {
		window.location.replace(json.value);
	    }
	}
	sup.HideModal('#approve_modal');
	sup.ShowModal("#waitwait");
	var xmlthing = sup.CallServerMethod(null,
					    "dataset",
					    "approve",
					    {"uuid" : dataset_uuid});
	xmlthing.done(callback);
    }
    //
    // Extend dataset.
    //
    function ExtendDataset()
    {
	var callback = function(json) {
	    sup.HideModal('#waitwait');
	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    if (embedded) {
		window.parent.location.replace("../" + json.value);
	    }
	    else {
		window.location.replace(json.value);
	    }
	}
	sup.HideModal('#extend_modal');
	sup.ShowModal("#waitwait");
	var xmlthing = sup.CallServerMethod(null,
					    "dataset",
					    "extend",
					    {"uuid" : dataset_uuid});
	xmlthing.done(callback);
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

    /*
     * Show the snapshot modal/form for imdatasets.
     */
    function ShowSnapshotModal(formfields, errors)
    {
	if (formfields === null) {
	    formfields = {};
	}
	// Generate the main template.
	var html   = snapTemplate({
	    formfields:         formfields,
	    embedded:		embedded,
	    instancelist:	instances,
	});
	html = formatter(html, errors).html();
	$('#snapshot_div').html(html);

	// Handler for instance change.
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
	
	//
	// Handle submit button.
	//
	$('#snapshot_submit_button').click(function (event) {
	    event.preventDefault();
	    HandleSubmit();
	});
	sup.ShowModal("#snapshot_modal");
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

	    if (json.code) {
		sup.HideModal("#waitwait");
		if (checkonly && json.code == 2) {
		    // Regenerate with errors.
		    ShowSnapshotModal(formfields, json.value);
		    return;
		}
		sup.SpitOops("oops", json.value);
		return;
	    }
	    // Now do the actual create.
	    if (checkonly) {
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
	var fields = $('#snapshot_dataset_form').serializeArray();
	$.each(fields, function(i, field) {
	    formfields[field.name] = field.value;
	});
	formfields["dataset_uuid"] = dataset_uuid;
	console.info(formfields);
	sup.HideModal('#snapshot_modal');
	sup.ShowModal('#waitwait');
	var xmlthing = sup.CallServerMethod(null, "dataset", "modify",
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


