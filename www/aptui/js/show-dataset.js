require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'moment',
	 'js/lib/text!template/show-dataset.html', 'js/image',
	 'jquery-ui'],
function (_, sup, moment, mainString, ShowImagingModal)
{
    'use strict';
    var mainTemplate    = _.template(mainString);
    var dataset_uuid    = null;
    var embedded        = 0;
    var canrefresh      = 0;
    
    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	dataset_uuid = window.UUID;
	embedded     = window.EMBEDDED;
	canrefresh   = window.CANREFRESH;

	var fields = JSON.parse(_.unescape($('#fields-json')[0].textContent));
	
	// Generate the templates.
	var html   = mainTemplate({
	    formfields:		fields,
	    candelete:	        window.CANDELETE,
	    canapprove:	        window.CANAPPROVE,
	    canrefresh:	        window.CANREFRESH,
	    embedded:		embedded,
	    title:		window.TITLE,
	});
	$('#main-body').html(html);

	// Initialize the popover system.
	$('[data-toggle="popover"]').popover({
	    trigger: 'hover',
	    container: 'body'
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
	if (fields.dataset_state == "busy" ||
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
	ShowImagingModal(function()
			 {
			     return sup.CallServerMethod(null,
							 "dataset",
							 "getinfo",
							 {"uuid" :
							    dataset_uuid});
			 },
			 function(failed)
			 {
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
    $(document).ready(initialize);
});


