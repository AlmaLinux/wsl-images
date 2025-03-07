from argparse import ArgumentParser
from json import load, dump
from pathlib import Path

parser = ArgumentParser()
parser.add_argument('--distro', choices=['8', '9', 'kitten_10'], required=True)
parser.add_argument('--amd64url', required=True)
parser.add_argument('--amd64sha256', required=True)
parser.add_argument('--arm64url', required=True)
parser.add_argument('--arm64sha256', required=True)

args = parser.parse_args()

wsl_manifest_tpl = Path(__file__).parent / f'test_manifest_{args.distro}.json.tmpl'
wsl_manifest = Path(__file__).parent / 'test_manifest.json'

with wsl_manifest_tpl.open() as f:
    wsl_manifest_decoded = load(f)

distros = wsl_manifest_decoded['ModernDistributions']['AlmaLinux']
for distro in distros:
    distro['Amd64Url']['Url'] = args.amd64url
    distro['Amd64Url']['Sha256'] = args.amd64sha256
    distro['Arm64Url']['Url'] = args.arm64url
    distro['Arm64Url']['Sha256'] = args.arm64sha256

with wsl_manifest.open(mode='w') as f:
    dump(wsl_manifest_decoded, f, indent=4)
