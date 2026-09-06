import QtQuick
import Quickshell
import Quickshell.Io

// Singleton lock state for Clean Lock. Every monitor's Panel reads this.
Item {
  id: root

  readonly property string pluginDir: String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "").replace(/\/$/, "")
  readonly property string bin: pluginDir + "/bin/cleanlock"

  property bool keyboardLocked: false
  property bool trackpadLocked: false
  property bool locked: false
  property int chordProgress: 0
  property string lastError: ""
  property bool busy: false

  function refresh() {
    statusProc.running = true
  }

  function applyStatus(text) {
    try {
      var data = JSON.parse(String(text || "{}"))
      keyboardLocked = !!data.keyboardLocked
      trackpadLocked = !!data.trackpadLocked
      locked = !!data.locked
      chordProgress = Number(data.chordProgress || 0)
    } catch (e) {
      lastError = "Could not read cleanlock status"
    }
  }

  function run(args) {
    if (busy) return
    lastError = ""
    busy = true
    actionProc.command = [bin].concat(args)
    actionProc.running = true
  }

  function lockKeyboard() { run(["lock-keyboard"]) }
  function lockTrackpad() { run(["lock-trackpad"]) }
  function lockBoth() { run(["lock-both"]) }
  function unlock() { run(["unlock"]) }

  Process {
    id: statusProc
    command: [root.bin, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatus(text)
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var err = String(text || "").trim()
        if (err !== "") root.lastError = err
      }
    }
    onExited: function () {
      root.busy = false
      root.refresh()
    }
  }

  // Poll often while locked so the fullscreen overlay counter stays smooth.
  Timer {
    interval: root.locked ? 100 : 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()

  IpcHandler {
    target: "io.github.leofle.cleanlock"
    function status(): string {
      return JSON.stringify({
        locked: root.locked,
        keyboardLocked: root.keyboardLocked,
        trackpadLocked: root.trackpadLocked,
        chordProgress: root.chordProgress
      })
    }
    function lockKeyboard(): string { root.lockKeyboard(); return "ok" }
    function lockTrackpad(): string { root.lockTrackpad(); return "ok" }
    function lockBoth(): string { root.lockBoth(); return "ok" }
    function unlock(): string { root.unlock(); return "ok" }
  }
}
