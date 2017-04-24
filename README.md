# To Install:

### Stable (1.12.0) with HTTP/2

```shell
curl -sL https://raw.githubusercontent.com/MelonSmasher/NginxInstaller/master/nginx-install.sh | bash -s -- -a
```

### Mainline (1.11.13) with HTTP/2

```shell
curl -sL https://raw.githubusercontent.com/MelonSmasher/NginxInstaller/master/nginx-install.sh | bash -s -- -x -a
```

#### Options:

* -x `Install Mainline instead of Stable`
* -m `Compile with Mail module`
* -v `Compile with VTS module` [more info](https://github.com/vozlt/nginx-module-vts)
* -a `Compile with ALPN support` - (Need this for HTTP2/SPDY)
* -g `Compile with GEO IP module`
* -p `Compile with PageSpeed module` [more info](https://developers.google.com/speed/pagespeed/)
* -c `Compile with CachePurge module` [more info](https://github.com/FRiCKLE/ngx_cache_purge)
* -l `Compile with LDAP auth module` [more info](https://github.com/kvspb/nginx-auth-ldap)
* -f `Force the installation even if the correct version is installed.`
