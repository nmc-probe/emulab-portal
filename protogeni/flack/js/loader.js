var isPortal = false;
var basePath = '';

(function () {
  var importList = [
    'forge/debug.js',
    'forge/util.js',
    'forge/log.js',
    'forge/socket.js',
    'forge/md5.js',
    'forge/sha1.js',
    'forge/hmac.js',
    'forge/aes.js',
    'forge/asn1.js',
    'forge/jsbn.js',
    'forge/prng.js',
    'forge/random.js',
    'forge/oids.js',
    'forge/rsa.js',
    'forge/pki.js',
    'forge/tls.js',
    'forge/tlssocket.js',
    'forge/http.js',
    'main.js'
  ];

  var sourceOptionList = ['local', 'devel', 'stable', 'none'];

  var sourceOptions = {
    'local': 'http://localhost:8080/',
    'devel': 'https://www.emulab.net/protogeni/flack-devel/',
    'stable': 'https://www.emulab.net/protogeni/flack-stable/',
    'none': ''
  };

  function getQueryParams(qs) {
    qs = qs.split('+').join(' ');
    var params = {};
    var re = /[?&]?([^=]+)=([^&]*)/g;
    var tokens = re.exec(qs);
    
    while (tokens) {
      params[decodeURIComponent(tokens[1])]
        = decodeURIComponent(tokens[2]);
      tokens = re.exec(qs);
    }
    
    return params;
  }

  var params = getQueryParams(window.location.search);

  if (params['portal'] && params['portal'] === '1')
  {
    isPortal = true;
  }
  var sourceName = params['source'];
  var basePath = sourceOptions['stable'];
  if (sourceOptionList.indexOf(sourceName) !== -1)
  {
    basePath = sourceOptions[sourceName];
  }

  var body = document.getElementsByTagName('body')[0];
  var i = 0;
  for (i = 0; i < importList.length; i += 1)
  {
    var script = document.createElement('script');
    script.src = basePath + importList[i];
    script.type = 'application/javascript';
    script.async = false;
    script.defer = false;
    body.appendChild(script);
  }
}());
