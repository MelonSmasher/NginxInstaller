# To Install:

### Stable (1.10.2) with HTTP/2

```shell
curl -sL https://raw.githubusercontent.com/MelonSmasher/NginxInstaller/master/nginx-install.sh | bash -s --
```

### Mainline (1.11.5) with HTTP/2

```shell
curl -sL https://raw.githubusercontent.com/MelonSmasher/NginxInstaller/master/nginx-install.sh | bash -s -- -x
```

#### Options:

* -x `Install Mainline instead of stable`
* -m `Install Mail module`
* -v `Install VTS module` [more info](https://github.com/vozlt/nginx-module-vts)
