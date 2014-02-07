window.APT_OPTIONS.config();

require(['jquery', 'js/quickvm_sup',
	 // jQuery modules
	 'bootstrap'],
function ($, sup)
{
    'use strict';

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

        sup.UpdateProfileSelection($('#profile_name li[value = ' +
				     window.PROFILE + ']'));
        $('#quickvm_topomodal').on('hidden.bs.modal', function() {
	    sup.ShowProfileList($('.current'))
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
	    sup.HideModal('#quickvm_topomodal');
	});
	// We have to get the selected profile from the hidden form variable.
	$('a#instantiate').click(function (event) {
	    event.preventDefault();
	    var profile = $('#selected_profile').attr('value');	    
	    window.location.replace("quickvm.php?profile=" + profile);
	});
    }

    $(document).ready(initialize);
});
