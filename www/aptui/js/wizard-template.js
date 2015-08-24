define(['underscore'],
function(_) {

	function ClusterStatusHTML(options) {
		var html = $('<div id="cluster_picker_status" class="btn-group">'
					    +'<button type="button" class="form-control btn btn-default dropdown-toggle" data-toggle="dropdown">'
					    	+'<span class="value"></span>'
							+'<span class="caret"></span>'
					    +'</button>'
					    +'<ul class="dropdown-menu" role="menu">'
					    	+'<li role="separator" class="divider"></li>'
					    +'</ul>'
					+'</div>');

		var dropdown = html.find('.dropdown-menu .divider');
		$(options).each(function() {
			if ($(this).prop('disabled')) {
				dropdown.after('<li class="disabled"><a data-toggle="tooltip" data-placement="right" data-html="true" title="<div>This testbed is incompatible with the selected profile</div>" href="#" value="'+$(this).attr('value')+'">'+$(this).attr('value')+'</a></li>')
			}
			else {
				dropdown.before('<li class="enabled"><a href="#" value="'+$(this).attr('value')+'">'+$(this).attr('value')+'</a></li>');
			}
		});

		return html;
	}

	function StatusClickEvent(html, that) {
		    html.find('.dropdown-toggle .value').html($(that).attr('value'));   
		    
		    if ($(that).children('.picker_stats').length) {
		    	if (!html.find('.dropdown-toggle > .picker_stats').length) {
		    		html.find('.dropdown-toggle').append('<div class="picker_stats"></div>');
		    	}
		    	else {
		    		html.find('.dropdown-toggle > .picker_stats').html('');
		    	}

		    	html.find('.dropdown-toggle > .picker_stats').append($(that).children('.picker_stats').html());
		    }

		    html.find('.selected').removeClass('selected');
		    $(that).parent().addClass('selected');
	}

	function CalculateRating(data, type) {
		var rating = 0;
		var tooltip = '';


		if (data.status == 'SUCCESS') {
			if (data.health) {
				rating = data.health;
				tooltip += '<div>Testbed is '
				if (rating >= 75) {
					tooltip += 'healthy';
				}
				else if (rating >= 50) {
					tooltip += 'moderately healthy';
				}
				else {
					tooltip += 'unhealthy';
				}
				tooltip += '</div>';
			}
			else {
				rating = 100;
				tooltip += '<div>Testbed is up</div>'
			}
		}
		else {
			tooltip += '<div>Testbed is down</div>'
			return [rating, tooltip];
		}

		var available, max, label;
		if (type == 'VM') {
			available = parseInt(data.VMsAvailable);
			max = parseInt(data.VMsTotal);
			label = 'VMs';
		} 
		else {
			available = parseInt(data.rawPCsAvailable);
			max = parseInt(data.rawPCsTotal);
			label = 'PCs';
		}

		if (!isNaN(available) && !isNaN(max)) {
			var ratio = available/max;
			rating = rating * ratio;
			tooltip += '<div>'+available+'/'+max+' ('+Math.round(ratio*100)+'%) '+label+' available</div>';
		}

		return [rating, tooltip];
	}

	function AssignGlyph(rating) {
		if (rating >= 50) {
			return ['text-success', 'glyphicon-plus'];
		}
		else if (rating > 0) {
			return ['text-warning', 'glyphicon-minus'];
		}
		else {
			return ['text-danger', 'glyphicon-remove'];
		}
	}

	function StatsLineHTML(glyph, title) {
		return '<div class="picker_stats" data-toggle="tooltip" data-placement="right" data-html="true" title="'+title+'">'
							+'<span class="picker_status '+glyph[0]+'"><span class="glyphicon '+glyph[1]+'"></span></span>'
							+'</div>';
	}

	return {
		ClusterStatusHTML: ClusterStatusHTML,
		StatusClickEvent: StatusClickEvent,
		CalculateRating: CalculateRating,
		AssignGlyph: AssignGlyph,
		StatsLineHTML
	};
}
);