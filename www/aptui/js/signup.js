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
 	$('button#reset-form').click(function (event) {
	    event.preventDefault();
	    sup.resetForm($('#quickvm_signup_form'));
	});
	if (window.APT_OPTIONS.ShowVerifyModal)
	{
	    sup.ShowModal('#verify_modal');
	}
    }

    $(document).ready(initialize);
});
