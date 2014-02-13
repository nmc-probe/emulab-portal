window.APT_OPTIONS.config();

require(['jquery', 'js/quickvm_sup', 
	 // jQuery modules
	 'bootstrap','filestyle'],
function ($, sup)
{
    'use strict';

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	try {
	    $('#rspecfile').change(function() {
		var reader = new FileReader();
		reader.onload = function(event) {
		    var content = event.target.result;

		    ShowRspecContent(content);
		};
		reader.readAsText(this.files[0]);
	    });
	}
	catch (e) {
	    alert(e);
	}

	$.fn.animateBackgroundHighlight = function(highlightColor, duration) {
	    var highlightBg = highlightColor || "#FFFF9C";
	    var animateMs = duration || 1500;
	    var originalBg = this.css("backgroundColor");
	    console.log(originalBg);
	};

	$('#showtopo_modal_button').click(function (event) {
	    event.preventDefault();
	    // The rspec is taken from the text area.
	    ShowRspecContent($('#profile_rspec_textarea').val());
	});
	$('#expand_rspec_modal_button').click(function (event) {
	    $('#modal_profile_rspec_textarea').val(
		$('#profile_rspec_textarea').val());
	    $('#rspec_modal').modal({'backdrop':'static','keyboard':false});
	    $('#rspec_modal').modal('show');
	});
	$('#collapse_rspec_modal_button').click(function (event) {
	    // Copy back to the plain textarea and kill the modal contents.
	    // The topo is drawn from the plain textarea. 
	    $('#profile_rspec_textarea').val(
		$('#modal_profile_rspec_textarea').val());
	    $('#rspec_modal').modal('hide');
	    $('#modal_profile_rspec_textarea').val("");	    
	    $('#profile_rspec_textarea').css({"opacity":"0.2"});
	    $('#profile_rspec_textarea').animate({"opacity":"1.0"}, 1500);
	});
	// Enable the Modify button if the form changes.
        $('#quickvm_create_profile_form :input').each(function() {
	    // Need to use keyup since an input does not "change"
	    // until focus is lost.
	    $(this).keyup(function() {
		$('#profile_submit_button').prop('disabled', false);
	    });
	});
	// This one for the checkboxes.
        $('#quickvm_create_profile_form').change(function() {
	    $('#profile_submit_button').prop('disabled', false);
	});
    }

    //
    // Show the rspec text in the modal.
    //
    function ShowRspecContent(content)
    {
	var xmlDoc = $.parseXML(content);
	var xml    = $(xmlDoc);
	var topo   = sup.ConvertManifestToJSON(null, xml);
	console.info(topo);

	sup.ShowModal("#quickvm_topomodal");

	// Subtract -2 cause of the border. 
	sup.maketopmap("#showtopo_nopicker",
 		   ($("#showtopo_nopicker").outerWidth() - 2),
		   300, topo);
    }

    $(document).ready(initialize);
});
