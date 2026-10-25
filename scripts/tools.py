"""Install checksum-pinned repository tools without modifying a user's PATH.

`python3 scripts/tools.py ensure NAME` prints the path to the pinned binary, or
nothing when this host is not pinned (an Intel Mac, say), so the caller falls
back to a PATH install. Versions, URLs and hashes live in
`.github/infra-tools.json`; bump them there, together.
"""
import hashlib
import io
import json
import platform
import sys
import tarfile
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _key():
    machine = {'x86_64': 'amd64', 'amd64': 'amd64', 'aarch64': 'arm64', 'arm64': 'arm64'}.get(platform.machine().lower())
    return None if machine is None else f'{platform.system().lower()}-{machine}'


def ensure(name):
    key = _key()
    if key is None:
        return None
    spec = json.loads((ROOT / '.github/infra-tools.json').read_text()).get(name)
    if spec is None or key not in spec['platforms']:
        return None
    asset = spec['platforms'][key]
    binary = ROOT / 'target/infra-tools' / f'{name}-{spec["version"]}-{key}' / name
    if binary.is_file():
        return binary
    print(f'x: installing {name} {spec["version"]} ({key})', file=sys.stderr, flush=True)
    with urllib.request.urlopen(asset['url'], timeout=60) as response:
        archive = response.read(64 * 1024 * 1024 + 1)
    if len(archive) > 64 * 1024 * 1024:
        raise SystemExit(f'x: {name}: archive exceeds size limit')
    if hashlib.sha256(archive).hexdigest() != asset['sha256']:
        raise SystemExit(f'x: {name}: archive checksum mismatch')
    if asset['url'].endswith('.zip'):
        with zipfile.ZipFile(io.BytesIO(archive)) as bundle:
            candidates = [entry for entry in bundle.infolist()
                          if not entry.is_dir() and Path(entry.filename).name == name]
            if len(candidates) != 1:
                raise SystemExit(f'x: {name}: expected one binary in archive')
            data = bundle.read(candidates[0])
    elif asset['url'].endswith(('.tar.gz', '.tgz')):
        with tarfile.open(fileobj=io.BytesIO(archive), mode='r:gz') as bundle:
            candidates = [entry for entry in bundle if entry.isfile() and Path(entry.name).name == name]
            if len(candidates) != 1:
                raise SystemExit(f'x: {name}: expected one binary in archive')
            data = bundle.extractfile(candidates[0]).read()
    else:
        data = archive
    binary.parent.mkdir(parents=True, exist_ok=True)
    temporary = binary.with_suffix('.tmp')
    temporary.write_bytes(data)
    temporary.chmod(0o755)
    temporary.replace(binary)
    return binary


def main():
    if len(sys.argv) != 3 or sys.argv[1] != 'ensure':
        raise SystemExit('usage: scripts/tools.py ensure NAME')
    path = ensure(sys.argv[2])
    if path is not None:
        print(path)


if __name__ == '__main__':
    main()
