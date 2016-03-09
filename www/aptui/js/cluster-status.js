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
		//console.log(json);
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
	_.each(amlist, function(urn, name) {
	    var callback = function(json) {
		console.log(json);
		if (json.code) {
		    console.log("Could not get prereserve data: " + json.value);
		    return;
		}
		var prereserve = json.value;
		var html = "";

		prereserve.forEach(function(value, index) {
		    var created = moment(value.created).format("ll");
		    var expando = "";

		    if (value.prereserved.length) {
			var target = "#" + value.pid + "-collapse";

			expando =
			    "<a data-target='" + target + "' class=expando>" +
			    "  <span " +
			    "    class='glyphicon glyphicon-chevron-right'>" +
			    "  </span></a> ";
		    }
		    html = html + "<tr> " +
			"<td>" + expando + value.pid + "</td>" +
			"<td>" + value.name + "</td>" +
			"<td>" + value.priority + "</td>" +
			"<td>" + value.count + "</td>" +
			"<td>" + value.prereserved.length + "</td>" +
			"<td>" + value.types + "</td>" +
			"<td>" + value.creator + "</td>" +
			"<td>" + created + "</td>" + "</tr>";
		    if (value.prereserved.length) {
			html = html +
			    " <tr><td class=hiddenRow></td> " +
			    "  <td colspan=7 class=hiddenRow>" +
			    "   <div class='collapse' " +
			    "        id='" +  value.pid + "-collapse'>" +
			    "    <center class=text-center>Pre Reserved</center>"+
			    "    <table class='tablesorter tablesorter-green'>"+
			    "     <thead> " +
			    "      <th>Node</th><th>Type</th> " +
			    "     </thead>";
			
			for (var i=0; i < value.prereserved.length; i++) {
			    var pre = value.prereserved[i];

			    html = html + "<tr>" +
				"<td>" + pre.node_id + "</td>" +
				"<td>" + pre.type + "</td>" + "</tr>";
			}
			html = html + "</table></div></td>" +
			    "</tr>";
		    }
		});
		$('#prereserve-' + name + '-tbody').html(html);

		/*
		 * Expand/collapse for all the prereserve rows.
		 */
		$('.expando').click(function () {
		    var rowname = $(this).data("target");

		    if (! $(rowname).hasClass("in")) {
			$(rowname).collapse('show');
			$(this).find('span')
			    .removeClass("glyphicon-chevron-right");
			$(this).find('span')
			    .addClass("glyphicon-chevron-down");
		    }
		    else {
			$(rowname).collapse('hide');
			$(this).find('span')
			    .removeClass("glyphicon-chevron-down");
			$(this).find('span')
			    .addClass("glyphicon-chevron-right");
		    }
		});
		 
		/*
		 * Expand/Collapse the prereserve table
		 */
		$('#prereserve-collapse-button-' + name).click(function () {
		    var panelname = '#prereserve-panel-' + name;

		    if (! $(panelname).hasClass("in")) {
			$(panelname).collapse('show');
			$(this).removeClass("glyphicon-chevron-right");
			$(this).addClass("glyphicon-chevron-down");
		    }
		    else {
			$(panelname).collapse('hide');
			$(this).removeClass("glyphicon-chevron-down");
			$(this).addClass("glyphicon-chevron-right");
		    }
		});
		// Show the panel.
		$('#prereserve-row-' + name).removeClass("hidden");
	    }
	    var xmlthing = sup.CallServerMethod(null, "cluster-status",
						"GetPreReservations",
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
		$(this).removeClass("glyphicon-chevron-right");
		$(this).addClass("glyphicon-chevron-down");
	    }
	    else {
		$(panelname).addClass("inuse-panel");
		$('#counts-panel-' + name).addClass("counts-panel");
		$(panelname).data("status", "minimized");
		$(this).removeClass("glyphicon-chevron-down");
		$(this).addClass("glyphicon-chevron-right");
	    }
	})
    }
    
    $(document).ready(initialize);
});
