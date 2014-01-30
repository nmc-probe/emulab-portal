require.config({
    baseUrl: '.',
    paths: {
	'jquery': 'js/lib/jquery-2.0.3.min',
	'bootstrap': 'bootstrap/js/bootstrap',
	'formhelpers': 'formhelpers/js/bootstrap-formhelpers',
	'dateformat': 'js/lib/date.format',
	'd3': 'js/lib/d3.v3',
    },
    shim: {
	'bootstrap': { deps: ['jquery'] },
	'formhelpers': { deps: ['bootstrap']},
	'dateformat': { exports: 'dateFormat' },
	'd3': { exports: 'd3' }
    },
});

require(['jquery', 'js/quickvm_sup',
	 // jQuery modules
	 'bootstrap', 'formhelpers'],
function ($, sup)
{
    'use strict';

    function initialize()
    {
	var pageType = 'donotsetthistoindex';
	if (window.APT_OPTIONS)
	{
	    console.log('APT_OPTIONS: ' + JSON.stringify(window.APT_OPTIONS));
	    if (window.APT_OPTIONS.isNewUser)
	    {
		sup.ShowModal('#verify_modal');
	    }
	    if (window.APT_OPTIONS.pageType)
	    {
		pageType = window.APT_OPTIONS.pageType;
	    }
	    initLoginButton();
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
	else if (pageType == 'signup') {
 	    $('button#reset-form').click(function (event) {
		event.preventDefault();
		sup.resetForm($('#quickvm_signup_form'));
	    });
	    if (window.APT_OPTIONS.ShowVerifyModal)
	    {
		sup.ShowModal('#verify_modal');
	    }
	}
	else if (pageType == 'manage_profile') {
	    if (1) {
		try {
		    $('#rspecfile').change(function() {
			var reader = new FileReader();
			reader.onload = function(event) {
			    var content = event.target.result;

			    sup.ShowUploadedRspec(content);
			};
			reader.readAsText(this.files[0]);
		    });
		}
		catch (e) {
		    alert(e);
		}
	    }
	}
	$('body').show();
    }

    function initIndex()
    {
        sup.UpdateProfileSelection($('#profile_name li[value = ' + window.PROFILE + ']'));
        $('#quickvm_topomodal').on('hidden.bs.modal', function() {
            sup.ShowProfileList($('.current'))
        });

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
    function initLoginButton()
    {
	$('#quickvm_login_modal_button').click(function (event) {
	    event.preventDefault();
	    sup.LoginByModal();
	});
	$('#logout_button').click(function (event) {
	    event.preventDefault();
	    sup.Logout();
	});
    }

    $(document).ready(initialize);
});
