import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Networking

// Lista de redes Wi-Fi con conexión y contraseña
ColumnLayout {
    id: page
    signal back()
    spacing: 10
    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var nets: dev ? dev.networks.values.slice().filter(n => n.name !== "").sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []
    property var pending: null
    onVisibleChanged: { if (dev) dev.scannerEnabled = visible; if (!visible) pending = null; }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        IconButton { icon: "arrow_back"; onClicked: page.back() }
        Text { text: "Wi-Fi"; color: Theme.text; font.family: Theme.font; font.pixelSize: 18; font.weight: Font.DemiBold; Layout.fillWidth: true }
        Switch {
            id: sw
            checked: Networking.wifiEnabled
            onToggled: Sys.run("nmcli radio wifi " + (checked ? "on" : "off"))
            indicator: Rectangle {
                implicitWidth: 52; implicitHeight: 30; radius: 15
                color: sw.checked ? Theme.primary : Theme.surfaceHi
                Behavior on color { ColorAnimation { duration: Theme.anim } }
                Rectangle {
                    width: 22; height: 22; radius: 11; y: 4
                    x: sw.checked ? parent.width - width - 4 : 4
                    color: sw.checked ? Theme.fgOnPrimary : Theme.sub
                    Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
                }
            }
        }
    }

    ListView {
        Layout.fillWidth: true; Layout.fillHeight: true
        clip: true; spacing: 6
        model: ScriptModel { values: page.nets }
        boundsBehavior: Flickable.StopAtBounds
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.anim } }
        delegate: Rectangle {
            id: item
            required property var modelData
            width: ListView.view.width
            implicitHeight: page.pending === modelData ? 108 : 56
            radius: Theme.radiusM
            color: modelData.connected ? Theme.primarySoft : (im.containsMouse ? Theme.surfaceHover : Theme.surfaceHi)
            clip: true
            Behavior on implicitHeight { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            MouseArea {
                id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (item.modelData.connected) item.modelData.disconnect();
                    else if (item.modelData.known || item.modelData.security === WifiSecurityType.Open) item.modelData.connect();
                    else { page.pending = item.modelData; pw.forceActiveFocus(); }
                }
            }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 8
                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: 36; spacing: 12
                    MIcon {
                        readonly property real sig: item.modelData.signalStrength > 1 ? item.modelData.signalStrength / 100 : item.modelData.signalStrength
                        size: 22; color: item.modelData.connected ? Theme.primary : Theme.text
                        name: sig > 0.75 ? "signal_wifi_4_bar" : sig > 0.5 ? "network_wifi_3_bar" : sig > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: item.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: item.modelData.connected ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text {
                            text: item.modelData.connected ? "Conectado" : item.modelData.stateChanging ? "Conectando…" : item.modelData.known ? "Guardada" : ""
                            visible: text !== ""; color: Theme.sub; font.family: Theme.font; font.pixelSize: 11
                        }
                    }
                    MIcon { name: "lock"; size: 16; color: Theme.faint; visible: item.modelData.security !== WifiSecurityType.Open }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    visible: page.pending === item.modelData
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 40; radius: 20; color: Theme.surface; border.width: 1; border.color: pw.activeFocus ? Theme.primary : Theme.outline
                        TextInput {
                            id: pw
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password; color: Theme.text; font.family: Theme.font; font.pixelSize: 14
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Contraseña"; color: Theme.faint; font: pw.font; visible: pw.text === "" }
                            onAccepted: { item.modelData.connectWithPsk(text); text = ""; page.pending = null; }
                            Keys.onEscapePressed: page.pending = null
                            onVisibleChanged: if (!visible) text = ""
                        }
                    }
                    IconButton { icon: "arrow_forward"; bgIdle: Theme.primary; fg: Theme.fgOnPrimary; onClicked: pw.accepted() }
                }
            }
        }
    }
    Text {
        visible: page.nets.length === 0
        Layout.alignment: Qt.AlignHCenter
        text: Networking.wifiEnabled ? "Buscando redes…" : "El Wi-Fi está apagado"
        color: Theme.sub; font.family: Theme.font; font.pixelSize: 13
    }
    Rectangle {
        Layout.fillWidth: true; implicitHeight: 40; radius: 20; color: sm.containsMouse ? Theme.surfaceHover : Theme.surfaceHi
        Text { anchors.centerIn: parent; text: "Ajustes de red avanzados"; color: Theme.text; font.family: Theme.font; font.pixelSize: 13 }
        MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Sys.run("nm-connection-editor") }
    }
}
