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
        sup.UpdateProfileSelection($('#profile_name li[value = ' + window.PROFILE + ']'));
        $('#quickvm_topomodal').on('hidden.bs.modal', function() {
            sup.ShowProfileList($('.current'))
        });

	$('button#reset-form').click(function (event) {
	    event.preventDefault();
	    sup.resetForm($('#quickvm_form'));
	});
	$('button#profile').click(function (event) {
	    event.preventDefault();
	    sup.ShowModal('#quickvm_topomodal');
	});
	$('li.profile-item').click(function (event) {
	    event.preventDefault();
	    sup.ShowProfileList(event.target);
	});
	$('button#showtopo_select').click(function (event) {
	    event.preventDefault();
	    sup.UpdateProfileSelection($('.selected'));
	});
    }

    $(document).ready(initialize);
});
