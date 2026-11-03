import QtQuick
import QtQuick.Layouts
// Toggle grande estilo end-4: círculo con icono + título + subtítulo. Clic = alternar, clic en la flecha = detalles
Rectangle {
    id: t
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool expandable: false
    signal toggled()
    signal expand()
    implicitHeight: 64
    radius: Theme.radiusL
    color: active ? Theme.primary : (ma.containsMouse ? Theme.surfaceHover : Theme.surfaceHi)
    scale: ma.pressed ? 0.97 : 1
    Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }

    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled() }

    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 10
        Rectangle {
            Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 22
            color: t.active ? Qt.rgba(0, 0, 0, 0.12) : Theme.surface
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            MIcon { anchors.centerIn: parent; name: t.icon; size: 22; color: t.active ? Theme.fgOnPrimary : Theme.text }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 1
            Text { text: t.title; color: t.active ? Theme.fgOnPrimary : Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
            Text { text: t.subtitle; visible: text !== ""; color: t.active ? Qt.rgba(0.02, 0.06, 0.12, 0.72) : Theme.sub; font.family: Theme.font; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        Rectangle {
            visible: t.expandable
            Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 15
            color: ea.containsMouse ? Qt.rgba(0, 0, 0, 0.12) : "transparent"
            MIcon { anchors.centerIn: parent; name: "chevron_right"; size: 20; color: t.active ? Theme.fgOnPrimary : Theme.sub }
            MouseArea { id: ea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.expand() }
        }
    }
}
