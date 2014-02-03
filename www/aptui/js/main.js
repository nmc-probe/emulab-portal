window.APT_OPTIONS.config();

require(['jquery', 'js/quickvm_sup',
	 // jQuery modules
	 'bootstrap'],
function ($, sup)
{
    'use strict';

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	// This activates the popover subsystem.
	$('[data-toggle="popover"]').popover({
	    trigger: 'hover',
	});
	$('body').show();
    }

    $(document).ready(initialize);
});
