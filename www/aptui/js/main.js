require.config({
    baseUrl: '.',
    paths: {
	'jquery': 'js/lib/jquery-2.0.3.min',
	'bootstrap': 'bootstrap/js/bootstrap'
    },
    shim: {
	'bootstrap': { deps: ['jquery'] }
    },
});

require(['jquery',
	 // jQuery modules
	 'bootstrap'],
function ($)
{
    'use strict';

    function initialize()
    {
        UpdateProfileSelection($('#profile_name li:eq(0)'));
        $('#quickvm_topomodal').on('hidden.bs.modal', function() {
            ShowProfileList($('.current'))
        });
	InitProfileSelector();

	console.log('APT_OPTIONS: ' + JSON.stringify(window.APT_OPTIONS));
	if (window.APT_OPTIONS.isNewUser)
	{
	    ShowModal('#working');
	}

	initButtons();

	$('body').show();
    }

    function initButtons()
    {
	$('button#reset-form').click(function (event) {
	    event.preventDefault();
	    resetForm($('#quickvm_form'));
	});
	$('button#profile').click(function (event) {
	    event.preventDefault();
	    ShowModal('#quickvm_topomodal');
	});
	$('li.profile-item').click(function (event) {
	    event.preventDefault();
	    ShowProfileList(event.target);
	});
	$('button#showtopo_select').click(function (event) {
	    UpdateProfileSelection($('.selected'));
	});
    }

    $(document).ready(initialize);
});
