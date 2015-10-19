require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'moment',
	 'js/lib/text!template/dashboard.html'],
function (_, sup, moment, dashboardString)
{
    'use strict';
    var isadmin           = 0;
    var dashboardTemplate = _.template(dashboardString);

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	isadmin = window.ISADMIN;

	DashboardLoop();
    }

    function DashboardLoop()
    {
	var callback = function(json) {
	    console.log(json);
	    
	    var dashboard_html = dashboardTemplate({"dashboard": json.value,
						    "isadmin": isadmin});
	    $('#page-body').html(dashboard_html);
	    
	    // Format dates with moment before display.
	    $('.format-date').each(function() {
		var date = $.trim($(this).html());
		if (date != "") {
		    $(this).html(moment($(this).html())
				 .format("ddd h:mm A"));
		}
	    });
	    setTimeout(function f() { DashboardLoop() }, 5000);
	}
	var xmlthing = sup.CallServerMethod(null, "dashboard",
					    "GetStats", null);
	xmlthing.done(callback);
    }
    $(document).ready(initialize);
});
