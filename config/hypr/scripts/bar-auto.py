#!/usr/bin/env python
import os, socket, subprocess, json, threading, signal, time

HIDE_AFTER = 3.0
forced = False
visible = True
timer = None
lock = threading.RLock()

def sh(*a):
    return subprocess.run(a, capture_output=True, text=True)

proc = None

def set_visible(v):
    global visible, proc
    if v == visible:
        return
    if v:
        # monitor-manager.sh también la relanza: no abrir una segunda barra
        if sh("pgrep", "-x", "waybar").returncode != 0:
            proc = subprocess.Popen(["waybar"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    else:
        sh("pkill", "-x", "waybar")
        if proc:
            try:
                proc.wait(timeout=2)
            except Exception:
                pass
            proc = None
    visible = v

def n_windows():
    try:
        return json.loads(sh("hyprctl", "activeworkspace", "-j").stdout).get("windows", 0)
    except Exception:
        return 1

def rofi_open():
    return sh("pgrep", "-x", "rofi").returncode == 0

def auto_hide():
    global timer
    with lock:
        if forced:
            return
        if n_windows() == 0:
            if rofi_open():
                timer = threading.Timer(1.0, auto_hide); timer.start()
            else:
                set_visible(False)

def evaluate():
    global timer
    with lock:
        if timer:
            timer.cancel(); timer = None
        if forced:
            set_visible(False); return
        set_visible(True)
        if n_windows() == 0:
            timer = threading.Timer(HIDE_AFTER, auto_hide); timer.start()

def on_usr1(*_):
    global forced, timer
    with lock:
        if timer:
            timer.cancel(); timer = None
        if visible:
            forced = True
            set_visible(False)
        else:
            forced = False
            set_visible(True)

signal.signal(signal.SIGUSR1, on_usr1)

if sh("pgrep", "-x", "waybar").returncode != 0:
    proc = subprocess.Popen(["waybar"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    time.sleep(1.5)
evaluate()

EV = ("workspace>>", "workspacev2>>", "openwindow>>", "closewindow>>", "movewindow>>", "movewindowv2>>")
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
