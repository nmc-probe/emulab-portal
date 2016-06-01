//
// Slothd graphs
//
define(['underscore', 'js/quickvm_sup', 'moment'],
    function(_, sup, moment)
    {
	'use strict';
	var uuid       = null;
	var loadavID   = null;
	var ctrlID     = null;
	var exptID     = null;
	var C_callback = null;

	function LoadIdleData() {
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
		    // If idlestats finds no data, the main array is
		    // zero length. Skip.
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
			    
			    for (var j = 1;
				 j < obj.interfaces[mac].length; j++) {
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
		console.info(loadavs);
		console.info(ctrlTraffic);
		console.info(exptTraffic);

		// We want to tell the caller if there is any actual data
		if (C_callback) {
		    C_callback(loadavs.length + ctrlTraffic.length +
			       exptTraffic.length);
		}

		if (loadavs.length) {
		    $(loadavID).removeClass("hidden");
		    $(loadavID + " .collapse").addClass("in");
		    
		    window.nv.addGraph(function() {
			var chart = window.nv.models.lineWithFocusChart();
			CreateIdleGraph(loadavID + ' svg',
					chart, loadavs, "float");
			chart.yAxis.axisLabel("Unix Load Average")
			chart.update();
		    });
		}
		if (ctrlTraffic.length) {
		    $(ctrlID).removeClass("hidden");
		    $(ctrlID + " .collapse").addClass("in");
		    
		    window.nv.addGraph(function() {
			var chart = window.nv.models.lineWithFocusChart();
			CreateIdleGraph(ctrlID + ' svg',
					chart, ctrlTraffic, "int");
			chart.yAxis.axisLabel("Packets Per Second")
			chart.update();
		    });
		}
		if (exptTraffic.length) {
		    $(exptID).removeClass("hidden");
		    $(exptID + " .collapse").addClass("in");
		    
		    window.nv.addGraph(function() {
			var chart = window.nv.models.lineWithFocusChart();
			CreateIdleGraph(exptID + ' svg',
					chart, exptTraffic, "int");
			chart.yAxis.axisLabel("Packets Per Second")
			chart.update();
		    });
		}
	    };
	    var xmlthing = sup.CallServerMethod(null, "status", "IdleData",
						{"uuid" : uuid});
	    xmlthing.done(callback);	
	}

	function UpdateXaxisLabel(chart) {
	    var extent = chart.brushExtent();
	    var min = moment(extent[0]);
	    var max = moment(extent[1]);

	    chart.xAxis.axisLabel(min.format('lll') + " ... " +
				  max.format('lll'));
	    chart.update();
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

	    // Update the display on the X axis after brush change.
	    chart.focus.brush.on("brushend", function () {
		UpdateXaxisLabel(chart);
	    });

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
	    
	    UpdateXaxisLabel(chart);

            // set up the tooltip to display full dates
            var tsFormat = d3.time.format('%b %-d, %Y %I:%M%p');
            var contentGenerator =
		chart.interactiveLayer.tooltip.contentGenerator();
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

	return function(args) {
	    uuid       = args.uuid;
	    loadavID   = args.loadavID;
	    ctrlID     = args.ctrlID;
	    exptID     = args.exptID;
	    C_callback = args.callback;
	    LoadIdleData();
	}
    }
);
