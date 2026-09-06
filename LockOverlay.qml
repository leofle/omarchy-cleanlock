import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Fullscreen overlay while inputs are locked for cleaning.
// Shows a large Super-hold counter so progress is visible with the panel closed.
PanelWindow {
  id: root

  property var service: null
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  readonly property bool locked: !!service && service.locked
  readonly property int holdSecond: service ? Number(service.chordProgress || 0) : 0
  readonly property bool holding: holdSecond > 0

  visible: locked
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  WlrLayershell.namespace: "omarchy-cleanlock"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.55)
  }

  BorderSurface {
    id: card
    anchors.centerIn: parent
    width: Math.min(parent.width - Style.space(80), Style.space(440))
    implicitHeight: cardColumn.implicitHeight + Style.space(40)
    radius: Style.cornerRadius
    color: Color.popups.background
    borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)

    Column {
      id: cardColumn
      anchors.centerIn: parent
      width: parent.width - Style.space(40)
      spacing: Style.space(14)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "󰌾"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.display * 1.5
      }

      Text {
        width: parent.width
        text: {
          if (!root.service) return "Clean Lock"
          var parts = []
          if (root.service.keyboardLocked) parts.push("Keyboard")
          if (root.service.trackpadLocked) parts.push("Trackpad")
          return (parts.length ? parts.join(" + ") : "Inputs") + " locked"
        }
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
      }

      Text {
        width: parent.width
        visible: !root.holding
        text: "Hold one Super / Windows key for 5 seconds to unlock"
        color: Qt.darker(root.foreground, 1.35)
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
      }

      // Big second counter — the whole point of this overlay.
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.holding
        text: root.holdSecond + " / 5"
        color: Color.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.display * 2.2
        font.bold: true
      }

      Text {
        width: parent.width
        visible: root.holding
        text: "Keep holding Super / Windows…"
        color: Qt.darker(root.foreground, 1.35)
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        horizontalAlignment: Text.AlignHCenter
      }

      // Progress bar under the counter
      BorderSurface {
        visible: root.holding
        width: parent.width
        implicitHeight: Style.space(10)
        radius: Style.cornerRadius
        color: Style.normalFillFor(root.foreground, Color.accent)
        borderSpec: Border.none()
        clip: true

        Rectangle {
          height: parent.height
          width: parent.width * (root.holdSecond / 5)
          color: Color.urgent
        }
      }
    }
  }
}
