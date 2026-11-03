pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Estado del sistema que no tiene servicio nativo: brillo, luz nocturna, cafeína, modo juego, uptime
Singleton {
    id: root
    property real brightness: 0.5
    property bool night: false
    property bool gaming: false
    property string uptime: ""
    readonly property bool caffeine: caffeineProc.running
    readonly property string user: Quickshell.env("USER")
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts/glass/"

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }
    function setBrightness(v) {
        brightness = Math.max(0.05, Math.min(1, v));
        run("brightnessctl -q set " + Math.round(brightness * 100) + "%");
    }
    function toggleNight() { run(scripts + "nightlight.sh"); night = !night; }
    function toggleCaffeine() { caffeineProc.running = !caffeineProc.running; }
    function toggleGaming() { run(scripts + "gamemode.sh"); gaming = !gaming; }

    Process { id: caffeineProc; command: ["systemd-inhibit", "--what=idle:sleep", "--who=cosmic-shell", "--why=Cafeína", "sleep", "infinity"] }

    Process {
        id: poll
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'; pgrep -x hyprsunset >/dev/null && echo 1 || echo 0; hyprctl getoption animations.enabled | head -1; cut -d. -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.brightness = (parseInt(l[0]) || 50) / 100;
                root.night = l[1] === "1";
                root.gaming = (l[2] || "").indexOf("false") !== -1;
                const s = parseInt(l[3]) || 0, h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
                root.uptime = h > 0 ? h + " h " + m + " min" : m + " min";
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: poll.running = true }
    function refresh() { poll.running = true; }
}
