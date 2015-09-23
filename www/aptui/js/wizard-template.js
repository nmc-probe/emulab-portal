define(['underscore'],
function(_) {

	function ClusterStatusHTML(options) {
		var html = $('<div class="cluster_picker_status btn-group">'
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

		if (!html.find('.disabled').length) {
			html.find('.divider').remove();
		}

		return html;
	}

	function StatusClickEvent(html, that) {
		    html.find('.dropdown-toggle .value').html($(that).attr('value'));   
		    
		    if ($(that).find('.picker_stats').length) {
		    	if (!html.find('.dropdown-toggle > .picker_stats').length) {
		    		html.find('.dropdown-toggle').append('<div class="picker_stats"></div>');
		    	}
		    	else {
		    		html.find('.dropdown-toggle > .picker_stats').html('');
		    	}

		    	html.find('.dropdown-toggle > .picker_stats').append($(that).find('.picker_stats').html());
		    }

		    html.find('.selected').removeClass('selected');
		    $(that).parent().addClass('selected');
	}

	function CalculateRating(data, type) {
		var health = 0;
		var rating = 0;
		var tooltip = [];


		if (data.status == 'SUCCESS') {
			if (data.health) {
				health = data.health;
				tooltip[0] = '<div>Testbed is '
				if (health >= 50) {
					tooltip[0] += 'healthy';
				}
				else {
					tooltip[0] += 'unhealthy';
				}
				tooltip[0] += '</div>';
			}
			else {
				health = 100;
				tooltip[0] = '<div>Testbed is up</div>'
			}
		}
		else {
			tooltip[0] = '<div>Testbed is down</div>'
			return [health, rating, tooltip];
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
			rating = available;
			tooltip[1] = '<div>'+available+'/'+max+' ('+Math.round(ratio*100)+'%) '+label+' available</div>';
		}

		return [health, rating, tooltip];
	}

	function AssignStatusClass(health, rating) {
		var result = [];
		if (health >= 50) {
			result[0] = 'status_healthy';
		}
		else if (health > 0) {
			result[0] = 'status_unhealthy';
		}
		else {
			result[0] = 'status_down';
		}

		if (rating > 20) {
			result[1] = 'resource_healthy';
		}
		else if (rating > 10) {
			result[1] = 'resource_unhealthy';
		}
		else {
			result[1] = 'resource_down';
		}

		return result;
	}

	function StatsLineHTML(classes, title) {
		var title1 = '';
		if (title[1]) {
			title1 = ' data-toggle="tooltip" data-placement="right" data-html="true" title="'+title[1]+'"';
		}
		return '<div class="tooltip_div"'+title1+'><div class="picker_stats" data-toggle="tooltip" data-placement="left" data-html="true" title="'+title[0]+'">'
							+'<span class="picker_status '+classes[0]+' '+classes[1]+'"><span class="circle"></span></span>'
							+'</div></div>';
	}

	return {
		ClusterStatusHTML: ClusterStatusHTML,
		StatusClickEvent: StatusClickEvent,
		CalculateRating: CalculateRating,
		AssignStatusClass: AssignStatusClass,
		StatsLineHTML
	};
}
);