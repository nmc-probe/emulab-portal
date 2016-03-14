require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup', 'js/aptforms',
	 'js/lib/text!template/invite.html'],
function (_, sup, aptforms, inviteString)
{
    'use strict';
    var inviteTemplate    = _.template(inviteString);

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

	var fields   = JSON.parse(_.unescape($('#form-json')[0].textContent));
	var errors   = JSON.parse(_.unescape($('#error-json')[0].textContent));
	var projlist = JSON.parse(_.unescape($('#projects-json')[0].textContent));

	// Generate the templates.
	var invite_html = inviteTemplate({
	    formfields:		fields,
	    projects:		projlist,
	    general_error:      (errors.error || '')
	});
	$('#invite-body').html(aptforms.FormatFormFields(invite_html));
	aptforms.GenerateFormErrors('#invite_form', errors);
    }

    $(document).ready(initialize);
});
