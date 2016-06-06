//
// Slothd graphs
//
define(['underscore', 'js/quickvm_sup', 'moment'],
    function(_, sup, moment)
    {
	'use strict';
	var uuid  = null;
	var divID = null;
	var cpu   = [];
	var net   = [];

	function LoadOpenstackData()
	{
	    var callback = function(json) {
		var openstackdata = JSON.parse(json.value);
		console.info("openstack", openstackdata);

		// First get the mapping of VM UUIDs to VM details.
		var vmmap = {};
		var index = 0;
		
		_.each(openstackdata.info.vms, function(vmlist, hostname) {
		    _.each(vmlist, function(details, uuid) {
			vmmap[uuid] = details;
			// And the pnode vname/nodeid
			details["hostvname"] =
			    openstackdata.info.host2vname[hostname];
			details["hostpnode"] =
			    openstackdata.info.host2pnode[hostname];
			details["index"] = index;
			
			cpu[index] = {
			    "type"   : "bar",
			    "yAxis"  : 1,
			    "key"    : details.name,
			    "values" : [],
			};
			net[index++] = {
			    "type"   : "line",
			    "yAxis"  : 2,
			    "key"    : details.name,
			    "values" : [],
			};
		    });
		});
		console.info("vmmap", vmmap);
		
		_.each(openstackdata.periods, function(data, time) {
		    console.log(time, data);
		    _.each(data.cpu_util, function(utildata, hostname) {
			_.each(utildata.vms, function(util, uuid) {
			    var index = vmmap[uuid].index;
			    var i = cpu[index].values.length;
			    cpu[index].values[i] = {
				// convert seconds to milliseconds.
				"x" : parseInt(time),
				"y" : util,
			    };
			});
		    });
		    _.each(data["network.outgoing.bytes.rate"],
			   function(utildata, hostname) {
			_.each(utildata.vms, function(rate, uuid) {
			    console.info(time, hostname, uuid, rate);
			    var index = vmmap[uuid].index;
			    var i = net[index].values.length;
			    net[index].values[i] = {
				// convert seconds to milliseconds.
				"x" : parseInt(time),
				"y" : rate,
			    };
			});
		    });
		});
		console.info("cpu and net", cpu, net);
		$(divID).removeClass("hidden");
		$(divID).append("<div id='foo' class='smalldiv " +
				"     with-3d-shadow with-transitions'>"+
				"  <svg></svg>" +
				"</div>");
		$(divID).append("<div id='bar' class='smalldiv " +
				"     with-3d-shadow with-transitions'>"+
				"  <svg></svg>" +
				"</div>");
		var chart1 = window.nv.models.multiBarChart();
		CreateOneGraph(divID + ' #foo svg', chart1, cpu,
			       "CPU Utilization");
		var chart2 = window.nv.models.multiBarChart();
		CreateOneGraph(divID + ' #bar svg', chart2, net,
			       "Network Bytes Transferred");
	    };
    	    var xmlthing = sup.CallServerMethod(null, "status",
						"OpenstackStats",
						{"uuid" : uuid});
	    xmlthing.done(callback);
	}

	function CreateOneGraph(id, chart, datums, ylabel)
	{
	    chart.showControls(false);
	    chart.color(d3.scale.category20().range());
	    var width = parseInt(d3.select(id).style('width')) - 80;

	    chart.xAxis
		.scale(d3.scale.ordinal()
 	               .rangeRoundBands([0,width], .1)
	               .domain(datums[0].values.map(function(d) {
			   return d.x; })));	    
	    
            chart.yAxis
		.axisLabel(ylabel)
		.tickFormat(d3.format(',.2f'));
	    
            d3.select(id)
		.datum(datums)
		.call(chart);
	    
            nv.utils.windowResize(chart.update);
	}

	return function(args) {
	    uuid     = args.uuid;
	    divID    = args.divID;

	    LoadOpenstackData();
	}
    }
);
