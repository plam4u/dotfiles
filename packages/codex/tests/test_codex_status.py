"""Exercise the CLI against a fake app server; no account/network needed."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


CLI = Path(__file__).resolve().parents[1] / "bin" / "codex_status"
SERVER = '''
import json, os, sys, time
assert sys.argv[1:] == ["app-server", "--stdio"]
for line in sys.stdin:
    request = json.loads(line)
    with open(os.environ["REQUEST_LOG"], "a") as log:
        log.write(request["method"] + "\\n")
    if request["method"] == "initialize":
        if os.environ.get("MODE") == "timeout":
            time.sleep(10)
        if os.environ.get("MODE") == "closed":
            sys.exit(0)
        if os.environ.get("MODE") == "init-error":
            print(json.dumps({"id": 1, "error": {"message": "init failed"}}), flush=True)
        else:
            print(json.dumps({"id": 1, "result": {}}), flush=True)
    elif request["method"] == "account/rateLimits/read":
        print(json.dumps({"method": "account/updated", "params": {}}), flush=True)
        print(json.dumps({"id": 2, **json.loads(os.environ["REPLY"])}), flush=True)
'''


class StatusTests(unittest.TestCase):
    def query(self, reply, mode="", timeout="3"):
        with tempfile.TemporaryDirectory() as directory:
            server = Path(directory) / "codex"
            server.write_text(f"#!{sys.executable}\n" + SERVER)
            server.chmod(0o755)
            log = Path(directory) / "requests"
            env = dict(os.environ, PATH=f"{directory}:{os.environ['PATH']}",
                       REPLY=json.dumps(reply), MODE=mode,
                       REQUEST_LOG=str(log), CODEX_STATUS_TIMEOUT=timeout)
            result = subprocess.run([str(CLI)], env=env, capture_output=True,
                                    text=True, timeout=5)
            requests = log.read_text().splitlines() if log.exists() else []
            return result, requests

    def test_modern_buckets_and_handshake(self):
        bucket = {"planType": "plus", "primary": {
            "usedPercent": 22, "windowDurationMins": 300, "resetsAt": 2000000000},
            "secondary": {"usedPercent": 34, "windowDurationMins": 10080}}
        result, requests = self.query({"result": {
            "rateLimitsByLimitId": {"codex": bucket},
            "rateLimits": {"primary": {"usedPercent": 99}},
            "rateLimitResetCredits": {"availableCount": 3}}})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(requests, ["initialize", "initialized", "account/rateLimits/read"])
        status = json.loads(result.stdout)
        self.assertEqual(status["fiveHour"]["remainingPercent"], 78)
        self.assertEqual(status["weekly"]["remainingPercent"], 66)
        self.assertEqual(status["fiveHour"]["resetInSeconds"], 2000000000 - status["updatedAt"])
        self.assertIsNone(status["weekly"]["resetInSeconds"])
        self.assertEqual(status["manualResets"], 3)
        self.assertEqual(status["planType"], "plus")

    def test_legacy_missing_windows_and_clamping(self):
        for used, expected in [(105, 0), (-5, 100), (None, None)]:
            with self.subTest(used=used):
                result, _ = self.query({"result": {"rateLimits": {
                    "primary": None, "secondary": {"usedPercent": used,
                    "windowDurationMins": 10080, "resetsAt": 1}}}})
                self.assertEqual(result.returncode, 0, result.stderr)
                status = json.loads(result.stdout)
                self.assertIsNone(status["fiveHour"])
                self.assertEqual(status["weekly"]["remainingPercent"], expected)
                self.assertEqual(status["weekly"]["resetInSeconds"], 0)

    def test_failures_produce_no_json(self):
        cases = [({"result": {}}, ""),
                 ({"error": {"message": "not signed in"}}, ""),
                 ({}, "init-error"), ({}, "closed"), ({}, "timeout")]
        for reply, mode in cases:
            with self.subTest(mode=mode, reply=reply):
                result, _ = self.query(reply, mode, "1")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")
                self.assertIn("codex_status:", result.stderr)


if __name__ == "__main__":
    unittest.main()
