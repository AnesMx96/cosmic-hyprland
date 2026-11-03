import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// Toasts de notificación arriba a la derecha
PanelWindow {
    id: win
    property bool ccOpen: false
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { top: 62; right: 12 }
    implicitWidth: 400
    implicitHeight: Math.max(1, col.implicitHeight)
    exclusiveZone: 0
    color: "transparent"
    visible: Notifs.popups.length > 0 && !ccOpen
    WlrLayershell.namespace: "cosmic-popups"
    WlrLayershell.layer: WlrLayer.Overlay

    ColumnLayout {
        id: col
        width: parent.width; spacing: 8
        Repeater {
            model: Notifs.popups
            Item {
                id: wrap
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: card.implicitHeight
                NotifCard {
                    id: card
                    width: parent.width
                    notif: wrap.modelData; popup: true
                    x: 420
                    Component.onCompleted: x = 0
                    Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveDecel } }
                    onDismissed: wrap.modelData.dismiss()
                    HoverHandler { id: h }
                }
                Timer {
                    id: timer
                    readonly property bool critical: wrap.modelData?.urgency === NotificationUrgency.Critical
                    interval: (wrap.modelData?.expireTimeout > 0 ? wrap.modelData.expireTimeout : 6000)
                    running: !critical && !h.hovered
                    onTriggered: Notifs.dropPopup(wrap.modelData)
                }
            }
        }
    }
}
