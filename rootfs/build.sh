#!/bin/bash
# description: AlmaLinux base image rootfs for WSL use 
# license: MIT.

set -euo pipefail

RELEASE_VER='8'
IMAGE_NAME="almalinux-${RELEASE_VER}-wsl.tar.gz"
KS_PATH="./kickstart/almalinux-${RELEASE_VER}-wsl.ks"
OUTPUT_DIR="./result"


if [[ -d "${OUTPUT_DIR}" ]]; then
    echo "Output directory ${OUTPUT_DIR} already exists, please remove it"
    exit 1
fi


livemedia-creator --no-virt --make-tar --ks "${KS_PATH}" \
                  --image-name="${IMAGE_NAME}" \
                  --project "AlmaLinux OS ${RELEASE_VER} WSL" \
                  --releasever "${RELEASE_VER}" \
                  --resultdir "${OUTPUT_DIR}" \
                  --compression gzip
