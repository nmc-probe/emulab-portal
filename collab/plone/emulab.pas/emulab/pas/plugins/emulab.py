import logging
import cgi
import urllib

from Products.PluggableAuthService.plugins.BasePlugin import BasePlugin
from AccessControl.SecurityInfo import ClassSecurityInfo
from Products.PluggableAuthService.utils import classImplements
from Globals import InitializeClass
from Products.PluggableAuthService.interfaces.plugins import \
     IAuthenticationPlugin, IUserEnumerationPlugin, IExtractionPlugin
from Products.PageTemplates.PageTemplateFile import PageTemplateFile
from zope.component.hooks import getSite

logger = logging.getLogger('emulabpas')
outfile = logging.FileHandler(filename='/tmp/emulabpas.log')
logger.addHandler(outfile)
# set logging level on whatever zope configured for root logger
#logger.setLevel(logging.getLogger().level)
logger.setLevel(logging.DEBUG)

manage_addEmulabPluginForm = PageTemplateFile('../www/addEmulabPAS',
    globals(), __name__='manage_addEmulabPluginForm')

def addEmulabPlugin(self, id, title='', REQUEST=None):
    ''' Add a Emulab PAS Plugin to Plone PAS
    '''
    o = EmulabPlugin(id, title)
    self._setObject(o.getId(), o)

    if REQUEST is not None:
        REQUEST['RESPONSE'].redirect('%s/manage_main'
            '?manage_tabs_message=Emulab+PAS+Plugin+added.' %
            self.absolute_url())

class EmulabPlugin(BasePlugin):
    ''' Plugin for Emulab PAS
    '''
    meta_type = 'Emulab PAS'
    security = ClassSecurityInfo()

    def __init__(self, id, title=None):
        self._setId(id)
        self.title = title

    def extractCredentials(self, request):
        """Extract credentials from cookie or 'request'

        We try to extract credentials from the Emulab cookie here.

        """
        site = getSite();
	logger.debug("extractCredentials: " + site.id);
	
        if not hasattr(request, 'cookies'):
            logger.debug("No cookies found.")
            return {}
        cookies = request.cookies
        emulab_cookie = cookies.get('emulab_wiki')
        if not emulab_cookie:
            logger.debug("No emulab cookie found.")
            return {}
        logger.debug("extractCredentials: " + str(emulab_cookie));

        # cgi.parse_qs returns values as lists. Why?
        cookiestring = urllib.unquote_plus(emulab_cookie)
        tempdict = cgi.parse_qs(cookiestring)
        realdict = dict([(i, tempdict[i][0]) for i in tempdict])

        logger.debug(str(realdict))

        # Make sure it conforms. 
        if 'hash' not in realdict or 'user' not in realdict:
            return {}

        user_id = realdict['user']
        secret  = realdict['hash']

        logger.debug(secret)

        # If there is a user with this id, we do not authenticate
        # on this path, they have to log in normally.
        user = self._getPAS().getUserById(user_id)
        if user is not None:
            logger.debug("User '%s' exists, not doing anything.", user_id)
            return {}

        result = {}
        result['user_id'] = user_id
        result['login']   = user_id
        result['hash']    = secret
	return result

    # IAuthenticationPlugin implementation
    def authenticateCredentials(self, credentials):
        ''' Authenticate credentials against the fake external database
        '''
        extractor = credentials.get('extractor', 'none')
        if extractor != self.getId():
            return None
        
	logger.debug("authenticateCredentials")
	logger.debug(str(credentials))

        if 'hash' not in credentials or 'user_id' not in credentials:
            return None

        secret  = credentials['hash']
        user_id = credentials['user_id']

        #
        # Consult external somthing
        #
        verified = True
        
        if verified:
            return (user_id, user_id)

        return None
    pass

classImplements(EmulabPlugin, IAuthenticationPlugin, IExtractionPlugin)
InitializeClass(EmulabPlugin)
