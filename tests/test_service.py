"""Run the real Service.qml against an isolated backend, without input access."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
LOCKED = '{"keyboardLocked":true,"trackpadLocked":false,"locked":true,"chordProgress":2}'


@unittest.skipUnless(shutil.which('quickshell'), 'quickshell is required')
class ServiceTests(unittest.TestCase):
    def run_service(self, checks, backend=None, delay=250, setup="", fast_timeouts=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = (ROOT / 'Service.qml').read_text()
            if fast_timeouts:
                source = source.replace('interval: 3000', 'interval: 120').replace('interval: 10000', 'interval: 120')
            (root / 'Service.qml').write_text(source)
            (root / 'bin').mkdir()
            if backend is not None:
                command = root / 'bin/cleanlock'
                command.write_text('#!/bin/bash\n' + backend)
                command.chmod(0o755)
            (root / 'shell.qml').write_text('''import QtQuick
import Quickshell
ShellRoot {
  Service { id: service }
  Timer {
    interval: 30
    running: true
    onTriggered: { ''' + setup + ''' }
  }
  function check(condition, message) {
    if (!condition) { console.error("ASSERTION FAILED: " + message); Qt.quit() }
  }
  Timer {
    interval: ''' + str(delay) + '''
    running: true
    onTriggered: {
''' + checks + '''
      console.log("CHECKS PASSED")
      Qt.quit()
    }
  }
}
''')
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QPA_PLATFORMTHEME='basic',
                       XDG_RUNTIME_DIR=directory, XDG_CACHE_HOME=directory)
            result = subprocess.run(['quickshell', '-p', str(root / 'shell.qml')],
                                    env=env, capture_output=True, text=True, timeout=8)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertNotIn('ASSERTION FAILED', output)
            self.assertIn('CHECKS PASSED', output)
            return (root / 'calls').read_text() if (root / 'calls').exists() else ''

    def test_invalid_status_preserves_state_and_recovers(self):
        self.run_service('''
      service.applyStatus(''' + repr(LOCKED) + ''')
      var invalid = ["", "{}", "null", "broken", '{"keyboardLocked":"false"}',
        '{"keyboardLocked":false,"trackpadLocked":false,"locked":true,"chordProgress":0}',
        '{"keyboardLocked":false,"trackpadLocked":false,"locked":false,"chordProgress":6}']
      for (var i = 0; i < invalid.length; i++) {
        service.applyStatus(invalid[i])
        check(service.locked && service.keyboardLocked && service.chordProgress === 2, "preserve lock")
        check(!service.statusAvailable && service.lastError !== "", "report invalid status")
      }
      service.applyStatus(''' + repr(LOCKED) + ''')
      check(service.statusAvailable && service.lastError === "", "recover status")
''')

    def test_failed_status_does_not_apply_valid_stdout(self):
        self.run_service('''
      check(!service.statusAvailable, "failed exit invalidates status")
      check(!service.locked, "failed output was not applied")
      check(service.lastError.indexOf("status failure") >= 0, "stderr visible")
''', 'echo \'' + LOCKED + '\'\necho "status failure" >&2\nexit 1\n')

    def test_refresh_is_not_queued(self):
        calls = self.run_service('''
      check(service.statusAvailable, "status completed")
      check(!service.locked, "status applied")
''', 'echo call >> "$(dirname "$0")/../calls"\nsleep 0.15\necho \'' + LOCKED.replace('true', 'false').replace(':2', ':0') + '\'\n', setup='service.refresh(); service.refresh(); service.refresh()')
        self.assertEqual(calls.count('call'), 1)

    def test_action_launch_failure_and_crash(self):
        # A second timer starts actions before the assertion timer fires.
        for backend in [None, 'if [[ $1 != status ]]; then kill -KILL $$; fi\necho \'' + LOCKED + '\'\n']:
            with self.subTest(backend=backend):
                self.run_service('''
      check(!service.busy, "failed action clears busy")
      check(service.actionError !== "", "failed action reports error")
''', backend, setup='service.lockKeyboard()')

    def test_status_timeout_keeps_last_state(self):
        calls = self.run_service('''
      check(service.locked, "timeout preserves last lock")
      check(!service.statusAvailable, "timeout invalidates status")
      check(service.statusError.indexOf("timed out") >= 0, "timeout reported")
''', 'echo call >> "$(dirname "$0")/../calls"\nexec sleep 2\n', setup='service.applyStatus(' + repr(LOCKED) + ')', fast_timeouts=True, delay=400)
        self.assertGreaterEqual(calls.count('call'), 2)

    def test_slow_action_remains_busy_and_blocks_overlap(self):
        calls = self.run_service('''
      check(service.busy, "slow action retains ownership")
      check(service.actionError.indexOf("taking too long") >= 0, "slow action reported")
      service.unlock()
''', 'if [[ $1 != status ]]; then echo action >> "$(dirname "$0")/../calls"; sleep 2; fi\necho \'' + LOCKED + '\'\n',
            setup='service.lockKeyboard()', fast_timeouts=True)
        self.assertEqual(calls.count('action'), 1)
