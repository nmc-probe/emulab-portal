require(window.APT_OPTIONS.configObject,
	['underscore', 'js/quickvm_sup',
	 'https://www.emulab.net/protogeni/speaks-for/lib/forge/forge',
	 'js/lib/text!template/geni-login.html'],
function (_, sup, forge, loginString)
{
    'use strict';
    var ajaxurl;
    var secret = null;

    var foo = "-----BEGIN PKCS7-----\n" +
	"MIIByQYJKoZIhvcNAQcDoIIBujCCAbYCAQAxggFcMIIBWAIBADCBwDCBuDELMAkG\n" +
	"A1UEBhMCVVMxDTALBgNVBAgTBFV0YWgxFzAVBgNVBAcTDlNhbHQgTGFrZSBDaXR5\n" +
	"MR0wGwYDVQQKExRVdGFoIE5ldHdvcmsgVGVzdGJlZDEeMBwGA1UECxMVQ2VydGlm\n" +
	"aWNhdGUgQXV0aG9yaXR5MRgwFgYDVQQDEw9ib3NzLmVtdWxhYi5uZXQxKDAmBgkq\n" +
	"hkiG9w0BCQEWGXRlc3RiZWQtb3BzQGZsdXgudXRhaC5lZHUCAwEv7TANBgkqhkiG\n" +
	"9w0BAQEFAASBgB3SoXZgUFEJrN8gGW06B0O7TzKs9vCSXgHPFGhTHLYWQy7MhV3z\n" +
	"neFDhJw4I4fUu/JOWSMZ58EustIewj652ASYKEGEzzUpNyYA8vyVceiLatiZblMP\n" +
	"vwPo3IBacDqPuiBFB1CPPO/vhd7/M1oZCknmm37sa4Has0fR8T5mIhIiMFEGCSqG\n" +
	"SIb3DQEHATAaBggqhkiG9w0DAjAOAgIAoAQIenog8mG95S6AKN0z8UedzqQ22T4Z\n" +
	"PHy/Lc5zyIDba6mmud8d1h5WT+gq+sP0aLPgQfA=\n" +
	"-----END PKCS7-----\n";

    var mycert = "-----BEGIN CERTIFICATE-----\n" +
	"MIID4DCCA0mgAwIBAgIDAlCGMA0GCSqGSIb3DQEBBAUAMIG4MQswCQYDVQQGEwJV\n" +
	"UzENMAsGA1UECBMEVXRhaDEXMBUGA1UEBxMOU2FsdCBMYWtlIENpdHkxHTAbBgNV\n" +
	"BAoTFFV0YWggTmV0d29yayBUZXN0YmVkMR4wHAYDVQQLExVDZXJ0aWZpY2F0ZSBB\n" +
	"dXRob3JpdHkxGDAWBgNVBAMTD2Jvc3MuZW11bGFiLm5ldDEoMCYGCSqGSIb3DQEJ\n" +
	"ARYZdGVzdGJlZC1vcHNAZmx1eC51dGFoLmVkdTAeFw0xNDAyMDMxNzAxMjJaFw0x\n" +
	"NTAyMDMxNzAxMjJaMIGqMQswCQYDVQQGEwJVUzENMAsGA1UECBMEVXRhaDEdMBsG\n" +
	"A1UEChMUVXRhaCBOZXR3b3JrIFRlc3RiZWQxGzAZBgNVBAsTEnV0YWhlbXVsYWIu\n" +
	"c3RvbGxlcjEtMCsGA1UEAxMkMGIyZWI5N2UtZWQzMC0xMWRiLTk2Y2ItMDAxMTQz\n" +
	"ZTQ1M2ZlMSEwHwYJKoZIhvcNAQkBFhJzdG9sbGVyQGVtdWxhYi5uZXQwgZ8wDQYJ\n" +
	"KoZIhvcNAQEBBQADgY0AMIGJAoGBAK5+JRzpLj9aJakzFHXyLri+eqNyfqySjsB8\n" +
	"2gnzW4h6MAChQFuc4j3m/fIh39buzDRX3nhMF10etZKEHb7sPmA6hzQzq+0y8vGj\n" +
	"3dSiyjsy8SOjGrZAKrBC2mV5eXIFklyglFHJF263SWbUzv48W/quQRFlG+hV3/oL\n" +
	"OH0tQUzbAgMBAAGjggECMIH/MAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFGAYW2vo\n" +
	"Fecr8tsRcL5H6gSXAUH9MHYGA1UdEQRvMG2GKHVybjpwdWJsaWNpZDpJRE4rZW11\n" +
	"bGFiLm5ldCt1c2VyK3N0b2xsZXKBEnN0b2xsZXJAZW11bGFiLm5ldIYtdXJuOnV1\n" +
	"aWQ6MGIyZWI5N2UtZWQzMC0xMWRiLTk2Y2ItMDAxMTQzZTQ1M2ZlMFgGCCsGAQUF\n" +
	"BwEBBEwwSjBIBhRpg8yTgKiYzKjHvbGngICqrteKG4YwaHR0cHM6Ly93d3cuZW11\n" +
	"bGFiLm5ldDoxMjM2OS9wcm90b2dlbmkveG1scnBjL3NhMA0GCSqGSIb3DQEBBAUA\n" +
	"A4GBAAF8aadZH3vXTFt0od9ooZ+dWvAaGWlkiAmlwOcpUsT5D8G+rUcaz7iPWrju\n" +
	"d3wPd/iFDIO7BqmolxSY6L/YjSwvtkvfMX8Q7gYkECmgCEX/ztMXRdcu9vGdfjYZ\n" +
	"nIPONT767s7Qrx0S6nA9GOV8WvDdywUluFSwE45g+e7zs2CO\n" +
	"-----END CERTIFICATE-----\n";
    
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

	CreateSecret(foo, mycert);
    }

    function CreateSecret(r1, cert)
    {
	var callback = function(json) {
	    if (json.code) {
		alert("Could not generate secret: " + json.value);
		return;
	    }
	    console.info(json.value);
	    secret = json.value.secret;

	    var md = forge.md.sha256.create();
	    md.update(mycert + secret);
	    console.log(md.digest().toHex());
	    VerifySpeaksfor(mycert, md.digest().toHex());
	}
	var $xmlthing = sup.CallServerMethod(ajaxurl,
					     "geni-login", "CreateSecret",
					     {"r1_encrypted" : r1,
					      "certificate"  : cert});
	$xmlthing.done(callback);
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
