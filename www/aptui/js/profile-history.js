require(window.APT_OPTIONS.configObject,
	['js/quickvm_sup'],
function (sup)
{
    'use strict';
    var ajaxurl = null;

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	ajaxurl  = window.AJAXURL;

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
	    if (json.code) {
		alert("Failed to get rspec for topology viewer: " + json.value);
		return;
	    }
	    sup.ShowModal("#quickvm_topomodal");
	    $("#quickvm_topomodal").one("shown.bs.modal", function () {
		sup.maketopmap('#showtopo_nopicker', json.value.rspec, null);
	    });
	};
	var $xmlthing = sup.CallServerMethod(ajaxurl,
					     "myprofiles",
					     "GetProfile",
				     	     {"uuid" : profile});
	$xmlthing.done(callback);
    }

    $(document).ready(initialize);
});
