define(['d3', 'dateformat', 'marked', 'jacks'],
function (d3) {

function ShowModal(which) 
{
//   console.log('Showing modal ' + which);
    $( which ).modal('show');
}
    
function HideModal(which) 
{
//   console.log('Hide modal ' + which);
    $( which ).modal('hide');
}
    
function CallServerMethod(url, route, method, args)
{
    if (url == null) {
	url = 'https://' + window.location.host + '/apt/server-ajax.php';
    }
    return $.ajax({
	// the URL for the request
	url: url,
 
	// the data to send (will be converted to a query string)
	data: {
	    ajax_route:     route,
	    ajax_method:    method,
	    ajax_args:      args,
	},
 
	// whether this is a POST or GET request
	type: "POST",
 
	// the type of data we expect back
	dataType : "json",
    });
}

var jacksInstance;
var jacksInput;
var jacksOutput;

function maketopmap(divname, xml, sshcallback)
{
    if (! jacksInstance)
    {
	jacksInstance = new window.Jacks({
	    mode: 'viewer',
	    source: 'rspec',
	    root: divname,
	    nodeSelect: false,
	    readyCallback: function (input, output) {
		jacksInput = input;
		jacksOutput = output;
		jacksInput.trigger('change-topology',
				   [{ rspec: xml }]);
		if (sshcallback)
		{
		    jacksOutput.on('click-event', function (event) {
			if (event.type === 'node')
			{
			    sshcallback(event.ssh, event.client_id);
			}
		    });
		}
	    },
	    show: {
		rspec: false,
		tour: false,
		version: false,
		menu: false
	    }
	});
    }
    else if (jacksInput)
    {
	jacksInput.trigger('change-topology',
			   [{ rspec: xml }]);
    }
}

// Spit out the oops modal.
function SpitOops(id, msg)
{
    var modal_name = "#" + id + "_modal";
    var modal_text_name = "#" + id + "_text";
    $(modal_text_name).html(msg);
    ShowModal(modal_name);
}

// Exports from this module for use elsewhere
return {
    ShowModal: ShowModal,
    HideModal: HideModal,
    CallServerMethod: CallServerMethod,
    maketopmap: maketopmap,
    SpitOops: SpitOops,
};
});
