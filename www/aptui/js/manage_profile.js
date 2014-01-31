window.APT_OPTIONS.config();

require(['jquery', 'js/quickvm_sup',
	 // jQuery modules
	 'bootstrap', 'formhelpers'],
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

		    sup.ShowUploadedRspec(content);
		};
		reader.readAsText(this.files[0]);
	    });
	}
	catch (e) {
	    alert(e);
	}
    }

    $(document).ready(initialize);
});
