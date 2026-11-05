-- Blur de cristal en capas (barra, menús, notificaciones)
hl.layer_rule({
    name = "waybar-blur",
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0.02,
})

-- Estándar del ejemplo oficial
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Extras
hl.window_rule({
    name = "flotantes-utilidades",
    match = { class = "^(.*pavucontrol|nm-connection-editor|blueman-manager)$" },
    float = true,
})
hl.window_rule({
    name = "picture-in-picture",
    match = { title = "^(Picture-in-Picture|Picture in picture|Imagen en imagen)$" },
    float = true,
    pin = true,
})
hl.window_rule({
    name = "idle-inhibit-fullscreen",
    match = { class = ".*" },
    idle_inhibit = "fullscreen",
})

hl.window_rule({
    name = "gsimplecal-flotante",
    match = { class = "^(gsimplecal|Gsimplecal)$" },
    float = true,
})

hl.window_rule({
    name = "popups-calendario-wifi",
    match = { class = "^(calendar-popup|wifi-popup)$" },
    float = true,
})

hl.layer_rule({
    name = "rofi-blur",
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.02,
})

hl.window_rule({
    name = "calendario-flotante",
    match = { class = "^(org.gnome.Calendar)$" },
    float = true,
})

hl.window_rule({
    name = "calendario-tui",
    match = { class = "^(calendario)$" },
    float = true,
})
