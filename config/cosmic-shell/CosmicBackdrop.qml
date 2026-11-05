import QtQuick
import QtQuick.Shapes

// El agujero negro del fondo de pantalla, dibujado a mano: estrellas, trazos del halo,
// sombra, anillo de fotones y banda de acreción blanca que acaba en cobre.
// Lo pesado se pinta una sola vez en Canvas; luego solo se rotan y funden capas.
Item {
    id: root
    property bool running: false
    property real holeX: width / 2
    property real holeY: height * 0.7
    property real holeR: 78
    property real strength: 1
    // sin GPU o sin shader se dibuja la versión en Canvas
    readonly property bool gpu: fx.status !== ShaderEffect.Error
    Behavior on strength { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#081434" }
            GradientStop { position: 0.5; color: "#050c24" }
            GradientStop { position: 1; color: Theme.vacuum }
        }
    }

    // Estrellas fijas
    Canvas {
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d");
            c.clearRect(0, 0, width, height);
            for (let i = 0; i < 170; i++) {
                const big = Math.random() > 0.92;
                c.fillStyle = Qt.rgba(0.85, 0.92, 1, 0.12 + Math.random() * (big ? 0.7 : 0.4));
                c.fillRect(Math.random() * width, Math.random() * height, big ? 1.6 : 1, big ? 1.6 : 1);
            }
        }
    }

    // Estrellas que titilan
    Repeater {
        model: 14
        Rectangle {
            required property int index
            readonly property real seed: (index * 0.61803) % 1
            x: root.width * ((index * 0.37 + 0.11) % 1)
            y: root.height * ((index * 0.73 + 0.07) % 1)
            width: 2; height: 2; radius: 1
            color: Theme.ice
            opacity: 0.2
            SequentialAnimation on opacity {
                running: root.running; loops: Animation.Infinite
                PauseAnimation { duration: 400 + 2400 * seed }
                NumberAnimation { to: 0.95; duration: 900 + 900 * seed; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.15; duration: 1100 + 900 * seed; easing.type: Easing.InOutSine }
            }
        }
    }

    Item {
        id: hole
        anchors.fill: parent
        opacity: root.strength

        // Resplandor azul
        Shape {
            anchors.fill: parent
            opacity: 0.8
            ShapePath {
                strokeWidth: 0; strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: root.holeX; centerY: root.holeY; centerRadius: root.holeR * 3.4
                    focalX: root.holeX; focalY: root.holeY; focalRadius: root.holeR * 0.8
                    GradientStop { position: 0; color: "#552C5F94" }
                    GradientStop { position: 0.45; color: "#1f2C5F94" }
                    GradientStop { position: 1; color: "#002C5F94" }
                }
                PathRectangle { x: 0; y: 0; width: root.width; height: root.height }
            }
        }

        BlackHole {
            id: fx
            width: root.width; height: Math.min(root.holeR * 6.5, root.height)
            y: Math.max(0, root.holeY - height / 2)
            centerY: root.holeY - y
            holeRadius: root.holeR
            running: root.running
            visible: root.gpu
        }

        Item {
        anchors.fill: parent
        visible: !root.gpu
        // Dos capas de trazos finos que giran a distinta velocidad
        Repeater {
            model: [
                { dir: 1, secs: 120, count: 300, alpha: 0.17, reach: 2.2 },
                { dir: -1, secs: 75, count: 170, alpha: 0.11, reach: 1.6 }
            ]
            Canvas {
                id: swirl
                required property var modelData
                width: root.holeR * 7; height: width
                x: root.holeX - width / 2; y: root.holeY - height / 2
                onPaint: {
                    const c = getContext("2d"), m = width / 2, R = root.holeR;
                    c.clearRect(0, 0, width, height);
                    c.lineCap = "round";
                    for (let i = 0; i < modelData.count; i++) {
                        const t = Math.pow(Math.random(), 1.7), r = R * (1.06 + modelData.reach * t);
                        const a0 = Math.random() * Math.PI * 2, len = 0.25 + Math.random() * 1.1;
                        const k = (1 - t) * modelData.alpha * (0.4 + Math.random() * 0.6);
                        c.strokeStyle = Math.random() > 0.3 ? Qt.rgba(0.83, 0.91, 0.96, k) : Qt.rgba(0.42, 0.59, 0.75, k * 1.4);
                        c.lineWidth = 0.4 + Math.random() * 0.9;
                        c.beginPath(); c.arc(m, m, r, a0, a0 + len); c.stroke();
                    }
                }
                RotationAnimator on rotation {
                    from: 0; to: 360 * swirl.modelData.dir
                    duration: swirl.modelData.secs * 1000
                    loops: Animation.Infinite; running: root.running
                }
            }
        }

        // Arco de luz sobre la sombra, como la lente gravitatoria del fondo
        Canvas {
            id: lens
            width: root.holeR * 7; height: width
            x: root.holeX - width / 2; y: root.holeY - height / 2
            onPaint: {
                const c = getContext("2d"), m = width / 2, R = root.holeR;
                c.clearRect(0, 0, width, height);
                c.lineCap = "round";
                for (let i = 0; i < 520; i++) {
                    const t = Math.pow(Math.random(), 1.5), r = R * (1.03 + 1.25 * t);
                    const span = 0.35 + Math.random() * 1.0;
                    const mid = (Math.random() - 0.5) * 2.9;          // 0 = arriba del todo
                    const a0 = -Math.PI / 2 + mid - span / 2;
                    const side = 1 - Math.pow(Math.abs(mid) / 1.45, 2) * 0.75;
                    c.strokeStyle = Qt.rgba(0.88, 0.95, 1, (1 - t) * side * (0.2 + Math.random() * 0.55));
                    c.lineWidth = 0.4 + Math.random() * 1.2;
                    c.beginPath(); c.arc(m, m, r, a0, a0 + span); c.stroke();
                }
            }
            SequentialAnimation on opacity {
                running: root.running; loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.72; duration: 3600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.72; to: 1; duration: 3600; easing.type: Easing.InOutSine }
            }
        }

        // Sombra y anillo de fotones: muy brillante arriba, casi apagado abajo
        Rectangle {
            x: root.holeX - root.holeR; y: root.holeY - root.holeR
            width: root.holeR * 2; height: width; radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "#0a2a63" }
                GradientStop { position: 0.55; color: "#061338" }
                GradientStop { position: 1; color: Theme.vacuum }
            }
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                fillColor: "transparent"
                strokeWidth: 1.6
                strokeGradient: LinearGradient {
                    x1: root.holeX; y1: root.holeY - root.holeR
                    x2: root.holeX; y2: root.holeY + root.holeR
                    GradientStop { position: 0; color: "#ffffff" }
                    GradientStop { position: 0.55; color: "#c0d4e9f6" }
                    GradientStop { position: 1; color: "#202C5F94" }
                }
                PathAngleArc { centerX: root.holeX; centerY: root.holeY; radiusX: root.holeR; radiusY: root.holeR; startAngle: 0; sweepAngle: 360 }
            }
        }

        // Banda de acreción: blanca arriba, cobre abajo, afilada hacia los extremos
        Canvas {
            width: root.width; height: root.holeR * 1.1
            x: 0; y: root.holeY + root.holeR * 0.66 - height / 2
            rotation: -1.5
            onPaint: {
                const c = getContext("2d"), w = width, h = height, cx = root.holeX;
                c.clearRect(0, 0, w, h);
                c.lineCap = "round";
                for (let i = 0; i < 420; i++) {
                    const g = (Math.random() + Math.random() + Math.random()) / 3;
                    const len = w * (0.1 + Math.random() * 0.34);
                    const x = cx + (Math.random() + Math.random() - 1) * w * 0.62 - len / 2;
                    const off = Math.abs(x + len / 2 - cx) / (w / 2);        // 0 centro, 1 borde
                    const y = h / 2 + (g - 0.5) * h * (1 - off * 0.7);
                    const lower = g > 0.54;
                    const k = (1 - Math.abs(g - 0.5) * 2) * (1 - off * 0.55) * (0.3 + Math.random() * 0.6);
                    const col = lower ? [0.79, 0.54, 0.42] : [0.92, 0.96, 1];
                    const grad = c.createLinearGradient(x, 0, x + len, 0);
                    grad.addColorStop(0, Qt.rgba(col[0], col[1], col[2], 0));
                    grad.addColorStop(0.5, Qt.rgba(col[0], col[1], col[2], k));
                    grad.addColorStop(1, Qt.rgba(col[0], col[1], col[2], 0));
                    c.strokeStyle = grad;
                    c.lineWidth = 0.4 + Math.random() * 1.0;
                    c.beginPath(); c.moveTo(x, y); c.quadraticCurveTo(x + len / 2, y + (lower ? 1.5 : -1.5), x + len, y); c.stroke();
                }
            }
        }
        }
    }

    // Estrella fugaz de vez en cuando
    Rectangle {
        id: comet
        width: 90; height: 1.5; radius: 1
        rotation: 18; opacity: 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: "#ffffff" }
        }
        ParallelAnimation {
            id: cometFly
            NumberAnimation { target: comet; property: "x"; from: comet.startX; to: comet.startX + 230; duration: 750; easing.type: Easing.InQuad }
            NumberAnimation { target: comet; property: "y"; from: comet.startY; to: comet.startY + 75; duration: 750; easing.type: Easing.InQuad }
            SequentialAnimation {
                NumberAnimation { target: comet; property: "opacity"; to: 0.95; duration: 180 }
                NumberAnimation { target: comet; property: "opacity"; to: 0; duration: 570 }
            }
        }
        property real startX: 0
        property real startY: 0
        Timer {
            interval: 8000; repeat: true; running: root.running
            onTriggered: {
                interval = 7000 + Math.random() * 9000;
                comet.startX = Math.random() * root.width * 0.5;
                comet.startY = Math.random() * root.height * 0.3;
                cometFly.restart();
            }
        }
    }
}
