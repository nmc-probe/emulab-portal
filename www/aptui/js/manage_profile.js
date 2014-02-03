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

	$('#showtopo_modal_button').click(function (event) {
	    event.preventDefault();
	    // The rspec is taken from the text area.
	    ShowRspecContent($('#profile_rspec').val());
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
    
	sup.maketopmap("#showtopo_div",
		   ($("#showtopo_dialog").outerWidth()) - 90,
		   300, topo);
    }

    $(document).ready(initialize);
});
