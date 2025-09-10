--[[
    Notifications Module
    ----------------------
    This module provides a unified interface for displaying notifications using various
    notification systems. The active system is determined by the Config.System.Notify setting.

    Supported systems include:
      • okok
      • qb
      • ox
      • red (default)
      • gta (default)
      • lation
      • esx
]]

local notifyFunc = {
    okok = {
        client =
            function(title, message, type)
                TriggerEvent('okokNotify:Alert', title, message, 6000, type)
            end,
        server =
            function(title, message, type, src)
                TriggerClientEvent('okokNotify:Alert', src, title, message, 6000, type)
            end,
    },

    qb = {
        client =
            function(title, message, type)
                TriggerEvent("QBCore:Notify", message, type)
            end,
        server =
            function(title, message, type, src)
                TriggerClientEvent("QBCore:Notify", src, message, type)
            end,
    },

    ox = {
        client =
            function(title, message, type)
                exports.ox_lib:notify({ title = title, description = message, type = type or "success" })
            end,
        server =
            function(title, message, type, src)
                TriggerClientEvent('ox_lib:notify', src, { title = title, description = message, type = type or "success" })
            end,
    },

    esx = {
        client =
            function(title, message, type)
                exports["esx_notify"]:Notify(type, 4000, message)
            end,
        server =
            function(title, message, type, src)
                TriggerClientEvent(getScript()..":DisplayESXNotify", src, type, message)
            end,
    },

    lation = {
        client =
            function(title, message, type)
                exports.lation_ui:notify({ title = title, message = message, type = type or "success", })
            end,
        server =
            function(title, message, type, src)
                TriggerClientEvent("lation_ui:notify", src, { title = title, message = message, type = type or "success", })
            end,
    },

    gta = {
        client =
            function(title, message, type)
                exports.jim_bridge:Notify(title, message, type)
            end,
        server =
            function(title, message, type, src)
                TriggerClientEvent("jim-bridge:Notify", src, title, message, type)
            end,
    },

    red = {
        client =
            function(title, message, type)
                TriggerEvent("jim-redui:Notify", title, message, type)
            end,
        server =
            function(title, message, type, src)
                TriggerClientEvent("jim-redui:Notify", src, title, message, type)
            end,
    },
}
--- Displays notifications to the player using the configured notification system.
---
--- Supports multiple notification systems based on Config.System.Notify. Can be triggered from both
--- client and server contexts.
---
--- @param title string|nil The notification title (optional for some systems).
--- @param message string The main message content.
--- @param type string The notification type ("success", "error", "info").
--- @param src number|nil Optional server ID; if provided, the notification is sent to that player.
---
--- @usage
--- ```lua
--- -- Client-side usage without specifying a player (shows to the current player)
--- triggerNotify("Success", "You have completed the task!", "success")
---
--- -- Server-side usage specifying a player by their server ID
--- triggerNotify("Alert", "You have been warned for misconduct.", "error", playerId)
--- ```
function triggerNotify(title, message, type, src)
    if not Config.System?.Notify then debugPrint("Notify triggered but not set up") return end

    if src then
        notifyFunc[Config.System.Notify].server(title, message, type, src)
    else
        notifyFunc[Config.System.Notify].client(title, message, type)
    end
end

-------------------------------------------------------------
-- ESX Notifications
-------------------------------------------------------------

--- Registers a server-side event to display ESX notifications to clients.
---
--- Listens for DisplayESXNotify events and triggers the ESX notification on the client.
---
--- @param type string The notification type.
--- @param text string The notification message.
---
--- @usage
--- ```lua
--- TriggerClientEvent(getScript()..":DisplayESXNotify", playerId, "success", "New achievement unlocked!")
--- ```
RegisterNetEvent(getScript()..":DisplayESXNotify", function(type, text)
    exports["esx_notify"]:Notify(type, 4000, text)
end)

-------------------------------------------------------------
-- GTA-style Notifications
-------------------------------------------------------------

--- Displays GTA-style text notifications using native GTA functions.
---
--- Selects an appropriate icon based on the current script (if applicable) and renders the notification.
---
--- @param title string The notification title/identifier (used to select an icon).
--- @param text string The notification message.
---
--- @usage
--- ```lua
--- TriggerEvent(getScript()..":DisplayGTANotify", "taxiname", "Taxi service has arrived.")
--- ```
--RegisterNetEvent(getScript()..":DisplayGTANotify", function(title, text)
--    local iconTable = {}
--    if getScript() == "jim-npcservice" then
--        iconTable = {
--            [Loc[Config.Lan].notify["taxiname"]] = "CHAR_TAXI",
--            [Loc[Config.Lan].notify["limoname"]] = "CHAR_CASINO",
--            [Loc[Config.Lan].notify["ambiname"]] = "CHAR_CALL911",
--            [Loc[Config.Lan].notify["pilotname"]] = "CHAR_DEFAULT",
--            [Loc[Config.Lan].notify["planename"]] = "CHAR_BOATSITE2",
--            [Loc[Config.Lan].notify["heliname"]] = "CHAR_BOATSITE2",
--        }
--    end
--
--    BeginTextCommandThefeedPost("STRING")
--    AddTextComponentSubstringKeyboardDisplay(text)
--    EndTextCommandThefeedPostMessagetext(
--        iconTable[title] or "CHAR_DEFAULT",
--        iconTable[title] or "CHAR_DEFAULT",
--        true, 1, title, nil, text
--    )
--    EndTextCommandThefeedPostTicker(true, false)
--end)