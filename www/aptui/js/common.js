window.APT_OPTIONS = window.APT_OPTIONS || {};

window.APT_OPTIONS.config = function ()
{
    require.config({
	baseUrl: '.',
	paths: {
	    'jquery': 'js/lib/jquery-2.0.3.min',
	    'bootstrap': 'bootstrap/js/bootstrap',
	    'formhelpers': 'formhelpers/js/bootstrap-formhelpers',
	    'dateformat': 'js/lib/date.format',
	    'd3': 'js/lib/d3.v3',
	    'filestyle': 'js/lib/filestyle',
	    'tablesorter': 'js/lib/jquery.tablesorter.min',
	    'tablesorterwidgets': 'js/lib/jquery.tablesorter.widgets.min',
	},
	shim: {
	    'bootstrap': { deps: ['jquery'] },
	    'formhelpers': { deps: ['bootstrap']},
	    'dateformat': { exports: 'dateFormat' },
	    'd3': { exports: 'd3' },
	    'filestyle': { deps: ['bootstrap']},
	    'tablesorter': { deps: ['jquery'] },
	    'tablesorterwidgets': { deps: ['tablesorter'] },
	},
    });
}

window.APT_OPTIONS.initialize = function (sup)
{
    if (window.APT_OPTIONS.isNewUser)
    {
	sup.ShowModal('#verify_modal');
    }

    $('body').show();
}
