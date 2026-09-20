#!/usr/bin/env python3

import os
import selectors
import subprocess
import sys
import tempfile
import time
from pathlib import Path


SOURCE_COMMAND = ["sops", "--decrypt", "--extract", '["ssh_known_hosts"]', "secrets/secrets.yaml"]
MAX_BYTES = 1024 * 1024
SOURCE_TIMEOUT = 30
SOURCE_CLEANUP_TIMEOUT = 1


def _stop_source(process):
    if process is None:
        return
    try:
        if process.poll() is None:
            process.kill()
    except OSError:
        pass
    try:
        process.wait(timeout=SOURCE_CLEANUP_TIMEOUT)
    except (OSError, subprocess.TimeoutExpired):
        try:
            process.kill()
        except OSError:
            pass
        try:
            process.wait(timeout=SOURCE_CLEANUP_TIMEOUT)
        except (OSError, subprocess.TimeoutExpired):
            pass
    for stream in (getattr(process, "stdout", None), getattr(process, "stderr", None)):
        if stream is not None:
            try:
                stream.close()
            except OSError:
                pass


def _extract_source():
    process = None
    selector = None
    source = bytearray()
    stream_closed = False
    try:
        process = subprocess.Popen(
            SOURCE_COMMAND, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
        )
        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + SOURCE_TIMEOUT
        while not stream_closed:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return None, "tool-error"
            if not selector.select(remaining):
                return None, "tool-error"
            remaining_bytes = MAX_BYTES + 1 - len(source)
            chunk = os.read(process.stdout.fileno(), remaining_bytes)
            if not chunk:
                stream_closed = True
                continue
            source.extend(chunk)
            if len(source) > MAX_BYTES:
                return None, "source-unusable"
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return None, "tool-error"
        try:
            return_code = process.wait(timeout=remaining)
        except subprocess.TimeoutExpired:
            return None, "tool-error"
        if return_code != 0:
            return None, "source-extraction-failed"
        return bytes(source), None
    except (OSError, subprocess.TimeoutExpired):
        return None, "tool-error"
    finally:
        if selector is not None:
            try:
                selector.close()
            except OSError:
                pass
        _stop_source(process)


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
        source, error = _extract_source()
        if error:
            return error
        if not source:
            return "source-unusable"
        with tempfile.NamedTemporaryFile(dir=directory) as known_hosts:
            known_hosts.write(source)
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
        try:
            os.rmdir(directory)
        except OSError:
            pass


def main():
    try:
        directory = Path(os.environ["RUNNER_TEMP"]) / (
            f"known-host-source-check-{os.environ['GITHUB_RUN_ID']}-"
            f"{os.environ['GITHUB_RUN_ATTEMPT']}"
        )
        status = check(os.environ.get("HERO_HOST", ""), directory)
    except Exception:
        status = "tool-error"
    print(f"source_known_hosts: status={status}")
    return 0 if status == "match-found" else 1


if __name__ == "__main__":
    sys.exit(main())
