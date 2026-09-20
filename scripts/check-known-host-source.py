#!/usr/bin/env python3

import os
import subprocess
import sys
import tempfile
from pathlib import Path


SOURCE_COMMAND = ["sops", "--decrypt", "--extract", '["ssh_known_hosts"]', "secrets/secrets.yaml"]
MAX_BYTES = 1024 * 1024


def check(host, directory):
    if not host or host.startswith("-") or any(
        char.isspace() or ord(char) < 32 or ord(char) == 127 for char in host
    ):
        return "invalid-input"
    try:
        os.mkdir(directory, mode=0o700)
    except OSError:
        return "tool-error"
    try:
        source = subprocess.run(SOURCE_COMMAND, capture_output=True, timeout=30)
        if source.returncode != 0:
            return "source-extraction-failed"
        if not source.stdout or len(source.stdout) > MAX_BYTES:
            return "source-unusable"
        with tempfile.NamedTemporaryFile(dir=directory) as known_hosts:
            known_hosts.write(source.stdout)
            known_hosts.flush()
            matched = subprocess.run(
                ["ssh-keygen", "-F", host, "-f", known_hosts.name],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5,
            )
        if matched.returncode == 0:
            return "match-found"
        if matched.returncode == 1:
            return "missing-host-entry"
        return "tool-error"
    except (OSError, subprocess.TimeoutExpired):
        return "tool-error"
    finally:
        os.rmdir(directory)


def main():
    try:
        directory = Path(os.environ["RUNNER_TEMP"]) / "known-host-source-check"
        status = check(os.environ.get("HERO_HOST", ""), directory)
    except Exception:
        status = "tool-error"
    print(f"source_known_hosts: status={status}")
    return 0 if status == "match-found" else 1


if __name__ == "__main__":
    sys.exit(main())
