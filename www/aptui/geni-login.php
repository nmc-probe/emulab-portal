<?php
#
# Copyright (c) 2000-2014 University of Utah and the Flux Group.
# 
# {{{EMULAB-LICENSE
# 
# This file is part of the Emulab network testbed software.
# 
# This file is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
# 
# This file is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
# License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this file.  If not, see <http://www.gnu.org/licenses/>.
# 
# }}}
#
chdir("..");
include("defs.php3");
chdir("apt");
include("quickvm_sup.php");
$page_title = "Login";

#
# Get current user but make sure coming in on SSL.
#
RedirectSecure();
$this_user = CheckLogin($check_status);
if (0 && $CHECKLOGIN_STATUS & CHECKLOGIN_LOGGEDIN) {
    SPITUSERERROR("You are already logged in!");
}
$hash = GENHASH();

SPITHEADER(1);

# Place to hang the toplevel template.
echo "<div id='page-body'></div>\n";

echo "<script type='text/javascript'>\n";
echo "    window.HOST  = 'https://www.emulab.net';\n";
echo "    window.PATH  = '/protogeni/speaks-for/index.html';\n";
echo "    window.HASH  = '$hash';\n";
echo "    window.ID    = 'urn:publicid:IDN+emulab.net+authority+s';\n";
echo "    window.CERT  = ";
?>
'-----BEGIN CERTIFICATE-----\n' +
'MIIDoTCCAwqgAwIBAgIDAS/uMA0GCSqGSIb3DQEBBAUAMIG4MQswCQYDVQQGEwJV\n' +
'UzENMAsGA1UECBMEVXRhaDEXMBUGA1UEBxMOU2FsdCBMYWtlIENpdHkxHTAbBgNV\n' +
'BAoTFFV0YWggTmV0d29yayBUZXN0YmVkMR4wHAYDVQQLExVDZXJ0aWZpY2F0ZSBB\n' +
'dXRob3JpdHkxGDAWBgNVBAMTD2Jvc3MuZW11bGFiLm5ldDEoMCYGCSqGSIb3DQEJ\n' +
'ARYZdGVzdGJlZC1vcHNAZmx1eC51dGFoLmVkdTAeFw0xMTEwMDUxOTUxMDZaFw0x\n' +
'NzAzMjcyMDUxMDZaMIGsMQswCQYDVQQGEwJVUzENMAsGA1UECBMEVXRhaDEdMBsG\n' +
'A1UEChMUVXRhaCBOZXR3b3JrIFRlc3RiZWQxFjAUBgNVBAsTDXV0YWhlbXVsYWIu\n' +
'c2ExLTArBgNVBAMTJDJiNDM3ZmFhLWFhMDAtMTFkZC1hZDFmLTAwMTE0M2U0NTNm\n' +
'ZTEoMCYGCSqGSIb3DQEJARYZdGVzdGJlZC1vcHNAZmx1eC51dGFoLmVkdTCBnzAN\n' +
'BgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA1ayN3cGHH9hsmTgVWVjb2ZOqF8zFJ1Ew\n' +
'TFRpXVtI//wk05+Z7uunpxn/QL1F3NjdcIEToEupo1q2tRUfCc2hquLBgC5zNfut\n' +
'YD/b5ukEsF5COKHb+pYl2RZly9BVckt+ySFLnC23erKW7ILyO2fGBD/QzHZNPhdY\n' +
'/fs18iCh58cCAwEAAaOBwjCBvzAdBgNVHQ4EFgQUU2CjacFUMyUNL++CplFi++MF\n' +
'Sl0wMwYDVR0RBCwwKoYodXJuOnB1YmxpY2lkOklETitlbXVsYWIubmV0K2F1dGhv\n' +
'cml0eStzYTAPBgNVHRMBAf8EBTADAQH/MFgGCCsGAQUFBwEBBEwwSjBIBhRpg8yT\n' +
'gKiYzKjHvbGngICqrteKG4YwaHR0cHM6Ly93d3cuZW11bGFiLm5ldDoxMjM2OS9w\n' +
'cm90b2dlbmkveG1scnBjL3NhMA0GCSqGSIb3DQEBBAUAA4GBAIDXwcvEu3HJApFQ\n' +
'bQduTiHGXQ8Og/2ZIFLXHkqu4SW81RaYVbHwRFxnKHOktKm7js9wjEPo/F0tqIRT\n' +
'21x7yE7uOce/8tWNW241fVuIRyO/o/DNd/FVFyFU5WNqP6f/rzEu92iuO6zIJPBg\n' +
'fmkqRvZqMOm5R//SSNBFl83lZzlu\n' +
'-----END CERTIFICATE-----';
<?php
echo "</script>\n";
echo "<script src='$APTBASE/xml-signer/geni-auth.js'></script>\n";
echo "<script src='js/lib/jquery-2.0.3.min.js'></script>\n";
echo "<script src='js/lib/bootstrap.js'></script>\n";
echo "<script src='js/lib/require.js' data-main='js/geni-login'></script>\n";

SPITFOOTER();
?>
