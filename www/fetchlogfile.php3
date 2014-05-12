<html>
<head>
  <script src="apt/js/lib/jquery-2.0.3.min.js"></script>
  <script src="apt/js/lib/underscore-min.js"></script>
  <script>
    $(document).ready(function () {
      var lastIndex = 0;
      var url = window.location.protocol + '//' +
        window.location.host +
        '/spewlogfile.php3' +
        window.location.search;
      var xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function ()
      {
        if (xhr.responseText)
        {
          var newText = xhr.responseText.substr(lastIndex);
          lastIndex = xhr.responseText.length;
          var shouldScroll = (document.body.scrollHeight - document.body.clientHeight == document.body.scrollTop);
          $('pre').append(_.escape(newText));
          if (shouldScroll)
          {
            document.body.scrollTop = document.body.scrollHeight - document.body.clientHeight;
          }
        }
      };
      xhr.open('get', url, true);
      xhr.send();
    });
  </script>
</head>
<body>
  <pre></pre>
</body>
</html>
