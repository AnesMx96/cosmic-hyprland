import QtQuick
// Icono Material Round por nombre (ligadura): MIcon { name: "wifi" }
Text {
    property string name: ""
    property real size: 20
    text: name
    font.family: Theme.icons
    font.pixelSize: size
    color: Theme.text
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
