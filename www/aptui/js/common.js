window.APT_OPTIONS = window.APT_OPTIONS || {};

window.APT_OPTIONS.config = function ()
{
    require.config({
	baseUrl: '.',
	paths: {
	    'jquery-ui': 'js/lib/jquery-ui-1.10.4.custom',
	    'jquery-grid':'js/lib/jquery.appendGrid-1.3.1.min',
	    'formhelpers': 'formhelpers/js/bootstrap-formhelpers',
	    'dateformat': 'js/lib/date.format',
	    'd3': 'js/lib/d3.v3',
	    'filestyle': 'js/lib/filestyle',
	    'tablesorter': 'js/lib/jquery.tablesorter.min',
	    'tablesorterwidgets': 'js/lib/jquery.tablesorter.widgets.min',
	    'marked': 'js/lib/marked',
	    'moment': 'js/lib/moment',
	    'underscore': 'js/lib/underscore-min',
	    'jacks': 'https://www.emulab.net/protogeni/jacks-stable/js/jacks'
	},
	shim: {
	    'jquery-ui': { },
	    'jquery-grid': { deps: ['jquery-ui'] },
	    'formhelpers': { },
	    'dateformat': { exports: 'dateFormat' },
	    'd3': { exports: 'd3' },
	    'filestyle': { },
	    'tablesorter': { },
	    'tablesorterwidgets': { deps: ['tablesorter'] },
	    'marked' : { exports: 'marked' },
	    'underscore': { exports: '_' }
	},
    });
};

window.APT_OPTIONS.initialize = function (sup)
{
    $('body').show();
}
