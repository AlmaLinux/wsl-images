#!/usr/bin/env bash

# Buildah version: 2:1.33.7-3.el9_4
# Podman version: 4:4.9.4-6.el9_4
# ShellCheck version: c7611dfcc6ccb320b530a4e9179e6facee96a422
# Requirements:
# - Build tools: dnf -y install @container-management jq


wsl_builder_ct=$(buildah from quay.io/almalinuxorg/almalinux:8)
wsl_ct=$(buildah from scratch)

buildah run "$wsl_builder_ct" -- mkdir /rootfs

buildah run "$wsl_builder_ct" -- dnf -y \
    --installroot=/rootfs \
    --releasever=8 \
    --setopt=cachedir=/var/cache/dnf \
    --setopt=logdir=/var/log \
    install \
    almalinux-release \
    glibc \
    systemd \
    filesystem \
    setup \
    langpacks-en \
    bash \
    coreutils \
    util-linux \
    rpm \
    dnf \
    crypto-policies \
    crypto-policies-scripts \
    sudo \
    iproute \
    iputils \
    dnf-plugins-core \
    hostname \
    findutils \
    file \
    ncurses \
    bash-completion \
    vim \
    nano \
    less \
    man-db \
    passwd \
    openssh-clients \
    procps-ng \
    rootfiles \
    shadow-utils \
    sudo \
    tar \
    gzip \
    bzip2 \
    xz \
    zstd \
    zip \
    curl \
    wget \
    tmux \
    jq


# Cleanup
# DNF
buildah run "$wsl_builder_ct" -- rm -rfv \
    /rootfs/var/lib/dnf/history.sqlite \
    /rootfs/var/lib/dnf/history.sqlite-shm \
    /rootfs/var/lib/dnf/history.sqlite-wal
buildah run "$wsl_builder_ct" -- rm -rfv \
    /rootfs/var/log/dnf.log \
    /rootfs/var/log/dnf.rpm.log \
    /rootfs/var/log/dnf.librepo.log

# Set en_US.UTF-8 as default locale
buildah copy --chmod 0644 "$wsl_builder_ct" locale.conf /rootfs/etc/locale.conf

# Apply WSL configuration
buildah copy --chmod 0644 "$wsl_builder_ct" wsl.conf /rootfs/etc/wsl.conf


buildah copy --from="$wsl_builder_ct" "$wsl_ct" /rootfs /


buildah run "$wsl_ct" -- systemctl mask \
    systemd-remount-fs.service \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    systemd-logind.service \
    getty.target \
    console-getty.service \
    systemd-udev-trigger.service \
    systemd-udevd.service \
    systemd-random-seed.service \
    systemd-machine-id-commit.service



buildah config --cmd '/sbin/init' "$wsl_ct"
buildah config --stop-signal 'SIGRTMIN+3' "$wsl_ct"

buildah rm "$wsl_builder_ct"
wsl_img=$(buildah commit --squash --rm --manifest wsl:8 "$wsl_ct" wsl:8-amd64)

# Extract RootFS from the container image
timestamp=$(date -u '+%Y%m%d')

rm -rfv wsl_8_amd64_dir && mkdir wsl_8_amd64_dir

buildah push "$wsl_img" oci:wsl_8_amd64_dir

manifest=$(jq -r '.manifests[].digest | split(":")[1]' wsl_8_amd64_dir/index.json)

rootfs=$(jq -r '.layers[] | select(.mediaType == "application/vnd.oci.image.layer.v1.tar+gzip") | .digest | split(":")[1]' wsl_8_amd64_dir/blobs/sha256/"$manifest")

printf 'Root filesystem: %s\n' "$rootfs"

cp -v wsl_8_amd64_dir/blobs/sha256/"$rootfs" rootfs_wsl_8_amd64_"$timestamp".tar.gz

rm -rfv wsl_8_amd64_dir
