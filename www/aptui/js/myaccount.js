require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'js/aptforms',
	 'js/lib/text!template/myaccount.html',
	 'js/lib/text!template/verify-modal.html',
	 'js/lib/text!template/oops-modal.html',
	 'js/lib/text!template/waitwait-modal.html',
	 // jQuery modules
	 'formhelpers'],
function (_, sup, aptforms,
	  myaccountString, verifyString, oopsString, waitwaitString)
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

    function renderForm(formfields)
    {
	var verify = verifyTemplate({
	    id: 'verify_modal',
	    label: "Confirm",
	});
	var generror = '';
	if (errors && errors.error) {
	    generror = errors.error;
	}
	var myaccount = aptforms.FormatFormFields(myaccountTemplate({
	    formfields: formfields,
	    general_error: generror,
	    verify_modal: verify,
	    nopassword: window.APT_OPTIONS.nopassword,
	});
	
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
	    SubmitForm();
	    return false;
	});
	$('#verify_modal_submit').click(function (event) {
	    event.preventDefault();
	    // Disable the Stay on Page alert above.
	    window.onbeforeunload = null;
	    sup.HideModal('#verify_modal');
	    SubmitForm();
	    return false;
	});
    }
    
    //
    // Submit the form.
    //
    function SubmitForm()
    {
	var submit_callback = function(json) {
	    if (json.code) {
		sup.SpitOops("oops", json.value);
		return;
	    }
	    window.location.reload();	    
	};
	var checkonly_callback = function(json) {
	    if (json.code) {
		// Email not verified, throw up form.
		if (json.code == 3) {
		    sup.ShowModal('#verify_modal');
		    return;
		}
		else if (json.code != 2) {
		    sup.SpitOops("oops", json.value);		    
		}
		return;
	    }
	    aptforms.SubmitForm('#myaccount_form', "myaccount", "update",
				submit_callback);
	};
	aptforms.CheckForm('#myaccount_form', "myaccount", "update",
			   checkonly_callback);
    }
    $(document).ready(initialize);
});
