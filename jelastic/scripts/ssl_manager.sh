#!/bin/bash
#  $Id$
#  $Revision$
#  $Date$
#  $Author$
#  $HeadURL$

_SED=`which sed`;
SERVER_XML_CONFIG="/etc/httpd/conf.d/ssl.conf";

function _enableSSL(){
        local default_httpd_conf="/etc/sysconfig/httpd"
        grep -q "OPENSSL_NO_DEFAULT_ZLIB" $default_httpd_conf || echo "export OPENSSL_NO_DEFAULT_ZLIB=1" >>  $default_httpd_conf;
        local err;
        doAction keystore DownloadKeys;
        err=$?; [[ ${err} -gt 0 ]] && exit ${err};
        $_SED -i 's/SSLEngine=\"off\"/SSLEnabled=\"on\"/g' $SERVER_XML_CONFIG;
        sed -i "/^#LoadModule.*ssl_module.*/ s/^#LoadModule/LoadModule/" /etc/httpd/conf/httpd.conf||  { writeJSONResponceErr "result=>4020" "message=>Cannot enable SSL module!"; return 4020; };
        sed -i "/^#LoadModule.*ssl_module.*/ s/^#LoadModule/LoadModule/" ${CARTRIDGE_HOME}/versions/2.4/httpd.conf
        service httpd restart >> /dev/null;
}

function _disableSSL(){
        local err;
        doAction keystore remove;
        err=$?; [[ ${err} -gt 0 ]] && exit ${err};
        $_SED -i 's/SSLEngine=\"on\"/SSLEnabled=\"off\"/g' $SERVER_XML_CONFIG;
        sed -i "/^LoadModule.*ssl_module.*/ s/LoadModule/#LoadModule/" /etc/httpd/conf/httpd.conf ||  { writeJSONResponceErr "result=>4021" "message=>Cannot disable SSL module!"; return 4021; };
        sed -i "/^LoadModule.*ssl_module.*/ s/LoadModule/#LoadModule/" ${CARTRIDGE_HOME}/versions/2.4/httpd.conf
        service httpd restart >> /dev/null;
}

