import contextlib
import importlib.util
import io
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("source_check", ROOT / "scripts/check-known-host-source.py")
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)
REAL_RUN = subprocess.run


class SourceCheckTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.directory = self.root / "known-host-source-check"
        key = self.root / "fixture"
        result = REAL_RUN(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-C", "fixture", "-f", str(key)],
                          capture_output=True, timeout=10)
        self.assertTrue(result.returncode == 0, "fixture generation failed")
        self.value = b"example.test " + key.with_suffix(".pub").read_bytes()

    def run_check(self, value=None, extraction_code=0, parse_error=None):
        source = self.value if value is None else value
        before = set(self.root.iterdir())

        def run(args, **kwargs):
            if args[0] == "sops":
                self.assertTrue(args == ["sops", "--decrypt", "--extract", '["ssh_known_hosts"]', "secrets/secrets.yaml"],
                                "wrong source extraction")
                self.assertTrue(kwargs.get("capture_output") and kwargs.get("timeout") == 30, "unsafe extraction")
                return subprocess.CompletedProcess(args, extraction_code, stdout=source, stderr=b"sensitive-sentinel")
            self.assertTrue(args[:3] == ["ssh-keygen", "-F", "example.test"], "unexpected command")
            self.assertTrue(kwargs.get("stdout") == subprocess.DEVNULL and kwargs.get("stderr") == subprocess.DEVNULL,
                            "probe output not suppressed")
            self.assertTrue(kwargs.get("timeout") == 5, "probe unbounded")
            path = Path(args[4])
            self.assertTrue(path.parent == self.directory, "wrong temporary location")
            self.assertTrue(path.stat().st_mode & 0o777 == 0o600, "unsafe file mode")
            self.assertTrue(self.directory.stat().st_mode & 0o777 == 0o700, "unsafe directory mode")
            if parse_error:
                raise parse_error
            return REAL_RUN(args, **kwargs)

        stdout, stderr = io.StringIO(), io.StringIO()
        with mock.patch.dict(os.environ, {"RUNNER_TEMP": str(self.root), "HERO_HOST": "example.test"}):
            with mock.patch.object(CHECK.subprocess, "run", side_effect=run):
                with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                    code = CHECK.main()
        output = stdout.getvalue()
        statuses = ("match-found", "missing-host-entry", "source-extraction-failed", "source-unusable", "tool-error")
        self.assertTrue(output in {f"source_known_hosts: status={status}\n" for status in statuses}, "unexpected output")
        self.assertTrue(stderr.getvalue() == "", "stderr disclosure")
        for forbidden in ("example.test", "ssh-ed25519", "sensitive-sentinel", "SHA256:", str(self.root)):
            self.assertTrue(forbidden not in output, "diagnostic disclosure")
        self.assertTrue(set(self.root.iterdir()) == before, "temporary plaintext residue")
        status = output.strip().split("=", 1)[1]
        self.assertTrue(code == (0 if status == "match-found" else 1), "wrong exit code")
        return status

    def test_match(self):
        self.assertTrue(self.run_check() == "match-found", "valid entry not found")

    def test_missing_entry(self):
        self.assertTrue(self.run_check(self.value.replace(b"example.test", b"other.test")) == "missing-host-entry", "wrong host matched")

    def test_hashed_entry(self):
        fixture = self.root / "hashed"
        fixture.write_bytes(self.value)
        result = REAL_RUN(["ssh-keygen", "-H", "-f", str(fixture)], capture_output=True, timeout=5)
        self.assertTrue(result.returncode == 0, "fixture hashing failed")
        self.assertTrue(self.run_check(fixture.read_bytes()) == "match-found", "hashed host rejected")

    def test_extraction_failure(self):
        self.assertTrue(self.run_check(extraction_code=1) == "source-extraction-failed", "extraction error misclassified")

    def test_empty_and_oversized(self):
        for value in (b"", b"x" * (CHECK.MAX_BYTES + 1)):
            self.assertTrue(self.run_check(value) == "source-unusable", "invalid size accepted")

    def test_probe_failure_cleanup(self):
        for error in (FileNotFoundError("sensitive-sentinel"), subprocess.TimeoutExpired(["ssh-keygen"], 5)):
            self.assertTrue(self.run_check(parse_error=error) == "tool-error", "tool error misclassified")

    def test_invalid_host(self):
        for host in ("", "-F", "bad host", "bad\nhost", "bad\x00host"):
            self.assertTrue(CHECK.check(host, self.directory) == "invalid-input", "invalid target accepted")
            self.assertTrue(not self.directory.exists(), "unexpected temporary directory")

    def test_existing_directory_not_touched(self):
        self.directory.mkdir()
        sentinel = self.directory / "sentinel"
        sentinel.write_text("untouched")
        self.assertTrue(CHECK.check("example.test", self.directory) == "tool-error", "existing path accepted")
        self.assertTrue(sentinel.read_text() == "untouched", "existing path modified")

    def test_sops_timeout_cleanup(self):
        with mock.patch.object(CHECK.subprocess, "run", side_effect=subprocess.TimeoutExpired(["sops"], 30)):
            self.assertTrue(CHECK.check("example.test", self.directory) == "tool-error", "extraction timeout misclassified")
        self.assertTrue(not self.directory.exists(), "temporary directory remains")


if __name__ == "__main__":
    unittest.main()
