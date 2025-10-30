# How to build AlmaLinux OS Windows Subsystem for Linux images

## WSL format (`.wsl`)

Shell scripts and configuration files are stored on `rootfs` to build RootFS in `.wsl` format.

### Requirements
- [Buildah](https://github.com/containers/buildah/blob/main/install.md)
- [jq](https://jqlang.org/download/)

## Build

Each distro and major version has own builder scripts. Each scripts has these positional parameters:
- `minor_version`: Minor version of AlmaLinux OS 10. By default it's set to latest (e.g. 0 for 10.0).
- `build_number`: The build number of the version. Default value is the `0` as a first build of a version.

Example: AlmaLinux OS 10 with default minor version (`0` for `10.0`) and build number (e.g. `20250801.0`).

With default values.

```sh
bash -x rootfs/almalinux_10_x64.sh
```

With custom values for AlmaLinux OS 10.1.

```sh
# bash -x rootfs/almalinux_10_x64.sh minor_version build_number
bash -x rootfs/almalinux_10_x64.sh 1 0
```

Output: `AlmaLinux-10."${minor_version}"_x64_"${build_version}".wsl`

## Install

```sh
wsl --install --from-file $IMAGE
```

## Microsoft App (legacy)

### Requirements

1. Use [WinGet](https://github.com/microsoft/winget-cli) as a package manager to install build tools. Please, consult to the official [documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget) for the installation guide.

2. Install Visual Studio Community 2022 with [Desktop development with C++](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2022&preserve-view=true#desktop-development-with-c) workload.

```powershell
winget install --id Microsoft.VisualStudio.2022.Community --override '--wait --includeRecommended --includeOptional --add Microsoft.VisualStudio.Workload.Universal'
```

On the component selection, Universal workload will be checked. Click on "Install" to finish the installation. After the installation, Visual Studio will be open. Close the Visual Studio and Visual Studio Installer to finish the installation process.


## Build

1. Use the build scripts inside the `rootfs` directory to create tarballs of root filesystems.
2. Copy RootFS tarballs into `x64` and `ARM64` directories and rename to `install.tar.gz` i.e. `apps/9/x64/install.tar.gz` and `apps/9/ARM64/install.tar.gz`.
3. Generate a self-signed certificate via Visual Studio or command line.

```powershell
$params = @{
  TextExtension = @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
  KeyUsage = 'DigitalSignature'
  KeyLength = 4096
  KeyAlgorithm = 'RSA'
  Type = 'Custom'
  Subject = 'CN=AlmaLinux OS, O=AlmaLinux OS Foundation, C=US'
  FriendlyName = 'AlmaLinux OS WSL'
  HashAlgorithm = 'SHA256'
  CertStoreLocation = 'Cert:\CurrentUser\My'
}
New-SelfSignedCertificate @params
```

4. Right click on the AlmaLinux-8/9 project > Publish > Create package for side-loading.

## Testing

1. Activate Developer Mode https://learn.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development#activate-developer-mode
to able to install apps outside of Microsoft Store.

2. Right click on the file with the `AppxBundle` and import the digital signature which we created to sign the application: Install Certificate > Local Machine > Place all certificates in the following store > Trusted People

3. Now it is ready to install with double click.

## Extras

Additional tools might be useful.
```powershell
winget upgrade --all
winget install Microsoft.PowerShell Microsoft.WindowsTerminal Microsoft.OpenSSH.Beta Git.Git cURL.cURL jqlang.jq Neovim.Neovim
```
