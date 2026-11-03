hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = {
                colors = {
                    "rgba(FFFFFFE6)",
                    "rgba(8CCBFF66)",
                    "rgba(2F6BFF33)",
                    "rgba(FFFFFFB3)",
                    "rgba(38BDF8E6)",
                },
                angle = 45,
            },
            inactive_border = "rgba(FFFFFF2E)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 14,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = "rgba(020617AA)",
        },
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            vibrancy = 0.15,
            brightness = 1.0,
            contrast = 1.0,
            noise = 0.015,
            popups = true,
            popups_ignorealpha = 0.2,
        },
    },
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        focus_on_activate = true,
    },
    input = {
        kb_layout = "es",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
            tap_to_click = true,
            disable_while_typing = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

