require(window.APT_OPTIONS.configObject,
	['underscore', 'constraints', 'js/quickvm_sup', 'js/ppwizardstart', 'js/JacksEditor', 'js/wizard-template',
	 'js/lib/text!template/aboutapt.html',
	 'js/lib/text!template/aboutcloudlab.html',
	 'js/lib/text!template/waitwait-modal.html',
         'formhelpers', 'filestyle', 'marked', 'jacks', 'jquery-steps'],
function (_, Constraints, sup, ppstart, JacksEditor, wt, aboutaptString, aboutcloudString, waitwaitString)
{
    'use strict';

    var ajaxurl;
    var amlist        = null;
    var amdefault     = null;
    var selected_uuid = null;
    var selected_rspec = null;
    var ispprofile    = 0;
    var webonly       = 0;
    var isadmin       = 0;
    var multisite     = 0;
    var doconstraints = 0;
    var portal        = null;
    var registered    = false;
    var JACKS_NS      = "http://www.protogeni.net/resources/rspec/ext/jacks/1";
    var jacks = {
      instance: null,
      input: null,
      output: null
    };
    var editor        = null;
    var loaded_uuid	  = null;
    var ppchanged     = false;
    var monitor       = null;

    function initialize()
    {
    // Get context for constraints
	var contextUrl = 'https://www.emulab.net/protogeni/jacks-context/cloudlab-utah.json';
        $('#profile_where').prop('disabled', true);
        $('#instantiate_submit').prop('disabled', true);
        $.get(contextUrl).then(contextReady, contextFail);

	var jqxhr = $.getJSON('https://clnode049.clemson.cloudlab.us:8081/index.html?callback=?')
		.done(function(data) {
			monitor = data;
			// Check if third tab is already active.
			// If it is, the user got to the third tab before the request was finished.
			if ($('#stepsContainer-p-2').is(':visible')) {
				CreateClusterStatus();
			}
		}).error(function(a) {
			console.log(a);
		});

	window.APT_OPTIONS.initialize(sup);
	window.APT_OPTIONS.initialize(ppstart);
	registered = window.REGISTERED;
	webonly    = window.WEBONLY;
	isadmin    = window.ISADMIN;
	multisite  = window.MULTISITE;
	portal     = window.PORTAL;
	ajaxurl    = window.AJAXURL;
	doconstraints = window.DOCONSTRAINTS;

	$('#stepsContainer').steps({
		headerTag: "h3",
		bodyTag: "div",
		transitionEffect: "slideLeft",
		autoFocus: true,
		onStepChanging: function(event, currentIndex, newIndex) {
			if (currentIndex == 0 && newIndex == 1) {
			    if (ispprofile) {
				if (selected_uuid != loaded_uuid) {
				    $('#stepsContainer-p-1 > div')
					.attr('style','display:block');
				    ppstart.StartPP(
					{uuid         : selected_uuid,
					 registered   : registered,
					 isadmin      : isadmin,
					 callback     : ConfigureDone,
					 rspec        :
					   (!window.SKIPSTEPS ? null :
					    $('#pp_rspec_textarea').val()),
					});
				    loaded_uuid = selected_uuid;
				    ppchanged =
					(window.SKIPSTEPS ? false : true);
				}
			    }
			    else {
				$('#stepsContainer-p-1 > div')
				    .attr('style','display:none');
				loaded_uuid = selected_uuid;
			    }
			}
			else if (currentIndex == 1 && newIndex == 2) {
				if (ispprofile && ppchanged &&
				    !window.SKIPSTEPS) {
				    ppstart.HandleSubmit(function(success) {
					if (success) {
					    ppchanged = false;
					    $('#stepsContainer-t-1')
						.parent().removeClass('error');
					    $('#stepsContainer').steps('next');
					}
					else {
					    $('#stepsContainer-t-1')
						.parent().addClass('error');
					}
				    });
				    // We do not proceed until the form is
				    // submitted properly. This has a bad
				    // side effect; the steps code assumes
				    // this means failure and adds the error
				    // class.
				    return false;
				}
			    
				// Set up the Finalize tab
				$('#stepsContainer-p-2 #finalize_options').html('');
				// Each .experiment_option in the form is copied to the last page.
				// When the finish button is pressed, these values are copied back.
				$('#experiment_options .experiment_option').each(function() {
					if (!$(this).hasClass('hidden')) {
						var fieldId = $(this).attr('id');
						var fieldHTML = $(this).html();

						$('#stepsContainer-p-2 #finalize_options').append(''
							+'<div class="'+fieldId+'">'
							+'<div class="form-horizontal">'
							+fieldHTML
							+'</div></div>');
					}
				});
				// Build the picker that uses the monitoring stats.
				// Currently does not support multisite, so don't call if it is multisite.
				if ($('#aggregate_selector #site_selector').hasClass('hidden')) {
					CreateClusterStatus();
				}
			    if (!$('#cluster_status_link').length) {
				$('#stepsContainer-p-2 #finalize_options').parent().append(''
					+'<div id="cluster_status_link"><center>'
						+'<a target="_blank" href="cluster-graphs.php">Check Cluster Status</a>'
					+'</center></div>');
			    }
			}

			if (currentIndex == 2) {
				SwitchJacks('small');
			}

			if (currentIndex == 0 && selected_uuid == null) {
				return false;
			}
			return true;
		},
		onStepChanged: function(event, currentIndex, priorIndex) {
			var cIndex = currentIndex;
			if (currentIndex == 1) {
				// If the profile isn't parameterized, skip the second step
				if (!ispprofile) {
					if (priorIndex < currentIndex) {
						// Generate the profile on the third tab
						ShowProfileSelectionInline($('#profile_name .current'), $('#stepsContainer-p-2 #inline_jacks'), true);

						$(this).steps('next');
						$('#stepsContainer-t-1').parent().removeClass('done').addClass('disabled');
					}
					if (priorIndex > currentIndex) {
						$(this).steps('previous');
						cIndex--;
					}
				}
				$('#pp_form input').change(function() {
					ppchanged = true;
				});
				$('#pp_form select').change(function() {
					ppchanged = true;
				});
			}
			else if (currentIndex == 2 && priorIndex == 1) {
				// Keep the two panes the same height
				$('#inline_container').css('height', $('#finalize_container').outerHeight());
			}

			if (currentIndex < priorIndex) {
				// Disable going forward by clicking on the labels
				for (var i = cIndex+1; i < $('.steps > ul > li').length; i++) {
					$('#stepsContainer-t-'+i).parent().removeClass('done').addClass('disabled');
				}
			}
		}
	});

	// Set up wizard final page formatting
	$('#stepsContainer .steps').addClass('col-lg-8 col-lg-offset-2 col-md-8 col-md-offset-2 col-sm-10 col-sm-offset-1 col-xs-12 col-xs-offset-0');
	$('#stepsContainer .actions').addClass('col-lg-8 col-lg-offset-2 col-md-8 col-md-offset-2 col-sm-10 col-sm-offset-1 col-xs-12 col-xs-offset-0');

	// Set up jacks swap
	$('#stepsContainer #inline_overlay').click(function() {
		SwitchJacks('large');
	});

	// Set up the Finish button to submit the form
	$('#stepsContainer .actions a[href="#finish"]').click(function() {
		$('#stepsContainer-p-2 #finalize_options > div').each(function() {
			var fieldId = $(this).attr('class');
			$('#'+fieldId+' .form-control').val($('.'+fieldId+' .form-control').val());
		});
		if (!ispprofile) {
			$('#instantiate_submit').click();
		}
	});

	if ($('#amlist-json').length) {
	    amlist  = JSON.parse(_.unescape($('#amlist-json')[0].textContent));
	  _.each(_.keys(amlist), function (key) {
	    amValueToKey[amlist[key]] = key;
	  });
	}

	$('#waitwait_div').html(waitwaitString);
	// The about panel.
	if (window.SHOWABOUT) {
	    $('#about_div').html(window.ISCLOUD ?
				 aboutcloudString : aboutaptString);
	}
	// This activates the popover subsystem.
	$('[data-toggle="popover"]').popover({
	    trigger: 'hover',
	    placement: 'auto',
	    container: 'body',
	});

	if (window.APT_OPTIONS.isNewUser) {
	    $('#verify_modal_submit').click(function (event) {
		$('#verify_modal').modal('hide');
		$("#waitwait-modal").modal('show');
		return true;
	    });
	    $('#verify_modal').modal('show');
	}
        $('#quickvm_topomodal').on('shown.bs.modal', function() {
            ShowProfileSelection($('#profile_name .current'))
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
	    ChangeProfileSelection($('#quickvm_topomodal .selected'));
	    selected_uuid = $('#quickvm_topomodal .selected').attr('value');
	    console.log(selected_uuid);
	    $('#quickvm_topomodal').modal('hide');
	    $('.steps .error').removeClass('error');
	});
	$('#instantiate_submit').click(function (event) {
	    if (webonly != 0) {
		event.preventDefault();
		sup.SpitOops("oops",
		     "You do not belong to any projects at your Portal, " +
		     "so you have have very limited capabilities. Please " +
		     "join or create a project at your " +
		     (portal && portal != "" ?
		      "<a href='" + portal + "'>Portal</a>" : "Portal") +
		     " to enable more capabilities. Thanks!")
		return false;
	    }
	    // Prevent double click.
	    if ($(this).data('submitted') === true) {
		// Previously submitted - don't submit again
		console.info("Ignoring double submit");
		event.preventDefault();
		return false;
	    }
	    else {
		// See if all cluster selections have been made. Seems
		// to be a common problem.
		if (!AllClustersSelected()) {
		    alert("Please make all your cluster selections!");
		    event.preventDefault();
		    return false;
		}
		// Mark it so that the next submit can be ignored
		$(this).data('submitted', true);
	    }
	    $("#waitwait-modal").modal('show');
	    return true;
	});
	/*
	 * Need to update image constraints when the project selector
	 * is changed.
	 */
	$('#profile_pid').change(function (event) {
	  console.log('profile-pid change');
	    UpdateImageConstraints();
	    return true;
	});
	$('#profile_copy_button').click(function (event) {
	    event.preventDefault();
	    if (!registered) {
		sup.SpitOops("oops", "You must be a registered user to copy " +
			     "a profile.");
		return;
	    }
	    var url = "manage_profile.php?action=copy&uuid=" + selected_uuid;
	    window.location.replace(url);
	    return false;
	});

	$('#profile_show_button').click(function (event) {
	    event.preventDefault();
	    if (!registered) {
		sup.SpitOops("oops", "You must be a registered user to view " +
			     "profile details.");
		return;
	    }
	    var url = "show-profile.php?uuid=" + selected_uuid;
	    window.location.replace(url);
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

    function CreateClusterStatus() {
    	if (monitor == null || $.isEmptyObject(monitor)) {
    		return;
    	}
    	var html = '<div id="cluster_picker_status" class="btn-group">'
					    +'<button type="button" class="form-control btn btn-default dropdown-toggle" data-toggle="dropdown">'
					    	+'<span class="value"></span>'
							+'<span class="caret"></span>'
					    +'</button>'
					    +'<ul class="dropdown-menu" role="menu">'
					    	+'<li role="separator" class="divider"></li>'
					    +'</ul>'
					+'</div>';
		var which = 'nosite_selector';

		// Need to add support for multisite
		/*if (!$('#aggregate_selector #site_selector').hasClass('hidden')) {
			which = 'site_selector';
		}*/

		$('.'+which+' #profile_where').after(html);
		$('.'+which+' #profile_where').addClass('hidden');

		var dropdown = $('#cluster_picker_status .dropdown-menu .divider');
		$('#'+which+' #profile_where option').each(function() {
			if ($(this).prop('disabled')) {
				dropdown.after('<li class="disabled"><a data-toggle="tooltip" data-placement="right" data-html="true" title="<div>This testbed is incompatible with the selected profile</div>" href="#" value="'+$(this).attr('value')+'">'+$(this).attr('value')+'</a></li>')
			}
			else {
				dropdown.before('<li class="enabled"><a href="#" value="'+$(this).attr('value')+'">'+$(this).attr('value')+'</a></li>');
			}
		});

		$('#cluster_picker_status .dropdown-menu a').on('click', function(){    
		    $('#cluster_picker_status .dropdown-toggle .value').html($(this).attr('value'));   
		    $('.'+which+' #profile_where').val($('#cluster_picker_status .value').html()); 
		    
		    if ($(this).children('.picker_stats').length) {
		    	if (!$('#cluster_picker_status .dropdown-toggle > .picker_stats').length) {
		    		$('#cluster_picker_status .dropdown-toggle').append('<div class="picker_stats"></div>');
		    	}
		    	else {
		    		$('#cluster_picker_status .dropdown-toggle > .picker_stats').html('');
		    	}

		    	$('#cluster_picker_status .dropdown-toggle > .picker_stats').append($(this).children('.picker_stats').html());
		    }

		    $('#cluster_picker_status .selected').removeClass('selected');
		    $(this).parent().addClass('selected');
		});


		// HARDCODED, from mockup state! //
		$('#cluster_picker_status .dropdown-menu li a:contains("APT Utah")').parent().attr('data-testbed','utahApt');
		$('#cluster_picker_status .dropdown-menu li a:contains("IG UtahDDC")').parent().attr('data-testbed','utahddc-ig');
		$('#cluster_picker_status .dropdown-menu li a:contains("Utah PG")').parent().attr('data-testbed','utah-pg');
		$('#cluster_picker_status .dropdown-menu li a:contains("Cloudlab Clemson")').parent().attr('data-testbed','cloudlabClemson');
		$('#cluster_picker_status .dropdown-menu li a:contains("Cloudlab Wisconsin")').parent().attr('data-testbed','cloudlabWisconsin');
		$('#cluster_picker_status .dropdown-menu li a:contains("Cloudlab Utah")').parent().attr('data-testbed','cloudlabUtah');
		// END HARDCODED //

		// Set up statistics
		$('#cluster_picker_status .dropdown-menu .enabled a').each(function() {
			var data = monitor[$(this).parent().attr('data-testbed')];
			if (data && !$.isEmptyObject(data)) {
				// Calculate testbed rating and set up tooltips.
				var rating = wt.CalculateRating(data);

				$(this).parent().attr('data-rating', rating[0]);

				var stats = wt.StatsLineHTML(wt.AssignGlyph(rating[0]), rating[1]);
				$(this).append(stats);
			}
		});

		$('#cluster_picker_status .dropdown-menu').find('.enabled').sort(function (a, b) {
			return +b.dataset.rating - +a.dataset.rating;
		}).prependTo($('#cluster_picker_status .dropdown-menu'));

		$('[data-toggle="tooltip"]').tooltip();

		$('#cluster_picker_status .dropdown-menu .enabled a')[0].click();
    }

    function SwitchJacks(which) {
    	if (which == 'small' && $('#stepsContainer-p-2 #inline_jacks').html() == '') {
			$('#stepsContainer #finalize_container').removeClass('col-lg-12 col-md-12 col-sm-12');
    		$('#stepsContainer #finalize_container').addClass('col-lg-8 col-md-8 col-sm-8');
			$('#stepsContainer #inline_large_jacks').html('');
			$('#inline_large_container').addClass('hidden');
			if (ispprofile) {
				ppstart.ChangeJacksRoot($('#stepsContainer-p-2 #inline_jacks'), true);
			}
			else {
				ShowProfileSelectionInline($('#profile_name .current'), $('#stepsContainer-p-2 #inline_jacks'), true);
			}
			$('#stepsContainer-p-2 #inline_container').removeClass('hidden');
    	}
    	else if (which == 'large') {
    		// Sometimes the steps library will clean up the added elements
    		if ($('#inline_large_container').length === 0) {	
	    		$('<div id="inline_large_container" class="hidden"></div>').insertAfter('#stepsContainer .content');
				$('#inline_large_container').html(''
					+'<button id="closeLargeInline" type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>'
					+'<div id="inline_large_jacks"></div>');
				$('#stepsContainer #inline_large_container').addClass('col-lg-8 col-lg-offset-2 col-md-8 col-md-offset-2 col-sm-10 col-sm-offset-1 col-xs-12 col-xs-offset-0');
    		
				$('#closeLargeInline').click(function() {
					SwitchJacks('small');
				});
    		}

    		$('#stepsContainer #finalize_container').removeClass('col-lg-8 col-md-8 col-sm-8');
			$('#stepsContainer #finalize_container').addClass('col-lg-12 col-md-12 col-sm-12');
			$('#stepsContainer-p-2 #inline_jacks').html('');
			$('#stepsContainer-p-2 #inline_container').addClass('hidden');
			if (ispprofile) {
				ppstart.ChangeJacksRoot($('#stepsContainer #inline_large_jacks'), false);
			}
			else {
				ShowProfileSelectionInline($('#profile_name .current'), $('#stepsContainer #inline_large_jacks'), false);
			}
			$('#inline_large_container').removeClass('hidden');
    	}
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
	    sup.maketopmap('#showtopo_div', rspec, false, !multisite);
	};
	GetProfile($(selectedElement).attr('value'), continuation);
    }

    // Used to generate the topology on Tab 3 of the wizard for non-pp profiles
    function ShowProfileSelectionInline(selectedElement, root, selectionPane) {
	editor = new JacksEditor(root, true, true,
				 selectionPane, true, !multisite);
	var continuation = function(rspec, description, name, amdefault, ispp) {
	  if (rspec)
	  {
	    editor.show(rspec);
	  }
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
	    selected_rspec = rspec;
	    amdefault     = amdef;

	    // Show the configuration button, disable the create button.
	    if (ispprofile) {
		$('#instantiate_submit').attr('disabled', true);
	    }
	    else {
		$('#instantiate_submit').attr('disabled', false);
	    }

	    CreateAggregateSelectors(rspec);

	    // Hide the aggregate picker for a parameterized profile.
	    // Shown later.
	    if (ispprofile) {
		$("#aggregate_selector").addClass("hidden");
	    }
	    else {
		$("#aggregate_selector").removeClass("hidden");
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
	    if (window.SKIPSTEPS) {
	    	if (!$('#stepsContainer-p-0 fieldset > .has-error').length) {
				$('#stepsContainer').steps("next");
				if (ispprofile) {
				    $('#stepsContainer').steps("next");
				}
	    	}
		window.SKIPSTEPS = 0;
	    }
	    updateWhere();
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
    function ConfigureDone(newRspec) {
	// If not a registered user, we do not get an rspec back, since
	// the user is not allowed to change the configuration.
	if (newRspec) {
	    $('#pp_rspec_textarea').val(newRspec);
	    CreateAggregateSelectors(newRspec);
	}
	// Enable the create button.
	$('#instantiate_submit').attr('disabled', false);
	if (window.NOPPRSPEC) {
	    alert("Guest users may configure parameterized profiles " +
		  "for demonstration purposes only. The parameterized " +
		  "configuration will not be used if you Create this " +
		  "experiment.");
	}
    }

    var sites  = {};
    var siteIdToSiteNum = {};
    /*
     * Build up a list of Aggregate selectors. Normally just one, but for
     * a multisite aggregate, need more then one.
     */
    function CreateAggregateSelectors(rspec)
    {
	var xmlDoc = $.parseXML(rspec);
	var xml    = $(xmlDoc);
	var html   = "";
	var bound  = 0;
	var count  = 0;
        sites = {};

	/*
	 * Find the sites. Might not be any if not a multisite topology
	 */
	$(xml).find("node").each(function() {
	    var node_id = $(this).attr("client_id");
	    var site    = this.getElementsByTagNameNS(JACKS_NS, 'site');
	    var manager = $(this).attr("component_manager_id");

	    // Keep track of how many bound nodes, of the total.
	    count++;

	    if (manager && manager.length) {
		var parser = /^urn:publicid:idn\+([\w#!:.]*)\+/i;
		var matches = parser.exec(manager);
		if (! matches) {
		    console.error("Could not parse urn: " + manager);
		    return;
		}
		// Bound node, no dropdown will be provided for these
		// nodes, and if all nodes are bound, no dropdown at all.
		bound++;
	    }
	    else if (site.length) {
		var siteid = $(site).attr("id");
		if (siteid === undefined) {
		    console.error("No site ID in " + site);
		    return;
		}
		sites[siteid] = siteid;
	    }
	});

	// All nodes bound, no dropdown.
	if (count == bound) {
	    $("#site_selector").addClass("hidden");
	    $("#nosite_selector").addClass("hidden");
	    // Clear the form data.
	    $("#site_selector").html("");
	    $("#nosite_selector").html("");
	    return;
	}

	// If multisite is disabled for the user, or no sites or 1 site.
	if (!multisite || Object.keys(sites).length <= 1) {
	    $("#site_selector").addClass("hidden");
	    $("#nosite_selector").removeClass("hidden");
	    // Clear the form data.
	    $("#site_selector").html("");
	    return;
	}

	var sitenum = 0;

	// Create the dropdown selection lists.
	_.each(sites, function(siteid) {
	    siteIdToSiteNum[siteid] = sitenum;
	    var options = "";
	    _.each(amlist, function(name, key) {
		options = options +
		    "<option value='" + name + "'>" + name + "</option>";
	    });

	    html = html +
		"<div id='site"+sitenum+"cluster' " +
		"     class='form-horizontal experiment_option'>" +
		"  <div class='form-group'>" +
		"    <label class='col-sm-4 control-label' " +
		"           style='text-align: right;'>"+
		"          Site " + siteid  + " Cluster:</a>" +
		"    </label> " +
		"    <div class='col-sm-6'>" +
		"      <select name=\"formfields[sites][" + siteid + "]\"" +
		"              class='form-control'>" +
		"        <option value=''>Please Select</option>" + options +
		"      </select>" +
		"</div>" +
	        "<div class='col-sm-4'></div>" +
		"<div class='col-sm-6 alert alert-warning' id='where-warning' style='display: none; margin-top: 5px; margin-bottom: 5px'>This site only works on some clusters. Incompatible clusters are unselectable.</div>" +
	        "<div class='col-sm-6 alert alert-danger' id='where-nowhere' style='display: none; margin-top: 5px; margin-bottom: 5px'>This site <b>will not work on any clusters</b>. All clusters are unselectable.</div>" +
	        "</div></div>";
	    sitenum++;
	});
	//console.info(html);
	$("#nosite_selector").addClass("hidden");
	$("#site_selector").removeClass("hidden");
	$("#site_selector").html(html);
	updateWhere();
    }

    /*
     * Make sure all clusters selected before submit.
     */
    function AllClustersSelected() 
    {
	if (!multisite || Object.keys(sites).length <= 1) {
	    return $('#nosite_selector').find('select').val() != "";
	}
	else {
	    var allgood = 1;
	    _.each(_.keys(sites), function (siteId) {
		$('#site_selector #site' +
		  siteIdToSiteNum[siteId] + 'cluster')
		    .find('select').each(function () {
			if ($(this).val() == "") {
			    allgood = 0;
			    return;
			}
		    });
	    });
	    return allgood;
	}
    }

    var constraints;
    var context;

    function contextReady(data)
    {
      context = data;
      if (typeof(context) === 'string')
      {
	context = JSON.parse(context);
      }
      if (context.canvasOptions.defaults.length === 0)
      {
	delete context.canvasOptions.defaults;
      }
      constraints = new Constraints(context);
      jacks.instance = new window.Jacks({
	mode: 'viewer',
	source: 'rspec',
	root: '#jacks-dummy',
	nodeSelect: true,
	readyCallback: function (input, output) {
	  jacks.input = input;
	  jacks.output = output;
	  jacks.output.on('found-images', onFoundImages);
          $('#profile_where').prop('disabled', false);
          $('#instantiate_submit').prop('disabled', false);
	  updateWhere();
	},
	canvasOptions: context.canvasOptions,
	constraints: context.constraints
      });
    }

    var foundImages = [];

    function onFoundImages(images)
    {
	if (! doconstraints) {
	    return true;
	}
	if (! _.isEqual(foundImages, images)) {
	    foundImages = images;

	    UpdateImageConstraints();
	}
	return true;
    }

    /*
     * Update the image constraints if anything changes.
     */
    function UpdateImageConstraints() {
	if (!foundImages.length || !doconstraints) {
	    return;
	}
      
      $('#stepsContainer .actions a[href="#finish"]').attr('disabled', true);
	var callback = function(json) {
	    if (json.code) {
		alert("Could not get image info: " + json.value);
		return;
	    }
	    // This gets munged someplace, and so the printed value
	    // is not what actually comes back. Copy before print.
	    var mycopy = $.extend(true, {}, json.value);
	    console.log('json', mycopy);
	    if (1) {
	      constraints = new Constraints(context);
	      constraints.addPossibles({ images: foundImages });
	      allowWithSites(json.value[0].images, json.value[0].constraints);
	      updateWhere();
              $('#stepsContainer .actions a[href="#finish"]')
		    .removeAttr('disabled');
	    }
	};
	/*
	 * Must pass the selected project along for constraint checking.
	 * But we have this problem of the actual project selection being a
	 * copy cause of the steps containerizaton. There is a handler on
	 * that copy, to write the new selection back to the original, which
	 * is what we reference below. 
	 */
	var $xmlthing =
	    sup.CallServerMethod(ajaxurl,
				 "instantiate", "GetImageInfo",
				 {"images"  : foundImages,
				  "project" : $('#project_selector #profile_pid')
				                  .val()});
	$xmlthing.done(callback);
	return true;
    }

  function allowWithSites(newImages, newConstraints)
  {
    console.log('newImages', newImages);
    console.log('newConstraints', newConstraints);
    var sites = context.canvasOptions.site_info;
    var finalItems = [];
    _.each(newConstraints, function (item) {
      console.log('item:', item);
      var valid = [];
      _.each(_.keys(sites), function (key) {
	// Items from server might just be comma-separated lists in
	// strings instead of split out properly. Let's split them out
	// here.
	item.node.hardware = splitItems(item.node.hardware);
	item.node.types = splitItems(item.node.types);

	// The image list returned are the only valid images
	if (_.findWhere(newImages, { id: item.node.images[0] }))
	{
	  _.each(item.node.hardware, function (hardware) {
	    if (_.contains(sites[key].hardware, hardware))
	    {
	      finalItems.push({
		node: {
		  hardware: [hardware],
		  images: item.node.images,
		  aggregates: [key]
		}
	      });
	    }
	  });
	  _.each(item.node.types, function (type) {
	    if (_.contains(sites[key].types, type))
	    {
	      finalItems.push({
		node: {
		  types: [type],
		  images: item.node.images,
		  aggregates: [key]
		}
	      });
	    }
	  });
	}
      });
    });
    console.log(finalItems);
    constraints.allowAllSets(finalItems);
    constraints.allowAllSets([
      {
	node: {
	  aggregates: ['!'],
	  images: ['!'],
	  hardware: ['!']
	}
      },
      {
	node: {
	  aggregates: ['!'],
	  images: ['!'],
	  types: ['!']
	}
      },
    ]);
  }

  function splitItems(list) {
    var result = [];
    _.each(list, function (item) {
      result = result.concat(item.split(','));
    });
    return result;
  }

    function contextFail(fail1, fail2)
    {
        console.log('Failed to fetch context', fail1, fail2);
        alert('Failed to fetch context from ' + contextUrl + '\n\n' + 'Check your network connection and try again or contact testbed support with this message and the URL of this webpage.');
    }

    function updateWhere()
    {
	if (jacks.input && constraints && selected_rspec)
	{
	  jacks.input.trigger('change-topology',
			      [{ rspec: selected_rspec }],
			      { constrainedFields: finishUpdateWhere });
	}
    }

    var amValueToKey = {};
    
    function finishUpdateWhere(allNodes, nodesBySite)
    {
      console.log('finishUpdateWhere');
      if (!multisite || Object.keys(sites).length <= 1) {
	updateSiteConstraints(allNodes, $('#nosite_selector'));
      } else {
	_.each(_.keys(sites), function (siteId) {
	  var nodes = nodesBySite[siteId];
	  if (nodes)
	  {
	    updateSiteConstraints(nodes, $('#site_selector #site' + siteIdToSiteNum[siteId] + 'cluster'));
	  }
	  else
	  {
	    console.log('Could not find siteId', siteId, nodesBySite);
	  }
	})
      }
    }

    function updateSiteConstraints(nodes, domNode)
    {
      var allowed = [];
      var rejected = [];
      var bound = nodes;
      var subclause = 'node';
      var clause = 'aggregates';
      allowed = constraints.getValidList(bound, subclause,
					 clause, rejected);
      if (allowed.length == 0)
      {
	domNode.find('#where-warning').hide();
	domNode.find('#where-nowhere').show();
      }
      else if (rejected.length > 0)
      {
	domNode.find('#where-warning').show();
	domNode.find('#where-nowhere').hide();
      }
      else
      {
	domNode.find('#where-warning').hide();
	domNode.find('#where-nowhere').hide();
      }
      domNode.find('select').children().each(function () {
	var value = $(this).attr('value');
	// Skip the Please Select option
	if (value == "") {
	    return;
	}
	var key = amValueToKey[value];
	var i = 0;
	var found = false;
	for (; i < allowed.length; i += 1)
	{
	  if (allowed[i] === key)
	  {
	    found = true;
	    break;
	  }
	}
	if (found)
	{
	  $(this).prop('disabled', false);
	  if (allowed.length == 1) {
	      $(this).attr('selected', "selected");
	      // This does not appear to do anything, at least in Chrome
	      $(this).prop('selected', true);
	  }
	}
	else
	{
	  $(this).prop('disabled', true);
	  $(this).removeAttr('selected');
	  // See above comment.
	  $(this).prop('selected', false);
	}
      });
    }

    $(document).ready(initialize);
});
