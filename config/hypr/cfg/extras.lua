-- ============================================================
--  EXTRAS · Cosmic Glass  (no modifica tus atajos de binds.lua)
-- ============================================================
local g = "$HOME/.config/hypr/scripts/glass/"

-- Ajustes finos ------------------------------------------------
hl.config({
    cursor = {
        hide_on_key_press = true,
        inactive_timeout = 8,
    },
    misc = {
        vrr = 2,                      -- VRR solo en pantalla completa
        enable_swallow = true,        -- la terminal "se traga" la ventana que lanza
        swallow_regex = "^(kitty)$",
        swallow_exception_regex = "^(wev|.*[Dd]ragon.*)$",
        animate_manual_resizes = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    gestures = {
        workspace_swipe_distance = 280,
        workspace_swipe_cancel_ratio = 0.25,
        workspace_swipe_create_new = false,
        workspace_swipe_direction_lock = true,
    },
    binds = {
        workspace_back_and_forth = false,
        allow_workspace_cycles = true,
    },
})

-- Gestos: 3 dedos arriba = scratchpad, abajo = flotante
hl.gesture({ fingers = 3, direction = "up", action = "special", workspace_name = "magic" })
hl.gesture({ fingers = 3, direction = "down", action = "float" })

-- Animaciones especiales para menús y scratchpad -------------
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "cosmic", style = "slidevert" })
hl.layer_rule({ name = "rofi-anim", match = { namespace = "rofi" }, animation = "popin 90%" })
for _, ns in ipairs({ "swaync-control-center", "swaync-notification-window" }) do
    hl.layer_rule({ name = ns .. "-glass", match = { namespace = ns }, blur = true, ignore_alpha = 0.1, animation = "slide right" })
end
hl.layer_rule({ name = "osd-blur", match = { namespace = "swayosd" }, blur = true, ignore_alpha = 0.1, animation = "popin 85%" })

-- Reglas de ventanas -------------------------------------------
hl.window_rule({
    name = "dialogos-flotantes",
    match = { title = "^(Abrir.*|Guardar.*|Open.*|Save.*|Select.*|Seleccionar.*|Choose.*|Elegir.*|File Upload.*|Subir archivo.*|Confirm.*|Confirmar.*)$" },
    float = true, center = true,
})
hl.window_rule({
    name = "portal-dialogos",
    match = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-kde|org.freedesktop.impl.portal.desktop.kde|polkit-.*|hyprpolkitagent|org.kde.polkit-kde-authentication-agent-1)$" },
    float = true, center = true,
})
hl.window_rule({
    name = "utilidades-flotantes-extra",
    match = { class = "^(org.kde.kcalc|kcalc|nwg-look|qt6ct|org.gnome.Calculator|btop|org.kde.ark|file-roller|blueberry.py|.*blueman-manager.*)$" },
    float = true, center = true,
})
hl.window_rule({ name = "btop-size", match = { class = "^(btop)$" }, size = "1100 680" })
hl.window_rule({ name = "pip-esquina", match = { title = "^(Picture-in-Picture|Picture in picture|Imagen en imagen)$" }, size = "480 270", move = "monitor_w-500 monitor_h-290", keep_aspect_ratio = true })
hl.window_rule({ name = "video-opaco", match = { class = "^(mpv|vlc|org.kde.haruna|celluloid)$" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ name = "fullscreen-opaco", match = { fullscreen = true }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ name = "juegos-tearing", match = { class = "^(steam_app_.*|gamescope|.*\\.exe)$" }, immediate = true, opacity = "1.0 override 1.0 override" })

-- Atajos NUEVOS (solo teclas que estaban libres) ---------------
hl.bind("SUPER + N", hl.dsp.exec_cmd("qs -p $HOME/.config/cosmic-shell ipc call cc toggle"), { description = "Centro de notificaciones" })
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(g .. "nightlight.sh"), { description = "Luz nocturna" })
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd(g .. "colorpicker.sh"), { description = "Cuentagotas (copia color)" })
hl.bind("SUPER + X", hl.dsp.exec_cmd(g .. "powermenu.sh"), { description = "Menú de apagado" })
hl.bind("SUPER + PERIOD", hl.dsp.exec_cmd(g .. "emoji.sh"), { description = "Selector de emojis" })
hl.bind("SUPER + SLASH", hl.dsp.exec_cmd("python " .. g .. "keybinds.py"), { description = "Chuleta de atajos" })
hl.bind("SUPER + F1", hl.dsp.exec_cmd("python " .. g .. "keybinds.py"), { description = "Chuleta de atajos" })
hl.bind("SUPER + G", hl.dsp.exec_cmd(g .. "gamemode.sh"), { description = "Modo juego" })
hl.bind("SUPER + TAB", hl.dsp.focus({ workspace = "previous" }), { description = "Escritorio anterior" })
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(g .. "launcher.sh"), { description = "Lanzador en cuadrícula" })

-- Servicios del tema ----------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("swayosd-server")
end)

-- Cosmic Shell (Quickshell): la animación la hace la propia shell
hl.layer_rule({ name = "cosmic-cc-noanim", match = { namespace = "cosmic-cc" }, no_anim = true })
hl.layer_rule({ name = "cosmic-popups-noanim", match = { namespace = "cosmic-popups" }, no_anim = true })

-- ============================================================
--  Gestos del touchpad y Alt-Tab inverso
-- ============================================================
local function set_fullscreen(on)
    local w = hl.get_active_window()
    if not w then return end
    local is_fs = (w.fullscreen or 0) ~= 0
    if is_fs ~= on then
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
    end
end

-- 3 dedos: abrir (zoom) = pantalla completa · pellizcar = salir
hl.gesture({ fingers = 3, direction = "pinchout", action = function() set_fullscreen(true) end })
hl.gesture({ fingers = 3, direction = "pinchin",  action = function() set_fullscreen(false) end })

-- 4 dedos: izquierda/derecha = cambiar de ventana · arriba = maximizar
hl.gesture({ fingers = 4, direction = "right", action = function()
    hl.dispatch(hl.dsp.window.cycle_next()); hl.dispatch(hl.dsp.window.bring_to_top())
end })
hl.gesture({ fingers = 4, direction = "left", action = function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false })); hl.dispatch(hl.dsp.window.bring_to_top())
end })
hl.gesture({ fingers = 4, direction = "up", action = function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
end })

-- Alt+Shift+Tab: igual que tu Alt+Tab pero hacia atrás
hl.bind("ALT + SHIFT + TAB", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Ventana anterior" })
