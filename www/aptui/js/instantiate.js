require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'js/ppstart',
	 'js/lib/text!template/aboutapt.html',
	 'js/lib/text!template/aboutcloudlab.html',
	 'js/lib/text!template/waitwait-modal.html',
         'formhelpers', 'filestyle', 'marked'],
function (_, sup, ppstart, aboutaptString, aboutcloudString, waitwaitString)
{
    'use strict';

    var ajaxurl;
    var amlist        = null;
    var amdefault     = null;
    var selected_uuid = null;
    var ispprofile    = 0;
    var registered    = false;

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	registered = window.REGISTERED;
	ajaxurl = window.AJAXURL;
	if ($('#amlist-json').length) {
	    amlist  = JSON.parse(_.unescape($('#amlist-json')[0].textContent));
	}

	$('#waitwait_div').html(waitwaitString);
	// The about panel.
	if (window.SHOWABOUT) {
	    $('#about_div').html(window.ISCLOUD ?
				 aboutcloudString : aboutaptString);
	}

	if (window.APT_OPTIONS.isNewUser) {
	    $('#verify_modal_submit').click(function (event) {
		$('#verify_modal').modal('hide');
		$("#waitwait-modal").modal('show');
		return true;
	    });
	    $('#verify_modal').modal('show');
	}
        $('#quickvm_topomodal').on('shown.bs.modal', function() {
            ShowProfileSelection($('.current'))
        });

	$('button#reset-form').click(function (event) {
	    event.preventDefault();
	    resetForm($('#quickvm_form'));
	});
	$('button#profile').click(function (event) {
	    event.preventDefault();
	    $('#quickvm_topomodal').modal('show');
	});
	$('li.profile-item').click(function (event) {
	    event.preventDefault();
	    ShowProfileSelection(event.target);
	});
	$('button#showtopo_select').click(function (event) {
	    event.preventDefault();
	    ChangeProfileSelection($('.selected'));
	    $('#quickvm_topomodal').modal('hide');
	});
	$('#instantiate_submit').click(function (event) {
	    $("#waitwait-modal").modal('show');
	    return true;
	});
	$('#configurator_button').click(function (event) {
	    if (ispprofile) {
		event.preventDefault();
		ppstart({uuid         : selected_uuid,
			 registered   : registered,
			 amlist       : amlist,
			 amdefault    : amdefault,
			 callback     : ConfigureDone,
			 button_label : "Accept"});
	    }
	    return false;
	});
	$('#profile_copy_button').click(function (event) {
	    event.preventDefault();
	    if (!registered) {
		sup.SpitOops("oops", "You must be a registered user to copy " +
			     "a profile.");
	    }
	    else {
		var url = "manage_profile.php?action=copy&uuid=" +
		    selected_uuid;
		window.location.replace(url);
	    }
	    return false;
	});

	// Profile picker search box.
	var profile_picker_timeout = null;
	
	$("#profile_picker_search").on("keyup", function () {
	    var options   = $('#profile_name');
	    var userInput = $("#profile_picker_search").val();
	    userInput = userInput.toLowerCase();
	    window.clearTimeout(profile_picker_timeout);

	    profile_picker_timeout =
		window.setTimeout(function() {
		    var matches = 
			options.children("li").filter(function() {
			    var text = $(this).text();
			    text = text.toLowerCase();

			    if (text.indexOf(userInput) > -1)
				return true;
			    return false;
			});
		    options.children("li").hide();
		    matches.show();
		}, 500);
	});
	    
	var startProfile = $('#profile_name li[value = ' + window.PROFILE + ']')
        ChangeProfileSelection(startProfile);
	_.delay(function () {$('.dropdown-toggle').dropdown();}, 500);
    }

    function resetForm($form) {
	$form.find('input:text, input:password, select, textarea').val('');
    }

    function ShowProfileSelection(selectedElement) {
	if (!$(selectedElement).hasClass('selected')) {
	    $('#profile_name li').each(function() {
		$(this).removeClass('selected');
	    });
	    $(selectedElement).addClass('selected');
	}
	
	var continuation = function(rspec, description, name, amdefault, ispp) {
	    $('#showtopo_title').html("<h3>" + name + "</h3>");
	    $('#showtopo_description').html(description);
	    sup.maketopmap('#showtopo_div', rspec, null);
	};
	GetProfile($(selectedElement).attr('value'), continuation);
    }
    
    function ChangeProfileSelection(selectedElement) {
	if (!$(selectedElement).hasClass('current')) {
	    $('#profile_name li').each(function() {
		$(this).removeClass('current');
	    });
	    $(selectedElement).addClass('current');
	}

	var profile_name = $(selectedElement).text();
	var profile_value = $(selectedElement).attr('value');
	$('#selected_profile').attr('value', profile_value);
	$('#selected_profile_text').html("" + profile_name);
	
	var continuation = function(rspec, description, name, amdef, ispp) {
	    $('#showtopo_title').html("<h3>" + name + "</h3>");
	    $('#showtopo_description').html(description);
	    $('#selected_profile_description').html(description);

	    ispprofile    = ispp;
	    selected_uuid = profile_value;
	    amdefault     = amdefault;

	    // Show the configuration button, disable the create button.
	    if (ispprofile) {
		$("#configurator_button").removeClass("hidden");
		$('#instantiate_submit').attr('disabled', true);
	    }
	    else {
		$("#configurator_button").addClass("hidden");
		$('#instantiate_submit').attr('disabled', false);
	    }

	    // Hide the aggregate picker for a parameterized profile.
	    // Shown later.
	    if (ispprofile) {
		$("#profile_where").addClass("hidden");
	    }
	    else {
		$("#profile_where").removeClass("hidden");
	    }

	    // Set the default aggregate.
	    if ($('#profile_where').length) {
		// Deselect current option.
		$('#profile_where option').prop("selected", false);
		// Find and select new option.
		$('#profile_where option')
		    .filter('[value="'+ amdefault + '"]')
                    .prop('selected', true);		
	    }
	};
	GetProfile($(selectedElement).attr('value'), continuation);
    }
    
    function GetProfile(profile, continuation) {
	var callback = function(json) {
	    if (json.code) {
		alert("Could not get profile: " + json.value);
		return;
	    }
	    //console.info(json);
	    
	    var xmlDoc = $.parseXML(json.value.rspec);
	    var xml    = $(xmlDoc);
    
	    /*
	     * We now use the desciption from inside the rspec, unless there
	     * is none, in which case look to see if the we got one in the
	     * rpc reply, which we will until all profiles converted over to
	     * new format rspecs.
	     */
	    var description = null;
	    $(xml).find("rspec_tour").each(function() {
		$(this).find("description").each(function() {
		    var marked = require("marked");
		    description = marked($(this).text());
		});
	    });
	    if (!description || description == "") {
		description = "Hmm, no description for this profile";
	    }
	    continuation(json.value.rspec, description,
			 json.value.name, json.value.amdefault,
			 json.value.ispprofile);
	}
	var $xmlthing = sup.CallServerMethod(ajaxurl,
					     "instantiate", "GetProfile",
					     {"uuid" : profile});
	$xmlthing.done(callback);
    }

    /*
     * Callback from the PP configurator. Stash rspec into the form.
     */
    function ConfigureDone(newRspec, where) {
	// If not a registered user, we do not get an rspec back, since
	// the user is not allowed to change the configuration.
	if (newRspec) {
	    $('#pp_rspec_textarea').val(newRspec);
	}
	// Need to change the form before submit.
	if (where && $('#profile_where').length) {
	    // Deselect current option.
	    $('#profile_where option').prop("selected", false);
	    // Find and select new option.
	    $('#profile_where option')
		.filter('[value="'+ where + '"]')
                .prop('selected', true);		
	}
	// Enable the create and copy buttons.
	$('#instantiate_submit').attr('disabled', false);
    }

    $(document).ready(initialize);
});
