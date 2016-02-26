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
			"<td>" + value.reserved_pid + "</td>" + "</tr>";
		});
		$('#' + name + '-tbody').html(html);
		InitTable(name);
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
	
	var table = $(tablename)
		.tablesorter({
		    theme : 'green',
		    widgets: ["filter", "resizable"],

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
			filter_columnFilters : false,
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
	$(tablename).removeClass("hidden");
    }
    
    $(document).ready(initialize);
});
