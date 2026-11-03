//@ pragma UseQApplication
//@ pragma IconTheme breeze-dark
import QtQuick
import Quickshell
import Quickshell.Io

// COSMIC SHELL · centro de control + notificaciones
ShellRoot {
    ControlCenter { id: cc }
    Popups { ccOpen: cc.open }

    IpcHandler {
        target: "cc"
        function toggle(): void { cc.open = !cc.open }
        function open(): void { cc.open = true }
        function close(): void { cc.open = false }
        function wifi(): void { cc.open = true; cc.page = "wifi" }
        function bluetooth(): void { cc.open = true; cc.page = "bt" }
    }
    IpcHandler {
        target: "notifs"
        function toggleDnd(): void { Notifs.dnd = !Notifs.dnd }
        function clear(): void { Notifs.clearAll() }
    }
}
