local inProgress = false

local function loadTextureDict(dict)
	if not HasStreamedTextureDictLoaded(dict) then
		while not HasStreamedTextureDictLoaded(dict) do RequestStreamedTextureDict(dict) Wait(5) end
	end
end

local function loadAnimDict(animDict)
	if not DoesAnimDictExist(animDict) then
		print("^6Bridge^7: ^1ERROR^7: ^2Anim Dictionary^7 - '^6"..animDict.."^7' ^2does not exist in server") return
	else
		while not HasAnimDictLoaded(animDict) do RequestAnimDict(animDict) Wait(5) end
	end
end

local function playAnim(animDict, animName, duration, flag, ped, speed)
    loadAnimDict(animDict)
	TaskPlayAnim(ped and ped or PlayerPedId(), animDict, animName, speed or 8.0, speed or -8.0, duration or 30000, flag or 50, 1, false, false, false)
end

local function stopAnim(animDict, animName, ped)
    StopAnimTask(ped or PlayerPedId(), animDict, animName, 0.5)
    StopAnimTask(ped or PlayerPedId(), animName, animDict, 0.5)
    RemoveAnimDict(animDict)
end

function redProgressBar(data)
    local ped = PlayerPedId()

    local result = nil

    loadTextureDict("generic_textures")
    if inProgress then return false end
    inProgress = true
    local wait = debugMode and 1000 or data.time
    local endTime = GetGameTimer() + wait

    LocalPlayer.state:set("inv_busy", true, true)
    TriggerEvent('inventory:client:busy:status', true)
    TriggerEvent('canUseInventoryAndHotbar:toggle', not true)

    -- Setup Animation/Task if specified
    if data.dict then
        playAnim(data.dict, data.anim, -1, data.flag or 32)
    elseif data.task then
        TaskStartScenarioInPlace(ped, data.task, -1, true)
    end

    -- Progress bar rendering loop
    CreateThread(function()
        while GetGameTimer() < endTime and inProgress do
            Wait(0)
            local elapsed = GetGameTimer()
            local percentage = ((elapsed - (endTime - wait)) / wait) * 100
            if percentage < 0 then percentage = 0 end
            if percentage > 100 then percentage = 100 end

            -- Draw your segmented progress bar
            ShowRedProgressBar(percentage, data.label, ("%.0f%%"):format(percentage))

            -- Controls to disable during progress
            if data.disableMouse then
                DisableControlAction(0, `INPUT_LOOK_LR`, true)
                DisableControlAction(0, `INPUT_LOOK_UD`, true)
                DisableControlAction(0, `INPUT_VEH_MOUSE_CONTROL_OVERRIDE`, true)
            end

            if data.disableMovement then
                DisableControlAction(0, `INPUT_MOVE_LR`, true)
                DisableControlAction(0, `INPUT_MOVE_UD`, true)
                DisableControlAction(0, `INPUT_DUCK`, true)
                DisableControlAction(0, `INPUT_SPRINT`, true)
            end

            if data.disableCarMovement then
                DisableControlAction(0, `INPUT_VEH_MOVE_LEFT_ONLY`, true)
                DisableControlAction(0, `INPUT_VEH_MOVE_RIGHT_ONLY`, true)
                DisableControlAction(0, `INPUT_VEH_ACCELERATE`, true)
                DisableControlAction(0, `INPUT_VEH_BRAKE`, true)
                DisableControlAction(0, `INPUT_VEH_EXIT`, true)
            end

            if data.disableCombat then
                DisablePlayerFiring(PlayerId(), true)
                DisableControlAction(0, `INPUT_ATTACK`, true)
                DisableControlAction(0, `INPUT_AIM`, true)
                DisableControlAction(0, `INPUT_OPEN_WHEEL_MENU`, true)
                DisableControlAction(0, `INPUT_DETONATE`, true)
                DisableControlAction(0, `INPUT_THROW_GRENADE`, true)
                DisableControlAction(0, `INPUT_MELEE_ATTACK`, true)
                DisableControlAction(0, `INPUT_MELEE_GRAPPLE_ATTACK`, true)
            end

            if data.cancel and (
                IsControlJustReleased(0, `INPUT_FRONTEND_RS`) or
                IsControlJustReleased(0, `INPUT_SWITCH_SHOULDER`) or
                IsControlJustReleased(0, `INPUT_GAME_MENU_TAB_RIGHT_SECONDARY`) or
                IsControlJustReleased(0, `INPUT_FRONTEND_CANCEL`) or
                IsControlJustReleased(0, `INPUT_GAME_MENU_CANCEL`) or
                IsControlJustReleased(0, `INPUT_FRONTEND_RRIGHT`) or
                IsControlJustReleased(0, `INPUT_QUIT`) or
                IsControlJustReleased(0, `INPUT_MINIGAME_QUIT`)
            ) then
                inProgress = false
            end
        end
    end)

    -- Wait for completion or cancel
    while GetGameTimer() < endTime and inProgress do
        Wait(100)
    end

    -- Cleanup animations/tasks
    if data.dict then
        stopAnim(data.dict, data.anim, ped)
    end
    if data.task then
        ClearPedTasks(ped)
    end

    result = inProgress
    inProgress = false

    while result == nil do Wait(10) end

    -- Cleanup
    FreezeEntityPosition(ped, false)

    LocalPlayer.state:set("inv_busy", false, true)
    TriggerEvent('inventory:client:busy:status', false)
    TriggerEvent('canUseInventoryAndHotbar:toggle', not false)

    return result
end

function ShowRedProgressBar(percentage, title, level)
    local loc = vec2(0.40, 0.90)
    local size = vec2(0.3, 0.03)
    local tickCount = 10        -- visually split into 10 segments (9 inner lines)
    local barHeight = size.y / 3.4
    local barWidth  = 0.21      -- tuned to your existing layout
    local barLeft   = (loc.x - size.x / 4) + 0.075
    local barCenter = barLeft + barWidth / 2
    local lineW     = 0.001
    local lineH     = barHeight + 0.00

    -- Background plate
    DrawSprite("generic_textures", "inkroller_1a", loc.x + 0.1, loc.y - 0.01, 0.25, 0.07, 180.0, 0, 0, 0, 200)

    -- Title (left)
    SetTextFontForCurrentCommand(6)
    SetTextScale(0.35, 0.35)
    SetTextColor(255, 255, 255, 255)
    SetTextDropshadow(1, 0, 0, 0, 200)
    BgDisplayText(title, loc.x - size.x / 4 + 0.074, loc.y - 0.034)

    -- Percentage (right)
    SetTextFontForCurrentCommand(1)
    SetTextScale(0.35, 0.35)
    SetTextColor(255, 255, 255, 255)
    SetTextDropshadow(1, 0, 0, 0, 200)
    BgDisplayText(level, loc.x - size.x / 4 + 0.246, loc.y - 0.030)

    -- Track (bg)
    DrawRect(barCenter, loc.y, barWidth, barHeight, 100, 100, 100, 255)

    -- Fill
    local fillWidth = barWidth * (percentage / 100.0)
    if fillWidth > 0.0 then
        local fillCenter = barLeft + (fillWidth / 2.0)
        DrawRect(fillCenter, loc.y, fillWidth, barHeight, 255, 0, 0, 200)  -- red fill
    end

    -- Tick lines (9 inner lines for 10 segments)
    for i = 1, (tickCount - 1) do
        local x = barLeft + (barWidth * (i / tickCount))
        DrawRect(x, loc.y, lineW, lineH, 0, 0, 0, 120)
    end
end

function gtaProgressBar(data)
    local ped = PlayerPedId()

    local result = nil

    loadTextureDict("timerbars")
    if inProgress then return false end
    inProgress = true
    local wait = debugMode and 1000 or data.time
    local endTime = GetGameTimer() + wait

    -- Setup Animation/Task if specified
    if data.dict then
        playAnim(data.dict, data.anim, -1, data.flag or 32)
    elseif data.task then
        TaskStartScenarioInPlace(ped, data.task, -1, true)
    end

    -- Progress bar rendering loop
    CreateThread(function()
        while GetGameTimer() < endTime and inProgress do
            Wait(0)
            local elapsed = GetGameTimer()
            local percentage = ((elapsed - (endTime - wait)) / wait) * 100

            if percentage < 0 then percentage = 0 end
            if percentage > 100 then percentage = 100 end

            -- Draw your segmented progress bar
            ShowGTAProgressBar(percentage, data.label, ("%.0f%%"):format(percentage))

            -- Controls to disable during progress
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 25, true) -- Disable aim
            DisableControlAction(0, 21, true) -- Disable sprint
            DisableControlAction(0, 30, true) -- Disable move left/right
            DisableControlAction(0, 31, true) -- Disable move forward/back
            DisableControlAction(0, 36, true) -- Disable stealth

            if data.cancel and (IsControlJustReleased(0, 202) or IsControlJustReleased(0, 177) or IsControlJustReleased(0, 73)) then
                inProgress = false
            end
        end
        result = inProgress
    end)


    -- Wait for completion or cancel
    while result == nil do Wait(10) end
    inProgress = false

    print(tostring(result))
    -- Cleanup animations/tasks
    if data.dict then
        stopAnim(data.dict, data.anim, ped)
    end
    if data.task then
        ClearPedTasks(ped)
    end


    -- Cleanup
    FreezeEntityPosition(ped, false)

    LocalPlayer.state:set("inv_busy", false, true)
    TriggerEvent('inventory:client:busy:status', false)
    TriggerEvent('canUseInventoryAndHotbar:toggle', not false)

    return result
end

function ShowGTAProgressBar(percentage, title, level)
    local loc = vec2(0.37, 0.90)
    local size = vec2(0.3, 0.03)
    local tickCount = 10
    local barHeight = size.y / 3.4
    local barWidth  = 0.19
    local barLeft   = (loc.x - size.x / 4) + 0.075
    local barCenter = barLeft + barWidth / 2
    local lineW     = 0.001
    local lineH     = barHeight + 0.00

    -- Background plates
    DrawSprite("timerbars", "all_black_bg", loc.x + 0.028, loc.y - 0.01, 0.15, 0.07, 0.0,   255, 255, 255, 255)
    DrawSprite("timerbars", "all_black_bg", loc.x + 0.170, loc.y - 0.01, 0.15, 0.07, 180.0, 255, 255, 255, 255)

    -- Title (left)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(title)
    DrawText(loc.x - size.x / 4 + 0.074, loc.y - 0.034)

    -- Percentage (right)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.25)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    AddTextComponentString(level)
    DrawText(loc.x - size.x / 4 + 0.246, loc.y - 0.030)

    -- Track (bg)
    DrawRect(barCenter, loc.y, barWidth, barHeight, 100, 100, 100, 255)

    -- Fill
    local fillWidth = barWidth * (percentage / 100.0)
    if fillWidth > 0.0 then
        local fillCenter = barLeft + (fillWidth / 2.0)
        DrawRect(fillCenter, loc.y, fillWidth, barHeight, 93, 182, 229, 255) -- GTA blue
    end

    -- Tick lines
    for i = 1, (tickCount - 1) do
        local x = barLeft + (barWidth * (i / tickCount))
        DrawRect(x, loc.y, lineW, lineH, 0, 0, 0, 120)
    end
end


function stopProgressBar() inProgress = false end
function isProgressBar() return inProgress end

function progressBar(...)
    if GetCurrentGameName() == "rdr3" then
        return redProgressBar(...)
    else
        return gtaProgressBar(...)
    end
end

exports("progressBar", function(...)
    return progressBar(...)
end)
exports("gtaProgressBar", function(...)
    return gtaProgressBar(...)
end)
exports("redProgressBar", function(...)
    return redProgressBar(...)
end)

exports("stopProgressBar", stopProgressBar)
exports("isProgressBar", isProgressBar)

--RegisterCommand("testprog", function()
--    print("test")
--    if progressBar({
--        label = "Processing...",
--        time = 10000,
--        disableMovement = true,
--        --dict = "amb@world_human_hang_out_street@female_hold_arm@base",
--        --anim = "base",
--        --flag = 49,
--        cancel = true,
--    }) then
--        Notify("Success!", "Short test message", "success")
--    else
--        Notify("Error!", "This is a longer example message to show stacking.", "error")
--    end
--end)