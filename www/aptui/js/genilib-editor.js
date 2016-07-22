require(window.APT_OPTIONS.configObject,
['underscore', 'js/quickvm_sup',
 'js/lib/text!template/genilib-editor.html',	 
 'js/lib/text!template/oops-modal.html',
 'js/lib/text!template/waitwait-modal.html',
 'jacks'],
function (_, sup, pageString, oopsString, waitwaitString)
{
  'use strict';
  var editor;
  var isWaiting = false;
  var settingsShown = false;
  var rspec = '';
  var jacks = null;
  var jacksInput = null;
  var jacksOutput = null;

  function initialize()
  {
    window.APT_OPTIONS.initialize(sup);

    $('#page-body').html(pageString);
    $('#oops_div').html(oopsString);
    $('#waitwait_div').html(waitwaitString);
    
    editor = ace.edit('editor');
    editor.setTheme('ace/theme/chrome');
    editor.getSession().setMode('ace/mode/python');

    loadSettings();

    $('#saveButton').on('click', save);
    $('#loadButton').on('click', load);
    $('#runButton').on('click', run);
    $('#settingsButton').on('click', toggleSettings);
    $('#closeErrorButton').on('click', closeError);
    $('#closeSettingsButton').on('click', closeSettings);
    $('#settings-root select').on('change', onChangeSettings);
  }


  function save()
  {
    if (! isWaiting)
    {
      var scriptString = editor.getValue();
      var file = new Blob([scriptString],
			  { type: 'application/octet-stream' });
      var a = document.createElement('a');
      a.href = window.URL.createObjectURL(file); 
      a.download = 'saved.py';
      document.body.appendChild(a);
      a.click(); $('a').last().remove();
    }
  }

  function load()
  {
    if (! isWaiting)
    {
      $('#load-input').html('<input type="file"/>');
      $('#load-input input').on('change', function () {
	var file = $('#load-input input')[0].files[0];
	if (file)
	{
          var reader = new FileReader();
          reader.onload = function (e) {
            var contents = e.target.result;
	    editor.setValue(contents);
	    $('#jacks-root').hide();
	    $('#error-root').hide();
//            jacksInput.trigger('change-topology', [{ rspec: contents }]);
          };
          reader.readAsText(file);
	}
      });
      $('#load-input input').click();
    }
  }

  function run()
  {
    if (! isWaiting)
    {
      $('#jacks-root').hide();
      $('#error-root').hide();
      closeSettings();
      $('#waitwait-modal').modal('show');
      isWaiting = true;

      var script = editor.getValue();
      var call = sup.CallServerMethod(null, "instantiate",
				      "RunScript",
				      {"script" : script});
      call.done(runComplete);
    }
  }

  function runComplete(json)
  {
    $('#waitwait-modal').modal('hide');
    isWaiting = false;

    if (json.code == 0)
    {
      $('#jacks-root').show();
      rspec = json.value;
      _.defer(jacksUpdate);
    }
    else if (json.code == 2)
    {
      $('#error-message').html('');
      var errors = json.value.split('\n');
      for (var i in errors)
      {
	var item = $('<div class="error-item">');

	var re = /[0-9].py", line ([0-9]+)/;
	var found = re.exec(errors[i]);
	if (found !== null)
	{
	  var line = parseInt(found[1], 10);
	  item.append(makeLineButton(line));
	}

	item.append('<pre>' + _.escape(errors[i]) + '</pre></div>');
	$('#error-message').append(item);
      }
//      $('#error-message').html(_.escape(json.value));
      $('#error-root').show();
    }
    else
    {
      sup.SpitOops('oops', json.value);
    }
  }

  function makeLineButton(line)
  {
    var button = $('<button class="btn btn-default pull-right"><span class="glyphicon glyphicon-share-alt" aria-hidden="true"></span></button>');
    button.on('click', function () {
      editor.gotoLine(line);
    });
    return button;
  }

  function closeError()
  {
    $('#error-root').hide();
  }

  function onChangeSettings()
  {
    var settings = saveSettings();
    updateSettings(settings);
  }

  function closeSettings()
  {
    $('#settings-root').hide();
    settingsShown = false;
  }

  function toggleSettings()
  {
    if (settingsShown)
    {
      closeSettings();
    }
    else
    {
      settingsShown = true;
      $('#settings-root').show();
      $('#jacks-root').hide();
      $('#error-root').hide();
    }
  }

  function loadSettings()
  {
    var settings = {
      'theme': 'chrome',
      'fontsize': '12px',
      'codefolding': 'manual',
      'keybinding': 'ace',
      'showspace': 'disabled'
    };
    try
    {
      var settingsString = window.localStorage.getItem('genilib-editor-settings');
      if (settingsString)
      {
	settings = JSON.parse(settingsString);
      }
    }
    catch (e)
    {
      console.log('Failed to load settings. Falling back to defaults.');
    }

    updateSettings(settings);
  }

  function saveSettings()
  {
    var settings = {};
    $('#settings-root select').each(function () {
      settings[this.id] = $(this).val();
    });
    try
    {
      var settingsString = JSON.stringify(settings);
      window.localStorage.setItem('genilib-editor-settings', settingsString);
    }
    catch (e)
    {
      console.log('Cannot save settings');
    }
    return settings;
  }

  function updateSettings(settings)
  {
    for (var key in settings)
    {
      if ($('#settings-root').find('#' + key).val() !== settings[key])
      {
	$('#settings-root').find('#' + key).val(settings[key]);
      }
    }
    if (editor.getTheme() !== 'ace/theme/' + settings['theme'])
    {
      editor.setTheme('ace/theme/' + settings['theme']);
    }

    if (editor.getFontSize() !== settings['fontsize'])
    {
      editor.setFontSize(settings['fontsize']);
    }

    var shouldFold = (settings['codefolding'] !== 'manual');
    if (editor.getShowFoldWidgets() !== shouldFold)
    {
      editor.setShowFoldWidgets(shouldFold);
    }

    if (editor.getKeyboardHandler() !== settings['keybinding'])
    {
      editor.setKeyboardHandler('ace/keyboard/' + settings['keybinding']);
    }
    var shouldShowSpace = (settings['showspace'] === 'enabled');
    if (editor.getShowInvisibles() !== shouldShowSpace)
    {
      editor.setShowInvisibles(shouldShowSpace);
    }
  }
  
  function jacksUpdate()
  {
    if (jacks)
    {
      if (jacksInput)
      {
	jacksInput.trigger('change-topology',
			   [{ rspec: rspec }]);
      }
    }
    else
    {
      jacks = new window.Jacks({
        mode: 'viewer',
        source: 'rspec',
        root: '#jacks-container',
        readyCallback: jacksReady,
	show:
	{
	  rspec: true,
	  tour: false,
	  version: false,
	  menu: true,
	  selectInfo: true,
	  clear: false
	}
      });
    }
  }

  function jacksReady(input, output)
  {
    jacksInput = input;
    jacksOutput = output;
    jacksInput.trigger('change-topology',
		       [{ rspec: rspec }]);
  }
  
  $(document).ready(initialize);
});
