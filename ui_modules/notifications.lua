local notifications = {}
local spacing = 60  -- vertical spacing between notifications
local activeDrawing = false -- flag for drawing loop state

local function loadTextureDict(dict)
	if not HasStreamedTextureDictLoaded(dict) then
		while not HasStreamedTextureDictLoaded(dict) do RequestStreamedTextureDict(dict) Wait(5) end
	end
end


--- GTA Section ---

local notifTypes = {
    success = "✔️",
    error = "❌",
    warning = "⚠️",
    police = "🚓",
    ambulance = "🚑",
}

function gtaNotify(title, message, emoji, src)
    local notif = {
        title = title,
        message = message,
        emoji = notifTypes[emoji] or "❔",
        state = "enter",
        startTime = GetGameTimer(),
        progress = 0,
        holdTime = 8000,
        slideDuration = 100,
        currentOffset = 0,
    }
    table.insert(notifications, notif)

    -- Activate drawing loop if not already running
    -- This allows it to be silent until the first notifcation is called, then the loop starts
    if not activeDrawing then
        activeDrawing = true
        StartGTADrawingLoop()
    end
end

-- Drawing loop as a separate controlled thread
function StartGTADrawingLoop()
    --loadTextureDict("timerbars")
    CreateThread(function()
        while #notifications > 0 do
            local currentTime = GetGameTimer()

            -- Update notifications vertical offset
            for i, notif in ipairs(notifications) do
                local target = (#notifications - i) * spacing
                notif.currentOffset += (target - notif.currentOffset) * 0.1
            end

            for i = #notifications, 1, -1 do
                local notif = notifications[i]

                if notif.state == "enter" then
                    local elapsed = currentTime - notif.startTime
                    notif.progress = math.min(elapsed / notif.slideDuration, 1.0)
                    if notif.progress >= 1.0 then
                        notif.state = "hold"
                        notif.holdStart = currentTime
                    end
                elseif notif.state == "hold" then
                    if currentTime - notif.holdStart >= notif.holdTime then
                        notif.state = "exit"
                        notif.exitStart = currentTime
                    end
                elseif notif.state == "exit" then
                    local elapsed = currentTime - notif.exitStart
                    notif.progress = 1.0 - math.min(elapsed / notif.slideDuration, 1.0)
                    if notif.progress <= 0 then
                        table.remove(notifications, i)
                        goto continue
                    end
                end

                local startX, targetX = 1.0, 0.8
                local posX = startX - (startX - targetX) * notif.progress
                local posY = 0.05 + (notif.currentOffset / 1080)

                -- Background sprite
                DrawSprite("timerbars", "all_black_bg", posX + 0.11, posY + 0.025, 0.2, 0.053, 0.0, 255, 255, 255, 255)

                -- Title text
                local moveMessage = false
                if not notif.title or notif.title == "" then
                    moveMessage = true
                else
                    drawGTANotiText(8, 0.4, vec2(0.75, 0.975), notif.title, vec2(posX, posY))
                end

                -- Message text
                drawGTANotiText(4, 0.3, vec2(0.75, 0.975), notif.message, vec2(posX, posY + (moveMessage and 0.015 or 0.03)))

                -- Emoji
                drawGTANotiText(0, 0.3, vec2(0.75, 0.995), notif.emoji, vec2(posX, posY + 0.015))

                ::continue::
            end
            Wait(0)
        end
        activeDrawing = false -- No notifications left, pause drawing
    end)
end

function drawGTANotiText(font, scale, wrap, string, pos)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextWrap(wrap.x, wrap.y)
    SetTextJustification(2)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(string)
    DrawText(pos.x, pos.y)
end


------------------
-- REDM SECTION --
------------------
---
---
local REDMnotifTypes = {
    success = vec3(0, 150, 0),
    error = vec3(150, 0, 0),
    warning = vec3(0, 150, 150),
    police = vec3(0, 0, 150),
    ambulance = vec3(0, 0, 150),
}

function redNotify(title, message, style)
    local notif = {
        title = title and CreateVarString(10, "LITERAL_STRING", title) or nil,
        message = message and CreateVarString(10, "LITERAL_STRING", message) or nil,
        state = "enter",
        startTime = GetGameTimer(),
        style = REDMnotifTypes[style] or vec3(0, 0, 0),
        progress = 0,
        holdTime = 8000,
        slideDuration = 100,
        currentOffset = 0,
    }
    table.insert(notifications, notif)

    -- Activate drawing loop if not already running
    if not activeDrawing then
        activeDrawing = true
        StartREDMDrawingLoop()
    end
end

-- Drawing loop as a separate controlled thread
function StartREDMDrawingLoop()
    CreateThread(function()
        loadTextureDict("generic_textures")
        while #notifications > 0 do
            local currentTime = GetGameTimer()

            -- Update notifications vertical offset
            for i, notif in ipairs(notifications) do
                local target = (#notifications - i) * spacing
                notif.currentOffset += (target - notif.currentOffset) * 0.1
            end

            for i = #notifications, 1, -1 do
                local notif = notifications[i]

                if notif.state == "enter" then
                    local elapsed = currentTime - notif.startTime
                    notif.progress = math.min(elapsed / notif.slideDuration, 1.0)
                    if notif.progress >= 1.0 then
                        notif.state = "hold"
                        notif.holdStart = currentTime
                    end
                elseif notif.state == "hold" then
                    if currentTime - notif.holdStart >= notif.holdTime then
                        notif.state = "exit"
                        notif.exitStart = currentTime
                    end
                elseif notif.state == "exit" then
                    local elapsed = currentTime - notif.exitStart
                    notif.progress = 1.0 - math.min(elapsed / notif.slideDuration, 1.0)
                    if notif.progress <= 0 then
                        table.remove(notifications, i)
                        goto continue
                    end
                end

                local startX, targetX = 1.0, 0.8
                local posX = startX - (startX - targetX) * notif.progress
                local posY = 0.05 + (notif.currentOffset / 1080)

                -- Background sprite
                DrawSprite("generic_textures", "inkroller_1a", posX + 0.09, posY + 0.025, 0.2, 0.053, 180.0, notif.style.x, notif.style.y, notif.style.z, 150)

                -- Title text
                local moveMessage = false
                if not notif.title or notif.title == "" then
                    moveMessage = true
                else
                    drawREDMNotiText(1, 0.4, vec2(0.75, 0.975), notif.title, vec2(posX, posY))
                end

                -- Message text
                drawREDMNotiText(6, 0.3, vec2(0.75, 0.975), notif.message, vec2(posX, posY + (moveMessage and 0.0145 or 0.025)))

                ::continue::
            end
            Wait(0)
        end
        activeDrawing = false -- No notifications left, pause drawing
    end)
end

function drawREDMNotiText(font, scale, wrap, string, pos)
    SetTextFontForCurrentCommand(font)
    SetTextScale(scale, scale)
	SetTextColor(255, 255, 255, 255)
    SetTextWrap(wrap.x, wrap.y)
    SetTextJustification(2)
	SetTextDropshadow(1, 0, 0, 0, 200)
	DisplayText(string, pos.x, pos.y)
end

-- Exports --
-- Example:
-- TriggerEvent("jim_bridge:Notify", nil, "Short test message", "success")
--
-- exports["jim_bridge"]:Notify(nil, "Short test message", "success")
--

RegisterNetEvent("jim_bridge:RedNotify", redNotify)
RegisterNetEvent("jim_bridge:GTANotify", gtaNotify)

RegisterNetEvent("jim_bridge:Notify", function(...)
    if GetCurrentGameName() == "rdr3" then
        redNotify(...)
    else
        gtaNotify(...)
    end
end)

function Notify(...)
    if GetCurrentGameName() == "rdr3" then
        redNotify(...)
    else
        gtaNotify(...)
    end
end

exports("Notify", Notify)

-- Example testing notifications (can remove after testing)
--CreateThread(function()
--    TriggerEvent("jim_bridge:Notify", nil, "Short test message", "success")
--    Wait(3000)
--    TriggerEvent("jim_bridge:Notify", "Error!", "This is a longer example message to show stacking.", "error")
--    Wait(3000)
--    TriggerEvent("jim_bridge:Notify", "Test!", "This notification has to 'type' set.", nil )
--    Wait(4000)
--end)