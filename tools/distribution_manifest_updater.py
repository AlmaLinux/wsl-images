# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "requests<3",
# ]
# ///
from json import dump
from logging import INFO, basicConfig, getLogger
from pathlib import Path
from sys import stdout

from requests import HTTPError, get

GITHUB_ORG = 'AlmaLinux'
GITHUB_REPO = 'wsl-images'
DISTRIBUTION_MANIFEST_UPSTREAM = 'https://raw.githubusercontent.com/microsoft/WSL/refs/heads/master/distributions/DistributionInfo.json'
DISTROS = {
    'AlmaLinux-8': 'AlmaLinux OS 8',
    'AlmaLinux-9': 'AlmaLinux OS 9',
    'AlmaLinux-10': 'AlmaLinux OS 10',
    'AlmaLinux-Kitten-10': 'AlmaLinux OS Kitten 10',
}

logger = getLogger(__name__)


def configure_logging():
    """Configure logging.

    Configure standard output (stdout) for logging output.
    """
    basicConfig(level=INFO, stream=stdout)
    return logger


def get_releases(gh_org, gh_repo):
    """Gets releases from a GitHub repository.

    Uses GitHub REST API to retrieve GitHub releases.
    Checks for available versions of GitHub REST API,
    gives a warning when the used version (gh_api_version)
    is not latest anymore.
    When a new version of GitHub REST API is available,
    HTTP status code 400 will be returned after the support for
    the old version ends. Which is 24 months after a new version is released.

    :param gh_org: Name of a GitHub organization.
    :type gh_org: str
    :param gh_repo: Name of a GitHub repository.
    :type gh_repo: str
    :raises HTTPError: If GitHub REST API version is depreciated.
    :returns: GitHub releases.
    :rtype: dict
    """
    gh_api = 'https://api.github.com'
    gh_api_version = '2022-11-28'
    gh_api_headers = {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': f'{gh_api_version}',
    }
    gh_api_releases = f'{gh_api}/repos/{gh_org}/{gh_repo}/releases'

    try:
        gh_api_versions_response = get(f'{gh_api}/versions', headers=gh_api_headers)
        gh_api_versions_response.raise_for_status()
        gh_api_versions = gh_api_versions_response.json()

        # Handle different possible response structures
        current_version = None
        if isinstance(gh_api_versions, list) and len(gh_api_versions) > 0:
            # If it's a list, get the first element
            current_version = gh_api_versions[0]
        elif isinstance(gh_api_versions, dict):
            # If it's a dict, try common keys for current/latest version
            current_version = gh_api_versions.get('current') or gh_api_versions.get('latest') or gh_api_versions.get('default')

        if current_version and current_version != gh_api_version:
            logger.warning(
                f'A new version of the GitHub REST API is available: {current_version}. '
                f'Currently using: {gh_api_version}. Please update to the new version.'
            )
    except (HTTPError, KeyError, TypeError) as e:
        logger.warning(f'Could not check GitHub API version: {e}. Continuing with current version: {gh_api_version}')

    try:
        response_releases = get(
            gh_api_releases,
            headers=gh_api_headers,
        )
        response_releases.raise_for_status()
        return response_releases.json()

    except HTTPError as http_error:
        if http_error.response.status_code == 400:
            logger.exception(
                f'The GitHub REST API version {gh_api_version} is deprecated.'
            )


def get_releases_by_distro(distro_friendly_name, releases):
    """Get GitHub releases for a distribution.

    :param distro_friendly_name: Friendly name of a distro, e.g., AlmaLinux OS 10.
    :type distro_friendly_name: str
    :param releases: GitHub releases for a repository.
    :type releases: dict
    :returns: Distro specific version of GitHub releases.
    :rtype: list
    """
    distro_releases = [
        release
        for release in releases
        if release['name'].startswith(distro_friendly_name)
    ]
    return distro_releases


def get_latest_release(release_distro):
    """Get the latest GitHub release

    The order of releases that are returned by GitHub REST API
    is descending by date. Which means the first release is the latest.

    :param release_distro: GitHub releases of a distro.
    :type release_distro: list
    :returns: The latest GitHub release of a distro.
    :rtype: dict
    """
    return release_distro[0]


def get_release_assets_by_distro(distro_name, distro_release):
    """Get assets from a distro specific GitHub release

    :param distro_name: Name of a distro.
    :type distro_name: str
    :param distro_release: GitHub release of a distro.
    :type distro_release: dict
    :returns: Assets of a GitHub release.
    :rtype: dict
    """
    x64_image_url = ''
    x64_image_checksum = ''
    arm64_image_url = ''
    arm64_image_checksum = ''

    for asset in distro_release['assets']:
        if 'x64' in asset['name']:
            if asset['name'].endswith('.wsl'):
                x64_image_url = asset['browser_download_url']
            elif asset['name'].endswith('.wsl.sha256sum'):
                x64_image_checksum = get(asset['browser_download_url']).text.partition(
                    ' '
                )[0]
        elif 'ARM64' in asset['name']:
            if asset['name'].endswith('.wsl'):
                arm64_image_url = asset['browser_download_url']
            elif asset['name'].endswith('.wsl.sha256sum'):
                arm64_image_checksum = get(
                    asset['browser_download_url']
                ).text.partition(' ')[0]

    distro_release_assets = {
        'distro': distro_name,
        'image_url_x64': x64_image_url,
        'image_checksum_x64': x64_image_checksum,
        'image_url_arm64': arm64_image_url,
        'image_checksum_arm64': arm64_image_checksum,
    }

    return distro_release_assets


def generate_distribution_manifest(distro_assets):
    """Generate distribution manifest

    :param distro_assets: Assets of a distro.
    :type distro_assets: list
    :returns: Distribution manifest.
    :rtype: dict
    """
    distribution_manifest = get(DISTRIBUTION_MANIFEST_UPSTREAM).json()

    for distribution in distribution_manifest['ModernDistributions']['AlmaLinux']:
        for distro_asset in distro_assets:
            if distribution['Name'] == distro_asset['distro']:
                distribution['Amd64Url']['Url'] = distro_asset['image_url_x64']
                distribution['Amd64Url']['Sha256'] = distro_asset['image_checksum_x64']
                distribution['Arm64Url']['Url'] = distro_asset['image_url_arm64']
                distribution['Arm64Url']['Sha256'] = distro_asset[
                    'image_checksum_arm64'
                ]
    return distribution_manifest


def create_distribution_manifest_file(distribution_manifest):
    """Write a distribution manifest into a file after serializing it as a JSON.

    :param distribution_manifest: Distribution manifest.
    :type distribution_manifest: dict
    """
    distribution_manifest_path = (
        Path(__name__).parent / 'DistributionInfo_generated.json'
    )

    with distribution_manifest_path.open('w') as file:
        dump(distribution_manifest, file, indent=4)
        file.write('\n')

    logger.info(
        f'The Distribution manifest created on: {distribution_manifest_path.resolve()}'
    )


def main():
    log = configure_logging()
    releases = get_releases(GITHUB_ORG, GITHUB_REPO)
    distro_assets = []

    log.info('The new distribution manifest will be created with these release assets')

    for distro_name, distro_friendly_name in DISTROS.items():
        distro_releases = get_releases_by_distro(distro_friendly_name, releases)
        distro_release_latest = get_latest_release(distro_releases)
        distro_release_assets = get_release_assets_by_distro(
            distro_name, distro_release_latest
        )

        log.info(
            f'{distro_friendly_name} Image URL (x64): {distro_release_assets["image_url_x64"]}'
        )
        log.info(
            f'{distro_friendly_name} Image Checksum (x64): {distro_release_assets["image_checksum_x64"]}'
        )
        log.info(
            f'{distro_friendly_name} Image URL (ARM64): {distro_release_assets["image_url_arm64"]}'
        )
        log.info(
            f'{distro_friendly_name} Image Checksum (ARM64): {distro_release_assets["image_checksum_arm64"]}'
        )

        distro_assets.append(distro_release_assets)

    distribution_manifest = generate_distribution_manifest(distro_assets)
    create_distribution_manifest_file(distribution_manifest)


if __name__ == '__main__':
    main()
