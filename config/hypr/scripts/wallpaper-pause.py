#!/usr/bin/env python
import os, socket, subprocess, json, time, signal, sys

paused = None

def sh(*a):
    return subprocess.run(a, capture_output=True, text=True)

def n_windows():
    try:
        return json.loads(sh("hyprctl", "activeworkspace", "-j").stdout).get("windows", 0)
    except Exception:
        return 1

def evaluate():
    global paused
    want = n_windows() > 0
    if want != paused:
        sh("pkill", "-STOP" if want else "-CONT", "-x", "mpvpaper")
        paused = want

def bye(*_):
    sh("pkill", "-CONT", "-x", "mpvpaper")
    sys.exit(0)

signal.signal(signal.SIGTERM, bye)
signal.signal(signal.SIGINT, bye)

time.sleep(4)  # espera a que arranque mpvpaper
evaluate()

EV = ("workspace>>", "workspacev2>>", "openwindow>>", "closewindow>>", "movewindow>>", "movewindowv2>>", "fullscreen>>")
path = f"{os.environ['XDG_RUNTIME_DIR']}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock"
s = socket.socket(socket.AF_UNIX)
s.connect(path)
buf = b""
while True:
    d = s.recv(4096)
    if not d:
        break
    buf += d
    while b"\n" in buf:
        line, buf = buf.split(b"\n", 1)
        if line.decode(errors="ignore").startswith(EV):
            time.sleep(0.1)
            evaluate()
