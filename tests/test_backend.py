import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class BackendTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        shutil.copy(ROOT / 'bin/cleanlock', self.bin)
        self.env = dict(os.environ, XDG_STATE_HOME=str(self.root / 'state'), CLEANLOCK_SILENT='1', PATH=str(self.bin)+':'+os.environ['PATH'], CALLS=str(self.root / 'calls'))
        self.script('hyprctl', '''#!/bin/bash
if [[ $1 == devices ]]; then
 echo '{"keyboards":[{"name":"test-keyboard"}],"mice":[{"name":"test-touchpad"}]}'
else
 echo "$*" >> "$CALLS"
 [[ ${FAIL_DISABLE:-0} != 1 || $* != *false* ]]
fi
''')
        self.script('omarchy-hw-touchpad', '#!/bin/bash\necho test-touchpad\n')
        self.script('cleanlock-chord', '''#!/usr/bin/env python3
import os,sys,time
from pathlib import Path
if '--check' in sys.argv: sys.exit(int(os.getenv('NO_ACCESS','0')))
if os.getenv('MONITOR_FAIL'): sys.exit(1)
p=Path(os.environ['XDG_STATE_HOME'])/'omarchy/cleanlock/chord-ready'
p.write_text(str(os.getpid()))
time.sleep(30)
''')
        self.script('cleanlock-guard', '#!/usr/bin/env python3\nimport time\ntime.sleep(30)\n')

    def script(self, name, text):
        p = self.bin / name
        p.write_text(text)
        p.chmod(0o755)

    def run_cmd(self, cmd):
        return subprocess.run([str(self.bin / 'cleanlock'), cmd], env=self.env, capture_output=True, text=True, timeout=8)

    def calls(self):
        p=self.root/'calls'
        return p.read_text() if p.exists() else ''

    def tearDown(self):
        self.run_cmd('unlock')
        self.tmp.cleanup()

    def test_lock_and_unlock(self):
        self.assertEqual(self.run_cmd('lock-both').returncode,0)
        self.assertTrue(json.loads(self.run_cmd('status').stdout)['locked'])
        self.assertEqual(self.calls().count('enabled = false'),2)
        self.assertEqual(self.run_cmd('unlock').returncode,0)
        self.assertFalse(json.loads(self.run_cmd('status').stdout)['locked'])
        self.assertEqual(self.calls().count('enabled = true'),2)

    def test_no_access_never_disables(self):
        self.env['NO_ACCESS']='1'
        self.assertNotEqual(self.run_cmd('lock-both').returncode,0)
        self.assertEqual(self.calls(),'')

    def test_monitor_failure_never_disables(self):
        self.env['MONITOR_FAIL']='1'
        self.assertNotEqual(self.run_cmd('lock-both').returncode,0)
        self.assertNotIn('enabled = false',self.calls())
        self.assertFalse(json.loads(self.run_cmd('status').stdout)['locked'])

    def test_compositor_error_rolls_back(self):
        self.env['FAIL_DISABLE']='1'
        self.assertNotEqual(self.run_cmd('lock-both').returncode,0)
        self.assertIn('enabled = true',self.calls())
        self.assertFalse(json.loads(self.run_cmd('status').stdout)['locked'])
