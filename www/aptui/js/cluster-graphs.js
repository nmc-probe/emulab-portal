require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup',
	 'js/lib/text!template/cluster-graphs.html',
	 'js/bilevel', 'js/liquidFillGauge'],
function (_, sup, clusterString)
{
    'use strict';
    var mainsite = false;
    var template = _.template(clusterString);

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	mainsite = window.MAINSITE;

	$('#cluster-graphs')
	    .html(template({"mainsite" : mainsite}));

	if (mainsite) {
	    bilevelAsterGraph("/cloudlab-nofed.json",
			      "#status-nofed","auto","large");
	    bilevelAsterGraph("/cloudlab-fedonly.json",
			      "#status-fedonly","auto","large");
	}
	else {
	    $('#status-local').load("/node_usage/freenodes.svg");
	}
	setTimeout(function f() { Refresh() }, 30000);
    }

    /*
     * Refresh the graphs.
     */
    function Refresh()
    {
	if (mainsite) {
	    $('#status-fedonly').html("");
	    $('#status-nofed').html("");
	    $("div").remove(".d3-tip");
	
	    bilevelAsterGraph("/cloudlab-nofed.json",
			      "#status-nofed","auto","large");
	    bilevelAsterGraph("/cloudlab-fedonly.json",
			      "#status-fedonly","auto","large");
	}
	else {
	    $('#status-local').html("");
	    $('#status-local').load("/node_usage/freenodes.svg");
	}
	setTimeout(function f() { Refresh() }, 30000);
    }
	
    $(document).ready(initialize);
});
