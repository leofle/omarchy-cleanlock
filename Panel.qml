import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

// Bar widget + popout for Clean Lock.
Panel {
  id: root
  moduleName: "io.github.leofle.cleanlock"
  ipcTarget: "io.github.leofle.cleanlock"
  manageIpc: false

  readonly property string pluginId: "io.github.leofle.cleanlock"
  readonly property var service: bar?.shell?.serviceFor(root.pluginId) ?? null

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color barIconColor: (!!service && service.locked) ? urgent : barForeground

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened && service) service.refresh()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      Item {
        Text {
          anchors.centerIn: parent
          text: (!!service && service.locked) ? "󰌾" : "󰌌"
          color: root.barIconColor
          font.family: root.fontFamily
          font.pixelSize: Style.font.icon
        }
      }
    }
    onPressed: function () {
      if (!service) return
      if (service.locked && !service.trackpadLocked) {
        service.unlock()
        return
      }
      root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(420))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function (direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          id: hero
          width: parent.width
          title: "Clean Lock"
          meta: {
            if (!service) return "Loading…"
            if (service.locked) {
              var parts = []
              if (service.keyboardLocked) parts.push("keyboard")
              if (service.trackpadLocked) parts.push("trackpad")
              var held = service.chordProgress > 0
                ? (" · holding Super " + service.chordProgress + "%")
                : ""
              return "Locked: " + parts.join(" + ") + held
            }
            return "Ready to clean"
          }
          foreground: root.foreground
          fontFamily: root.fontFamily

          iconComponent: Component {
            Text {
              text: (!!service && service.locked) ? "󰌾" : "󰌌"
              color: (!!service && service.locked) ? root.urgent : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        Text {
          width: parent.width
          wrapMode: Text.WordWrap
          color: Qt.darker(root.foreground, 1.4)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          text: "Unlock: hold Left Super + Right Super for 5 seconds. Sleep/lock are inhibited while cleaning."
        }

        PanelSeparator { width: parent.width }

        PanelSectionHeader {
          width: parent.width
          text: "LOCK"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        ActionRow {
          label: "Keyboard"
          detail: "Disable keys only"
          iconText: "󰌌"
          rowEnabled: !!service && !service.busy
          onActivated: if (service) { service.lockKeyboard(); root.close() }
        }
        ActionRow {
          label: "Trackpad"
          detail: "Disable trackpad only"
          iconText: "󰟸"
          rowEnabled: !!service && !service.busy
          onActivated: if (service) { service.lockTrackpad(); root.close() }
        }
        ActionRow {
          label: "Both"
          detail: "Keyboard + trackpad"
          iconText: "󰌾"
          rowEnabled: !!service && !service.busy
          onActivated: if (service) { service.lockBoth(); root.close() }
        }

        PanelSeparator { width: parent.width }

        ActionRow {
          label: "Unlock now"
          detail: service && service.trackpadLocked
            ? "Or hold both Super keys for 5s"
            : "Click here, or hold both Super keys 5s"
          iconText: "󰌿"
          rowEnabled: !!service && service.locked && !service.busy
          onActivated: if (service) { service.unlock(); root.close() }
        }

        Text {
          visible: !!service && service.lastError !== ""
          width: parent.width
          wrapMode: Text.WordWrap
          color: root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          text: service ? service.lastError : ""
        }
      }
    }
  }

  component ActionRow: Item {
    id: row
    property string label: ""
    property string detail: ""
    property string iconText: ""
    property bool rowEnabled: true
    property bool hovered: mouse.containsMouse
    signal activated()

    width: column.width
    height: Style.spacing.popupRowHeight + Style.space(16)
    opacity: rowEnabled ? 1 : 0.45

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: row.hovered && row.rowEnabled ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.space(8)
      anchors.rightMargin: Style.space(8)
      spacing: Style.space(12)

      Text {
        text: row.iconText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
      }

      Column {
        Layout.fillWidth: true
        spacing: 2
        Text {
          text: row.label
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }
        Text {
          text: row.detail
          color: Qt.darker(root.foreground, 1.5)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      enabled: row.rowEnabled
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: row.activated()
    }
  }
}
