# Building AlmaLinux RootFS

This folder contains AlmaLinux KickStart file used to rootfs.tar.gz  required for WSL. KickStart file will help to bugfix/customize/enhancements.

## Build Requirements

Kickstart files can build in AlmaLinux desktop environemnt or using AlmaLinux docker utility `almalinux/ks2rootfs`.

### Using AlmaLinux Desktop/Workstation/Server

You need an **AlmaLinux system** with following RPM packages installed to run the `build.sh` script in a terminal window to create `rootfs` file in `result` folder.

* anaconda-tui
* lorax
* subscription-manager (make sure the `rhsm` service is running, see [rhbz#1872902](https://bugzilla.redhat.com/show_bug.cgi?id=1872902))

### Using ks2rootfs utility in container

This approach can be used in `Windows`, `Mac` or any `Linux` system which has `docker` or `podman` command line installed configured. Issue following command to use `almalinux/ks2rootfs` container to build `rootfs` file in container environment.

Unix/Linux environment support multi line command support, issue following command to build.

```sh
docker run --rm --privileged -v "$PWD:/build:z" \
    -e BUILD_KICKSTART=kickstart/almalinux-8-wsl.ks \
    -e BUILD_ROOTFS=almalinux-8-wsl.x86_64.tar.gz \
    -e BUILD_OUTDIR=result \
    -e BUILD_COMPTYPE gzip \
    almalinux/ks2rootfs
```
