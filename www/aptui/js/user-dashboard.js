require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'moment',
	 'js/lib/text!template/user-dashboard.html',
	 'js/lib/text!template/experiment-list.html',
	 'js/lib/text!template/profile-list.html',
	 'js/lib/text!template/project-list.html',
	 'js/lib/text!template/user-profile.html',
	 'js/lib/text!template/oops-modal.html',
	 'js/lib/text!template/waitwait-modal.html',
	],
function (_, sup, moment, mainString,
	  experimentString, profileListString, projectString,
	  profileString, oopsString, waitwaitString)
{
    'use strict';
    var mainTemplate = _.template(mainString);

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	// Generate the main template.
	var html = mainTemplate({
	    emulablink  : window.EMULAB_LINK,
	    isadmin     : window.ISADMIN,
	    target_user : window.TARGET_USER,
	});
	$('#main-body').html(html);
	$('#oops_div').html(oopsString);
	$('#waitwait_div').html(waitwaitString);

        // Javascript to enable link to tab
        var hash = document.location.hash;
        if (hash) {
            $('.nav-tabs a[href='+hash+']').tab('show');
        }
        // Change hash for page-reload
        $('a[data-toggle="tab"]').on('show.bs.tab', function (e) {
            window.location.hash = e.target.hash;
        });

	LoadExperimentTab();
	// Should we do these on demand?
	LoadProfileListTab();
	LoadProjectsTab();
	LoadProfileTab();
    }

    function LoadExperimentTab()
    {
	var callback = function(json) {
	    console.info(json);

	    if (json.code) {
		console.info(json.value);
		return;
	    }
	    if (json.value.length == 0) {
		$('#experiments_loading').addClass("hidden");
		$('#experiments_noexperiments').removeClass("hidden");
		return;
	    }
	    var template = _.template(experimentString);

	    $('#experiments_content')
		.html(template({"experiments" : json.value,
				"showCreator" : false,
				"showProject" : true}));
	    
	    // Format dates with moment before display.
	    $('#experiments_table .format-date').each(function() {
		var date = $.trim($(this).html());
		if (date != "") {
		    $(this).html(moment($(this).html()).format("ll"));
		}
	    });
	    var table = $('#experiments_table')
		.tablesorter({
		    theme : 'green',
		});
	}
	var xmlthing = sup.CallServerMethod(null,
					    "user-dashboard", "ExperimentList",
					    {"uid" : window.TARGET_USER});
	xmlthing.done(callback);
    }

    function LoadProfileListTab()
    {
	var callback = function(json) {
	    console.info(json);

	    if (json.code) {
		console.info(json.value);
		return;
	    }
	    if (json.value.length == 0) {
		$('#profiles_noprofiles').removeClass("hidden");
		return;
	    }
	    var template = _.template(profileListString);

	    $('#profiles_content')
		.html(template({"profiles"    : json.value,
				"showCreator" : false,
				"showProject" : true}));
	    
	    // Format dates with moment before display.
	    $('#profiles_table .format-date').each(function() {
		var date = $.trim($(this).html());
		if (date != "") {
		    $(this).html(moment($(this).html()).format("ll"));
		}
	    });
	    // Display the topo.
	    $('.showtopo_modal_button').click(function (event) {
		event.preventDefault();
		ShowTopology($(this).data("profile"));
	    });
	    
	    var table = $('#profiles_table')
		.tablesorter({
		    theme : 'green',
		});
	}
	var xmlthing = sup.CallServerMethod(null,
					    "user-dashboard", "ProfileList",
					    {"uid" : window.TARGET_USER});
	xmlthing.done(callback);
    }

    function ShowTopology(profile)
    {
	var profile;
	var index;
    
	var callback = function(json) {
	    if (json.code) {
		alert("Failed to get rspec for topology viewer: " + json.value);
		return;
	    }
	    sup.ShowModal("#quickvm_topomodal");
	    $("#quickvm_topomodal").one("shown.bs.modal", function () {
		sup.maketopmap('#showtopo_nopicker',
			       json.value.rspec, false, !window.ISADMIN);
	    });
	};
	var $xmlthing = sup.CallServerMethod(null,
					     "myprofiles",
					     "GetProfile",
				     	     {"uuid" : profile});
	$xmlthing.done(callback);
    }

    function LoadProjectsTab()
    {
	var callback = function(json) {
	    console.info(json);

	    if (json.code) {
		console.info(json.value);
		return;
	    }
	    if (json.value.length == 0) {
		return;
	    }
	    var template = _.template(projectString);

	    $('#membership_content')
		.html(template({"projects" : json.value}));

	    var table = $('#projects_table')
		.tablesorter({
		    theme : 'green',
		});
	}
	var xmlthing = sup.CallServerMethod(null,
					    "user-dashboard", "ProjectList",
					    {"uid" : window.TARGET_USER});
	xmlthing.done(callback);
    }

    /*
     * We actually display two profile tabs, one for the non-admin view,
     * which is always the same. The other for the admin view. 
     */

    function LoadProfileTab()
    {
	var callback = function(json) {
	    console.info(json.value);

	    if (json.code) {
		console.info(json.value);
		return;
	    }
	    if (json.value.length == 0) {
		return;
	    }
	    var template = _.template(profileString);

	    if (window.ISADMIN) {
		$('#admin_content')
		    .html(template({"fields"  : json.value,
				    "isadmin" : 1}));

		// Format dates with moment before display.
		$('#admin_content .format-date').each(function() {
		    var date = $.trim($(this).html());
		    if (date != "") {
			$(this).html(moment($(this).html()).format("ll"));
		    }
		});
		$('#admin_content .toggle').click(function() {
		    Toggle(this);
		});
	    }
	    $('#myprofile_content')
		.html(template({"fields"  : json.value,
				"isadmin" : 0}));
	}
	var xmlthing = sup.CallServerMethod(null,
					    "user-dashboard", "AccountDetails",
					    {"uid" : window.TARGET_USER});
	xmlthing.done(callback);
    }

    //
    // Toggle flags.
    //
    function Toggle(item) {
	var name = item.dataset["name"];

	var callback = function(json) {
	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    LoadProfileTab();
	};
	sup.CallServerMethod(null, "user-dashboard", "Toggle",
			     {"uid" : window.TARGET_USER,
			      "toggle" : name},
			     callback);
    }

    $(document).ready(initialize);
});
