<?php
   header("Content-type: text/html; charset=utf-8");
   header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
   header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
   header("Cache-Control: no-cache, must-revalidate");
   header("Pragma: no-cache");
?>
<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'
          'http://www.w3.org/TR/html4/loose.dtd'>
<html>
<head>
  <script src="apt/js/lib/jquery-2.0.3.min.js"></script>
  <script src="apt/js/lib/underscore-min.js"></script>
  <script>
    $(document).ready(function () {
      var lastIndex = 0;
      // The url is the same as this one with 'spewlogfile.php3' instead of
      // the current path.
      var url = window.location.protocol + '//' +
        window.location.host +
        '/spewlogfile.php3' +
        window.location.search;

      // Fetch spewlogfile via AJAX call
      var xhr = new XMLHttpRequest();

      // Every time new data comes in or the state variable changes,
      // this function is invoked.
      xhr.onreadystatechange = function ()
      {
        // xhr.responseText contains all data received so far from spewlogfile
        if (xhr.responseText)
        {
          // Append only new text
          var newText = xhr.responseText.substr(lastIndex);
          lastIndex = xhr.responseText.length;

          // If the user is scrolled to the bottom, make sure they
          // stay scrolled to the bottom after appending.
          var shouldScroll = (document.body.scrollHeight - document.body.clientHeight == document.body.scrollTop);
          $('pre').append(_.escape(newText));
          if (shouldScroll)
          {
            document.body.scrollTop = document.body.scrollHeight - document.body.clientHeight;
          }
        }
      };
      // Invoke the AJAX
      xhr.open('get', url, true);
      xhr.send();
    });
  </script>
</head>
<body>
  <pre></pre>
</body>
</html>
