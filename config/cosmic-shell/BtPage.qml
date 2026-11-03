import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth

ColumnLayout {
    id: page
    signal back()
    spacing: 10
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devs: Bluetooth.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
    onVisibleChanged: if (adapter && adapter.enabled) adapter.discovering = visible

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        IconButton { icon: "arrow_back"; onClicked: page.back() }
        Text { text: "Bluetooth"; color: Theme.text; font.family: Theme.font; font.pixelSize: 18; font.weight: Font.DemiBold; Layout.fillWidth: true }
        Switch {
            id: sw
            checked: page.adapter?.enabled ?? false
            onToggled: if (page.adapter) page.adapter.enabled = checked
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
        clip: true; spacing: 6; model: page.devs
        delegate: Rectangle {
            id: d
            required property var modelData
            width: ListView.view.width; implicitHeight: 56; radius: Theme.radiusM
            color: modelData.connected ? Theme.primarySoft : (dm.containsMouse ? Theme.surfaceHover : Theme.surfaceHi)
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            MouseArea {
                id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: d.modelData.connected ? d.modelData.disconnect() : (d.modelData.paired ? d.modelData.connect() : d.modelData.pair())
            }
            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 12
                MIcon {
                    size: 22; color: d.modelData.connected ? Theme.primary : Theme.text
                    name: (d.modelData.icon || "").indexOf("audio") !== -1 ? "headphones" : (d.modelData.icon || "").indexOf("phone") !== -1 ? "smartphone" : (d.modelData.icon || "").indexOf("input") !== -1 ? "mouse" : "bluetooth"
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    Text { text: d.modelData.name || d.modelData.address; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; elide: Text.ElideRight; Layout.fillWidth: true }
                    Text {
                        text: d.modelData.connected ? "Conectado" + (d.modelData.batteryAvailable ? " · " + Math.round(d.modelData.battery * 100) + "%" : "") : d.modelData.pairing ? "Emparejando…" : d.modelData.paired ? "Emparejado" : "Disponible"
                        color: Theme.sub; font.family: Theme.font; font.pixelSize: 11
                    }
                }
            }
        }
    }
    Text {
        visible: page.devs.length === 0; Layout.alignment: Qt.AlignHCenter
        text: (page.adapter?.enabled ?? false) ? "Buscando dispositivos…" : "El Bluetooth está apagado"
        color: Theme.sub; font.family: Theme.font; font.pixelSize: 13
    }
    Rectangle {
        Layout.fillWidth: true; implicitHeight: 40; radius: 20; color: bm.containsMouse ? Theme.surfaceHover : Theme.surfaceHi
        Text { anchors.centerIn: parent; text: "Abrir gestor Bluetooth"; color: Theme.text; font.family: Theme.font; font.pixelSize: 13 }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Sys.run("blueman-manager") }
    }
}
