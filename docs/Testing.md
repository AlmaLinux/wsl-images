# Testing of AlmaLinux OS Windows Subsystem for Linux (WSL) images
## WSL native packaging

A WSL distribution manifest file `test_manifest.json` can be created either using the `tests/generate_manifest.py` or manually editing the template files `tests/test_manifest_[8-9].json.tmpl`.

```sh
python3 tests/generate_manifest.py \
    --distro [ 8 | 9 ] \
    --amd64url $WSL_URL_X64 \
    --amd64sha256 $WSL_SHA256_X64 \
    --arm64url $WSL_URL_ARM64 \
    --arm64sha256 $WSL_SHA256_ARM64
```

To append the test manifest to [the system default](https://github.com/microsoft/WSL/blob/master/distributions/DistributionInfo.json).

```powershell
.\tests\append_manifest.ps1 .\tests\test_manifest.json
```

Now, new distributions should be listed.

```powershell
wsl --list --online
```

The URLs of WSL files will be used to download and compared with the SHA256 checksums which are defined on the `test_manifest.json` during the installation.

```powershell
wsl --install [ AlmaLinux-8 | AlmaLinux-9 ]
```

You can delete this from the Registry for deleting the appended manifest file.
```powershell
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss\DistributionListUrl
```

Terminate and delete and WSL distro.

```powershell
wsl --terminate [ AlmaLinux-8 | AlmaLinux-9 ]
wsl --unregister [ AlmaLinux-8 | AlmaLinux-9 ]
```
