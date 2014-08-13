require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup',
	 'js/lib/text!template/geni-login.html'],
function (_, sup, loginString)
{
    'use strict';

    function initialize()
    {
	window.APT_OPTIONS.initialize(sup);

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
    }

    function authenticate(userCertificate, success, failure)
    {
	// Some AJAX call that ends with success or failure based on the result
	// success should be called with the PKCS#7 string
	success('-----BEGIN PKCS7-----\n'+
		'MIIByQYJKoZIhvcNAQcDoIIBujCCAbYCAQAxggFcMIIBWAIBADCBwDCBuDELMAkG\n'+
		'A1UEBhMCVVMxDTALBgNVBAgTBFV0YWgxFzAVBgNVBAcTDlNhbHQgTGFrZSBDaXR5\n'+
		'MR0wGwYDVQQKExRVdGFoIE5ldHdvcmsgVGVzdGJlZDEeMBwGA1UECxMVQ2VydGlm\n'+
		'aWNhdGUgQXV0aG9yaXR5MRgwFgYDVQQDEw9ib3NzLmVtdWxhYi5uZXQxKDAmBgkq\n'+
		'hkiG9w0BCQEWGXRlc3RiZWQtb3BzQGZsdXgudXRhaC5lZHUCAwEv7TANBgkqhkiG\n'+
		'9w0BAQEFAASBgDaDHASj7fN7Dp3dvp/Gm2pgfeIf6W+bhanzmgb/21PqU4wQDjDD\n'+
		'IWsdmGigRKsvn4D/a2kbI27s3QrSf8bsZXeKRsDNm0wWvtdhPQuiiFHYwXjYmE7j\n'+
		'Zi6OEWLxCoVfNL/fdjNppAqGKn2rg6vPVArBGYk+JpAB8QwWJjA2mQIeMFEGCSqG\n'+
		'SIb3DQEHATAaBggqhkiG9w0DAjAOAgIAoAQI5C991yqoRxiAKAfhoqHKJjQTAp3A\n'+
		'W5P/6+wNAa5TLBMbDlEyN3L3FolO4LKqJ5tbnKo=\n'+
		'-----END PKCS7-----\n');
    }

    function complete(credential, authenticationToken, encryptedCredential)
    {
	$('#credential').show();
	$('#credential').val(credential);
	console.log(authenticationToken, encryptedCredential);
    }
    $(document).ready(initialize);
});
