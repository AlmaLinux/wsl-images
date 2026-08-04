#!/bin/bash
# Rewrite the working tree to build the WSL images from the PUNGI
# pre-release repositories (https://<arch>-pungi-<major>.almalinux.dev)
# instead of the public repositories. This allows building WSL images
# before an AlmaLinux version is publicly released. Counterpart of
# tools/pungi-repos.sh in the cloud-images repository.
#
# The rootfs build scripts (rootfs/almalinux_<major>_<arch>.sh) bootstrap
# the image with a single 'dnf --installroot' run inside the released
# quay.io/almalinuxorg/almalinux:<major> builder container, resolving
# against the container's standard repositories - there are no repository
# URLs in the scripts to substitute. Instead, the script injects exclusive
# PUNGI compose repositories into that dnf command, right after its
# --releasever option:
#
#     --disablerepo='*'
#     --repofrompath=pungi-baseos,<compose>/BaseOS/<arch>/os/
#     --repofrompath=pungi-appstream,<compose>/AppStream/<arch>/os/
#     --enablerepo='pungi-*'
#     --setopt=pungi-baseos.gpgcheck=1
#     --setopt=pungi-baseos.gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-<major>
#     --setopt=pungi-appstream.gpgcheck=1
#     --setopt=pungi-appstream.gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-<major>
#
# where <compose> is
#
#   https://<archdash>-pungi-<major>.almalinux.dev/almalinux/<major>/<arch>/latest_result_almalinux/compose
#
# with <archdash> being the arch with underscores dashed for the host name
# (x86_64 -> x86-64, x86_64_v2 -> x86-64-v2; aarch64 as-is). The script
# file name suffixes map to the repository arches as x64 -> x86_64,
# x64_v2 -> x86_64_v2, ARM64 -> aarch64.
#
# The compose packages are signed with the official AlmaLinux key of the
# major, so gpgcheck stays on: the key is read from the builder container
# (file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-<major>, shipped by its
# almalinux-gpg-keys package) and dnf imports it into the image rpmdb while
# installing, exactly as a GA build does - the PUNGI image content is
# identical to a GA build.
#
# Only the builder's dnf command line is touched - nothing is written into
# /rootfs, so the shipped image keeps the standard repositories seeded by
# the almalinux-release package (which itself comes from the compose).
#
# Intentionally NOT rewritten:
#   - AlmaLinux 8: no PUNGI hosts exist - 8 keeps building from the
#     public repositories.
#   - AlmaLinux Kitten: a rolling, stream-based OS with no releases -
#     its public repos already ARE the latest compose, so there is no
#     pre-release state to switch to. Kitten keeps its public repos.
#
# The script is idempotent: scripts already carrying the pungi-baseos
# repository are skipped, so a second run is a no-op. No arguments.

set -euo pipefail

cd "$(dirname "$0")/.."

MAJORS=(9 10)
SUFFIXES=(x64 x64_v2 ARM64)

repo_arch() {
    # Script file name suffix -> repository arch
    case "$1" in
        x64) echo x86_64 ;;
        x64_v2) echo x86_64_v2 ;;
        ARM64) echo aarch64 ;;
        *) echo "[Error] Unknown script suffix: $1" >&2; exit 1 ;;
    esac
}

arch_dash() {
    # Host names dash the underscores: x86_64 -> x86-64, x86_64_v2 -> x86-64-v2
    echo "${1//_/-}"
}

echo "[Info] Rewriting the rootfs build scripts to PUNGI repositories (AlmaLinux 9/10; 8 and Kitten stay on their public repos)"
for major in "${MAJORS[@]}"; do
    for suffix in "${SUFFIXES[@]}"; do
        f="rootfs/almalinux_${major}_${suffix}.sh"
        [ -e "${f}" ] || continue
        grep -q 'pungi-baseos' "${f}" && continue

        if ! grep -qE "^[[:space:]]*--releasever=${major} \\\\$" "${f}"; then
            echo "[Error] ${f} has no '--releasever=${major}' dnf option, cannot inject the PUNGI repositories"
            exit 1
        fi

        arch=$(repo_arch "${suffix}")
        base="https://$(arch_dash "${arch}")-pungi-${major}.almalinux.dev/almalinux/${major}/${arch}/latest_result_almalinux/compose"

        inj=$(mktemp)
        cat > "${inj}" <<EOF
    --disablerepo='*' \\
    --repofrompath=pungi-baseos,${base}/BaseOS/${arch}/os/ \\
    --repofrompath=pungi-appstream,${base}/AppStream/${arch}/os/ \\
    --enablerepo='pungi-*' \\
    --setopt=pungi-baseos.gpgcheck=1 \\
    --setopt=pungi-baseos.gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-${major} \\
    --setopt=pungi-appstream.gpgcheck=1 \\
    --setopt=pungi-appstream.gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-${major} \\
EOF
        awk -v ins="${inj}" '
            { print }
            /^[[:space:]]*--releasever=/ && !repos_done {
                while ((getline line < ins) > 0) print line
                close(ins)
                repos_done = 1
            }
        ' "${f}" > "${f}.pungi.tmp" && mv "${f}.pungi.tmp" "${f}"
        rm -f "${inj}"
        echo "[Info]   rewritten: ${f}"
    done
done

# Verify every 9/10 rootfs script now installs from the PUNGI compose.
for major in "${MAJORS[@]}"; do
    for suffix in "${SUFFIXES[@]}"; do
        f="rootfs/almalinux_${major}_${suffix}.sh"
        [ -e "${f}" ] || continue
        if ! grep -q 'pungi-baseos' "${f}"; then
            echo "[Error] ${f} still installs from the public repositories after the PUNGI rewrite"
            exit 1
        fi
    done
done

echo "[Info] PUNGI rewrite complete"
