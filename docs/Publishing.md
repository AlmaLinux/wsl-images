# How to publish AlmaLinux OS WSL images

## Automated

### GitHub Actions

#### Build

The building workflows are divided for each distributions (AlmaLinux OS and AlmaLinux OS Kitten) and major versions (AlmaLinux OS 8, 9, 10 and AlmaLinux OS Kitten 10). The workflows can be started in two modes; [Test](#test) and [Release](#release).

##### Test

The purpose of this mode to use an object storage to store build artifacts during the development and testing.
Required inputs:
- **Release on GitHub**: `false`

##### Release

The purpose of this mode to use GitHub releases to store stable build artifacts which are used for [publishing](#publish).
Required inputs:
- **Release on GitHub**: `true`

#### Publish

The Publish with Pull Request (`publish.yaml`) workflow creates a pull request to https://github.com/microsoft/WSL with updated version of distribution manifest. Which is generated from the artifacts uploaded on [Release](#release).
