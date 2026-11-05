import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// Anillo pequeño de rendimiento: CPU, memoria, temperatura
RowLayout {
    id: s
    property real value: 0                // 0..1
    property string title: ""
    property string text: ""
    spacing: 8
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    Item {
        Layout.preferredWidth: 38; Layout.preferredHeight: 38
        Shape {
            anchors.fill: parent
            ShapePath {
                fillColor: "transparent"; strokeColor: Theme.surfaceHover; strokeWidth: 3.5
                PathAngleArc { centerX: 19; centerY: 19; radiusX: 16; radiusY: 16; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {
                fillColor: "transparent"; strokeWidth: 3.5; capStyle: ShapePath.RoundCap
                strokeColor: s.value > 0.85 ? Theme.danger : s.value > 0.65 ? Theme.ember : Theme.primary
                PathAngleArc { centerX: 19; centerY: 19; radiusX: 16; radiusY: 16; startAngle: -90; sweepAngle: Math.max(1, 360 * s.shown) }
            }
        }
    }
    ColumnLayout {
        spacing: 0
        Text { text: s.text; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
        Text { text: s.title; color: Theme.sub; font.family: Theme.font; font.pixelSize: 11 }
    }
}
