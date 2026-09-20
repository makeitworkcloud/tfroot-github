import contextlib
import importlib.util
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("source_check", ROOT / "scripts/check-known-host-source.py")
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)
REAL_POPEN = subprocess.Popen
REAL_RUN = subprocess.run


class SourceCheckTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.directory = self.root / "known-host-source-check-123-1"
        key = self.root / "fixture"
        result = REAL_RUN(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-C", "fixture", "-f", str(key)],
                          capture_output=True, timeout=10)
        self.assertTrue(result.returncode == 0, "fixture generation failed")
        self.value = b"example.test " + key.with_suffix(".pub").read_bytes()
        self.source_file = self.root / "synthetic-source"
        self.source_file.write_bytes(b"")

    def producer(self, mode, exit_code=0):
        if mode == "chunks":
            code = "import pathlib,sys; data=pathlib.Path(sys.argv[1]).read_bytes();\nfor i in range(0,len(data),8192): sys.stdout.buffer.write(data[i:i+8192]); sys.stdout.buffer.flush()"
            return [sys.executable, "-c", code, str(self.source_file)]
        if mode == "oversize":
            code = "import os; chunk=b'x'*65536\nwhile True: os.write(1,chunk)"
            return [sys.executable, "-c", code]
        if mode == "sleep":
            code = "import time; time.sleep(2)"
            return [sys.executable, "-c", code]
        code = "import sys; sys.exit(int(sys.argv[1]))"
        return [sys.executable, "-c", code, str(exit_code)]

    def source_popen(self, source, mode="chunks", exit_code=0, processes=None):
        self.source_file.write_bytes(source)

        def popen(args, **kwargs):
            if args == CHECK.SOURCE_COMMAND:
                self.assertTrue(args == ["sops", "--decrypt", "--extract", '["ssh_known_hosts"]', "secrets/secrets.yaml"],
                                "wrong source extraction")
                self.assertTrue(kwargs.get("stdout") == subprocess.PIPE and kwargs.get("stderr") == subprocess.DEVNULL,
                                "unsafe extraction output")
                process = REAL_POPEN(self.producer(mode, exit_code), **kwargs)
                if processes is not None:
                    processes.append(process)
                return process
            return REAL_POPEN(args, **kwargs)

        return popen

    def run_check(self, value=None, extraction_code=0, parse_error=None):
        source = self.value if value is None else value
        before = set(self.root.iterdir())

        def run(args, **kwargs):
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
        with mock.patch.dict(os.environ, {"RUNNER_TEMP": str(self.root), "GITHUB_RUN_ID": "123",
                                           "GITHUB_RUN_ATTEMPT": "1", "HERO_HOST": "example.test"}):
            with mock.patch.object(CHECK.subprocess, "Popen",
                                   side_effect=self.source_popen(
                                       source,
                                       mode="exit" if extraction_code else "chunks",
                                       exit_code=extraction_code,
                                   )):
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
        self.assertTrue(self.run_check(b"") == "source-unusable", "empty source accepted")
        processes = []
        before = set(self.root.iterdir())
        with mock.patch.object(CHECK.subprocess, "Popen",
                               side_effect=self.source_popen(b"", mode="oversize", processes=processes)):
            status = CHECK.check("example.test", self.directory)
        self.assertTrue(status == "source-unusable", "oversized source accepted")
        self.assertTrue(processes and processes[0].poll() is not None, "oversized source child remains running")
        self.assertTrue(set(self.root.iterdir()) == before, "temporary plaintext residue")

    def test_probe_failure_cleanup(self):
        for error in (FileNotFoundError("sensitive-sentinel"), subprocess.TimeoutExpired(["ssh-keygen"], 5)):
            self.assertTrue(self.run_check(parse_error=error) == "tool-error", "tool error misclassified")

    def test_invalid_host(self):
        for host in ("", "-F", "bad host", "bad\nhost", "bad\x00host"):
            self.assertTrue(CHECK.check(host, self.directory) == "invalid-input", "invalid target accepted")
            self.assertTrue(not self.directory.exists(), "unexpected temporary directory")

    def test_invalid_input_main_output_and_exit(self):
        for host in ("", "-F", "bad host", "bad\nhost"):
            stdout, stderr = io.StringIO(), io.StringIO()
            with mock.patch.dict(os.environ, {"RUNNER_TEMP": str(self.root), "GITHUB_RUN_ID": "123",
                                               "GITHUB_RUN_ATTEMPT": "1", "HERO_HOST": host}):
                with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                    code = CHECK.main()
            self.assertTrue(code == 1, "invalid input returned success")
            self.assertTrue(stdout.getvalue() == "source_known_hosts: status=invalid-input\n", "invalid output changed")
            self.assertTrue(stderr.getvalue() == "", "invalid input disclosed stderr")
            self.assertTrue(not self.directory.exists(), "invalid input created temporary directory")

    def test_existing_directory_not_touched(self):
        self.directory.mkdir()
        sentinel = self.directory / "sentinel"
        sentinel.write_text("untouched")
        self.assertTrue(CHECK.check("example.test", self.directory) == "tool-error", "existing path accepted")
        self.assertTrue(sentinel.read_text() == "untouched", "existing path modified")

    def test_source_timeout_cleanup(self):
        processes = []
        with mock.patch.object(CHECK, "SOURCE_TIMEOUT", 0.05):
            with mock.patch.object(CHECK.subprocess, "Popen",
                                   side_effect=self.source_popen(b"", mode="sleep", processes=processes)):
                status = CHECK.check("example.test", self.directory)
        self.assertTrue(status == "tool-error", "source timeout misclassified")
        self.assertTrue(processes and processes[0].poll() is not None, "timed-out source child remains running")
        self.assertTrue(not self.directory.exists(), "temporary directory remains")

    def test_cleanup_failure_is_safe(self):
        processes = []
        stdout, stderr = io.StringIO(), io.StringIO()
        with mock.patch.dict(os.environ, {"RUNNER_TEMP": str(self.root), "GITHUB_RUN_ID": "123",
                                           "GITHUB_RUN_ATTEMPT": "1", "HERO_HOST": "example.test"}):
            with mock.patch.object(CHECK.subprocess, "Popen",
                                   side_effect=self.source_popen(self.value, processes=processes)):
                with mock.patch.object(CHECK.subprocess, "run", side_effect=lambda args, **kwargs: REAL_RUN(args, **kwargs)):
                    with mock.patch.object(CHECK.os, "rmdir", side_effect=OSError("sensitive-sentinel")):
                        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                            code = CHECK.main()
        self.assertTrue(code == 0, "cleanup failure changed result")
        self.assertTrue(stdout.getvalue() == "source_known_hosts: status=match-found\n", "cleanup failure disclosed output")
        self.assertTrue(stderr.getvalue() == "", "cleanup failure disclosed stderr")
        self.assertTrue(self.directory.exists(), "cleanup failure unexpectedly removed directory")
        self.directory.rmdir()

    def test_workflow_guardrails(self):
        workflow = (ROOT / ".github/workflows/check-known-host-source.yml").read_text()
        synthetic = workflow.split("  check-source:", 1)[0]
        source = workflow.split("  check-source:", 1)[1]
        self.assertTrue("if: github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main'" in source,
                        "source job is not manual main-only")
        self.assertTrue("needs: synthetic-tests" in source, "source job bypasses synthetic tests")
        self.assertTrue("environment: production" in source and "id-token: write" in source,
                        "source job lost production/OIDC gate")
        for forbidden in ("configure-aws-credentials", "production", "id-token", "secrets."):
            self.assertTrue(forbidden not in synthetic, "synthetic job contains production material")
        self.assertTrue("tofu" not in workflow.lower() and "make " not in workflow.lower() and "apply" not in workflow.lower(),
                        "workflow contains infrastructure commands")
        for line in workflow.splitlines():
            if "uses:" in line:
                self.assertTrue(line.strip().rsplit("@", 1)[-1].isalnum() and
                                len(line.strip().rsplit("@", 1)[-1]) == 40,
                                "workflow action is not pinned")


if __name__ == "__main__":
    unittest.main()
