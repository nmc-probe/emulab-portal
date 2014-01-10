require.config({
    baseUrl: '.',
    paths: {
	'jquery': 'js/lib/jquery-2.0.3.min',
	'bootstrap': 'bootstrap/js/bootstrap',
	'dateformat': 'js/lib/date.format',
	'd3': 'js/lib/d3.v3'
    },
    shim: {
	'bootstrap': { deps: ['jquery'] },
	'dateformat': { exports: 'dateFormat' },
	'd3': { exports: 'd3' }
    },
});

require(['jquery', 'js/quickvm_sup',
	 // jQuery modules
	 'bootstrap'],
function ($, sup)
{
    'use strict';

    function initialize()
    {
        sup.UpdateProfileSelection($('#profile_name li:eq(0)'));
        $('#quickvm_topomodal').on('hidden.bs.modal', function() {
            sup.ShowProfileList($('.current'))
        });
	sup.InitProfileSelector();

	if (window.APT_OPTIONS)
	{
	    console.log('APT_OPTIONS: ' + JSON.stringify(window.APT_OPTIONS));
	    if (window.APT_OPTIONS.isNewUser)
	    {
		sup.ShowModal('#working');
	    }
	}
	else
	{
	    console.log('APT_OPTIONS is undefined');
	}

	initButtons();

	$('body').show();
    }

    function initButtons()
    {
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
	    sup.UpdateProfileSelection($('.selected'));
	});
    }

    $(document).ready(initialize);
});
