#! /bin/bash

# Function called when the script fails
function die {
	if [ $? -ne 0 ]; then { echo "$1" ; exit 1; } fi
}

# Version of nginx to install
VERSION=1.9.10
# Install build environment
sudo apt-get install build-essential zlib1g-dev libpcre3-dev libssl-dev unzip libssl-dev libxslt1-dev libxml2-dev libgd2-xpm-dev libgeoip-dev libgoogle-perftools-dev libperl-dev curl chkconfig -y;
# Remove apt-version of nginx
sudo apt-get remove --purge nginx* -y;
# Stop Nginx if it is installed from source.
sudo service nginx stop;
# Get nginx init script
curl -o /tmp/nginx-init.zip https://codeload.github.com/Fleshgrinder/nginx-sysvinit-script/zip/master &&  unzip -o /tmp/nginx-init.zip && rm -rf /tmp/nginx-init.zip;
# Get Nginx Source
cd /tmp; curl http://nginx.org/download/nginx-$VERSION.tar.gz | tar xvz;
# Move into nginx src directory.
cd /tmp/nginx-$VERSION;
# Configure with the module path
./configure --user=nginx --group=nginx --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --without-http_scgi_module --without-http_uwsgi_module --with-http_gzip_static_module --with-pcre-jit --with-http_ssl_module --with-pcre --with-file-aio --with-http_realip_module --with-http_v2_module;
# Exit if configure failed
die "Failed, at configure aborting...";
# Compile nginx
make;
# Exit if make failed
die "Failed, at make aborting...";
# Install Nginx
sudo make install;
# Exit if install failed
die "Failed, at make install aborting...";
# Add the nginx user if it does not already exist
sudo id -u nginx &>/dev/null || sudo useradd -r nginx;
# Install NGINX init script
cd /tmp/nginx-sysvinit-script;
sudo make;
# exit if it fails while installing init script
die "Failed, at make init script aborting...";
# Have chkconfig monitor nginx's config file
sudo chkconfig --add nginx;
sudo chkconfig --level 345 nginx on;
# Verify
nginx -v;
sudo service nginx start;
sudo service nginx status;
## Cleanup
sudo rm -rf /tmp/nginx-$VERSION;
sudo rm -rf /tmp/nginx-sysvinit-script;
