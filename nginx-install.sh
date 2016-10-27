#! /bin/bash

# NGINX Versions
STABLE=1.10.2
MAINLINE=1.11.5

# Default Flag Values
INSTALL_MAINLINE=false
INSTALL_MAIL=false
INSTALL_VTS=false
VERSION_TO_INSTALL=$STABLE

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

function download_build_nginx {
	cd /tmp/NginxInstaller;
	# Determine what version needs to be installed
	if $INSTALL_MAINLINE; then
		VERSION_TO_INSTALL=$MAINLINE
	fi
	# Build argument string
	ARGUMENT_STR="--user=nginx --group=nginx --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --without-http_scgi_module --without-http_uwsgi_module --with-http_gzip_static_module --with-pcre-jit --with-http_ssl_module --with-pcre --with-file-aio --with-http_realip_module --with-http_v2_module --with-http_stub_status_module "
	# If we are to install the mail modules, add them to the argument string
	if $INSTALL_MAIL; then
		ARGUMENT_STR=$ARGUMENT_STR"--with-mail --with-mail_ssl_module --with-stream "
	fi
	# IF we are to install the VTS module download it and add it to the argument string
	# https://github.com/vozlt/nginx-module-vts
	if $INSTALL_VTS; then
		cd /tmp/NginxInstaller;
		curl -o nginx-vts-module.zip https://codeload.github.com/vozlt/nginx-module-vts/zip/master && aunpack nginx-vts-module.zip; rm nginx-vts-module.zip;
		ARGUMENT_STR=$ARGUMENT_STR"--add-module=/tmp/NginxInstaller/nginx-module-vts-master "
	fi
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
	sudo apt-get install -y build-essential zlib1g-dev libpcre3-dev libssl-dev libssl-dev libxslt1-dev libxml2-dev libgd2-xpm-dev libgeoip-dev libgoogle-perftools-dev libperl-dev curl unzip atool chkconfig;
	# Remove apt-version of nginx
	sudo apt-get remove --purge nginx nginx-* -y;
	# Get nginx init script
	cd /tmp/NginxInstaller; curl -o nginx-sysvinit-script.zip https://codeload.github.com/Fleshgrinder/nginx-sysvinit-script/zip/master && aunpack nginx-sysvinit-script.zip; rm nginx-sysvinit-script.zip;
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
	# Install build environment
	sudo yum -y install gcc gcc-c++ make zlib-devel pcre-devel openssl-devel curl unzip;
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
	sudo firewall-cmd --permanent --add-service=http
	sudo firewall-cmd --permanent --add-service=https
	sudo systemctl restart firewalld
}

while getopts xmv: flag; do
  case "${flag}" in
    x) INSTALL_MAINLINE=true ;;
    m) INSTALL_MAIL=true ;;
    v) INSTALL_VTS=true ;;
    *) echo "Unexpected option ${flag} ... ignoring" ;;
  esac
done

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
