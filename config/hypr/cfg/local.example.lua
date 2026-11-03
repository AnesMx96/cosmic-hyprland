-- ============================================================
--  Ajustes locales de tu equipo. Copia este archivo a cfg/local.lua
--  (cfg/local.lua no se sube al repo, así tus monitores no pisan los de nadie).
--  Lista tus pantallas con:  hyprctl monitors
-- ============================================================

-- Ejemplo: portátil + monitor externo a la derecha
-- hl.monitor({ output = "eDP-1",    mode = "preferred", position = "auto",       scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto-right", scale = 1 })

-- Escritorios 1-5 en el portátil y 6-10 en el externo
-- for i = 1, 5  do hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1",    persistent = true }) end
-- for i = 6, 10 do hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", persistent = true }) end

-- Distribución de teclado (por defecto "es")
-- hl.config({ input = { kb_layout = "us" } })
