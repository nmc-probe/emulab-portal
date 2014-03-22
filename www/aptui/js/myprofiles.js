window.APT_OPTIONS.config();

require(['jquery', 'js/quickvm_sup',
	 'tablesorter', 'tablesorterwidgets', 'bootstrap'],
function ($, sup)
{
    'use strict';

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	var table = $(".tablesorter")
		.tablesorter({
		    theme : 'green',
		    
		    //cssChildRow: "tablesorter-childRow",

		    // initialize zebra and filter widgets
		    widgets: ["zebra", "filter", "resizable"],

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

	// Target the $('.search') input using built in functioning
	// this binds to the search using "search" and "keyup"
	// Allows using filter_liveSearch or delayed search &
	// pressing escape to cancel the search
	$.tablesorter.filter.bindSearch( table, $('#profile_search') );

	$('.showtopo_modal_button').click(function (event) {
	    event.preventDefault();
	    ShowTopology($(this).data("profile"));
	});
	
    }

    function ShowTopology(profile)
    {
	var profile;
	var index;
    
	var callback = function(json) {
	    var xmlDoc = $.parseXML(json.value.rspec);
	    var xml    = $(xmlDoc);
	    var topo   = sup.ConvertManifestToJSON(profile, xml);

	    sup.ShowModal("#quickvm_topomodal");

	    // Subtract -2 cause of the border. 
	    sup.maketopmap("#showtopo_nopicker",
 			   ($("#showtopo_nopicker").outerWidth() - 2),
			   300, topo, null);
	};
	var $xmlthing = sup.CallMethod("getprofile", null, 0, profile);
	$xmlthing.done(callback);
    }

    $(document).ready(initialize);
});
