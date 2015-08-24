define(['underscore'],
function(_) {

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
		CalculateRating: CalculateRating,
		AssignGlyph: AssignGlyph,
		StatsLineHTML
	};
}
);