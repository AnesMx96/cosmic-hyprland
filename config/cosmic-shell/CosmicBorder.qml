import QtQuick
import QtQuick.Shapes

// Filo del panel con una luz que lo recorre sin parar, como el anillo de fotones
Shape {
    id: b
    property real radius: Theme.radiusXl
    property real thickness: 1.5
    property bool running: false
    ShapePath {
        strokeWidth: 0; strokeColor: "transparent"
        fillRule: ShapePath.OddEvenFill
        fillGradient: ConicalGradient {
            centerX: b.width / 2; centerY: b.height / 2
            NumberAnimation on angle { from: 0; to: 360; duration: 14000; loops: Animation.Infinite; running: b.running }
            GradientStop { position: 0; color: "#ffffff" }
            GradientStop { position: 0.14; color: "#6A96BF" }
            GradientStop { position: 0.36; color: "#242C5F94" }
            GradientStop { position: 0.62; color: "#242C5F94" }
            GradientStop { position: 0.8; color: "#c98a6b" }
            GradientStop { position: 1; color: "#ffffff" }
        }
        PathRectangle { x: 0; y: 0; width: b.width; height: b.height; radius: b.radius }
        PathRectangle { x: b.thickness; y: b.thickness; width: b.width - 2 * b.thickness; height: b.height - 2 * b.thickness; radius: b.radius - b.thickness }
    }
}
