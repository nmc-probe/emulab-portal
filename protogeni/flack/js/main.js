(function ()
{
  // For version detection, set to min. required Flash Player version, or 0 (or 0.0.0), for no version detection.
var swfVersionStr = "11.1.0";
  // To use express install, set to playerProductInstall.swf, otherwise the empty string.
  var xiSwfUrlStr = "playerProductInstall.swf";
  var flashvars = {};
  if (isPortal)
  {
    flashvars.skipstartup = '1';
    flashvars.bundlepreset = '1';
    flashvars.keycertpreset = '1';
    flashvars.loadallmanagerswithoutasking = '1';
    flashvars.saurl = encodeURIComponent(document.getElementById('sa-url-parameter').innerText);
    flashvars.saurn = encodeURIComponent(document.getElementById('sa-urn-parameter').innerText);
    flashvars.churl = encodeURIComponent(document.getElementById('ch-url-parameter').innerText);
    flashvars.sliceurn = encodeURIComponent(document.getElementById('slice-urn-parameter').innerText);
  }
  var params = {};
  params.quality = "high";
  params.bgcolor = "#d2e1f0";
  params.allowscriptaccess = "always";
  params.allowfullscreen = "true";
  params.fullScreenOnSelection = "true";
  var attributes = {};
  attributes.id = "flack";
  attributes.name = "flack";
  attributes.align = "middle";
  swfobject.embedSWF(
    basePath + "flack.swf", "flashContent",
    "100%", "100%",
    swfVersionStr, xiSwfUrlStr,
    flashvars, params, attributes);
  // JavaScript enabled so display the flashContent div in case it is not replaced with a swf object.
  swfobject.createCSS("#flashContent", "display:block;text-align:left;");
  swfobject.embedSWF(
    basePath + 'forge/SocketPool.swf', 'socketPool',
    '0', '0',
    '9.0.0', false,
    {}, {allowscriptaccess: 'always'}, {});
  swfobject.createCSS("#socketPool", "visibility:visible;");
}());

// CA certificate for test server
var serverCerts = [];
var clientCerts = [];
var clientKey = '';

var flash_id = "";

function getSWF()
{
  if (navigator.appName.indexOf("Microsoft") != -1)
  {
    return window[flash_id];
  }
  else
  {
    return document[flash_id];
  }
}

var sp;

function init(new_flash_id)
{
  try
  {
    if (isPortal)
    {
      setServerCert(document.getElementById('server-cert-parameter').innerHTML);
      setClientKey(document.getElementById('client-key-parameter').innerHTML);
      setClientCert(document.getElementById('client-cert-parameter').innerHTML);
    }

    flash_id = new_flash_id;
    sp = forge.net.createSocketPool({
      flashId: 'socketPool',
      policyPort: 843,
      msie: false
    });
  }
  catch(ex)
  {
    console.log('ERROR init:');
    console.dir(ex);
  }
}

// local aliases
var tls = window.forge.tls;
var http = window.forge.http;
var util = window.forge.util;

var clients = new Object();

function make_request(instance, host, path, sendData)
{
  try
  {
    var newClient = client_init(host);
    if (clients[instance] == null)
    {
      clients[instance] = newClient;
      client_send(newClient, path, sendData, instance);
    }
  }
  catch(ex)
  {
    console.log('ERROR make_request:');
    console.dir(ex);
  }
}

function cancel_request(instance)
{
  try
  {
    var client = clients[instance];
    if (client != null)
    {
      client_cleanup(client);
      delete client[instance];
    }
  }
  catch(ex)
  {
    console.log('ERROR cancel_request:');
    console.dir(ex);
  }
  return false;
}

function setServerCert(newCert)
{
  try
  {
    serverCerts = [];
    var list = newCert.split("-----END CERTIFICATE-----");
    for (var i = 0; i < list.length - 1; ++i)
    {
      serverCerts.push(list[i] + "-----END CERTIFICATE-----\n");
    }
  }
  catch(ex)
  {
    console.log('ERROR setServerCert:');
    console.dir(ex);
  }
}

function addServerCert(newCert)
{
  try
  {
    var list = newCert.split("-----END CERTIFICATE-----");
    for (var i = 0; i < list.length - 1; ++i)
    {
      serverCerts.push(list[i] + "-----END CERTIFICATE-----\n");
    }
  }
  catch(ex)
  {
    console.log('ERROR addServerCert:');
    console.dir(ex);
  }
}

function setClientCert(newCert)
{
  try
  {
    clientCerts = [];
    if (typeof(newCert) === "string")
    {
      var list = newCert.split("-----END CERTIFICATE-----");
      for (var i = 0; i < list.length - 1; ++i)
      {
	clientCerts.push(list[i] + "-----END CERTIFICATE-----\n");
      }
    }
    else
    {
      clientCerts = newCert;
    }
  }
  catch (ex)
  {
    console.log('ERROR setting client cert:');
    console.dir(ex);
  }
}

function setClientKey(newKey)
{
  try
  {
    clientKey = newKey;
  }
  catch(ex)
  {
    console.log('ERROR setting client key:');
    console.dir(ex);
  }
}

function client_init(host)
{
  var result = null;
  try
  {
    var arg = {
      url: host,
      socketPool: sp,
      connections: 1,
      // optional cipher suites in order of preference
      caCerts : serverCerts,
      cipherSuites: [
        tls.CipherSuites.TLS_RSA_WITH_AES_128_CBC_SHA,
        tls.CipherSuites.TLS_RSA_WITH_AES_256_CBC_SHA],
      verify: function(c, verified, depth, certs)
      {

/*
             forge.log.debug('forge.tests.tls',
                'TLS certificate ' + depth + ' subject: ' + certs[depth].subject.getField('CN').value + " issuer: " + certs[depth].issuer.getField('CN').value, verified);
             // Note: change to always true to test verifying without cert
             //return verified;
             // FIXME: temporarily accept any cert to allow hitting any bpe
             if(verified !== true)
             {
                forge.log.warning('forge.tests.tls',
                   'Certificate NOT verified. Ignored for test.');
             }
             return true;
*/
        return verified;
      },
      primeTlsSockets: false
    };
    if (clientCerts.length > 0)
    {
      arg.getCertificate = function(c, request) { return clientCerts; };
      arg.getPrivateKey = function(c, cert) { return clientKey; };
    }
    result = http.createClient(arg);
  }
  catch(ex)
  {
    console.log('ERROR: client_init');
    console.dir(ex);
  }
  
  return result;
}

function client_cleanup(client)
{
  client.destroy();
}

function client_send(client, path, data, instance)
{
  var requestArg = {
    path: path,
    method: 'GET'
  };
  if (data != "")
  {
    requestArg.method = 'POST';
    requestArg.headers = [{'Content-Type': 'text/xml'}];
    requestArg.body = data;
  }
  var request = http.createRequest(requestArg);
  client.send({
    request: request,
    connected: function(e)
    {
      //             forge.log.debug('forge.tests.tls', 'connected', e);
    },
    headerReady: function(e)
    {
      //             forge.log.debug('forge.tests.tls', 'header ready', e);
    },
    bodyReady: function(e)
    {
      //           forge.log.debug('forge.tests.tls', 'body ready called', e);
      var response = e.response.body;
      e.socket.close();
      getSWF().flash_onbody(instance, response);
    },
    error: function(e)
    {
      var response = e.type + ": " + e.message;
      if (e.cause != null)
      {
	//             response += ": " + String(e.cause);
      }
      e.socket.close();
      getSWF().flash_onerror(instance, response);
    }
  });
  return false;
}
