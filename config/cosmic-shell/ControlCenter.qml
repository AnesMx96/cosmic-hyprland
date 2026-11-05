import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Widgets

PanelWindow {
    id: win
    property bool open: false
    property string page: "main"
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    // sin ancla arriba ni abajo: queda pegado a la derecha y centrado en vertical
    anchors { right: true }
    margins { right: 12 }
    implicitWidth: 440
    implicitHeight: Math.min(830, (win.screen?.height ?? 1080) - 110)
    exclusiveZone: 0
    color: "transparent"
    visible: open || slide.running
    WlrLayershell.namespace: "cosmic-cc"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        Sys.active = open;
        if (!open) return;
        page = "main"; Sys.refresh();
        const h = new Date().getHours();
        greeting = h < 6 ? "Buenas noches" : h < 13 ? "Buenos días" : h < 21 ? "Buenas tardes" : "Buenas noches";
    }

    HyprlandFocusGrab { windows: [win]; active: win.open; onCleared: win.open = false }
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    readonly property var sink: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var source: Pipewire.defaultAudioSource?.audio ?? null
    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifiDev ? wifiDev.networks.values.find(n => n.connected) ?? null : null
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property real bat: { const p = UPower.displayDevice?.percentage ?? 0; return p > 1 ? p : p * 100; }
    property string greeting: ""

    Rectangle {
        id: panel
        width: parent.width; height: parent.height
        x: win.open ? 0 : width + 24
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.96
        transformOrigin: Item.Right
        radius: Theme.radiusXl
        color: "transparent"
        focus: win.open
        Keys.onEscapePressed: win.page === "main" ? win.open = false : win.page = "main"
        Behavior on x { NumberAnimation { id: slide; duration: Theme.animSlow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveDecel } }
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
        Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveDecel } }

        // El espacio: el agujero negro ocupa el hueco de las notificaciones y se aparta si hay alguna
        ClippingRectangle {
            anchors.fill: parent
            radius: Theme.radiusXl
            color: Theme.bg
            CosmicBackdrop {
                anchors.fill: parent
                running: win.visible
                holeY: parent.height - 16 - nlist.height / 2
                holeR: Math.min(86, Math.max(46, nlist.height * 0.27))
                strength: win.page === "main" && Notifs.count === 0 ? 1 : 0.4
            }
        }
        CosmicBorder { anchors.fill: parent; running: win.visible }

        // Entrada escalonada: de arriba abajo
        Reveal { target: header; active: win.open; delay: 40 }
        Reveal { target: stats; active: win.open; delay: 65 }
        Reveal { target: tWifi; active: win.open; delay: 90 }
        Reveal { target: tBt; active: win.open; delay: 120 }
        Reveal { target: tDnd; active: win.open; delay: 150 }
        Reveal { target: tNight; active: win.open; delay: 180 }
        Reveal { target: tCaf; active: win.open; delay: 210 }
        Reveal { target: tGame; active: win.open; delay: 240 }
        Reveal { target: sliders; active: win.open; delay: 280 }
        Reveal { target: media; active: win.open; delay: 330 }
        Reveal { target: notifHead; active: win.open; delay: 370 }

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
                    id: header
                    Layout.fillWidth: true; spacing: 12
                    OrbitAvatar { letter: Sys.user.charAt(0).toUpperCase(); running: win.visible }
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

                // Rendimiento
                RowLayout {
                    id: stats
                    Layout.fillWidth: true; Layout.leftMargin: 4; Layout.rightMargin: 4
                    StatRing { Layout.fillWidth: true; title: "CPU"; value: Sys.cpu; text: Math.round(Sys.cpu * 100) + "%" }
                    StatRing { Layout.fillWidth: true; title: "Memoria"; value: Sys.mem; text: Math.round(Sys.mem * 100) + "%" }
                    StatRing { Layout.fillWidth: true; title: "Temperatura"; value: Math.min(1, Sys.temp / 100); text: Math.round(Sys.temp) + "°" }
                }

                // Toggles
                GridLayout {
                    Layout.fillWidth: true; columns: 2; rowSpacing: 8; columnSpacing: 8
                    Tile {
                        id: tWifi
                        Layout.fillWidth: true; icon: Networking.wifiEnabled ? "wifi" : "wifi_off"; title: "Wi-Fi"; expandable: true
                        subtitle: !Networking.wifiEnabled ? "Apagado" : (win.wifiNet?.name ?? "Sin conexión")
                        active: Networking.wifiEnabled
                        onToggled: Sys.run("nmcli radio wifi " + (Networking.wifiEnabled ? "off" : "on"))
                        onExpand: win.page = "wifi"
                    }
                    Tile {
                        id: tBt
                        Layout.fillWidth: true; title: "Bluetooth"; expandable: true
                        readonly property bool on: Bluetooth.defaultAdapter?.enabled ?? false
                        icon: on ? (win.btConnected.length ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
                        subtitle: !on ? "Apagado" : (win.btConnected.length ? win.btConnected[0].name : "Encendido")
                        active: on
                        onToggled: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !on
                        onExpand: win.page = "bt"
                    }
                    Tile { id: tDnd; Layout.fillWidth: true; icon: Notifs.dnd ? "notifications_off" : "notifications"; title: "No molestar"; subtitle: Notifs.dnd ? "Activado" : "Desactivado"; active: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
                    Tile { id: tNight; Layout.fillWidth: true; icon: "nightlight"; title: "Luz nocturna"; subtitle: Sys.night ? "4500 K" : "Desactivada"; active: Sys.night; onToggled: Sys.toggleNight() }
                    Tile { id: tCaf; Layout.fillWidth: true; icon: "coffee"; title: "Cafeína"; subtitle: Sys.caffeine ? "Pantalla siempre encendida" : "Desactivada"; active: Sys.caffeine; onToggled: Sys.toggleCaffeine() }
                    Tile { id: tGame; Layout.fillWidth: true; icon: "sports_esports"; title: "Modo juego"; subtitle: Sys.gaming ? "Sin efectos" : "Desactivado"; active: Sys.gaming; onToggled: Sys.toggleGaming() }
                }

                // Sliders
                ColumnLayout {
                    id: sliders
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

                MediaCard { id: media; Layout.fillWidth: true }

                // Notificaciones
                RowLayout {
                    id: notifHead
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
                        anchors.centerIn: parent; anchors.verticalCenterOffset: -Math.min(86, Math.max(46, nlist.height * 0.27)) * 0.42; spacing: 6; visible: Notifs.count === 0
                        MIcon { Layout.alignment: Qt.AlignHCenter; name: Notifs.dnd ? "notifications_paused" : "notifications_none"; size: 26; color: Theme.ice }
                        Text { Layout.alignment: Qt.AlignHCenter; text: Notifs.dnd ? "No molestar" : "Todo al día"; color: Theme.ice; font.family: Theme.font; font.pixelSize: 13 }
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
