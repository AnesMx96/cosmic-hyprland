import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: win
    property bool open: false
    property string page: "main"
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; right: true; bottom: true }
    margins { top: 62; right: 12; bottom: 12 }
    implicitWidth: 440
    exclusiveZone: 0
    color: "transparent"
    visible: open || slide.running
    WlrLayershell.namespace: "cosmic-cc"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: if (open) { page = "main"; Sys.refresh(); }

    HyprlandFocusGrab { windows: [win]; active: win.open; onCleared: win.open = false }
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    readonly property var sink: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var source: Pipewire.defaultAudioSource?.audio ?? null
    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifiDev ? wifiDev.networks.values.find(n => n.connected) ?? null : null
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property real bat: { const p = UPower.displayDevice?.percentage ?? 0; return p > 1 ? p : p * 100; }
    readonly property string greeting: { const h = new Date().getHours(); return h < 6 ? "Buenas noches" : h < 13 ? "Buenos días" : h < 21 ? "Buenas tardes" : "Buenas noches"; }

    Rectangle {
        id: panel
        width: parent.width; height: parent.height
        x: win.open ? 0 : width + 24
        opacity: win.open ? 1 : 0
        radius: Theme.radiusXl
        color: Theme.bg
        border.width: 1; border.color: Theme.edge
        focus: win.open
        Keys.onEscapePressed: win.page === "main" ? win.open = false : win.page = "main"
        Behavior on x { NumberAnimation { id: slide; duration: Theme.animSlow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveDecel } }
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }

        // filo de luz superior, como la barra
        Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 1; width: parent.width - 2 * Theme.radiusXl; height: 1; color: Qt.rgba(1, 1, 1, 0.35) }

        Item {
            id: pages
            anchors.fill: parent; anchors.margins: 16
            clip: true

            // ================= PÁGINA PRINCIPAL =================
            ColumnLayout {
                id: mainPage
                width: parent.width; height: parent.height
                x: win.page === "main" ? 0 : -width * 0.25
                opacity: win.page === "main" ? 1 : 0
                visible: opacity > 0
                spacing: 12
                Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: Theme.anim } }

                // Cabecera
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 48; Layout.preferredHeight: 48; radius: 24
                        gradient: Gradient { GradientStop { position: 0; color: "#8cc3ff" } GradientStop { position: 1; color: "#5b6cff" } }
                        Text { anchors.centerIn: parent; text: Sys.user.charAt(0).toUpperCase(); color: Theme.fgOnPrimary; font.family: Theme.font; font.pixelSize: 20; font.weight: Font.Bold }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: win.greeting + ", " + Sys.user; color: Theme.text; font.family: Theme.font; font.pixelSize: 16; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                        RowLayout {
                            spacing: 10
                            RowLayout { spacing: 3; MIcon { name: "schedule"; size: 14; color: Theme.sub } Text { text: Sys.uptime; color: Theme.sub; font.family: Theme.font; font.pixelSize: 12 } }
                            RowLayout {
                                spacing: 3; visible: UPower.displayDevice?.isLaptopBattery ?? false
                                MIcon { name: UPower.onBattery ? "battery_std" : "battery_charging_full"; size: 14; color: win.bat < 20 ? Theme.danger : Theme.sub }
                                Text { text: Math.round(win.bat) + "%"; color: Theme.sub; font.family: Theme.font; font.pixelSize: 12 }
                            }
                        }
                    }
                    IconButton { icon: "settings"; onClicked: { win.open = false; Sys.run("systemsettings"); } }
                    IconButton { icon: "lock"; onClicked: { win.open = false; Sys.run("hyprlock"); } }
                    IconButton { icon: "power_settings_new"; danger: true; onClicked: { win.open = false; Sys.run(Sys.scripts + "powermenu.sh"); } }
                }

                // Toggles
                GridLayout {
                    Layout.fillWidth: true; columns: 2; rowSpacing: 8; columnSpacing: 8
                    Tile {
                        Layout.fillWidth: true; icon: Networking.wifiEnabled ? "wifi" : "wifi_off"; title: "Wi-Fi"; expandable: true
                        subtitle: !Networking.wifiEnabled ? "Apagado" : (win.wifiNet?.name ?? "Sin conexión")
                        active: Networking.wifiEnabled
                        onToggled: Sys.run("nmcli radio wifi " + (Networking.wifiEnabled ? "off" : "on"))
                        onExpand: win.page = "wifi"
                    }
                    Tile {
                        Layout.fillWidth: true; title: "Bluetooth"; expandable: true
                        readonly property bool on: Bluetooth.defaultAdapter?.enabled ?? false
                        icon: on ? (win.btConnected.length ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
                        subtitle: !on ? "Apagado" : (win.btConnected.length ? win.btConnected[0].name : "Encendido")
                        active: on
                        onToggled: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !on
                        onExpand: win.page = "bt"
                    }
                    Tile { Layout.fillWidth: true; icon: Notifs.dnd ? "notifications_off" : "notifications"; title: "No molestar"; subtitle: Notifs.dnd ? "Activado" : "Desactivado"; active: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
                    Tile { Layout.fillWidth: true; icon: "nightlight"; title: "Luz nocturna"; subtitle: Sys.night ? "4500 K" : "Desactivada"; active: Sys.night; onToggled: Sys.toggleNight() }
                    Tile { Layout.fillWidth: true; icon: "coffee"; title: "Cafeína"; subtitle: Sys.caffeine ? "Pantalla siempre encendida" : "Desactivada"; active: Sys.caffeine; onToggled: Sys.toggleCaffeine() }
                    Tile { Layout.fillWidth: true; icon: "sports_esports"; title: "Modo juego"; subtitle: Sys.gaming ? "Sin efectos" : "Desactivado"; active: Sys.gaming; onToggled: Sys.toggleGaming() }
                }

                // Sliders
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8
                    FatSlider {
                        Layout.fillWidth: true
                        value: win.sink?.volume ?? 0
                        dimmed: win.sink?.muted ?? false
                        icon: (win.sink?.muted ?? false) ? "volume_off" : value < 0.35 ? "volume_down" : "volume_up"
                        onMoved: v => { if (win.sink) { win.sink.muted = false; win.sink.volume = v; } }
                        onIconClicked: if (win.sink) win.sink.muted = !win.sink.muted
                    }
                    FatSlider {
                        Layout.fillWidth: true
                        value: win.source?.volume ?? 0
                        dimmed: win.source?.muted ?? false
                        icon: (win.source?.muted ?? false) ? "mic_off" : "mic"
                        onMoved: v => { if (win.source) { win.source.muted = false; win.source.volume = v; } }
                        onIconClicked: if (win.source) win.source.muted = !win.source.muted
                    }
                    FatSlider {
                        Layout.fillWidth: true
                        value: Sys.brightness
                        icon: value < 0.4 ? "brightness_low" : value < 0.75 ? "brightness_medium" : "brightness_high"
                        onMoved: v => Sys.setBrightness(v)
                    }
                }

                MediaCard { Layout.fillWidth: true }

                // Notificaciones
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 4
                    Text { text: "Notificaciones"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.DemiBold }
                    Rectangle {
                        visible: Notifs.count > 0; implicitWidth: cnt.implicitWidth + 14; implicitHeight: 20; radius: 10; color: Theme.primarySoft
                        Text { id: cnt; anchors.centerIn: parent; text: Notifs.count; color: Theme.primary; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        visible: Notifs.count > 0
                        implicitWidth: cl.implicitWidth + 28; implicitHeight: 30; radius: 15
                        color: clm.containsMouse ? Qt.darker(Theme.danger, 1.6) : Theme.surfaceHi
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        RowLayout { id: cl; anchors.centerIn: parent; spacing: 4
                            MIcon { name: "clear_all"; size: 16 }
                            Text { text: "Limpiar"; color: Theme.text; font.family: Theme.font; font.pixelSize: 12 } }
                        MouseArea { id: clm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                    }
                }
                ListView {
                    id: nlist
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 8
                    model: Notifs.list
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: NotifCard {
                        required property var modelData
                        width: nlist.width; notif: modelData
                        onDismissed: modelData.dismiss()
                    }
                    add: Transition { ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.anim }
                        NumberAnimation { property: "x"; from: 40; to: 0; duration: Theme.anim; easing.type: Easing.OutCubic } } }
                    remove: Transition { ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: Theme.animFast }
                        NumberAnimation { property: "x"; to: 120; duration: Theme.animFast } } }
                    displaced: Transition { NumberAnimation { property: "y"; duration: Theme.anim; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 6; visible: Notifs.count === 0
                        MIcon { Layout.alignment: Qt.AlignHCenter; name: Notifs.dnd ? "notifications_paused" : "notifications_none"; size: 44; color: Theme.faint }
                        Text { Layout.alignment: Qt.AlignHCenter; text: Notifs.dnd ? "No molestar activado" : "Todo al día"; color: Theme.sub; font.family: Theme.font; font.pixelSize: 13 }
                    }
                }
            }

            // ================= PÁGINAS DE DETALLE =================
            WifiPage {
                width: parent.width; height: parent.height
                x: win.page === "wifi" ? 0 : width
                visible: x < width
                Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                onBack: win.page = "main"
            }
            BtPage {
                width: parent.width; height: parent.height
                x: win.page === "bt" ? 0 : width
                visible: x < width
                Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                onBack: win.page = "main"
            }
        }
    }
}
