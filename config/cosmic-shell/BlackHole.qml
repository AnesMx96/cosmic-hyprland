import QtQuick

// Agujero negro en la GPU (ver shaders/blackhole.frag). Solo avanza con running.
ShaderEffect {
    id: fx
    property bool running: false
    property real holeRadius: 70          // radio de la sombra, en píxeles
    property real centerX: width / 2
    property real centerY: height / 2
    property real time: 0
    property real tilt: 0.2
    readonly property real aspect: width / Math.max(1, height)
    readonly property real cx: centerX / Math.max(1, width)
    readonly property real cy: centerY / Math.max(1, height)
    readonly property real zoom: holeRadius / 2.72 / Math.max(1, height)
    readonly property real pixel: 1 / Math.max(1, height)
    fragmentShader: Qt.resolvedUrl("shaders/blackhole.frag.qsb")
    NumberAnimation on time { from: 0; to: 3600; duration: 3600000; loops: Animation.Infinite; running: fx.running }
}
