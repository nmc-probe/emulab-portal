require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup'],
function (_, sup)
{
    'use strict';
    var embedded = 0;
    
    function initialize()
    {
	embedded = window.EMBEDDED;

	// We share code with the modal version of login, and the
	// handler for the button is installed in initialize().
	// See comment there.
	if (window.ISCLOUD) {
	    sup.InitGeniLogin(embedded);
	}
	window.APT_OPTIONS.initialize(sup);
    }
    $(document).ready(initialize);
});
