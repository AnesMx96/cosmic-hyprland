import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Menú de apagado a pantalla completa, frente al agujero negro
PanelWindow {
    id: win
    property bool open: false
    property int current: 0
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: open || closeTimer.running
    WlrLayershell.namespace: "cosmic-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Timer { id: closeTimer; interval: Theme.anim }
    onOpenChanged: { if (open) { current = 0; keys.forceActiveFocus(); revealStamp++; Sys.refreshUptime(); } else closeTimer.restart(); }
    property int revealStamp: 0

    readonly property var actions: [
        { name: "Bloquear", icon: "lock", cmd: "hyprlock" },
        { name: "Suspender", icon: "bedtime", cmd: "systemctl suspend" },
        { name: "Salir", icon: "logout", cmd: "hyprctl dispatch 'hl.dsp.exit()'" },
        { name: "Reiniciar", icon: "restart_alt", cmd: "systemctl reboot" },
        { name: "Apagar", icon: "power_settings_new", cmd: "systemctl poweroff", danger: true }
    ]
    function run(i) { open = false; Sys.run("sleep 0.2; " + actions[i].cmd); }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
        Keys.onEscapePressed: win.open = false
        Keys.onLeftPressed: win.current = (win.current + win.actions.length - 1) % win.actions.length
        Keys.onRightPressed: win.current = (win.current + 1) % win.actions.length
        Keys.onTabPressed: win.current = (win.current + 1) % win.actions.length
        Keys.onReturnPressed: win.run(win.current)
        Keys.onEnterPressed: win.run(win.current)

        Rectangle { anchors.fill: parent; color: "#ee030819" }
        MouseArea { anchors.fill: parent; onClicked: win.open = false }

        BlackHole {
            id: hole
            anchors.fill: parent
            running: win.visible
            holeRadius: Math.min(parent.height * 0.2, 210)
            centerY: parent.height * 0.4
            tilt: 0.2
            scale: win.open ? 1 : 0.86
            Behavior on scale { NumberAnimation { duration: Theme.animSlow * 2; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveDecel } }
        }

        Column {
            x: (parent.width - width) / 2
            y: parent.height * 0.4 - hole.holeRadius * 0.56
            spacing: 2
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Hasta pronto, " + Sys.user; color: Theme.ice; font.family: Theme.font; font.pixelSize: 26; font.weight: Font.Light }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Encendido " + Sys.uptime; color: Theme.sub; font.family: Theme.font; font.pixelSize: 14 }
        }

        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.72
            spacing: 16
            Repeater {
                model: win.actions
                Item {
                    id: b
                    required property var modelData
                    required property int index
                    readonly property bool selected: win.current === index
                    width: 132; height: 132
                    opacity: 0
                    Translate { id: drop }
                    transform: drop
                    SequentialAnimation {
                        id: enter
                        PropertyAction { target: b; property: "opacity"; value: 0 }
                        PropertyAction { target: drop; property: "y"; value: 34 }
                        PauseAnimation { duration: 60 + b.index * 45 }
                        ParallelAnimation {
                            NumberAnimation { target: b; property: "opacity"; to: 1; duration: Theme.anim }
                            NumberAnimation { target: drop; property: "y"; to: 0; duration: Theme.animSlow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveDecel }
                        }
                    }
                    Connections { target: win; function onRevealStampChanged() { enter.restart(); } }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusXl
                        color: b.selected ? (b.modelData.danger ? "#44ff6b8b" : Theme.primarySoft) : Theme.card
                        border.width: 1
                        border.color: b.selected ? (b.modelData.danger ? Theme.danger : Theme.ice) : Theme.outline
                        scale: bm.pressed ? 0.94 : b.selected ? 1.07 : 1
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 10
                            MIcon { Layout.alignment: Qt.AlignHCenter; name: b.modelData.icon; size: 38; color: b.selected ? "#ffffff" : Theme.ice }
                            Text { Layout.alignment: Qt.AlignHCenter; text: b.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Medium }
                        }
                    }
                    MouseArea {
                        id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: win.current = b.index
                        onClicked: win.run(b.index)
                    }
                }
            }
        }
    }
}
