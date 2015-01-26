require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup',
	 'js/lib/text!template/geni-login.html',
	 'js/lib/text!template/waitwait-modal.html'],
function (_, sup, loginString, waitwaitString)
{
    'use strict';
    var embedded = 0;
    
    function initialize()
    {
	embedded = window.EMBEDDED;
	
	$('#page-body').html(loginString);
	$('#waitwait_div').html(waitwaitString);
	// We share code with the modal version of login, and the
	// handler for the button is installed in initialize().
	// See comment there.
	sup.InitGeniLogin(embedded);
	$('#authorize').click(function (event) {
	    event.preventDefault();
	    sup.StartGeniLogin();
	    return false;
	});
	window.APT_OPTIONS.initialize(sup);
    }
    $(document).ready(initialize);
});
