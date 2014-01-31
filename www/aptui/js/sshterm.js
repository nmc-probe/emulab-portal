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
	sup.StartSSH('sshpanel', window.APT_OPTIONS.authObject);
    }

    $(document).ready(initialize);
});
