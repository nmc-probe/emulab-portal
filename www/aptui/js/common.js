window.APT_OPTIONS = window.APT_OPTIONS || {};

window.APT_OPTIONS.config = function ()
{
    require.config({
	baseUrl: '.',
	paths: {
	    'jquery': 'js/lib/jquery-2.0.3.min',
	    'jquery-ui': 'jquery-ui/js/jquery-ui-1.10.4.custom',
	    'jquery-grid':'jquery.appendGrid/js/jquery.appendGrid-1.3.1.min',
	    'bootstrap': 'bootstrap/js/bootstrap',
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
	    'bootstrap': { deps: ['jquery'] },
	    'jquery-ui': { deps: ['jquery'] },
	    'jquery-grid': { deps: ['jquery-ui'] },
	    'formhelpers': { deps: ['bootstrap']},
	    'dateformat': { exports: 'dateFormat' },
	    'd3': { exports: 'd3' },
	    'filestyle': { deps: ['bootstrap']},
	    'tablesorter': { deps: ['jquery'] },
	    'tablesorterwidgets': { deps: ['tablesorter'] },
	    'marked' : { exports: 'marked' },
	    'underscore': { exports: '_' }
	},
    });
};

window.APT_OPTIONS.configNoQuery = function ()
{
    require.config({
	baseUrl: '.',
	paths: {
	    'jquery': 'js/lib/jquery-2.0.3.min',
	    'jquery-ui': 'jquery-ui/js/jquery-ui-1.10.4.custom',
	    'jquery-grid':'jquery.appendGrid/js/jquery.appendGrid-1.3.1.min',
	    'bootstrap': 'bootstrap/js/bootstrap',
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
	    'bootstrap': { },
	    'jquery-ui': { },
	    'jquery-grid': { deps: ['jquery-ui'] },
	    'formhelpers': { deps: ['bootstrap']},
	    'dateformat': { exports: 'dateFormat' },
	    'd3': { exports: 'd3' },
	    'filestyle': { deps: ['bootstrap']},
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
