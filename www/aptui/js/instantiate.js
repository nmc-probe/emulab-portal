window.APT_OPTIONS.config();

require(['jquery', 'js/quickvm_sup',
	 // jQuery modules
	 'bootstrap', 'formhelpers', 'filestyle'],
function ($, sup)
{
    'use strict';

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	if (window.APT_OPTIONS.isNewUser) {
	    $('#verify_modal_submit').click(function (event) {
		sup.HideModal('#verify_modal');
		sup.ShowModal("#waitwait");
		return true;
	    });
	    sup.ShowModal('#verify_modal');
	}
        $('#quickvm_topomodal').on('hidden.bs.modal', function() {
            ShowProfileList($('.current'))
        });

	$('button#reset-form').click(function (event) {
	    event.preventDefault();
	    resetForm($('#quickvm_form'));
	});
	$('button#profile').click(function (event) {
	    event.preventDefault();
	    sup.ShowModal('#quickvm_topomodal');
	});
	$('li.profile-item').click(function (event) {
	    event.preventDefault();
	    ShowProfileList(event.target);
	});
	$('button#showtopo_select').click(function (event) {
	    event.preventDefault();
	    UpdateProfileSelection($('.selected'));
	    sup.HideModal('#quickvm_topomodal');
	});
	$('#instantiate_submit').click(function (event) {
	    sup.ShowModal("#waitwait");
	    return true;
	});
        UpdateProfileSelection($('#profile_name li[value = ' +
				 window.PROFILE + ']'));
    }

    function resetForm($form) {
	$form.find('input:text, input:password, select, textarea').val('');
    }
    
    function UpdateProfileSelection(selectedElement)
    {
	var profile_name = $(selectedElement).text();
	var profile_value = $(selectedElement).attr('value');
	$('#selected_profile').attr('value', profile_value);
	$('#selected_profile_text').html("" + profile_name);

	if (!$(selectedElement).hasClass('current')) {
	    $('#profile_name li').each(function() {
		$(this).removeClass('current');
	    });
	    $(selectedElement).addClass('current');
	}
	ShowProfileList(selectedElement);
    }

    function ShowProfileList(selectedElement)
    {
	var profile = $(selectedElement).attr('value');

	if (!$(selectedElement).hasClass('selected')) {
	    $('#profile_name li').each(function() {
		$(this).removeClass('selected');
	    });
	    $(selectedElement).addClass('selected');
	}

	var callback = function(json) {
	    console.info(json.value);

	    if (json.code) {
		alert("Could not get profile: " + json.value);
		return;
	    }
	    
	    var xmlDoc = $.parseXML(json.value.rspec);
	    var xml    = $(xmlDoc);
	    var topo   = sup.ConvertManifestToJSON(profile, xml);
    
	    $('#showtopo_title').html("<h3>" + json.value.name + "</h3>");

	    /*
	     * We now use the desciption from inside the rspec, unless there
	     * is none, in which case look to see if the we got one in the
	     * rpc reply, which we will until all profiles converted over to
	     * new format rspecs.
	     */
	    var description = null;
	    $(xml).find("rspec_tour").each(function() {
		$(this).find("description").each(function() {
		    description = $(this).text();
		});
	    });
	    if (!description) {
		if (json.value.description != "") {
		    description = json.value.description;
		}
		else {
		    description = "Hmm, no description for this profile";
		}
	    }
	    $('#showtopo_description').html(description);
	    $('#selected_profile_description').html(description);

	    sup.maketopmap("#showtopo_div",
			   ($("#showtopo_div").outerWidth()),
			   300, topo, null);
	}
	var $xmlthing = sup.CallMethod("getprofile", null, 0, profile);
	$xmlthing.done(callback);
    }

    $(document).ready(initialize);
});
