window.APT_OPTIONS.configNoQuery();

require([// jQuery modules
        'formhelpers', 'filestyle', 'marked', 'jacks'],
function ()
{
    'use strict';

    var jacksInstance;
    var jacksUpdate;

    function initialize()
    {
	window.APT_OPTIONS.initialize();

	if (window.APT_OPTIONS.isNewUser) {
	    $('#verify_modal_submit').click(function (event) {
		$('#verify_modal').modal('hide');
		$("#waitwait").modal('show');
		return true;
	    });
	    $('#verify_modal').modal('show');
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
	    $('#quickvm_topomodal').modal('show');
	});
	$('li.profile-item').click(function (event) {
	    event.preventDefault();
	    ShowProfileList(event.target);
	});
	$('button#showtopo_select').click(function (event) {
	    event.preventDefault();
	    UpdateProfileSelection($('.selected'));
	    $('#quickvm_topomodal').modal('hide');
	});
	$('#instantiate_submit').click(function (event) {
	    $("#waitwait").modal('show');
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
		    var marked = require("marked");
		    description = marked($(this).text());
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

	    if (! jacksInstance)
	    {
		jacksInstance = new window.Jacks({
		    mode: 'viewer',
		    source: 'rspec',
		    root: '#showtopo_div',
		    size: { x: 643, y: 300 },
		    nodeSelect: false,
		    readyCallback: function (input, output) {
			jacksUpdate = input;
			jacksUpdate.trigger('change-topology',
					    [{ rspec: json.value.rspec }]);
		    }
		});
	    }
	    else if (jacksUpdate)
	    {
		jacksUpdate.trigger('change-topology',
				    [{ rspec: json.value.rspec }]);
	    }
	}
	var $xmlthing = CallMethod("getprofile", null, 0, profile);
	$xmlthing.done(callback);
    }

    function CallMethod(method, callback, uuid, arg)
    {
	return $.ajax({
	    // the URL for the request
	    url: window.location.href,
 
	    // the data to send (will be converted to a query string)
	    data: {
		uuid: uuid,
		ajax_request: 1,
		ajax_method: method,
		ajax_argument: arg,
	    },
 
	    // whether this is a POST or GET request
	    type: (arg ? "GET" : "GET"),
 
	    // the type of data we expect back
	    dataType : "json",
	});
    }

    $(document).ready(initialize);
});
