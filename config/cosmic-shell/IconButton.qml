import QtQuick
// Botón circular con icono, hover suave y "pulsación" con escala
Rectangle {
    id: b
    property string icon: ""
    property real iconSize: 20
    property color fg: Theme.text
    property color bgIdle: Theme.surfaceHi
    property color bgHover: Theme.surfaceHover
    property bool danger: false
    signal clicked()
    implicitWidth: 40; implicitHeight: 40
    radius: height / 2
    color: ma.containsMouse ? (danger ? Qt.darker(Theme.danger, 1.6) : bgHover) : bgIdle
    scale: ma.pressed ? 0.92 : 1
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
    MIcon { anchors.centerIn: parent; name: b.icon; size: b.iconSize; color: ma.containsMouse && b.danger ? "#ffffff" : b.fg }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
