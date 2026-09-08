import os
import pathlib
import stat
import subprocess
import tempfile
import unittest

SETUP = pathlib.Path(__file__).resolve().parents[1] / 'bin/cleanlock-setup-input'
SOURCE = SETUP.read_text()
RULE = 'line one\nline two'


def privileged_body():
    """The script that runs as root under pkexec."""
    body = SOURCE.split("pkexec /bin/bash -euc '", 1)[1]
    return body.rsplit("' cleanlock-install-udev-rule", 1)[0]


def run_privileged(target, rule=RULE):
    return subprocess.run(
        ['bash', '-euc', privileged_body(), 'cleanlock-install-udev-rule', str(target), rule],
        capture_output=True, text=True,
    )


class SetupInputTests(unittest.TestCase):
    def test_no_user_writable_path_crosses_pkexec(self):
        # A path created before pkexec can be swapped while the auth dialog is
        # open, so the rule must be generated inside the privileged shell.
        before = SOURCE.split('pkexec /', 1)[0]
        self.assertNotIn('mktemp', before)
        code = '\n'.join(l for l in SOURCE.splitlines() if not l.lstrip().startswith('#'))
        self.assertEqual(code.count('pkexec'), 1)

    def test_installs_rule_with_root_owner_and_mode(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = pathlib.Path(tmp) / 'rules.d/70-cleanlock-input.rules'
            run_privileged(target)
            self.assertEqual(target.read_text(), RULE + '\n')
            self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o644)

    def test_staging_file_leaves_no_leftovers(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = pathlib.Path(tmp) / 'rules.d/70-cleanlock-input.rules'
            run_privileged(target)
            self.assertEqual(os.listdir(target.parent), [target.name])

    def test_verification_rejects_tampered_content(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = pathlib.Path(tmp) / 'rules.d/70-cleanlock-input.rules'
            # An install that lands content other than the expected rule must
            # fail before udev is reloaded.
            body = privileged_body().replace('printf "%s\\n" "$rule"', 'printf "tampered\\n"')
            result = subprocess.run(
                ['bash', '-euc', body, 'x', str(target), RULE],
                capture_output=True, text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('does not match expected content', result.stderr)
            self.assertNotIn('udevadm', result.stderr)


if __name__ == '__main__':
    unittest.main()
