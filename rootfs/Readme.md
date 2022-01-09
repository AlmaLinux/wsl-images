# Building AlmaLinux RootFS

Creating `rootfs` requires two steps. First create create docker image. Next generate `rootfs` from the docker image.

### Build commands

```sh
$ docker build -t srbala/wsl:alma-amd64 .  
$ ./gen-rootfs srbala/wsl:alma-amd64 alma_amd64
```
### Docker image  build log

```log
[+] Building 111.2s (11/11) FINISHED
 => [internal] load build definition from Dockerfile                                                                                              0.0s 
 => => transferring dockerfile: 3.11kB                                                                                                            0.0s 
 => [internal] load .dockerignore                                                                                                                 0.0s 
 => => transferring context: 2B                                                                                                                   0.0s 
 => [internal] load metadata for docker.io/library/almalinux:latest                                                                              12.5s 
 => CACHED [system-build 1/3] FROM docker.io/library/almalinux@sha256:08042694fffd61e6a0b3a22dadba207c8937977915ff6b1879ad744fd6638837            0.0s 
 => [internal] load build context                                                                                                                 0.0s 
 => => transferring context: 296B                                                                                                                 0.0s 
 => [system-build 2/3] RUN mkdir -p /mnt/sys-root;     dnf install --installroot /mnt/sys-root --releasever 8 --setopt install_weak_deps=false   91.1s 
 => [system-build 3/3] COPY scripts/ /mnt/sys-root/                                                                                               0.0s 
 => [system-build2 1/2] COPY --from=system-build /mnt/sys-root/ /                                                                                 1.1s 
 => [system-build2 2/2] RUN systemctl set-default multi-user.target;     systemctl mask systemd-remount-fs.service     dev-hugepages.mount     s  0.5s 
 => [stage-2 1/1] COPY --from=system-build2 . .                                                                                                   1.1s
 => exporting to image                                                                                                                            2.2s 
 => => exporting layers                                                                                                                           2.2s 
 => => writing image sha256:ddbf50d3ee6da9490bc84a0487d8da4c39a0849865c401f1e1b3a35676a453ef                                                      0.0s 
 => => naming to docker.io/srbala/wsl:alma-amd64                                                                                                  0.0s 
```
### `install.tar.gz` build log
```log
Setting up temp work dir ...
Saving docker/container image ...
Found '1' layer(s) in image 'srbala/wsl:alma-amd64'.
Extracting rootfs 1b0173336ed42bded1656dc2b09f11fee10c5c25a5c09367032ed7bcb03e08f8/layer.tar ...
Compressing rootfs ...
Perform cleanup ...
Task complete. Output rootfs located at /c/proj/alma/wsl/rootfs/install_alma_amd64.tar.gz
```
