import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris

// Tarjeta de música con carátula desenfocada de fondo
Rectangle {
    id: card
    readonly property var player: Mpris.players.values.length > 0 ? (Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0]) : null
    visible: player !== null
    implicitHeight: visible ? 116 : 0
    radius: Theme.radiusL
    color: Theme.surfaceHi
    clip: true

    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }

    Image {
        id: bgArt
        anchors.fill: parent
        source: card.player?.trackArtUrl ?? ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: bgArt
        visible: bgArt.status === Image.Ready
        blurEnabled: true; blur: 1.0; blurMax: 64
        brightness: -0.45; saturation: 0.2
        opacity: 0.85
    }

    Timer { interval: 1000; running: card.visible && (card.player?.isPlaying ?? false); repeat: true; onTriggered: card.player.positionChanged() }

    RowLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 14
        Rectangle {
            Layout.preferredWidth: 88; Layout.preferredHeight: 88; radius: Theme.radiusM; color: Theme.surface; clip: true
            Image { id: art; anchors.fill: parent; source: card.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; visible: false }
            Rectangle { id: artMask; anchors.fill: parent; radius: Theme.radiusM; visible: false; layer.enabled: true }
            MultiEffect { anchors.fill: parent; source: art; maskEnabled: true; maskSource: artMask; visible: art.status === Image.Ready }
            MIcon { anchors.centerIn: parent; name: "music_note"; size: 36; color: Theme.faint; visible: art.status !== Image.Ready }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            Text { Layout.fillWidth: true; text: card.player?.trackTitle || "Sin título"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.DemiBold; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: card.player?.trackArtist || card.player?.identity || ""; color: Theme.sub; font.family: Theme.font; font.pixelSize: 12; elide: Text.ElideRight }
            Item { Layout.fillHeight: true }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 4; radius: 2; color: Qt.rgba(1, 1, 1, 0.14)
                visible: (card.player?.length ?? 0) > 0
                Rectangle { height: parent.height; radius: 2; color: Theme.primary; width: parent.width * Math.min(1, (card.player?.position ?? 0) / Math.max(1, card.player?.length ?? 1)) }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Text { text: card.fmt(card.player?.position ?? 0); color: Theme.sub; font.family: Theme.font; font.pixelSize: 11; visible: (card.player?.length ?? 0) > 0 }
                Item { Layout.fillWidth: true }
                IconButton { implicitWidth: 34; implicitHeight: 34; icon: "skip_previous"; bgIdle: "transparent"; onClicked: card.player.previous() }
                IconButton { implicitWidth: 40; implicitHeight: 40; icon: card.player?.isPlaying ? "pause" : "play_arrow"; iconSize: 24; bgIdle: Theme.primary; bgHover: Qt.lighter(Theme.primary, 1.1); fg: Theme.fgOnPrimary; onClicked: card.player.togglePlaying() }
                IconButton { implicitWidth: 34; implicitHeight: 34; icon: "skip_next"; bgIdle: "transparent"; onClicked: card.player.next() }
            }
        }
    }
}
