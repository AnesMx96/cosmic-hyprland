import QtQuick
import Quickshell
import Quickshell.Io

// Barras de audio con cava: solo corre con el panel abierto y la música sonando
Item {
    id: v
    property bool running: false
    property var bars: []

    Process {
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cosmic-shell/cava.conf"]
        running: v.running
        stdout: SplitParser {
            onRead: data => v.bars = data.split(";").filter(x => x !== "").map(Number)
        }
    }
    Row {
        anchors.fill: parent
        spacing: 2
        Repeater {
            model: 36
            Rectangle {
                required property int index
                anchors.bottom: parent.bottom
                width: (v.width - 35 * 2) / 36
                height: Math.max(2, v.height * (v.bars[index] ?? 0) / 100)
                radius: 1.5
                opacity: 0.28
                Behavior on height { NumberAnimation { duration: 90 } }
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.ice }
                    GradientStop { position: 1; color: Theme.primary }
                }
            }
        }
    }
}
