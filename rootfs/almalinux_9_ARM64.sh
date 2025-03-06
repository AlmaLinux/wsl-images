#!/usr/bin/env bash

set -ue

# Buildah version: 2:1.33.7-3.el9_4
# Podman version: 4:4.9.4-6.el9_4
# ShellCheck version: c7611dfcc6ccb320b530a4e9179e6facee96a422
# Requirements:
# - Build tools: dnf -y install @container-management jq
# - Multi architecture support: sudo podman run --rm --privileged docker.io/aptman/qus:latest -s -- -p aarch64

timestamp=$(date -u '+%Y%m%d')
build_number="${1:-0}"
build_version="${timestamp}"."${build_number}"

wsl_builder_ct=$(buildah from --platform=linux/arm64 quay.io/almalinuxorg/almalinux:9)
wsl_ct=$(buildah from --platform=linux/arm64 scratch)

buildah run "$wsl_builder_ct" -- mkdir /rootfs

buildah run "$wsl_builder_ct" -- dnf -y \
    --installroot=/rootfs \
    --releasever=9 \
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
buildah copy --chmod 0644 "$wsl_builder_ct" rootfs/locale.conf /rootfs/etc/locale.conf

# Apply WSL configuration
buildah copy --chmod 0644 "$wsl_builder_ct" rootfs/wsl.conf /rootfs/etc/wsl.conf

# Copy files for WSL native packaging format
buildah copy --chmod 0644 "$wsl_builder_ct" rootfs/wsl-distribution_9.conf /rootfs/etc/wsl-distribution.conf
buildah copy --chmod 0755 "$wsl_builder_ct" rootfs/oobe /rootfs/usr/lib/wsl/oobe
buildah copy --chmod 0644 "$wsl_builder_ct" rootfs/almalinux.ico /rootfs/usr/share/wsl/almalinux.ico
buildah copy --chmod 0644 "$wsl_builder_ct" rootfs/terminal-profile.json /rootfs/usr/share/wsl/terminal-profile.json


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

# https://learn.microsoft.com/en-us/windows/wsl/build-custom-distro#systemd-recommendations
buildah run "$wsl_ct" -- systemctl mask \
    systemd-resolved.service \
    systemd-networkd.service \
    NetworkManager.service \
    systemd-tmpfiles-setup.service \
    systemd-tmpfiles-clean.service \
    systemd-tmpfiles-clean.timer \
    systemd-tmpfiles-setup-dev-early.service \
    systemd-tmpfiles-setup-dev.service \
    tmp.mount


buildah config --cmd '/sbin/init' "$wsl_ct"
buildah config --stop-signal 'SIGRTMIN+3' "$wsl_ct"

buildah rm "$wsl_builder_ct"
wsl_img=$(buildah commit --squash --rm --manifest wsl:9 "$wsl_ct" wsl:9-ARM64)

# Extract RootFS from the container image
rm -rfv wsl_9_x64_dir && mkdir wsl_9_x64_dir

buildah push "$wsl_img" oci:wsl_9_ARM64_dir

manifest=$(jq -r '.manifests[].digest | split(":")[1]' wsl_9_ARM64_dir/index.json)

rootfs=$(jq -r '.layers[] | select(.mediaType == "application/vnd.oci.image.layer.v1.tar+gzip") | .digest | split(":")[1]' wsl_9_ARM64_dir/blobs/sha256/"$manifest")

printf 'Root filesystem: %s\n' "$rootfs"

cp -v wsl_9_ARM64_dir/blobs/sha256/"$rootfs" AlmaLinux-9_ARM64_"${build_version}".tar.gz
cp -v wsl_9_ARM64_dir/blobs/sha256/"$rootfs" AlmaLinux-9_ARM64_"${build_version}".wsl

rm -rfv wsl_9_ARM64_dir
