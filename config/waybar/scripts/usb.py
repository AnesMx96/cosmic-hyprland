#!/usr/bin/env python3
"""Waybar indicator and actions for USB storage devices."""

import json
import os
import re
import shutil
import subprocess
import sys


CONFIG = os.path.expanduser("~/.config")
ROFI_THEME = os.path.join(CONFIG, "rofi", "glass.rasi")


def run(args):
    try:
        return subprocess.run(args, capture_output=True, text=True, check=False)
    except OSError as exc:
        return subprocess.CompletedProcess(args, 127, "", str(exc))


def notify(title, message, critical=False):
    if shutil.which("notify-send"):
        args = ["notify-send", "-t", "5000"]
        if critical:
            args += ["-u", "critical"]
        run(args + [title, message])


def mountpoints(node):
    values = node.get("mountpoints") or []
    if isinstance(values, str):
        values = [values]
    return [value for value in values if value]


def usb_devices():
    result = run([
        "lsblk", "--json", "--paths", "--output",
        "NAME,PATH,TYPE,TRAN,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL",
    ])
    if result.returncode != 0:
        return []
    try:
        roots = json.loads(result.stdout).get("blockdevices", [])
    except (json.JSONDecodeError, AttributeError):
        return []

    devices = []
    for disk in roots:
        if disk.get("type") != "disk":
            continue
        if (disk.get("tran") or "").lower() != "usb":
            continue

        volumes = []

        def walk(node):
            if node.get("fstype") and node.get("path"):
                volumes.append({
                    "path": node["path"],
                    "label": node.get("label") or node.get("name") or node["path"],
                    "size": node.get("size") or "",
                    "mountpoints": mountpoints(node),
                })
            for child in node.get("children") or []:
                walk(child)

        walk(disk)
        devices.append({
            "path": disk.get("path") or "/dev/" + disk.get("name", ""),
            "name": disk.get("model") or disk.get("name") or "USB",
            "volumes": volumes,
        })
    return devices


def status():
    devices = usb_devices()
    count = len(devices)
    if not count:
        print(json.dumps({"text": "", "tooltip": ""}, ensure_ascii=False))
        return

    text = "󰕓 USB" if count == 1 else f"󰕓 USB ×{count}"
    lines = ["Almacenamiento USB conectado:"]
    for device in devices:
        lines.append(f"• {device['name']}")
        for volume in device["volumes"]:
            state = volume["mountpoints"][0] if volume["mountpoints"] else "Sin montar"
            lines.append(f"  {volume['label']} · {state}")
        if not device["volumes"]:
            lines.append("  Sin volúmenes montables")
    print(json.dumps({"text": text, "tooltip": "\n".join(lines)}, ensure_ascii=False))


def choose(options, prompt):
    args = ["rofi", "-dmenu", "-i", "-format", "i", "-no-custom", "-p", prompt]
    if os.path.isfile(ROFI_THEME):
        args += ["-theme", ROFI_THEME]
    result = subprocess.run(args, input="\n".join(options), capture_output=True, text=True)
    if result.returncode != 0 or not result.stdout.strip():
        return None
    try:
        index = int(result.stdout.strip())
    except ValueError:
        return None
    return index if 0 <= index < len(options) else None


def select_volume(devices):
    volumes = [
        (device, volume)
        for device in devices
        for volume in device["volumes"]
    ]
    if not volumes:
        notify("USB", "No hay ninguna partición con sistema de archivos reconocible.")
        return None
    if len(volumes) == 1:
        return volumes[0]

    labels = []
    for device, volume in volumes:
        state = "montada" if volume["mountpoints"] else "sin montar"
        labels.append(f"{volume['label']}  ·  {volume['size']}  ·  {state}")
    index = choose(labels, "Unidad USB")
    return volumes[index] if index is not None else None


def open_volume(devices):
    selected = select_volume(devices)
    if not selected:
        return
    _, volume = selected
    path = volume["mountpoints"][0] if volume["mountpoints"] else ""
    if not path:
        result = run(["udisksctl", "mount", "--block-device", volume["path"]])
        if result.returncode != 0:
            notify("No se pudo montar el USB", result.stderr.strip() or result.stdout.strip(), True)
            return
        refreshed = usb_devices()
        for device in refreshed:
            for updated in device["volumes"]:
                if updated["path"] == volume["path"] and updated["mountpoints"]:
                    path = updated["mountpoints"][0]
                    break
        if not path:
            match = re.search(r"\b at (.+)\.$", result.stdout.strip())
            path = match.group(1) if match else ""
    if not path:
        notify("USB montado", "No pude localizar la carpeta montada.", True)
        return
    try:
        subprocess.Popen(["dolphin", path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError as exc:
        notify("No se pudo abrir Dolphin", str(exc), True)


def eject(devices):
    if not devices:
        return
    labels = [device["name"] + "  ·  " + device["path"] for device in devices]
    index = 0 if len(devices) == 1 else choose(labels, "Expulsar USB")
    if index is None:
        return
    device = devices[index]

    for volume in device["volumes"]:
        if volume["mountpoints"]:
            result = run(["udisksctl", "unmount", "--block-device", volume["path"]])
            if result.returncode != 0:
                notify("No se pudo expulsar el USB", result.stderr.strip() or result.stdout.strip(), True)
                return

    result = run(["udisksctl", "power-off", "--block-device", device["path"]])
    if result.returncode == 0:
        notify("USB expulsado", device["name"])
    else:
        notify("USB desmontado", "Ya puedes retirarlo con seguridad.")


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "status"
    if action == "status":
        status()
    elif action == "open":
        open_volume(usb_devices())
    elif action == "eject":
        eject(usb_devices())
    else:
        raise SystemExit(f"Uso: {sys.argv[0]} [status|open|eject]")


if __name__ == "__main__":
    main()
