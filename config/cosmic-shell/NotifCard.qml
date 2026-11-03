import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Tarjeta de notificación (se usa en el panel y en los toasts)
Rectangle {
    id: c
    required property var notif
    property bool popup: false
    signal dismissed()
    implicitHeight: Math.max(66, col.implicitHeight + 24)
    radius: Theme.radiusL
    color: popup ? Theme.bg : (hover.hovered ? Theme.surfaceHover : Theme.surfaceHi)
    border.width: popup ? 1 : 0
    border.color: notif?.urgency === NotificationUrgency.Critical ? Theme.danger : Theme.edge
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    HoverHandler { id: hover }

    readonly property string iconSrc: {
        if (!notif) return "";
        if (notif.image) return notif.image;
        if (notif.appIcon) return notif.appIcon.startsWith("/") || notif.appIcon.startsWith("file:") ? notif.appIcon : Quickshell.iconPath(notif.appIcon, true);
        return notif.desktopEntry ? Quickshell.iconPath(notif.desktopEntry, true) : "";
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const def = c.notif?.actions?.find(a => a.identifier === "default");
            if (def) def.invoke();
            c.dismissed();
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent; anchors.margins: 12; spacing: 12
        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 42; Layout.preferredHeight: 42; radius: 21
            color: Theme.surface; clip: true
            IconImage { anchors.fill: parent; anchors.margins: c.notif?.image ? 0 : 7; source: c.iconSrc; visible: c.iconSrc !== "" }
            MIcon { anchors.centerIn: parent; name: "notifications"; size: 22; color: Theme.primary; visible: c.iconSrc === "" }
        }
        ColumnLayout {
            id: col
            Layout.fillWidth: true; spacing: 3
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Text { text: c.notif?.appName ?? ""; color: Theme.primary; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.maximumWidth: 180 }
                Text { text: "· " + Notifs.ago(c.notif); color: Theme.faint; font.family: Theme.font; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
            }
            Text { Layout.fillWidth: true; text: c.notif?.summary ?? ""; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.DemiBold; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: c.notif?.body ?? ""; visible: text !== ""; color: Theme.sub; font.family: Theme.font; font.pixelSize: 13; wrapMode: Text.Wrap; maximumLineCount: c.popup ? 3 : 4; elide: Text.ElideRight; textFormat: Text.StyledText; lineHeight: 1.1 }
            Flow {
                Layout.fillWidth: true; Layout.topMargin: 4; spacing: 6
                visible: (c.notif?.actions ?? []).filter(a => a.identifier !== "default").length > 0
                Repeater {
                    model: (c.notif?.actions ?? []).filter(a => a.identifier !== "default")
                    Rectangle {
                        required property var modelData
                        implicitWidth: at.implicitWidth + 24; implicitHeight: 30; radius: 15
                        color: am.containsMouse ? Theme.primary : Theme.primarySoft
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text { id: at; anchors.centerIn: parent; text: modelData.text; color: am.containsMouse ? Theme.fgOnPrimary : Theme.text; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium }
                        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { modelData.invoke(); c.dismissed(); } }
                    }
                }
            }
        }
    }
    IconButton {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
        implicitWidth: 26; implicitHeight: 26; icon: "close"; iconSize: 16
        bgIdle: "transparent"; danger: true
        opacity: hover.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        onClicked: c.notif.dismiss()
    }
}
