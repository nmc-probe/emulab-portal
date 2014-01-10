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
	var pageType = 'index';
	if (window.APT_OPTIONS)
	{
	    console.log('APT_OPTIONS: ' + JSON.stringify(window.APT_OPTIONS));
	    if (window.APT_OPTIONS.isNewUser)
	    {
		sup.ShowModal('#working');
	    }
	    if (window.APT_OPTIONS.pageType)
	    {
		pageType = window.APT_OPTIONS.pageType;
	    }
	}
	else
	{
	    console.log('APT_OPTIONS is undefined');
	}

	if (pageType === 'index')
	{
	    initIndex();
	}
	else if (pageType === 'sshterm')
	{
	    sup.StartSSH('sshpanel', window.APT_OPTIONS.authObject);
	}
	else if (pageType === 'status')
	{
	    sup.InitQuickVM(window.APT_OPTIONS.uuid,
			    window.APT_OPTIONS.sliceExpires);
	    initStatusButtons();
	}

	$('body').show();
    }

    function initIndex()
    {
        sup.UpdateProfileSelection($('#profile_name li:eq(0)'));
        $('#quickvm_topomodal').on('hidden.bs.modal', function() {
            sup.ShowProfileList($('.current'))
        });
	sup.InitProfileSelector();


	initIndexButtons();
    }

    function initIndexButtons()
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
	    event.preventDefault();
	    sup.UpdateProfileSelection($('.selected'));
	});
    }

    function initStatusButtons()
    {
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
	    sup.Terminate(window.APT_OPTIONS.uuid, 'quickvm.php');
	});
    }

    $(document).ready(initialize);
});
