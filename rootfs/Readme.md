# Building AlmaLinux RootFS

Building `rootfs` requires two steps. Since build step uses `docker` command, some working knowledge with docker is required.

* First create create docker image. 
* Next generate `rootfs` from the docker image.

## Build commands

Development system requires pre-installed docker. If you would like to use `podman` instead of `docker`, make sure to install `podman-docker` package which will provide necessary alias(s).

`Dockerfile` script contains `COPY` command to transfer some scripts for build process, use `rootfs` folder as current working directory.

Issue following two command to create rootfs file (assuming work environment is `x86_64`).

```sh
docker build -t almalinux/wsl:amd64 .  
./gen-rootfs almalinux/wsl:amd64 alma_amd64
```

Please refer to docker documentation to enable `buildx`, which will help to build other `arch` environment. For example, to build `aarch64` rootfs file, use following commands.

```sh
docker build --platform linux/arm64 -t almalinux/wsl:arm64 .
./gen-rootfs almalinux/wsl:arm64 alma_arm64
```

### `install.tar.gz` build log

```log
Setting up temp work dir ...
Saving docker/container image ...
Found '1' layer(s) in image 'almalinux/wsl:alma-amd64'.
Extracting rootfs 1b0173336ed42bded1656dc2b09f11fee10c5c25a5c09367032ed7bcb03e08f8/layer.tar ...
Compressing rootfs ...
Perform cleanup ...
Task complete. Output rootfs located at /c/proj/alma/wsl/rootfs/install_alma_amd64.tar.gz
```
