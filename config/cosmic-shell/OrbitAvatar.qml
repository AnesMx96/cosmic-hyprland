import QtQuick
import QtQuick.Shapes

// Inicial del usuario dentro de un agujero negro en miniatura, con un punto en órbita
Item {
    id: a
    property string letter: ""
    property bool running: false
    implicitWidth: 48; implicitHeight: 48

    Shape {
        anchors.fill: parent
        ShapePath {
            strokeWidth: 0; strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            fillGradient: ConicalGradient {
                centerX: a.width / 2; centerY: a.height / 2
                NumberAnimation on angle { from: 0; to: 360; duration: 6000; loops: Animation.Infinite; running: a.running }
                GradientStop { position: 0; color: "#ffffff" }
                GradientStop { position: 0.3; color: "#6A96BF" }
                GradientStop { position: 0.6; color: "#182C5F94" }
                GradientStop { position: 0.82; color: "#c98a6b" }
                GradientStop { position: 1; color: "#ffffff" }
            }
            PathAngleArc { centerX: a.width / 2; centerY: a.height / 2; radiusX: a.width / 2; radiusY: a.width / 2; startAngle: 0; sweepAngle: 360 }
            PathAngleArc { centerX: a.width / 2; centerY: a.height / 2; radiusX: a.width / 2 - 2; radiusY: a.width / 2 - 2; startAngle: 0; sweepAngle: 360 }
        }
    }
    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 6; height: width; radius: width / 2
        color: Theme.vacuum
        Text { anchors.centerIn: parent; text: a.letter; color: Theme.ice; font.family: Theme.font; font.pixelSize: 19; font.weight: Font.DemiBold }
    }
    Item {
        anchors.fill: parent
        RotationAnimator on rotation { from: 0; to: 360; duration: 9000; loops: Animation.Infinite; running: a.running }
        Rectangle { x: parent.width / 2 - 2.5; y: -1; width: 5; height: 5; radius: 2.5; color: "#ffffff" }
    }
}
