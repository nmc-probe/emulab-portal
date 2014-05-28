window.APT_OPTIONS = window.APT_OPTIONS || {};

window.APT_OPTIONS.configObject = {
    baseUrl: '.',
    paths: {
	'jquery-ui': 'js/lib/jquery-ui-1.10.4.custom',
	'jquery-grid':'js/lib/jquery.appendGrid-1.3.1.min',
	'formhelpers': 'js/lib/bootstrap-formhelpers',
	'dateformat': 'js/lib/date.format',
	'd3': 'js/lib/d3.v3',
	'filestyle': 'js/lib/filestyle',
	'tablesorter': 'js/lib/jquery.tablesorter.min',
	'tablesorterwidgets': 'js/lib/jquery.tablesorter.widgets.min',
	'marked': 'js/lib/marked',
	'moment': 'js/lib/moment',
	'underscore': 'js/lib/underscore-min',
	'filesize': 'js/lib/filesize.min',
	'jacks': 'https://www.emulab.net/protogeni/jacks-devel/js/jacks'
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
	'underscore': { exports: '_' },
	'filesize' : { exports: 'filesize' }
    }
};

window.APT_OPTIONS.initialize = function (sup)
{
    $('body').show();
}
