require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'moment',
	 'js/lib/text!template/adminextend.html',
	 'js/lib/text!template/waitwait-modal.html',
	 'js/lib/text!template/oops-modal.html'],
function (_, sup, moment, mainString, waitwaitString, oopsString)
{
    'use strict';
    var extensions         = null;
    var firstrowTemplate   = null;
    var secondrowTemplate  = null;
    var extensionsTemplate = null;

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	$('#main-body').html(mainString);
	$('#waitwait_div').html(waitwaitString);
	$('#oops_div').html(oopsString);

	firstrowTemplate = _.template($('#firstrow-template', html).html());
	secondrowTemplate = _.template($('#secondrow-template', html).html());
	extensionsTemplate = _.template($('#history-template', html).html());

	LoadUtilization();
	LoadIdleData();
	LoadFirstRow();

	// Second row is the user/project usage summarys. We make two calls
	// and use jquery "when" to wait for both to finish before running
	// the template.
	var xmlthing1 = sup.CallServerMethod(null, "user-dashboard", "UsageSummary",
					     {"uid"    : window.CREATOR});
	var xmlthing2 = sup.CallServerMethod(null, "show-project", "UsageSummary",
					     {"pid"    : window.PID});
	$.when(xmlthing1, xmlthing2).done(function(result1, result2) {
	    var html = secondrowTemplate({"uid"     : window.CREATOR,
					  "pid"     : window.PID,
					  "uuid"    : window.UUID,
					  "user"    : result1[0].value,
					  "project" : result2[0].value});
	    $("#secondrow").html(html);
	});

	// The extension details in a collapse panel.
	if ($('#extensions-json').length) {
	    extensions = decodejson('#extensions-json');
	    console.info(extensions);

	    var html = extensionsTemplate({"extensions" : extensions});
	    $("#history-panel-content").html(html);
	    $("#history-panel-div").removeClass("hidden");

	    // Scroll to the bottom does not appear to work until the div
	    // is actually expanded.
	    $('#history-collapse').on('shown.bs.collapse', function () {
		$("#history-panel-content").scrollTop(10000);
	    });
	}
	if ($('#extension-reason').length) {
	    $("#extension-reason-row pre").text($('#extension-reason').text());
	    $("#extension-reason-row").removeClass("hidden");
	}
	
	// Default number of days.
	if (window.DAYS) {
	    $('#days').val(window.DAYS);
	}
	// Handlers for Extend and Deny buttons.
	$('#deny-extension').click(function (event) {
	    event.preventDefault();
	    Action("deny");
	    return false;
	});
	$('#do-extension').click(function (event) {
	    event.preventDefault();
	    Action("extend");
	    return false;
	});
    }

    //
    // Do the extension.
    //
    function Action(action)
    {
	var howlong = $('#days').val();
	var reason  = $("#reason").val();
	var method  = (action == "extend" ? "RequestExtension" : "DenyExtension");

	var callback = function(json) {
	    sup.HideModal("#waitwait-modal");

	    if (json.code) {
		if (json.code < 0) {
		    message = "Could not extend experiment!";
		}
		else {
		    message = "Could not extend experiment: " + json.value;
		}
		sup.SpitOops("oops", message);
		return;
	    }
	    LoadFirstRow();
	};
	sup.ShowModal("#waitwait-modal");
	var xmlthing = sup.CallServerMethod(null, "status", method,
					    {"uuid"   : window.UUID,
					     "howlong": howlong,
					     "reason" : reason});
	xmlthing.done(callback);	
    }

    // First Row is the experiment summary info.
    function LoadFirstRow() {
	sup.CallServerMethod(null, "status", "ExpInfo", {"uuid" : window.UUID},
			     function (json) {
				 console.info(json);
				 if (json.code == 0) {
				     var html = firstrowTemplate({"expinfo": json.value,
							  "uuid"    : window.UUID,
							  "uid"     : window.CREATOR,
							  "pid"     : window.PID});
				     $("#firstrow").html(html);
				     $('.format-date').each(function() {
					 var date = $.trim($(this).html());
					 if (date != "") {
					     $(this).html(moment($(this).html())
							  .format("MMM D h:mm A"));
					 }
				     });
				     // lockout change event handler.
				     $('#lockout-checkbox').change(function() {
					 DoLockout($(this).is(":checked"));
				     });	
				 }
			     });
    }

    function LoadUtilization() {
	var util = $('#utilization-template', "html").html();
	var summary = $('#summary-template', "html").html();
	var utilizationTemplate = _.template(util);
	var summaryTemplate = _.template(summary);
	
	var callback = function(json) {
	    console.info(json);
	    var html = utilizationTemplate({"utilization" : json.value});
	    $("#utilization-panel-content").html(html);
	    InitTable("utilization");
	    $("#utilization-panel-div").removeClass("hidden");

	    var html = summaryTemplate({"utilization" : json.value});
	    $("#thirdrow").html(html);
	};
	var xmlthing = sup.CallServerMethod(null, "status", "Utilization",
					    {"uuid"   : window.UUID});
	xmlthing.done(callback);	
    }
    function InitTable(name)
    {
	var tablename  = "#" + name + "-table";
	
	var table = $(tablename)
		.tablesorter({
		    theme : 'green',
		    // initialize zebra and filter widgets
		    widgets: ["uitheme"],
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
    }

    //
    // Request lockout set/clear.
    //
    function DoLockout(lockout)
    {
	lockout = (lockout ? 1 : 0);
	
	var callback = function(json) {
	    if (json.code) {
		alert("Failed to change lockout: " + json.value);
		return;
	    }
	}
	var xmlthing = sup.CallServerMethod(null, "status", "Lockout",
					     {"uuid" : window.UUID,
					      "lockout" : lockout});
	xmlthing.done(callback);
    }

    function LoadIdleData()
    {
	var exptTraffic  = [];
	var ctrlTraffic  = [];
	var loadavs      = [];

	var ProcessSite = function(idledata) {
	    /*
	     * Array of objects, one per node. But some nodes might not
	     * have any data (main array is zero), so need to skip those.
	     */
	    var index = 0;
	    
	    for (var i in idledata) {
		var obj = idledata[i];
		var node_id = obj.node_id;
		var loadvalues = [];

		//
		// If idlestats finds no data, the main array is zero length.
		// Skip.
		//
		if (obj.main.length == 0) {
		    console.info("No idledata for " + node_id);
		    continue;
		}
		// The main array is the load average data.
		for (var j = 1; j < obj.main.length; j++) {
		    var loads = obj.main[j];

		    loadvalues[j - 1] = {
			// convert seconds to milliseconds.
			"x" : loads[0] * 1000,
			"y" : loads[3],
		    };
		}	    
		loadavs[index] = {
		    "key"    : node_id,
		    "area"   : 0,
		    "values" : loadvalues,
		};
		var control_iface = obj.interfaces.ctrl_iface;

		for (var mac in obj.interfaces) {
		    //console.info(mac, obj.interfaces[mac]);

		    if (mac == "ctrl_iface") {
			continue;
		    }
		
		    if (obj.interfaces[mac].length) {
			var trafficvalues = [];
		    
			for (var j = 1; j < obj.interfaces[mac].length; j++) {
			    var data = obj.interfaces[mac][j];

			    trafficvalues[j - 1] = {
				"x" : data[0] * 1000,
				"y" : data[1] + data[2]
			    };
			}
			var datum = {
			    "key"    : node_id,
			    "area"   : 0,
			    "values" : trafficvalues,
			};
			if (mac == control_iface) {
			    ctrlTraffic[index] = datum;
			}
			else {
			    exptTraffic[index] = datum;
			}
		    }
		}
		index++;
	    }
	};
	
	var callback = function(json) {
	    if (json.code) {
		console.info("Failed to get idledata: " + json.value);
		return;
	    }
	    _.each(json.value, function(data, name) {
		var idledata = JSON.parse(data);

		ProcessSite(idledata);
	    });
	    //console.info(loadavs);
	    //console.info(ctrlTraffic);
	    //console.info(exptTraffic);

	    if (loadavs.length) {
		$("#loadavg-panel-div").removeClass("hidden");
		$("#loadavg-collapse").addClass("in");
		
		window.nv.addGraph(function() {
		    var chart = window.nv.models.lineWithFocusChart();
		    CreateIdleGraph('#loadavg-chart svg',
				chart, loadavs, "float");
		});
	    }
	    if (ctrlTraffic.length) {
		$("#ctrl-traffic-panel-div").removeClass("hidden");
		$("#ctrl-traffic-collapse").addClass("in");

		window.nv.addGraph(function() {
		    var chart = window.nv.models.lineWithFocusChart();
		    CreateIdleGraph('#ctrl-traffic-chart svg',
				chart, ctrlTraffic, "int");
		});
	    }
	    if (exptTraffic.length) {
		$("#expt-traffic-panel-div").removeClass("hidden");
		$("#expt-traffic-collapse").addClass("in");

		window.nv.addGraph(function() {
		    var chart = window.nv.models.lineWithFocusChart();
		    CreateIdleGraph('#expt-traffic-chart svg',
				chart, exptTraffic, "int");
		});
	    }
	};
	var xmlthing = sup.CallServerMethod(null, "status", "IdleData",
					    {"uuid"   : window.UUID});
	xmlthing.done(callback);	
    }

    function CreateIdleGraph(id, chart, datums, ytype) {
        var tickMultiFormat = d3.time.format.multi([
	    // not the beginning of the hour
	    ["%-I:%M%p", function(d) { return d.getMinutes(); }],
	    // not midnight
	    ["%-I%p", function(d) { return d.getHours(); }],
	    // not the first of the month
	    ["%b %-d", function(d) { return d.getDate() != 1; }],
	    // not Jan 1st
	    ["%b %-d", function(d) { return d.getMonth(); }], 
	    ["%Y", function() { return true; }]
        ]);
	/*
	 * We need the min,max of the time stamps for the brush. We can use
	 * just one of the nodes.
	 */ 
	var minTime = d3.min(datums[0].values,
			     function (d) { return d.x; });
	var maxTime = d3.max(datums[0].values,
			     function (d) { return d.x; });
	// Adjust the brush to the last day.
	if (maxTime - minTime > (3600 * 24 * 1000)) {
	    minTime = maxTime - (3600 * 24 * 1000);
	}
	chart.brushExtent([minTime,maxTime]);

	// We want different Y axis scales, wow this took a long time
	// to figure out.
	chart.lines.scatter.yScale(d3.scale.sqrt());
	chart.yAxis.scale(d3.scale.sqrt());

	chart.xAxis.tickFormat(function (d) {
	    return tickMultiFormat(new Date(d));
	});
	chart.x2Axis.tickFormat(function (d) {
	    return tickMultiFormat(new Date(d));
	});
	if (ytype == "float") {
	    chart.yAxis.tickFormat(d3.format(',.2f'));
	    chart.y2Axis.tickFormat(d3.format(',.2f'));
	}
	else {
	    chart.yAxis.tickFormat(d3.format(',.0f'));
	    chart.y2Axis.tickFormat(d3.format(',.0f'));
	}
	chart.useInteractiveGuideline(true);
	d3.select(id)
	    .datum(datums)
	    .call(chart);

        // set up the tooltip to display full dates
        var tsFormat = d3.time.format('%b %-d, %Y %I:%M%p');
        var contentGenerator = chart.interactiveLayer.tooltip.contentGenerator();
        var tooltip = chart.interactiveLayer.tooltip;
        tooltip.contentGenerator(function (d) {
	    d.value = d.series[0].data.x; return contentGenerator(d);
	});
        tooltip.headerFormatter(function (d) {
	    return tsFormat(new Date(d));
	});
	tooltip.classes("tooltip-font");
	window.nv.utils.windowResize(chart.update);
	return chart;
    }

    // Helper.
    function decodejson(id) {
	return JSON.parse(_.unescape($(id)[0].textContent));
    }
    
    $(document).ready(initialize);
});
