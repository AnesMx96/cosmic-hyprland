import QtQuick

// Aparición escalonada de un elemento al abrir el panel
QtObject {
    id: r
    property Item target
    property bool active: false
    property int delay: 0
    property real distance: 16
    property Translate shift: Translate {}
    Component.onCompleted: if (target) target.transform = shift
    property var seq: SequentialAnimation {
        PropertyAction { target: r.target; property: "opacity"; value: 0 }
        PropertyAction { target: r.shift; property: "y"; value: r.distance }
        PauseAnimation { duration: r.delay }
        ParallelAnimation {
            NumberAnimation { target: r.target; property: "opacity"; to: 1; duration: Theme.anim; easing.type: Easing.OutCubic }
            NumberAnimation { target: r.shift; property: "y"; to: 0; duration: Theme.animSlow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveDecel }
        }
    }
    onActiveChanged: if (active) seq.restart()
}
