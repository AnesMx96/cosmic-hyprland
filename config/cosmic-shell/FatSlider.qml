import QtQuick
// Slider grueso estilo Material You: el relleno lleva el icono dentro
Item {
    id: s
    property real value: 0.5
    property string icon: "volume_up"
    property string label: Math.round(value * 100) + "%"
    property bool dimmed: false
    signal moved(real v)
    signal iconClicked()
    implicitHeight: 44

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceHi
        clip: true
        Rectangle {
            id: fill
            height: parent.height
            width: Math.max(height, parent.width * s.value)
            radius: height / 2
            color: s.dimmed ? Theme.faint : Theme.primary
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.anim } }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
            text: s.label; color: s.value > 0.86 ? (s.dimmed ? Theme.text : Theme.fgOnPrimary) : Theme.sub; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium
            font.features: { "tnum": 1 }
        }
    }
    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.leftMargin: 44
        cursorShape: Qt.PointingHandCursor
        function upd(mx) { s.moved(Math.max(0, Math.min(1, (mx + 44) / s.width))); }
        onPressed: m => upd(m.x)
        onPositionChanged: m => { if (pressed) upd(m.x) }
        onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
    // icono (clic = silenciar)
    Item {
        width: 44; height: 44
        MIcon { anchors.centerIn: parent; name: s.icon; size: 20; color: s.dimmed ? Theme.text : Theme.fgOnPrimary }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: s.iconClicked() }
    }
}
