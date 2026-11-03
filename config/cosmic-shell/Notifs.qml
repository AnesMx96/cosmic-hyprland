pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Servidor de notificaciones (sustituye a swaync)
Singleton {
    id: root
    property bool dnd: false
    property var popups: []          // notificaciones visibles como toast
    property var times: ({})         // id -> Date de llegada
    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length

    function ago(n) {
        const t = times[n.id]; if (!t) return "";
        const s = Math.floor((Date.now() - t) / 1000);
        if (s < 60) return "ahora";
        if (s < 3600) return Math.floor(s / 60) + " min";
        if (s < 86400) return Math.floor(s / 3600) + " h";
        return Math.floor(s / 86400) + " d";
    }
    function dropPopup(n) { popups = popups.filter(p => p !== n); }
    function clearAll() { for (const n of list.slice()) n.dismiss(); popups = []; }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            const t = Object.assign({}, root.times); t[n.id] = Date.now(); root.times = t;
            n.closed.connect(() => root.dropPopup(n));
            if (!root.dnd) root.popups = [n].concat(root.popups).slice(0, 4);
        }
    }

    // estado para la campana de waybar
    function writeStatus() {
        status.setText(JSON.stringify({
            text: "", alt: dnd ? "dnd" : (count > 0 ? "notification" : "none"),
            class: dnd ? "dnd-none" : (count > 0 ? "notification" : "none"),
            tooltip: count === 1 ? "1 notificación" : count > 1 ? count + " notificaciones" : "Sin notificaciones"
        }) + "\n");
    }
    onCountChanged: writeStatus()
    onDndChanged: writeStatus()
    Component.onCompleted: writeStatus()
    FileView { id: status; path: Quickshell.env("HOME") + "/.cache/cosmic-shell/notif.json"; blockWrites: false }
}
