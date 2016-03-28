require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'moment',
	 'js/lib/text!template/show-project.html',
	 'js/lib/text!template/experiment-list.html',
	 'js/lib/text!template/profile-list.html',
	 'js/lib/text!template/member-list.html',
	 'js/lib/text!template/project-profile.html',
	],
function (_, sup, moment, mainString,
	  experimentString, profileString, memberString, detailsString)
{
    'use strict';
    var mainTemplate    = _.template(mainString);
    
    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	
	// Generate the main template.
	var html = mainTemplate({
	    emulablink     : window.EMULAB_LINK,
	    isadmin        : window.ISADMIN,
	    target_project : window.TARGET_PROJECT,
	});
	$('#main-body').html(html);

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
	LoadProfileTab();
	LoadMembersTab();
	LoadProjectTab();
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
				"showCreator" : true,
				"showProject" : false}));
	    
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
					    "show-project", "ExperimentList",
					    {"pid" : window.TARGET_PROJECT});
	xmlthing.done(callback);
    }

    function LoadProfileTab()
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
	    var template = _.template(profileString);

	    $('#profiles_content')
		.html(template({"profiles"    : json.value,
				"showCreator" : true,
				"showProject" : false}));
	    
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
					    "show-project", "ProfileList",
					    {"pid" : window.TARGET_PROJECT});
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

    function LoadMembersTab()
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
	    var template = _.template(memberString);

	    $('#members_content')
		.html(template({"members" : json.value,
				"pid"     : window.TARGET_PROJECT}));
	    
	    // Format dates with moment before display.
	    $('#members_table .format-date').each(function() {
		var date = $.trim($(this).html());
		if (date != "") {
		    $(this).html(moment($(this).html()).format("ll"));
		}
	    });
	    var table = $('#members_table')
		.tablesorter({
		    theme : 'green',
		});
	}
	var xmlthing = sup.CallServerMethod(null,
					    "show-project", "MemberList",
					    {"pid" : window.TARGET_PROJECT});
	xmlthing.done(callback);
    }

    function LoadProjectTab()
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
	    var template = _.template(detailsString);

	    $('#admin_content')
		.html(template({"fields" : json.value}));
	    
	    // Format dates with moment before display.
	    $('#admin_table .format-date').each(function() {
		var date = $.trim($(this).html());
		if (date != "") {
		    $(this).html(moment($(this).html()).format("ll"));
		}
	    });
	}
	var xmlthing = sup.CallServerMethod(null,
					    "show-project", "ProjectProfile",
					    {"pid" : window.TARGET_PROJECT});
	xmlthing.done(callback);
    }

    $(document).ready(initialize);
});


