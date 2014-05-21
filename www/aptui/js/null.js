window.APT_OPTIONS.config();

require(['js/quickvm_sup'],
function (sup)
{
    'use strict';

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
    }

    $(document).ready(initialize);
});
