#!/usr/bin/env bash

set -ue

# Buildah version: 2:1.37.6-1.el9_5
# Podman version: 4:5.2.2-13.el9_5
# ShellCheck version: d3001f337aa3f7653a621b302261f4eac01890d0
# Requirements:
# - Build tools: dnf -y install @container-management jq

timestamp=$(date -u '+%Y%m%d')
# Minor version: the first argument, or - when not given - derived from the
# almalinux-release package in the BaseOS repository the image is built from
# (tools/almalinux-release.sh), so the image name agrees with
# /etc/almalinux-release inside it without hardcoding the minor version.
minor_version="${1:-}"
if [ -z "${minor_version}" ]; then
    release=$(bash "$(dirname "$0")/../tools/almalinux-release.sh" 10 x86_64_v2)
    minor_version="${release#10.}"
fi
build_number="${2:-0}"
build_version="${timestamp}"."${build_number}"
output_file=AlmaLinux-10."${minor_version}"_x64_v2_"${build_version}".wsl

wsl_builder_ct=$(buildah from --platform=linux/amd64/v2 quay.io/almalinuxorg/almalinux:10)
wsl_ct=$(buildah from scratch)

buildah run "$wsl_builder_ct" -- mkdir /rootfs

buildah run "$wsl_builder_ct" -- dnf -y \
    --installroot=/rootfs \
    --releasever=10 \
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


# Verify the installed release matches the image name. The minor version
# was derived from (or given for) one repository, while the image was just
# installed from the repository of its own arch - the two can lag behind
# each other during a release sync or a PUNGI compose cycle.
release_string=$(buildah run "$wsl_builder_ct" -- cat /rootfs/etc/almalinux-release)
if ! [[ "${release_string}" =~ ^"AlmaLinux release 10.${minor_version}"( |$) ]]; then
    echo "[Error] The image says '${release_string}', not AlmaLinux release 10.${minor_version} as its name claims" >&2
    exit 1
fi
printf 'Installed release: %s\n' "${release_string}"

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
buildah copy --chmod 0644 "$wsl_builder_ct" rootfs/wsl-distribution_10_x64_v2.conf /rootfs/etc/wsl-distribution.conf
buildah copy --chmod 0755 "$wsl_builder_ct" rootfs/oobe /rootfs/usr/lib/wsl/oobe
buildah copy --chmod 0644 "$wsl_builder_ct" rootfs/almalinux.ico /rootfs/usr/share/wsl/almalinux.ico
buildah copy --chmod 0644 "$wsl_builder_ct" rootfs/terminal-profile.json /rootfs/usr/share/wsl/terminal-profile.json


buildah copy --from="$wsl_builder_ct" "$wsl_ct" /rootfs /


# https://learn.microsoft.com/en-us/windows/wsl/build-custom-distro#systemd-recommendations
# Note: systemd-tmpfiles-* services are not masked to allow creation of runtime
# directories like /run/postgresql at boot (see issue #62)
buildah run "$wsl_ct" -- systemctl mask \
    systemd-resolved.service \
    systemd-networkd.service \
    NetworkManager.service \
    tmp.mount


buildah config --cmd '/sbin/init' "$wsl_ct"
buildah config --stop-signal 'SIGRTMIN+3' "$wsl_ct"

buildah rm "$wsl_builder_ct"
wsl_img=$(buildah commit --squash --rm --manifest wsl:10 "$wsl_ct" wsl:10-x64_v2)

# Extract RootFS from the container image
rm -rfv wsl_10_x64_v2_dir && mkdir wsl_10_x64_v2_dir

buildah push "$wsl_img" oci:wsl_10_x64_v2_dir

manifest=$(jq -r '.manifests[].digest | split(":")[1]' wsl_10_x64_v2_dir/index.json)

rootfs=$(jq -r '.layers[] | select(.mediaType == "application/vnd.oci.image.layer.v1.tar+gzip") | .digest | split(":")[1]' wsl_10_x64_v2_dir/blobs/sha256/"$manifest")

printf 'Root filesystem: %s\n' "$rootfs"

cp -v wsl_10_x64_v2_dir/blobs/sha256/"$rootfs" "$output_file"

sha256sum "$output_file" > "${output_file}".sha256sum

# Cleanup
rm -rfv wsl_10_x64_v2_dir
