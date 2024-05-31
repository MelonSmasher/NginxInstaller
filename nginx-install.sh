#! /bin/bash

# NGINX Versions
STABLE="1.26.1"
MAINLINE="1.27.0"
# OpenSSL Version for ALPN
OPENSSL_VERSION='openssl-1.0.2u'
# Default Flag Values
INSTALL_MAINLINE=false
INSTALL_MAIL=false
INSTALL_VTS=false
ALPN_SUPPORT=false
GEOP_IP_SUPPORT=false
LDAP_AUTH_SUPPORT=false
PAGESPEED_SUPPORT=false
CACHE_PURGE_SUPPORT=false
FORCE_INSTALL=false
BULD_DIR='/usr/local/src/Nginx_Installation_Files'
VERSION_TO_INSTALL=$STABLE
ARGUMENT_STR='--user=nginx --group=nginx --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_gzip_static_module --with-pcre-jit --with-http_ssl_module --with-pcre --with-file-aio --with-http_realip_module --with-http_v2_module --with-http_stub_status_module --with-http_sub_module --with-stream --with-stream_ssl_module ';
YUM_PACKAGES='openssl-devel libxml2-devel libxslt-devel gd gcc-c++ make perl-ExtUtils-Embed zlib-devel pcre-devel curl unzip ';
APT_PACKAGES='build-essential zlib1g-dev libpcre3 libpcre3-dev libssl-dev libssl-dev libxslt1-dev libxml2-dev pcre2-utils libgoogle-perftools-dev libperl-dev curl unzip atool ';

# Function called when the script fails
function die {
	if [ $? -ne 0 ]; then { echo "$1" ; exit 1; } fi
}

function init_tmp {
	# Crerate Temp installer dir
	sudo mkdir -p $BULD_DIR;
}

function cleanup_tmp {
	# Cleanup Temp installer dir
	sudo rm -rf $BULD_DIR;
}

function mk_confd {
	# Make the conf.d dir in /etc/nginx
	sudo mkdir -p /etc/nginx/conf.d;
}

function prep_args {
	# If we are installing the mail module add the
	if $INSTALL_MAIL;
		then ARGUMENT_STR=$ARGUMENT_STR'--with-mail --with-mail_ssl_module ';
	fi
	# Should we enable GEO IP support
	if $GEOP_IP_SUPPORT; then
		ARGUMENT_STR=$ARGUMENT_STR'--with-http_geoip_module ';
		YUM_PACKAGES=$YUM_PACKAGES'GeoIP-devel GeoIP ';
		APT_PACKAGES=$APT_PACKAGES'libgeoip-dev ';
	fi
	# If we are installing page speed support add it to the build options
	if $PAGESPEED_SUPPORT; then
		ARGUMENT_STR=$ARGUMENT_STR'--add-module='$BULD_DIR'/ngx_pagespeed-latest-stable ';
	fi
	# If we are building with the cache purge module add it here
	if $CACHE_PURGE_SUPPORT; then
		ARGUMENT_STR=$ARGUMENT_STR'--add-module='$BULD_DIR'/ngx_cache_purge-master ';
	fi
	# IF we are to install the VTS add it to the argument string
	# https://github.com/vozlt/nginx-module-vts
	if $INSTALL_VTS; then
		ARGUMENT_STR=$ARGUMENT_STR'--add-module='$BULD_DIR'/nginx-module-vts-master ';
	fi
	# If wee need ALPN add ssl argument
	if $ALPN_SUPPORT; then
		ARGUMENT_STR=$ARGUMENT_STR'--with-openssl='$BULD_DIR'/'$OPENSSL_VERSION' ';
	fi
	# ADD LDAP module arguments
	if $LDAP_AUTH_SUPPORT; then
		ARGUMENT_STR=$ARGUMENT_STR'--add-module='$BULD_DIR'/nginx-auth-ldap-master ';
		YUM_PACKAGES=$YUM_PACKAGES'openldap-devel openldap openldap-clients ';
		APT_PACKAGES=$APT_PACKAGES'libldap2-dev openldap ';
	fi
}

function prep_modules {
	# IF we are to install the VTS module download it
	# https://github.com/vozlt/nginx-module-vts
	if $INSTALL_VTS; then
		cd $BULD_DIR;
		curl -o nginx-vts-module.tar.gz https://codeload.github.com/vozlt/nginx-module-vts/tar.gz/master;
		tar -zxvf nginx-vts-module.tar.gz -C $BULD_DIR;
		rm nginx-vts-module.tar.gz;
	fi
	# Download OpenSSL
	if $ALPN_SUPPORT; then
		cd $BULD_DIR;
		curl -o $OPENSSL_VERSION'.tar.gz' 'https://www.openssl.org/source/old/1.0.2/'$OPENSSL_VERSION'.tar.gz';
		tar -zxvf $OPENSSL_VERSION'.tar.gz' -C $BULD_DIR;
		rm $OPENSSL_VERSION'.tar.gz';
	fi
	# Download LDAP auth module
	if $LDAP_AUTH_SUPPORT; then
		cd $BULD_DIR;
		curl -o nginx-auth-ldap.tar.gz https://codeload.github.com/kvspb/nginx-auth-ldap/tar.gz/master;
		tar -zxvf  nginx-auth-ldap.tar.gz -C $BULD_DIR;
		rm nginx-auth-ldap.tar.gz;
	fi
	# Download the PageSpeed module source
	if $PAGESPEED_SUPPORT; then
		cd $BULD_DIR;
		curl -o pagespeed-latest.tar.gz https://codeload.github.com/pagespeed/ngx_pagespeed/tar.gz/latest-stable;
		tar -zxvf pagespeed-latest.tar.gz -C $BULD_DIR;
		rm pagespeed-latest.tar.gz;
		cd $BULD_DIR/ngx_pagespeed-latest-stable;
		PSOL_URL=$(cat PSOL_BINARY_URL | sed 's/$BIT_SIZE_NAME/x64/');
		wget -O psol.tar.gz $PSOL_URL;
		tar -xzvf psol.tar.gz;
		rm psol.tar.gz;
	fi
	# Download the CachePurge module
	if $CACHE_PURGE_SUPPORT; then
		cd $BULD_DIR;
		curl -o ngx_cache_purge.tar.gz https://codeload.github.com/nginx-modules/ngx_cache_purge/tar.gz/master;
		tar -zxvf  ngx_cache_purge.tar.gz -C $BULD_DIR;
		rm ngx_cache_purge.tar.gz;
	fi
}

function download_build_nginx {
	# Get Nginx Source
	cd $BULD_DIR; curl http://nginx.org/download/nginx-$VERSION_TO_INSTALL.tar.gz | tar xvz;
	# Move into nginx src directory.
	cd $BULD_DIR/nginx-$VERSION_TO_INSTALL;
	# Configure with the module path
	./configure $ARGUMENT_STR;
	# Exit if configure failed
	die "Failed, at configure aborting...";
	# Compile nginx
	make;
	# Exit if make failed
	die "Failed, at make aborting...";
	# Stop Nginx if it is installed from source.
	sudo service nginx stop;
	# Install Nginx
	sudo make install;
	# Exit if install failed
	die "Failed, at make install aborting...";
	# Add the nginx user if it does not already exist
	sudo id -u nginx &>/dev/null || sudo useradd -r nginx;
}

function verify_nginx {
	# Have chkconfig monitor nginx's config file
	sudo chkconfig --add nginx
	sudo chkconfig --level 345 nginx on
	# Verify
	nginx -v;
	sudo service nginx start;
	sudo service nginx status;
}

# This function is for debian based systems
function debian_install {
	# Update apt cache
	sudo apt-get update;
	# Install build environment
	sudo apt-get install -y $APT_PACKAGES;
	# Remove apt-version of nginx
	sudo apt-get remove --purge nginx nginx-* -y;
	# Get nginx init script
	cd $BULD_DIR; curl -o nginx-sysvinit-script.zip https://codeload.github.com/Fleshgrinder/nginx-sysvinit-script/zip/master && aunpack nginx-sysvinit-script.zip; rm nginx-sysvinit-script.zip;
	# Gather Modules to be installed
	prep_modules;
	# Get Nginx and build it
	download_build_nginx;
	# Install NGINX init script
	cd $BULD_DIR/nginx-sysvinit-script-master; sudo make;
	# exit if it fails while installing init script
	die "Failed, at make init script aborting...";
	# Verify nginx
	verify_nginx;
}

# This function is for Red Hat based systems
function rhel_install {
	# Install dev tools group
	sudo yum -y groupinstall 'Development Tools';
	# Install build environment
	sudo yum -y install $YUM_PACKAGES;
	# Gather Modules to be installed
	prep_modules;
	# Get Nginx and build it
	download_build_nginx;
	# Download RHEL/Centos init script
	cd $BULD_DIR; curl -o rhel-init.sh https://raw.githubusercontent.com/MelonSmasher/NginxInstaller/master/support/init-rhel.sh;
	# Move the init script in place
	sudo mv rhel-init.sh /etc/init.d/nginx;
	# exit if it fails while installing init script
	die "Failed, to put init script in place.";
	# Make init script executable
	sudo chmod +x /etc/init.d/nginx;
	# exit if it fails while installing init script
	die "Failed, make init script executable.";
	# Verify nginx
	verify_nginx;
	# Configure firewall
	sudo firewall-cmd --permanent --add-service=http;
	sudo firewall-cmd --permanent --add-service=https;
	sudo systemctl restart firewalld;
}

function begin_install {
	prep_args;
	if [ -f /etc/redhat-release ]; then
		init_tmp;
		rhel_install;
		mk_confd;
		#cleanup_tmp;
	elif [ -f /etc/debian_version ]; then
		init_tmp;
		debian_install;
		mk_confd;
		#cleanup_tmp;
	else
		echo 'Supported Distros are RHEL/Centos and Debian/Ubuntu... sorry.';
	fi
}

while getopts "xmvaglfpc" flag; do
  case "${flag}" in
    x) INSTALL_MAINLINE=true ;;
    m) INSTALL_MAIL=true ;;
    v) INSTALL_VTS=true ;;
    a) ALPN_SUPPORT=true ;;
    g) GEOP_IP_SUPPORT=true ;;
    l) LDAP_AUTH_SUPPORT=true ;;
    f) FORCE_INSTALL=true ;;
    p) PAGESPEED_SUPPORT=true ;;
    c) CACHE_PURGE_SUPPORT=true ;;
    *) echo "Unexpected option ${flag} ... ignoring" ;;
  esac
done

# If we are got the mainline flag, set that as the version to install
if $INSTALL_MAINLINE; then VERSION_TO_INSTALL=$MAINLINE; fi;
nginx -v &> /tmp/nginx_version;
NGINX_VERSION_STRING=$(cat /tmp/nginx_version);
DESIRED_VERSION_STRING="nginx version: nginx/$VERSION_TO_INSTALL";

if [  "$DESIRED_VERSION_STRING" != "$NGINX_VERSION_STRING" ]; then
	begin_install
elif $FORCE_INSTALL; then
	begin_install
fi
