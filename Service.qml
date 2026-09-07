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
  property string actionError: ""
  property string statusError: ""
  readonly property string lastError: [actionError, statusError].filter(function (s) { return s !== "" }).join("\n")
  property bool statusAvailable: false
  property bool statusPending: false
  property bool statusTimedOut: false
  property bool busy: false

  function refresh() {
    if (statusPending || statusProc.running) return
    statusPending = true
    statusTimedOut = false
    statusTimeout.restart()
    statusProc.running = true
  }

  function applyStatus(text) {
    try {
      var data = JSON.parse(String(text))
      if (!data || typeof data.keyboardLocked !== "boolean"
          || typeof data.trackpadLocked !== "boolean" || typeof data.locked !== "boolean"
          || data.locked !== (data.keyboardLocked || data.trackpadLocked)
          || typeof data.chordProgress !== "number" || !isFinite(data.chordProgress)
          || data.chordProgress < 0 || data.chordProgress > 5
          || Math.floor(data.chordProgress) !== data.chordProgress) {
        throw new Error("Invalid status")
      }
      keyboardLocked = data.keyboardLocked
      trackpadLocked = data.trackpadLocked
      locked = data.locked
      chordProgress = data.chordProgress
      statusAvailable = true
      statusError = ""
    } catch (e) {
      statusAvailable = false
      statusError = "Could not read cleanlock status; showing last known state"
    }
  }

  function run(args) {
    if (busy || actionProc.running) return
    actionError = ""
    busy = true
    actionTimeout.restart()
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
    stdout: StdioCollector { id: statusOutput; waitForEnd: true }
    stderr: StdioCollector { id: statusStderr; waitForEnd: true }
    onExited: function (code, exitStatus) {
      statusTimeout.stop()
      root.statusPending = false
      if (root.statusTimedOut) return
      if (code === 0 && exitStatus === 0) root.applyStatus(statusOutput.text)
      else {
        root.statusAvailable = false
        root.statusError = String(statusStderr.text).trim() || "Cleanlock status command failed; showing last known state"
      }
    }
    onRunningChanged: {
      if (!running && root.statusPending) {
        statusTimeout.stop()
        root.statusPending = false
        root.statusAvailable = false
        root.statusError = "Could not start cleanlock status; check that " + root.bin + " is executable"
      }
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: actionStderr; waitForEnd: true }
    onExited: function (code, exitStatus) {
      actionTimeout.stop()
      root.actionError = code === 0 && exitStatus === 0 ? ""
        : (String(actionStderr.text).trim() || "Cleanlock command failed (exit " + code + ")")
      root.busy = false
      root.refresh()
    }
    onRunningChanged: {
      if (!running && root.busy) {
        actionTimeout.stop()
        root.busy = false
        root.actionError = "Could not start cleanlock; check that " + root.bin + " is executable"
      }
    }
  }

  Timer {
    id: statusTimeout
    interval: 3000
    onTriggered: {
      root.statusAvailable = false
      root.statusTimedOut = true
      root.statusError = "Cleanlock status timed out; showing last known state"
      // Status is read-only; stopping it cannot interrupt a lock transition.
      statusProc.signal(9)
    }
  }

  Timer {
    id: actionTimeout
    interval: 10000
    onTriggered: {
      // Do not abandon a command that may still be changing device state.
      root.actionError = "Cleanlock command is taking too long; waiting for it to finish"
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
