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
	setInterval(DashboardLoop,30000);
	setInterval(UpdateTimes,1000);
    }

    function DashboardLoop()
    {
	var callback = function(json) {
	    console.log(json);
	    if (json.code) {
		console.log("Could not get dashboard data: " + json.value);
		return;
	    }
	    var dashboard_html = dashboardTemplate({"dashboard": json.value,
						    "isadmin": isadmin});
	    $('#page-body').html(dashboard_html);
	    $('#last-refresh').data("time",new Date());
	    
	    // Format dates with moment before display.
	    $('.format-date').each(function() {
		var date = $.trim($(this).html());
		if (date != "") {
		    $(this).html(moment($(this).html())
				 .format("ddd h:mm A"));
		}
	    });
	    $('.format-date-withday').each(function() {
		var date = $.trim($(this).html());
		if (date != "") {
		    $(this).html(moment($(this).html())
				 .format("MMM D h:mm A"));
		}
	    });
	    $('.format-date-month').each(function() {
		var date = $.trim($(this).html());
		if (date != "") {
		    $(this).html(moment($(this).html())
				 .format("ll"));
		}
	    });
	    $('.format-date-relative').each(function() {
		var date = $.trim($(this).html());
		if (date != "") {
		    $(this).html(moment($(this).html()).fromNow());
		}
	    });
	    $('[data-toggle="popover"]').popover({
		trigger: 'hover',
		placement: 'auto',
		html: true,
		content: function () {
		    var uuid = $(this).data("uuid");
		    var html = "<code style='white-space: pre-wrap'>" +
			json.value.error_details[uuid].message + "</code>";
		    return html;
		}
	    });
	    UpdateTimes();
	}
	var xmlthing = sup.CallServerMethod(null, "dashboard",
					    "GetStats", null);
	xmlthing.done(callback);
    }

    function UpdateTimes()
    {
        $('.format-date-last-refresh').each(function() {
            var date = $(this).data("time");
            if (date != "") {
                $(this).html(moment(date).fromNow());
            }
        });

    }

    $(document).ready(initialize);
});
