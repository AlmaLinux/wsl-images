# AlmaLinux OS for Windows Subsystem for Linux (WSL)

## Get started

The WSL section of AlmaLinux Wiki has a comprehensive guide which covers from installation of WSL and distributions like AlmaLinux OS to extras features like running GUI apps and Docker desktop integration: https://wiki.almalinux.org/documentation/wsl.html

## Installation

Publishing is done by creating pull requests on https://github.com/microsoft/WSL to update the distributions manifest, which is used by wsl command-line tool during the download and installation.

These images can also be downloaded from the releases section of this GitHub repository, which can be useful for offline installations via `wsl --install --from-file`.

## Documentation

The `docs` directoy is used to store documentation about how building, testing and publishing is done.
