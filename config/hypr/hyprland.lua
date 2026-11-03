-- ==================================================================
--  COSMIC · Hyprland 0.57 (configuración en Lua)
--  Lo específico de cada equipo (monitores, teclado…) va en cfg/local.lua
-- ==================================================================

-- Cualquier pantalla: resolución preferida, posición automática
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

require("cfg.look")
require("cfg.animations")
require("cfg.rules")
require("cfg.binds")
require("cfg.autostart")
require("cfg.extras")

-- Ajustes locales (opcional)
local ok, err = pcall(require, "cfg.local")
if not ok and not tostring(err):find("not found") then
    hl.notification.create({ text = "cfg/local.lua: " .. tostring(err), timeout = 8000 })
end
