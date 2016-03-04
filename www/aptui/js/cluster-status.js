require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'moment',
	 'js/lib/text!template/cluster-status.html'],
function (_, sup, moment, mainString)
{
    'use strict';
    var isadmin      = 0;
    var mainTemplate = _.template(mainString);
    var amlist       = null;

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	isadmin = window.ISADMIN;
	amlist = JSON.parse(_.unescape($('#agglist-json')[0].textContent));
	
	var html = mainTemplate({
	    amlist: amlist,
	});
	$('#page-body').html(html);

	LoadData();
    }

    function LoadData()
    {
	_.each(amlist, function(urn, name) {
	    var callback = function(json) {
		console.log(json);
		if (json.code) {
		    console.log("Could not get cluster data: " + json.value);
		    return;
		}
		var inuse = json.value.inuse;
		var html = "";

		inuse.forEach(function(value, index) {
		    var type = "";
		    if (_.has(value, "type")) {
			type = value.type;
		    }
		    var expires = "";
		    if (_.has(value, "ttl")) {
			var ttl = value.ttl;
			if (ttl != "") {
			    expires = moment().add(ttl, 'seconds').fromNow();
			}
		    }
		    var allowed = "";
		    if (_.has(value, "maxttl")) {
			var maxttl = value.maxttl;
			if (maxttl != "") {
			    allowed = moment().add(maxttl, 'seconds').fromNow();
			}
		    }
		    var uid = "";
		    if (_.has(value, "uid")) {
			uid = value.uid;
		    }
		    var eid = value.eid;
		    if (_.has(value, "instance_uuid")) {
			var uuid = value.instance_uuid;
			eid = "<a href='status.php?uuid=" + uuid +
			    "' target=_blank>" + value.instance_name + "</a>";
		    }
		    html = html + "<tr>" +
			"<td>" + value.node_id + "</td>" +
			"<td>" + type + "</td>" +
			"<td>" + value.pid + "</td>" +
			"<td>" + eid + "</td>" +
			"<td>" + uid + "</td>" +
			"<td>" + expires + "</td>" +
			"<td>" + allowed + "</td>" +
			"<td>" + value.reserved_pid + "</td>" + "</tr>";
		});
		$('#' + name + '-tbody').html(html);
		InitTable(name);

		// These are the totals.
		html = "";
		
		_.each(json.value.totals, function(value, type) {
		    html = html + "<tr>" +
			"<td>" + type + "</td>" +
			"<td>" + value.inuse + "</td>" +
			"<td>" + value.preres + "</td>" +
			"<td>" + value.free;
		    if (value.free_preres) {
			html += " (" + value.free_preres + ")";
		    }
		    html += "</td>" + "</tr>";		    
		});
		$('#counts-' + name + '-tbody').html(html);
	    }
	    var xmlthing = sup.CallServerMethod(null, "cluster-status",
						"GetStatus",
						{"cluster" : urn});
	    xmlthing.done(callback);
	});
    }

    function InitTable(name)
    {
	var tablename  = "#inuse-table-" + name;
	var searchname = "#inuse-search-" + name;
	var countname  = "#inuse-count-" + name;
	var clickname  = "#inuse-click-" + name;
	var panelname  = "#inuse-panel-" + name;
	
	var table = $(tablename)
		.tablesorter({
		    theme : 'green',
		    widgets: ["filter"],

		    widgetOptions: {
			// include child row content while filtering, if true
			filter_childRows  : true,
			// include all columns in the search.
			filter_anyMatch   : true,
			// class name applied to filter row and each input
			filter_cssFilter  : 'form-control',
			// search from beginning
			filter_startsWith : false,
			// Set this option to false for case sensitive search
			filter_ignoreCase : true,
			// Only one search box.
			filter_columnFilters : true,
			}
		});

	table.bind('filterEnd', function(e, filter) {
	    $(countname).text(filter.filteredRows);
	});

	// Target the $('.search') input using built in functioning
	// this binds to the search using "search" and "keyup"
	// Allows using filter_liveSearch or delayed search &
	// pressing escape to cancel the search
	$.tablesorter.filter.bindSearch(table, $(searchname));
	$.tablesorter.filter.bindSearch(table, $('#inuse-search-all'));
	$(tablename).removeClass("hidden");

	/*
	 * This is the expand/collapse button for an individual table.
	 */
	$('#inuse-collapse-button-' + name).click(function () {
	    if ($(panelname).data("status") == "minimized") {
		$(panelname).removeClass("inuse-panel");
		$('#counts-panel-' + name).removeClass("counts-panel");
		$(panelname).data("status", "maximized");
	    }
	    else {
		$(panelname).addClass("inuse-panel");
		$('#counts-panel-' + name).addClass("counts-panel");
		$(panelname).data("status", "minimized");
	    }
	})
    }
    
    $(document).ready(initialize);
});
