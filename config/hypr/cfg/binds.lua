local mod = "SUPER"
local hypr = "$HOME/.config/hypr/scripts/"
local rofi = "rofi -show drun -theme $HOME/.config/rofi/glass.rasi"

-- Aplicaciones
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("dolphin"))
hl.bind(mod .. " + R", hl.dsp.exec_cmd(rofi))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("firefox --new-window https://www.google.com"))

-- Ventanas
hl.bind(mod .. " + Q", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/close.sh"))
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
-- hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + C", hl.dsp.window.center())
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind("ALT + TAB", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Minimizar y restaurar

-- Scratchpad
hl.bind(mod .. " + Z", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "special:magic" }))

-- Sistema
hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(hypr .. "screenshot.sh"))
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd(hypr .. "clipboard-history.sh"))

-- Escritorios
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + CTRL + PAGE_UP", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + CTRL + PAGE_DOWN", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Foco, mover, redimensionar
hl.bind(mod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + DOWN", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + SHIFT + LEFT", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + RIGHT", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + UP", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + DOWN", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + CTRL + LEFT", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
hl.bind(mod .. " + CTRL + RIGHT", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
hl.bind(mod .. " + CTRL + UP", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
hl.bind(mod .. " + CTRL + DOWN", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia, brillo y micrófono
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +5 --max-volume 150"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness +5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness -5"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("SUPER + H", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/bar-toggle.sh"))
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/monitor-manager.sh choose"))
-- hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("virt-manager"))

hl.bind("SUPER + V", hl.dsp.exec_cmd("code"))
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("virt-manager"))
hl.bind("CTRL + UP", hl.dsp.exec_cmd("wtype -m ctrl -k Up"), { repeating = true })
hl.bind("CTRL + DOWN", hl.dsp.exec_cmd("wtype -m ctrl -k Down"), { repeating = true })
hl.bind("F11", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
