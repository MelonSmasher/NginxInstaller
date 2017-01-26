#! /bin/bash

# NGINX Versions
STABLE="1.10.2"
MAINLINE="1.11.9"
# OpenSSL Version for ALPN
OPENSSL_VERSION='openssl-1.0.2j'
# Default Flag Values
INSTALL_MAINLINE=false
INSTALL_MAIL=false
INSTALL_VTS=false
ALPN_SUPPORT=false
GEOP_IP_SUPPORT=false
LDAP_AUTH_SUPPORT=false
FORCE_INSTALL=false
VERSION_TO_INSTALL=$STABLE
ARGUMENT_STR='--user=nginx --group=nginx --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_gzip_static_module --with-pcre-jit --with-http_ssl_module --with-pcre --with-file-aio --with-http_realip_module --with-http_v2_module --with-http_stub_status_module --with-stream ';
YUM_PACKAGES='openssl-devel libxml2-devel libxslt-devel gd perl-ExtUtils-Embed zlib-devel pcre-devel curl unzip ';
APT_PACKAGES='build-essential zlib1g-dev libpcre3-dev libssl-dev libssl-dev libxslt1-dev libxml2-dev libgd2-xpm-dev libgoogle-perftools-dev libperl-dev curl unzip atool chkconfig ';

# Function called when the script fails
function die {
	if [ $? -ne 0 ]; then { echo "$1" ; exit 1; } fi
}

function init_tmp {
	# Crerate Temp installer dir
	sudo mkdir -p /tmp/NginxInstaller;
}

function cleanup_tmp {
	# Cleanup Temp installer dir
	sudo rm -rf /tmp/NginxInstaller;
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
	# IF we are to install the VTS add it to the argument string
	# https://github.com/vozlt/nginx-module-vts
	if $INSTALL_VTS; then
		ARGUMENT_STR=$ARGUMENT_STR'--add-module=/usr/local/src/nginx-module-vts-master ';
	fi
	# If wee need ALPN add ssl argument
	if $ALPN_SUPPORT; then
		ARGUMENT_STR=$ARGUMENT_STR'--with-openssl=/usr/local/src/'$OPENSSL_VERSION' ';
	fi
	# ADD LDAP module arguments
	if $LDAP_AUTH_SUPPORT; then
		ARGUMENT_STR=$ARGUMENT_STR'--add-module=/usr/local/src/nginx-auth-ldap-master ';
		YUM_PACKAGES=$YUM_PACKAGES'openldap-devel openldap openldap-clients ';
		APT_PACKAGES=$APT_PACKAGES'libldap2-dev openldap ';
	fi
}

function prep_modules {
	cd /usr/local/src;
	# IF we are to install the VTS module download it
	# https://github.com/vozlt/nginx-module-vts
	if $INSTALL_VTS; then
		cd /usr/local/src;
		curl -o nginx-vts-module.zip https://codeload.github.com/vozlt/nginx-module-vts/zip/master;
		unzip nginx-vts-module.zip;
		rm nginx-vts-module.zip;
	fi
	# Download OpenSSL
	if $ALPN_SUPPORT; then
		cd /usr/local/src;
		curl -o $OPENSSL_VERSION'.tar.gz' 'https://www.openssl.org/source/'$OPENSSL_VERSION'.tar.gz';
		tar -zxvf $OPENSSL_VERSION'.tar.gz' -C /usr/local/src;
		rm $OPENSSL_VERSION'.tar.gz';
	fi
	# Download LDAP auth module
	if $LDAP_AUTH_SUPPORT; then
		cd /usr/local/src;
		curl -o nginx-auth-ldap.zip https://codeload.github.com/kvspb/nginx-auth-ldap/zip/master;
		unzip nginx-auth-ldap.zip;
		rm nginx-auth-ldap.zip;
	fi
}

function download_build_nginx {
	cd /tmp/NginxInstaller;
	# Get Nginx Source
	cd /tmp/NginxInstaller; curl http://nginx.org/download/nginx-$VERSION_TO_INSTALL.tar.gz | tar xvz;
	# Move into nginx src directory.
	cd /tmp/NginxInstaller/nginx-$VERSION_TO_INSTALL;
	# Configure with the module path
	./configure $ARGUMENT_STR;
	# Exit if configure failed
	die "Failed, at configure aborting...";
	# Compile nginx
	make;
	# Exit if make failed
	die "Failed, at make aborting...";
	# Stop Nginx if it is installed from source.
	sudo /etc/init.d/nginx stop;
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
	cd /tmp/NginxInstaller; curl -o nginx-sysvinit-script.zip https://codeload.github.com/Fleshgrinder/nginx-sysvinit-script/zip/master && aunpack nginx-sysvinit-script.zip; rm nginx-sysvinit-script.zip;
	# Gather Modules to be installed
	prep_modules;
	# Get Nginx and build it
	download_build_nginx;
	# Install NGINX init script
	cd /tmp/NginxInstaller/nginx-sysvinit-script-master; sudo make;
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
	cd /tmp/NginxInstaller; curl -o rhel-init.sh https://raw.githubusercontent.com/MelonSmasher/NginxInstaller/master/support/init-rhel.sh;
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
		cleanup_tmp;
	elif [ -f /etc/debian_version ]; then
		init_tmp;
		debian_install;
		cleanup_tmp;
	else
		echo 'Supported Distros are RHEL/Centos and Debian/Ubuntu... sorry.';
	fi
}

while getopts "xmvaglf" flag; do
  case "${flag}" in
    x) INSTALL_MAINLINE=true ;;
    m) INSTALL_MAIL=true ;;
    v) INSTALL_VTS=true ;;
    a) ALPN_SUPPORT=true ;;
    g) GEOP_IP_SUPPORT=true ;;
    l) LDAP_AUTH_SUPPORT=true ;;
    f) FORCE_INSTALL=true ;;
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
