# To Install

## Stable (1.26.2) with HTTP/2

```shell
curl -sL https://raw.githubusercontent.com/MelonSmasher/NginxInstaller/master/nginx-install.sh | bash -s -- -a
```

## Mainline (1.27.1) with HTTP/2

```shell
curl -sL https://raw.githubusercontent.com/MelonSmasher/NginxInstaller/master/nginx-install.sh | bash -s -- -x -a
```

## Options

* -x `Install Mainline instead of Stable`
* -m `Compile with Mail module`
* -v `Compile with VTS module` [more info](https://github.com/vozlt/nginx-module-vts)
* -g `Compile with GEO IP module`
* -c `Compile with CachePurge module` [more info](https://github.com/nginx-modules/ngx_cache_purge)
* -l `Compile with LDAP auth module` [more info](https://github.com/kvspb/nginx-auth-ldap)
* -f `Force the installation even if the correct version is installed.`
