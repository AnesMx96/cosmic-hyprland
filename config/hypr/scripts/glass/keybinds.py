#!/usr/bin/env python
"""Chuleta de atajos: lee los hl.bind() de tus .lua y los muestra en rofi."""
import os, re, subprocess
H = os.path.expanduser("~/.config/hypr/")
FILES = ["cfg/binds.lua", "cfg/extras.lua", "hyprland.lua", "hyprland.conf"]
NICE = {
    "window.close": "Cerrar ventana", "window.fullscreen": "Pantalla completa / maximizar",
    "window.float": "Alternar flotante", "window.center": "Centrar ventana", "window.pseudo": "Pseudo-tile",
    "togglesplit": "Cambiar orientación del split", "toggle_special": "Mostrar scratchpad",
    "exit()": "Salir de Hyprland", "window.drag": "Mover ventana con ratón",
    "window.resize": "Redimensionar", "window.move": "Mover ventana", "focus": "Foco / escritorio",
}
rows, seen = [], set()
for f in FILES:
    p = H + f
    if not os.path.exists(p):
        continue
    section = os.path.basename(f)
    for line in open(p, encoding="utf-8"):
        s = line.strip()
        if s.startswith("--") and not s.startswith("-- hl.bind"):
            section = s.strip("- ").strip() or section
            continue
        m = re.match(r'hl\.bind\((.+?),\s*(hl\.dsp\.|function)(.*)', s)
        if not m:
            continue
        key = re.sub(r'(mod|mainMod)\s*\.\.\s*"', '"SUPER', m.group(1))
        key = re.sub(r'"\s*\.\.\s*(key|i)\b.*', '0-9', key).replace('"', '').strip()
        if "for i" in key or not key:
            continue
        rest = m.group(3)
        d = re.search(r'description\s*=\s*"([^"]+)"', rest)
        if d:
            act = d.group(1)
        elif re.search(r'exec_cmd\((\w+)\)', rest):
            act = re.search(r'exec_cmd\((\w+)\)', rest).group(1)
        elif m.group(2) == "function":
            act = "Alt-Tab entre ventanas"
        elif (e := re.search(r'exec_cmd\((?:\w+\s*\.\.\s*)?"(.+?)"\)', rest)):
            act = os.path.basename(e.group(1).replace('\\"', '"').split()[0]) + "  " + " ".join(e.group(1).split()[1:])[:40]
        else:
            act = next((v for k, v in NICE.items() if rest.startswith(k) or k in rest[:30]), rest[:45])
        if key in seen:
            continue
        seen.add(key)
        act = act.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        rows.append(f"<b>{key}</b>    {act}    <span alpha='45%'>· {section}</span>")
if os.environ.get("DRY"): print("\n".join(rows)); raise SystemExit
subprocess.run(["rofi", "-dmenu", "-i", "-markup-rows", "-p", "󰌌 Atajos",
                "-theme", os.path.expanduser("~/.config/rofi/glass.rasi"),
                "-theme-str", "window { width: 820px; } listview { lines: 14; }"],
               input="\n".join(rows), text=True)
