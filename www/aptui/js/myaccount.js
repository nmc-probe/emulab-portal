require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup',
	 'js/lib/text!template/myaccount.html',
	 'js/lib/text!template/verify-modal.html',
	 'js/lib/text!template/oops-modal.html',
	 'js/lib/text!template/waitwait-modal.html',
	 // jQuery modules
	 'formhelpers'],
function (_, sup, myaccountString, verifyString, oopsString, waitwaitString)
{
    'use strict';

    var myaccountTemplate = _.template(myaccountString);
    var verifyTemplate    = _.template(verifyString);
    var modified          = false;

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	// Initial form contents.
	var fields = JSON.parse(_.unescape($('#form-json')[0].textContent));

	$('#oops_div').html(oopsString);	
	$('#waitwait_div').html(waitwaitString);	

	// Watch for USA
	if (fields.country === "USA") {
	    fields.country = "US";
	}
	renderForm(fields, null);
	
	// Warn user if they have not saved changes.
	window.onbeforeunload = function() {
	    if (! modified)
		return null;
	    return "You have unsaved changes!";
	}
    }

    function Modified()
    {
	modified = true;
	$('#submit_button').removeAttr("disabled");
    }

    function renderForm(formfields, errors)
    {
	var verify = verifyTemplate({
	    id: 'verify_modal',
	    label: "Confirm",
	});
	var myaccount = Formatter(myaccountTemplate({
	    formfields: formfields,
	    general_error: (errors.error || ''),
	    verify_modal: verify,
	}), errors);
	
	$('#page-body').html(myaccount);
	$('#signup_countries').bfhcountries({ country: formfields.country,
					      blank: false, ask: true });
	$('#signup_states').bfhstates({ country: 'signup_countries',
					state: formfields.state,
					blank: false, ask: true });

	/*
	 * We have to attached the event handlers after we update the DOM.
	 */
	$('#myaccount_form').find(".format-me").each(function() {
	    $(this).change(function() { Modified(); });
	});
	$('#submit_button').click(function (event) {
	    event.preventDefault();
	    // Disable the Stay on Page alert above.
	    window.onbeforeunload = null;
	    SubmitForm(1);
	    return false;
	});
	$('#verify_modal_submit').click(function (event) {
	    event.preventDefault();
	    // Disable the Stay on Page alert above.
	    window.onbeforeunload = null;
	    sup.HideModal('#verify_modal');
	    SubmitForm(1);
	    return false;
	});
    }
    
    function Formatter(fieldString, errors)
    {
	var root   = $(fieldString);
	var list   = root.find('.format-me');
	list.each(function (index, item) {
	    if (item.dataset)
	    {
  		var key = item.dataset['key'];
		var wrapper = $('<div></div>');
		var placeholder = item.placeholder;
		if (!placeholder) {
		    placeholder = item.dataset['placeholder'];
		}
		wrapper.append('<label class="control-label"> ' +
			       _.escape(placeholder) + '</label>');
		wrapper.append($(item).clone());

		if (errors && _.has(errors, key))
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

    //
    // Submit the form.
    //
    function SubmitForm(checkonly)
    {
	// Current form contents as formfields array.
	var formfields  = {};
	
	var callback = function(json) {
	    if (!checkonly) {
		sup.HideModal("#waitwait-modal");
	    }
	    console.info(json);

	    if (json.code) {
		if (json.code == 2) {
		    // Regenerate with errors.
		    renderForm(formfields, json.value);
		    return;
		}
		// Email not verified, throw up form.
		if (json.code == 3) {
		    sup.ShowModal('#verify_modal');
		    return;
		}
		sup.SpitOops("oops", json.value);
		return;
	    }
	    // Now do the actual create.
	    if (checkonly) {
		SubmitForm(0);
	    }
	    else {
		window.location.reload();
	    }
	}
	// Convert form data into formfields array, like all our
	// form handler pages expect.
	var fields = $('#myaccount_form').serializeArray();
	$.each(fields, function(i, field) {
	    formfields[field.name] = field.value;
	});
	if (!checkonly) {
	    sup.ShowModal("#waitwait-modal");
	}
	var xmlthing =
	    sup.CallServerMethod(null, "myaccount", "update",
				 {"formfields" : formfields,
				  "checkonly"  : checkonly});
	xmlthing.done(callback);
    }
    $(document).ready(initialize);
});
