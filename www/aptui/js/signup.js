require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup',
	 'js/lib/text!template/about-account.html',
	 'js/lib/text!template/verify-modal.html',
	 'js/lib/text!template/signup-personal.html',
	 'js/lib/text!template/signup-project.html',
	 'js/lib/text!template/signup.html',
	 // jQuery modules
	 'formhelpers'],
function (_, sup,
	  aboutString, verifyString, personalString,
	  projectString, signupString)
{
    'use strict';

    var aboutTemplate = _.template(aboutString);
    var verifyTemplate = _.template(verifyString);
    var personalTemplate = _.template(personalString);
    var projectTemplate = _.template(projectString);
    var signupTemplate = _.template(signupString);

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
 	$('button#reset-form').click(function (event) {
	    event.preventDefault();
	    clearForm($('#quickvm_signup_form'));
	});
	var fields = JSON.parse(_.unescape($('#form-json')[0].textContent));
	var errors = JSON.parse(_.unescape($('#error-json')[0].textContent));
	renderForm(fields, errors,
		   window.APT_OPTIONS.joinproject,
		   window.APT_OPTIONS.ShowVerifyModal,
		   window.APT_OPTIONS.this_user);

	// Carry this forward.
	if (window.APT_OPTIONS.ShowVerifyModal) {
	    var $jval = (window.APT_OPTIONS.joinproject ? "1" : "0");
	    
	    $('#quickvm_signup_form').append("<input type='hidden' " +
					     "  id='joinproject' " +
					     "  name='joinproject' " +
					     "  value='jval' />");
	}
	// But if bound, make sure we have proper tab active.
	if (typeof window.APT_OPTIONS.joinproject === 'undefined' ||
	    !window.APT_OPTIONS.joinproject) {
	    $("#project_tabs a:last").tab('show');
	}
	else {
	    $("#project_tabs a:first").tab('show');
	}

	/*
	 * Intercept the submit so we can check to see if the user
	 * is joining or starting a project. We do this by looking
	 * to see which of the tabs is active.
	 *
	 * XXX Both tabs need the same formfields[pid] entry, but
	 * it does not work to have two input fields with the same
	 * name, so yank the input field out of the inactive tab.
	 *
	 * Also add the joinproject boolean so the server side knows
	 * what the user is doing (join or start).
	 */
	$('button#submit_button').click(function (event) {
	    if ($('#join_tab').hasClass('active')) {
		$('#joinproject').remove();
		$('#quickvm_signup_form').append("<input type='hidden' " +
						 "  id='joinproject' " +
						 "  name='joinproject' " +
						 "  value='1' />");
		$('#form_start_pid').remove();
	    }
	    else {
		$('#joinproject').remove();
		$('#quickvm_signup_form').append("<input type='hidden' " +
						 "  id='joinproject' " +
						 "  name='joinproject' " +
						 "  value='0' />");
		$('#form_join_pid').remove();
	    }
	});

	/*
	 * When the user toggles from one tab to the other, change
	 * the label in the button.
	 */
	if (window.APT_OPTIONS.this_user) {
	    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
		if ($('#join_tab').hasClass('active')) {
		    $('#submit_button').text("Join Project");
		}
		else {
		    $('#submit_button').text("Start Project");
		}
	    });
	}
    }

    function renderForm(formfields, errors, joinproject, showVerify, thisUser)
    {
	var buttonLabel = calculateButtonLabel(joinproject, thisUser);
	var about = aboutTemplate({});
	var verify = verifyTemplate({
	    id: 'verify_modal',
	    label: buttonLabel
	});
	var personal = formatter(personalTemplate({
	    formfields: formfields
	}), errors);
	var project = Newformatter(projectTemplate({
	    joinproject: joinproject,
	    formfields: formfields
	}), errors);
	var signup = signupTemplate({
	    button_label: buttonLabel,
	    general_error: (errors.error || ''),
	    about_account: about,
	    this_user: thisUser,
	    joinproject: joinproject,
	    verify_modal: verify,
	    pubkey: formfields.pubkey,
	    personal_fields: personal.html(),
	    project_fields: project.html()
	});
	$('#signup-body').html(signup);
	if (showVerify)
	{
	    sup.ShowModal('#verify_modal');
	}
	$('#signup_countries').bfhcountries({ country: formfields.country,
					      blank: false, ask: true });
	$('#signup_states').bfhstates({ country: 'signup_countries',
					state: formfields.state,
					blank: false, ask: true });
    }
    
    function clearForm($form)
    {
	$form.find('input:text, input:password, select, textarea').val('');
    }

    function calculateButtonLabel(joinproject, thisUser)
    {
	var result = 'Create Account';
	if (thisUser)
	{
	    if (joinproject)
	    {
		result = 'Join Project';
	    }
	    else
	    {
		result = 'Create Project';
	    }
	}
	return result;
    }

    function formatter(fieldString, errors)
    {
	var result = $('<div/>');
	var fields = $(fieldString);
	fields.each(function (index, item) {
	    if (item.dataset)
	    {
  		var key = item.dataset['key'];
		var wrapper = $('<div>');
		wrapper.addClass('sidebyside-form');
		wrapper.addClass('form-group');
		wrapper.append(item);

		if (_.has(errors, key))
		{
		    wrapper.addClass('has-error');
		    wrapper.append('<label class="control-label" ' +
				   'for="inputError">' + _.escape(errors[key]) +
				   '</label>');
		}
		result.append(wrapper);
	    }
	});
	return result;
    }

    // Better version.
    function Newformatter(fieldString, errors)
    {
	var root   = $(fieldString);
	var list   = root.find('.format-me');
	list.each(function (index, item) {
	    if (item.dataset) {
		var key     = item.dataset['key'];
		var wrapper = $('<div></div>');
		wrapper.addClass('sidebyside-form');
		wrapper.addClass('form-group');
		wrapper.html($(item).clone());

		if (_.has(errors, key))
		{
		    wrapper.addClass('has-error');
		    wrapper.append('<label class="control-label" ' +
				   'for="inputError">' + _.escape(errors[key]) +
				   '</label>');
		}
		$(item).after(wrapper);
		$(item).remove();
	    }
	});
	return root;
    }

    $(document).ready(initialize);
});
