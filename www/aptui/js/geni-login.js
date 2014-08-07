require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup',
	 'js/lib/text!template/geni-login.html'],
function (_, sup, loginString)
{
    'use strict';

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	genilib.trustedHost = window.HOST;
	genilib.trustedPath = window.PATH;
	$('#page-body').html(loginString);

	$('#authorize').click(function (event) {
	    event.preventDefault();
	    genilib.authorize(window.ID, window.CERT, complete);
	    return false;
	});
    }

    function complete(credential)
    {
	$('#credential').show();
	$('#credential').val(credential);
    }
    $(document).ready(initialize);
});
