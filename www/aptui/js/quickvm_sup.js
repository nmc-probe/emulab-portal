define(['jquery', 'd3', 'dateformat', 'marked'],
function ($, d3) {

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
    
function CallMethod(method, callback, uuid, arg)
{
    return $.ajax({
	// the URL for the request
	url: window.location.href,
 
	// the data to send (will be converted to a query string)
	data: {
	    uuid: uuid,
	    ajax_request: 1,
	    ajax_method: method,
	    ajax_argument: arg,
	},
 
	// whether this is a POST or GET request
	type: (arg ? "GET" : "GET"),
 
	// the type of data we expect back
	dataType : "json",
    });
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

function maketopmap(divname, width, height, json, sshcallback)
{
	var ismousedown = false;
	var savedTrans;
	var savedScale;
        // Flag to distinguish between click and click/drag.
        var isDragging = false;

	var change_view = d3.behavior.zoom()
	.scaleExtent([1,5])
	.on("zoom", rescaleg);

	function rescaleg(d, i, j) {
		if (!ismousedown)
		{
			trans=d3.event.translate;
			scale=d3.event.scale;

			tx = Math.min(0, Math.max(width * (1 - scale), trans[0]));
			ty = Math.min(0, Math.max(height * (1 - scale), trans[1]));

			change_view.translate([tx, ty]);
			vis.attr("transform",
			    "translate(" + tx + "," + ty + ")"
			    + " scale(" + scale + ")");
		}
	}	

	function mousedown()
	{
		$("#quickvm_topomodal").addClass("unselectable");
	}

	function mouseup()
	{
		$("#quickvm_topomodal").removeClass("unselectable");
	}	

    $(divname).html("<div></div>");
    
    var outer = d3.select(divname).append("svg:svg")
		.attr("class", "topomap")
	        .style("visibility", "hidden")
		.attr("width", width)
		.attr("height", height)
		.attr("pointer-events", "all");

    var vis = outer
		.append('svg:g')
			.on("dblclick.zoom", null)
			.call(change_view)
		.append('svg:g')
			.on("mousedown", mousedown)
			.on("mouseup", mouseup);

    var rect = vis.append("svg:rect")
	.attr("width", width)
	.attr("height", height)
        .style("fill-opacity", 0.0)
        .style("stroke", "#000");

    var topo = function(json) {
	var force = self.force = d3.layout.force()
	    .nodes(json.nodes)
	    .links(json.links)
	    .distance(150)
	    .charge(-400)
	    .size([width, height])
	    .start();

	var linkg = vis.selectAll("g.link")
	    .data(json.links)
	    .enter().append("svg:g");

	var link = linkg.append("svg:line")
	    .attr("class", "linkline")
	    .attr("x1", function(d) { return d.source.x; })
	    .attr("y1", function(d) { return d.source.y; })
	    .attr("x2", function(d) { return d.target.x; })
	    .attr("y2", function(d) { return d.target.y; });
	
	var linklabel = linkg.append("svg:text")
	    .attr("class", "linktext")
	    .attr("x", function(d) { return (d.source.x + d.target.x) / 2 })
	    .attr("y", function(d) { return (d.source.y + d.target.y) / 2 })
	    .text(function(d) { return d.name });

	var node_drag = d3.behavior.drag()
	    .on("dragstart", dragstart)
	    .on("drag", dragmove)
	    .on("dragend", dragend);

	function dragstart(d, i) {
	    // stops the force auto positioning before you start dragging
	    force.stop() 
	    ismousedown = true;

	    savedTrans = change_view.translate();
	    savedScale = change_view.scale();
	}

	function dragmove(d, i) {
	    d.px += d3.event.dx;
	    d.py += d3.event.dy;
	    d.x  += d3.event.dx;
	    d.y  += d3.event.dy;
	    // this is the key to make it work together with updating
	    // both px,py,x,y on d !
	    tick(null); 
	}

	function dragend(d, i) {
	    // of course set the node to fixed so the force doesn't
	    // include the node in its auto positioning stuff
	    d.fixed = true; 
	    force.resume();

	    ismousedown = false;
	    change_view.translate(savedTrans);
	    change_view.scale(savedScale);
	}

	var nodeg = vis.selectAll("g.node")
	    .data(json.nodes)
	    .enter().append("svg:g")
	    .call(node_drag);

	//
	// The mouse events are to distinguish between click and drag.
	// I found it with a Google search of course.
	//
	var node = nodeg.append("svg:rect")
	    .attr("class", "nodebox")
	    .on("mousedown", function(d) {
		$(window).mousemove(function() {
		    isDragging = true;
		    $(window).unbind("mousemove");
		});
	    })
	    .on("mouseup", function(d) {
		var wasDragging = isDragging;
		isDragging = false;
		$(window).unbind("mousemove");
		if (!wasDragging && sshcallback) { //was clicking
		    sshcallback(d.hostport, d.client_id);
		}
	    })
	    .attr("x", "-10px")
	    .attr("y", "-10px")
	    .attr("width", "20px")
	    .attr("height", "20px");

	var nodelabel = nodeg.append("svg:text")
	    .attr("class", "nodetext")
	    .attr("dx", 16)
	    .attr("dy", ".35em")
	    .text(function(d) { return d.name });
	
	function tick(e) {
	    if (e && e.alpha < 0.05) {
		outer.style("visibility", "visible")
		force.stop();
		return;
	    }
	    if (0) {
		node.attr("x",
			  function(d) {
			      return d.x =
				  Math.max(10,
					   Math.min(width - 10, d.x));
			  })
		    .attr("y",
			  function(d) {
			      return d.y =
				  Math.max(10,
					   Math.min(height - 10, d.y));
			  });
		
	    }
	    else {
		nodeg.attr("transform", function(d) {
		    d.px = d.x = Math.max(12, Math.min(width - 12, d.x));
		    d.py = d.y = Math.max(12, Math.min(height - 12, d.y));
		    return "translate(" + d.x + "," + d.y + ")"; });
	    }
	    link.attr("x1", function(d) { return d.source.x; })
		.attr("y1", function(d) { return d.source.y; })
		.attr("x2", function(d) { return d.target.x; })
		.attr("y2", function(d) { return d.target.y; });
	    
	    linklabel.attr("x", function(d) { return (d.source.x + d.target.x)
					      / 2 })
		     .attr("y", function(d) { return (d.source.y + d.target.y)
					      / 2 });
	};
	force.on("tick", tick);
    }(json);

    return topo;
}

// Avoid recalc of the layout if we already have seen it. Stash
// json here and return it if we have it. 
var saved = new Object();

//
// Convert a manifest in XML to a JSON object of nodes and links.
//
function ConvertManifestToJSON(name, xml)
{
    if (name && saved[name]) {
	return saved[name];
    }
    var json = {
	"nodes": [],
	"links": [],
    };
    var interfaces = new Array();
    var count = 0;

    $(xml).find("node").each(function(){
	var client_id = $(this).attr("client_id");
	var jobj      = {"name" : client_id};
	
	$(this).find("interface").each(function() {
	    var interface_id = $(this).attr("client_id");
	    var interface    = new Object();
	    interface.client_id  = interface_id;
	    interface.node_id    = client_id;
	    interface.node_index = count;
	    interfaces.push(interface);
	});
	
	var login  = $(this).find("login");
	if (login) {
	    var user   = login.attr("username");
	    var host   = login.attr("hostname");
	    var port   = login.attr("port");
	    var sshurl = "ssh://" + user + "@" + host + ":" + port + "/";

	    jobj.client_id = client_id;
	    jobj.hostport  = host + ":" + port;
	    jobj.sshurl    = sshurl;
	}
	json.nodes[count] = jobj;
	count++;
    });

    $(xml).find("link").each(function(){
	var client_id = $(this).attr("client_id");
	var link_type = $(this).find("link_type");
	var ifacerefs = $(this).find("interface_ref");

	if (ifacerefs.length < 2) {
	    console.info("Oops, not enough interfaces in " + client_id);
	}
	else if (ifacerefs.length > 2) {
	    console.info("Oops, too many interfaces in " + client_id);
	}
	else {
	    var source    = ifacerefs[0];
	    var target    = ifacerefs[1];

	    source = $(source);
	    target = $(target);
	    
	    var source_ifname = source.attr("client_id");
	    var target_ifname = target.attr("client_id");
	    var source_name   = null;
	    var target_name   = null;
	    var source_index  = null;
	    var target_index  = null;

	    /*
	     * First we have map the client_ids to the node by
	     * searching all of the interfaces we put into the
	     * list above.
	     *
	     * Javascript does not do dictionaries. Too bad.
	     */
	    for (i = 0; i < interfaces.length; i++) {
		if (interfaces[i].client_id == source_ifname) {
		    source_name  = interfaces[i].node_id;
		    source_index = interfaces[i].node_index;
		}
		if (interfaces[i].client_id == target_ifname) {
		    target_name  = interfaces[i].node_id;
		    target_index = interfaces[i].node_index;
		}
	    }
	    json.links.push({"name"         : client_id,
			     "source"       : source_index,
			     "target"       : target_index,
			     "source_name"  : source_name,
			     "target_name"  : target_name,
			    });
	}
    });
    if (name) {
	saved[name] = json;
    }
    return json;
}

// Spit out the oops modal.
function SpitOops(id, msg)
{
    var modal_text_name = "#" + id + "_text";
    $(modal_text_name).html(msg);
    ShowModal("#" + id);
}

// Exports from this module for use elsewhere
return {
    ShowModal: ShowModal,
    HideModal: HideModal,
    CallMethod: CallMethod,
    CallServerMethod: CallServerMethod,
    ConvertManifestToJSON: ConvertManifestToJSON,
    maketopmap: maketopmap,
    SpitOops: SpitOops,
};
});
