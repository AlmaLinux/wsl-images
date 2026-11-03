#!/usr/bin/env bash
# Print the almalinux-release package version (e.g. 10.2) shipped by the
# BaseOS repository the WSL images of an AlmaLinux major are built from, read
# from the repository's repodata:
#
#   - the public repository (https://repo.almalinux.org) by default, for
#     AlmaLinux 8, 9 and 10
#   - the PUNGI pre-release compose (https://<arch>-pungi-<major>.almalinux.dev)
#     with PUNGI_REPOS=1, for AlmaLinux 9 and 10 - the majors PUNGI covers
#     (see tools/pungi-repos.sh)
#
# Usage: [PUNGI_REPOS=1] tools/almalinux-release.sh <major> [arch]
#   major: 8, 9 or 10
#   arch:  x86_64 (default), x86_64_v2 or aarch64
#
# The rootfs build scripts and the workflows derive the minor version of the
# images from this value instead of hardcoding it: the minor version names the
# images, the object storage paths and the GitHub release tag, so it has to
# agree with /etc/almalinux-release inside the images - both on a new public
# minor release and for a PUNGI build, whose compose ships the pre-release
# almalinux-release (e.g. 10.3 while the public repository still ships 10.2).

set -ueo pipefail

major="${1:?Usage: [PUNGI_REPOS=1] $0 <major> [arch]}"
arch="${2:-x86_64}"

case "${major}" in
    8|9|10) ;;
    *) echo "[Error] Unsupported AlmaLinux major '${major}' (8, 9 or 10)" >&2; exit 1 ;;
esac
case "${arch}" in
    x86_64|x86_64_v2|aarch64) ;;
    *) echo "[Error] Unsupported arch '${arch}' (x86_64, x86_64_v2 or aarch64)" >&2; exit 1 ;;
esac

if [[ "${PUNGI_REPOS:-}" == "1" ]]; then
    case "${major}" in
        9|10) ;;
        *) echo "[Error] No PUNGI compose exists for AlmaLinux ${major} (only 9 and 10)" >&2; exit 1 ;;
    esac
    # Host names dash the underscores: x86_64 -> x86-64, x86_64_v2 -> x86-64-v2
    baseos="https://${arch//_/-}-pungi-${major}.almalinux.dev/almalinux/${major}/${arch}/latest_result_almalinux/compose/BaseOS/${arch}/os"
else
    baseos="https://repo.almalinux.org/almalinux/${major}/BaseOS/${arch}/os"
fi

primary_href=$(curl -sf "${baseos}/repodata/repomd.xml" | grep -oE 'repodata/[^"]*-primary\.xml\.(gz|zst|xz)' | head -n 1) || primary_href=
if [ -z "${primary_href}" ]; then
    echo "[Error] Failed to read the BaseOS repodata (${baseos})" >&2
    exit 1
fi

case "${primary_href}" in
    *.gz) decompress="gunzip" ;;
    *.zst) decompress="zstd -dc" ;;
    *.xz) decompress="xz -dc" ;;
esac
release=$(curl -sf "${baseos}/${primary_href}" | ${decompress} \
    | python3 -c 'import re,sys; m=re.search(r"<name>almalinux-release</name>.*?ver=\"([^\"]+)\"", sys.stdin.read(), re.S); print(m.group(1) if m else "")') || release=

if [[ ! "${release}" =~ ^${major}\.[0-9]+$ ]]; then
    echo "[Error] Failed to derive the almalinux-release version from ${baseos}: '${release}'" >&2
    exit 1
fi

echo "${release}"
