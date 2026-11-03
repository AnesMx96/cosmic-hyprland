#!/usr/bin/env python
import os, re, subprocess

THEME = os.path.expanduser("~/.config/rofi/wifi.rasi")

def run(*a):
    return subprocess.run(a, capture_output=True, text=True)

def notify(msg):
    run("notify-send", "Wi-Fi", msg)

def rofi(opts, prompt, idx=True, password=False):
    cmd = ["rofi", "-dmenu", "-i", "-p", prompt, "-theme", THEME]
    if password:
        cmd += ["-password", "-theme-str", 'entry { placeholder: "Contraseña"; }']
    if idx:
        cmd += ["-format", "i"]
    r = subprocess.run(cmd, input="\n".join(opts), capture_output=True, text=True)
    out = r.stdout.strip()
    return out if r.returncode == 0 and out != "" else None

def main():
    if run("nmcli", "radio", "wifi").stdout.strip() != "enabled":
        if rofi(["󰖩  Activar Wi-Fi"], "󰖪 Wi-Fi") is not None:
            run("nmcli", "radio", "wifi", "on")
            notify("Wi-Fi activado")
        return
    subprocess.Popen(["nmcli", "device", "wifi", "rescan"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    out = run("nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "no").stdout
    nets = {}
    for line in out.splitlines():
        p = re.split(r'(?<!\\):', line, maxsplit=3)
        if len(p) < 4:
            continue
        use, sig, sec, ssid = p
        ssid = ssid.replace("\\:", ":").replace("\\\\", "\\")
        if not ssid:
            continue
        e = {"use": use.strip() == "*", "sig": int(sig or 0), "sec": sec not in ("", "--")}
        c = nets.get(ssid)
        if c is None or e["use"] or (not c["use"] and e["sig"] > c["sig"]):
            nets[ssid] = e
    order = sorted(nets, key=lambda s: (not nets[s]["use"], -nets[s]["sig"]))
    saved = set(run("nmcli", "-t", "-f", "NAME", "connection", "show").stdout.splitlines())

    def icon(s):
        return "󰤨" if s >= 75 else "󰤥" if s >= 50 else "󰤢" if s >= 25 else "󰤟"

    opts = []
    for s in order:
        n = nets[s]
        mark = "󰄬" if n["use"] else " "
        lock = "󰌾" if n["sec"] else ""
        opts.append(f"{mark}  {icon(n['sig'])}   {s[:32]}   ·   {n['sig']}%  {lock}")
    opts.append("󰖪  Desactivar Wi-Fi")

    sel = rofi(opts, "󰤨 Wi-Fi")
    if sel is None:
        return
    i = int(sel)
    if i == len(order):
        run("nmcli", "radio", "wifi", "off")
        notify("Wi-Fi desactivado")
        return
    ssid = order[i]
    n = nets[ssid]
    if n["use"]:
        run("nmcli", "connection", "down", "id", ssid)
        notify(f"Desconectado de {ssid}")
        return
    if ssid in saved:
        r = run("nmcli", "connection", "up", "id", ssid)
    elif n["sec"]:
        pw = rofi([], f"󰌾 {ssid}", idx=False, password=True)
        if pw is None:
            return
        r = run("nmcli", "device", "wifi", "connect", ssid, "password", pw)
    else:
        r = run("nmcli", "device", "wifi", "connect", ssid)
    notify(f"Conectado a {ssid}" if r.returncode == 0 else f"No se pudo conectar a {ssid}")

main()
