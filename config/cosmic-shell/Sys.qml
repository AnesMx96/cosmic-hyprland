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
    property bool active: false       // solo se consulta el sistema con el panel abierto
    property real cpu: 0
    property real mem: 0
    property real temp: 0
    property var cpuPrev: null
    property double brightnessSetAt: 0
    readonly property bool caffeine: caffeineProc.running
    readonly property string user: Quickshell.env("USER")
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts/glass/"

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }
    function setBrightness(v) {
        brightness = Math.max(0.05, Math.min(1, v));
        brightnessSetAt = Date.now();
        run("brightnessctl -q set " + Math.round(brightness * 100) + "%");
    }
    function toggleNight() { run(scripts + "nightlight.sh"); night = !night; }
    function toggleCaffeine() { caffeineProc.running = !caffeineProc.running; }
    function toggleGaming() { run(scripts + "gamemode.sh"); gaming = !gaming; }

    Process { id: caffeineProc; command: ["systemd-inhibit", "--what=idle:sleep", "--who=cosmic-shell", "--why=Cafeína", "sleep", "infinity"] }

    Process {
        id: poll
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'; pgrep -x hyprsunset >/dev/null && echo 1 || echo 0; hyprctl getoption animations.enabled | head -1; cut -d. -f1 /proc/uptime; head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable)' /proc/meminfo; cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                if (Date.now() - root.brightnessSetAt > 2500) root.brightness = (parseInt(l[0]) || 50) / 100;
                root.night = l[1] === "1";
                root.gaming = (l[2] || "").indexOf("false") !== -1;
                const s = parseInt(l[3]) || 0, h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
                root.uptime = h > 0 ? h + " h " + m + " min" : m + " min";
                const c = (l[4] || "").trim().split(/\s+/).slice(1).map(Number);
                if (c.length > 4) {
                    const idle = c[3] + c[4], total = c.reduce((a, b) => a + b, 0), p = root.cpuPrev;
                    if (p && total > p.total) root.cpu = 1 - (idle - p.idle) / (total - p.total);
                    root.cpuPrev = { idle, total };
                }
                const kb = t => parseInt((t || "").replace(/[^0-9]/g, "")) || 0;
                if (kb(l[5])) root.mem = 1 - kb(l[6]) / kb(l[5]);
                root.temp = (parseInt(l[7]) || 0) / 1000;
            }
        }
    }
    Timer { interval: 2000; running: root.active; repeat: true; triggeredOnStart: true; onTriggered: poll.running = true }
    function refresh() { poll.running = true; }
    function refreshUptime() { poll.running = true; }
}
