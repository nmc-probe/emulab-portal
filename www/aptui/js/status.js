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
	sup.InitQuickVM(window.APT_OPTIONS.uuid,
			window.APT_OPTIONS.sliceExpires);
	$('button#register-account').click(function (event) {
	    event.preventDefault();
	    sup.RegisterAccount(window.APT_OPTIONS.creatorUid,
				window.APT_OPTIONS.creatorEmail);
	});
	$('button#request-extension').click(function (event) {
	    event.preventDefault();
	    sup.RequestExtension(window.APT_OPTIONS.uuid);
	});
	$('button#extend').click(function (event) {
	    event.preventDefault();
	    sup.Extend(window.APT_OPTIONS.uuid);
	});
	$('button#terminate').click(function (event) {
	    event.preventDefault();
	    sup.Terminate(window.APT_OPTIONS.uuid, 'instantiate.php');
	});
    }

    $(document).ready(initialize);
});
