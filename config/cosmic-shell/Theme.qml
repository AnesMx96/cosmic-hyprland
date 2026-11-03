pragma Singleton
import QtQuick
import Quickshell

// Paleta "Cosmic" — azul noche sólido, blanco y acento cian (inspirada en Material You / end-4)
Singleton {
    readonly property color bg:          "#0b1222"
    readonly property color surface:     "#121b31"
    readonly property color surfaceHi:   "#1a2541"
    readonly property color surfaceHover:"#212e4f"
    readonly property color outline:     Qt.rgba(1, 1, 1, 0.08)
    readonly property color edge:        Qt.rgba(1, 1, 1, 0.22)
    readonly property color primary:     "#8cc3ff"
    readonly property color primarySoft: "#253a5e"
    readonly property color fgOnPrimary:   "#06101f"
    readonly property color text:        "#eaf2ff"
    readonly property color sub:         "#9fb0cf"
    readonly property color faint:       "#64739a"
    readonly property color danger:      "#ff6b8b"
    readonly property color warn:        "#ffd479"
    readonly property color ok:          "#9ef0c4"

    readonly property string font: "Inter"
    readonly property string icons: "Material Icons Round"

    readonly property int radiusXl: 28
    readonly property int radiusL: 22
    readonly property int radiusM: 16
    readonly property int radiusS: 12

    readonly property int animFast: 160
    readonly property int anim: 260
    readonly property int animSlow: 420
    // curva "emphasized decelerate" de Material 3
    readonly property list<real> curveDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property list<real> curveStd:   [0.2, 0, 0, 1, 1, 1]
}
