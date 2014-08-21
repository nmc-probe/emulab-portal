require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup',
	 'https://www.emulab.net/protogeni/speaks-for/lib/forge/forge',
	 'js/lib/text!template/geni-login.html'],
function (_, sup, forge, loginString)
{
    'use strict';
    var ajaxurl;
    
    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);
	ajaxurl = window.AJAXURL;

	genilib.trustedHost = window.HOST;
	genilib.trustedPath = window.PATH;
	$('#page-body').html(loginString);

	$('#authorize').click(function (event) {
	    event.preventDefault();
	    genilib.authorize({
		id: window.ID,
		toolCertificate: window.CERT,
		complete: complete,
		authenticate: authenticate
	    });
	    return false;
	});

//	CreateSecret(foo, mycert);
    }

    function VerifySpeaksfor(speaksfor, signature)
    {
	var callback = function(json) {
	    if (json.code) {
		alert("Could not verify speaksfor: " + json.value);
		return;
	    }
	    console.info(json.value);

	    //
	    // Need to set the cookies we get back so that we can
	    // redirect to the status page.
	    //
	    document.cookie =
		json.value.hashname + '=' + json.value.hash +
		'; max-age=' + json.value.timeout + '; path=/; secure';
	    document.cookie =
		json.value.loginname + '=' + json.value.login +
		'; max-age=' + json.value.timeout + '; path=/';
	}
	var $xmlthing = sup.CallServerMethod(ajaxurl,
					     "geni-login", "VerifySpeaksfor",
					     {"speaksfor" : speaksfor,
					      "signature" : signature});
	$xmlthing.done(callback);
    }

    function authenticate(cert, r1, success, failure)
    {
	var callback = function(json) {
	    console.log('callback');
	    if (json.code) {
		alert("Could not generate secret: " + json.value);
		failure();
	    } else {
		console.info(json.value);
		success(json.value.r2_encrypted);
	    }
	}
	var $xmlthing = sup.CallServerMethod(ajaxurl,
					     "geni-login", "CreateSecret",
					     {"r1_encrypted" : r1,
					      "certificate"  : cert});
	$xmlthing.done(callback);
    }

    function complete(credential, signature)
    {
	// signature is undefined if something failed before
	VerifySpeaksfor(credential, signature);
//	console.log(credential);
//	console.log(signature);
    }
    $(document).ready(initialize);
});
