local notifications = {}
local spacing = 60  -- vertical spacing between notifications
local activeDrawing = false -- flag for drawing loop state

if not HasStreamedTextureDictLoaded("timerbars") then
    while not HasStreamedTextureDictLoaded("timerbars") do
        RequestStreamedTextureDict("timerbars")
        Wait(5)
    end
end

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
        StartDrawingLoop()
    end
end

-- Drawing loop as a separate controlled thread
function StartDrawingLoop()
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
                    drawNotiText(8, 0.4, vec2(0.75, 0.975), notif.title, vec2(posX, posY))
                end

                -- Message text
                drawNotiText(4, 0.3, vec2(0.75, 0.975), notif.message, vec2(posX, posY + (moveMessage and 0.015 or 0.03)))

                -- Emoji
                drawNotiText(0, 0.3, vec2(0.75, 0.995), notif.emoji, vec2(posX, posY + 0.015))

                ::continue::
            end
            Wait(0)
        end
        activeDrawing = false -- No notifications left, pause drawing
    end)
end

function drawNotiText(font, scale, wrap, string, pos)
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

RegisterNetEvent("jim-bridge:Notify", gtaNotify)
exports("Notify", gtaNotify)