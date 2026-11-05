//@ pragma UseQApplication
//@ pragma IconTheme breeze-dark
import QtQuick
import Quickshell
import Quickshell.Io

// COSMIC SHELL · centro de control + notificaciones
ShellRoot {
    ControlCenter { id: cc }
    Popups { ccOpen: cc.open }
    Launcher { id: launcher }
    PowerMenu { id: power }

    IpcHandler {
        target: "cc"
        function toggle(): void { launcher.open = false; cc.open = !cc.open }
        function open(): void { launcher.open = false; cc.open = true }
        function close(): void { cc.open = false }
        function wifi(): void { launcher.open = false; cc.open = true; cc.page = "wifi" }
        function bluetooth(): void { launcher.open = false; cc.open = true; cc.page = "bt" }
    }
    IpcHandler {
        target: "power"
        function toggle(): void { cc.open = false; launcher.open = false; power.open = !power.open }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { cc.open = false; launcher.open = !launcher.open }
    }
    IpcHandler {
        target: "notifs"
        function toggleDnd(): void { Notifs.dnd = !Notifs.dnd }
        function clear(): void { Notifs.clearAll() }
    }
}
