import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
// Toggle de cristal: encendido brilla como el disco de acreción. Clic = alternar, flecha = detalles
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
    color: ma.containsMouse || ea.containsMouse ? Theme.surfaceHover : Theme.surfaceHi
    border.width: 1
    border.color: ma.containsMouse || ea.containsMouse ? Theme.edge : Theme.outline
    scale: ma.pressed ? 0.97 : (ma.containsMouse ? 1.012 : 1)
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }

    // Capa encendida, con un destello que la cruza
    Rectangle {
        anchors.fill: parent
        radius: t.radius
        opacity: t.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.ice }
            GradientStop { position: 0.55; color: Theme.primary }
            GradientStop { position: 1; color: "#6A96BF" }
        }
    }
    ClippingRectangle {
        anchors.fill: parent
        radius: t.radius
        color: "transparent"
        opacity: t.active ? 1 : 0
        Rectangle {
            id: sheen
            width: 70; height: parent.height * 2
            y: -parent.height / 2; rotation: 18
            x: -120
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#00ffffff" }
                GradientStop { position: 0.5; color: "#88ffffff" }
                GradientStop { position: 1; color: "#00ffffff" }
            }
            SequentialAnimation on x {
                running: t.active && Sys.active; loops: Animation.Infinite
                PauseAnimation { duration: 3600 }
                NumberAnimation { from: -120; to: t.width + 60; duration: 1100; easing.type: Easing.InOutSine }
            }
        }
    }

    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled() }

    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 10
        Rectangle {
            Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 22
            color: t.active ? Qt.rgba(0.01, 0.03, 0.1, 0.16) : Theme.surface
            border.width: 1; border.color: t.active ? Qt.rgba(1, 1, 1, 0.4) : Theme.outline
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
