-- NOTIFICATIONS --
-- This function is widely used to display notifications to the player, can be used server side or client side --

--- Displays notifications to the player using the configured notification system.
---
--- This function supports multiple notification systems based on the `Config.System.Notify` setting.
--- It can be triggered from both client-side and server-side scripts. Depending on the configuration,
--- it utilizes different exports or events to display the notification.
---
---@param title string|nil The title of the notification. Optional, used by certain notification systems.
---@param message string The main message content of the notification.
---@param type string The type/category of the notification (e.g., "success", "error", "info").
---@param src number|nil Optional. The server ID of the player to send the notification to. If `nil`, the notification is sent to the caller.
---
---@usage
--- ```lua
--- -- Client-side usage without specifying a player (shows to the current player)
--- triggerNotify("Success", "You have completed the task!", "success")
---
--- -- Server-side usage specifying a player by their server ID
--- triggerNotify("Alert", "You have been warned for misconduct.", "error", playerId)
--- ```
function triggerNotify(title, message, type, src)
	if Config.System.Notify == "okok" then
		if not src then TriggerEvent('okokNotify:Alert', title, message, 6000, type)
		else TriggerClientEvent('okokNotify:Alert', src, title, message, 6000, type) end
	elseif Config.System.Notify == "qb" then
		if not src then	TriggerEvent("QBCore:Notify", message, type)
		else TriggerClientEvent("QBCore:Notify", src, message, type) end
	elseif Config.System.Notify == "ox" then
		if not src then TriggerEvent('ox_lib:notify', {title = title, description = message, type = type or "success"})
		else TriggerClientEvent('ox_lib:notify', src, { type = type or "success", title = title, description = message }) end
	elseif Config.System.Notify == "gta" then
		if not src then TriggerEvent(getScript()..":DisplayGTANotify", title, message)
		else TriggerClientEvent(getScript()..":DisplayGTANotify", src, title, message) end
    elseif Config.System.Notify == "esx" then
		if not src then exports["esx_notify"]:Notify(type, 4000, message)
		else TriggerClientEvent(getScript()..":DisplayESXNotify", src, type, title, message) end
	end
end

--- Registers a server-side event to display ESX notifications to clients.
---
--- This event listens for `DisplayESXNotify` and triggers the ESX notification on the client side.
---
--- @param type string The type/category of the notification (e.g., "success", "error", "info").
--- @param title string The title of the notification.
--- @param text string The main message content of the notification.
---
--- @usage
--- ```lua
--- -- Server-side event trigger
--- TriggerClientEvent(getScript()..":DisplayESXNotify", playerId, "success", "Achievement Unlocked", "You have unlocked a new achievement!")
--- ```
RegisterNetEvent(getScript()..":DisplayESXNotify", function(type, title, text)
    exports["esx_notify"]:Notify(type, 4000, text)
end)

--- Displays default GTA-style text notifications.
---
--- This event handles displaying text-based notifications using GTA's native functions.
--- It supports specific scenarios by assigning different icons based on the script name.
---
---@param title string The title or identifier for the notification, used to select the appropriate icon.
---@param text string The main message content of the notification.
---
---@usage
--- ```lua
--- -- Client-side event trigger
--- TriggerEvent(getScript()..":DisplayGTANotify", "taxiname", "Taxi service has arrived.")
--- ```
RegisterNetEvent(getScript()..":DisplayGTANotify", function(title, text)
    local iconTable = {}
    if getScript() == "jim-npcservice" then
        iconTable = {
            [Loc[Config.Lan].notify["taxiname"]] = "CHAR_TAXI",
            [Loc[Config.Lan].notify["limoname"]] = "CHAR_CASINO",
            [Loc[Config.Lan].notify["ambiname"]] = "CHAR_CALL911",
            [Loc[Config.Lan].notify["pilotname"]] = "CHAR_DEFAULT",
            [Loc[Config.Lan].notify["planename"]] = "CHAR_BOATSITE2",
            [Loc[Config.Lan].notify["heliname"]] = "CHAR_BOATSITE2",
        }
    end
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringKeyboardDisplay(text)
    EndTextCommandThefeedPostMessagetext(iconTable[title] or "CHAR_DEFAULT", iconTable[title] or "CHAR_DEFAULT", true, 1, title, nil, text)
    EndTextCommandThefeedPostTicker(true, false)
end)