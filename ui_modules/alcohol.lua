local alcoholCount = 0
local drugCount = 0
local purgeTimer = 300000

local minDrugCount = 3
local maxDrugCount = 7

local minAlcoholCount = 2
local midAlcoholCount = 4
local maxAlcoholCount = 7

local alcoholEffectData = {
    levels = {
        ["min"] = {
            effect = "DrugsMichaelAliensFightIn",
            movement = "move_m@drunk@slightlydrunk",
            camShake = 0.5,
            canStumble = false,
        },
        ["mid"] = {
            effect = "DrugsMichaelAliensFightIn",
            movement = "move_m@drunk@moderatedrunk",
            canRagdoll = true,
            camShake = 0.5,
            canStumble = true,
            stumbleChance = 0.8,
            drunkDriving = true,
        },
        ["max"] = {
            effect = "DrugsMichaelAliensFightIn",
            movement = "move_m@drunk@verydrunk",
            canRagdoll = true,
            camShake = 2.8,
            canStumble = true,
            stumbleChance = 0.6,
            drunkDriving = true,
        },
    },
}

local drugEffectData = {
    levels = {
        ["min"] = {
            --effect = "SwitchHUDTrevorIn",
            --movement = "move_m@drunk@slightlydrunk",
        },
        ["max"] = {
            effect = "SwitchHUDTrevorIn",
            movement = "move_m@drunk@slightlydrunk",
            camShake = 0.2,
        },
    }

}

-- Alcohol Thread
function addAlocholCount(count, canOD)
    alcoholCount = alcoholCount + count
    --print("Alcohol count increased, current amount:", alcoholCount)
    CreateThread(function()
        runAlcoholThread()
    end)
    if alcoholCount >= maxAlcoholCount then
        -- max
        startAlcoholEffect(alcoholEffectData.levels["max"], "max")
        if canOD then
            SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) - math.random(10, 15))
        end
    elseif alcoholCount < maxAlcoholCount and alcoholCount >= midAlcoholCount then
        -- mid
        startAlcoholEffect(alcoholEffectData.levels["mid"], "mid")
        TriggerEvent("evidence:client:SetStatus", "heavyalcohol", 200)
        if canOD then
            SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) - math.random(5, 10))
        end
    elseif alcoholCount >= 1 then
        -- min
        TriggerEvent("evidence:client:SetStatus", "alcohol", 200)
        startAlcoholEffect(alcoholEffectData.levels["min"], "min")
    end
end

function getAlcoholCount()
    return alcoholCount
end

function removeAlcoholCount(count)
    alcoholCount = alcoholCount - count
    if alcoholCount < minAlcoholCount then
        clearCurrentAlcoholEffect()
    end
    --print("Alcohol count decreased, current amount:", alcoholCount)
end

local alcoholThreadRun = false
function runAlcoholThread()
    if alcoholThreadRun == true then
        return
    else
        alcoholThreadRun = true
    end
    --print("Alcohol Thread triggered")
    while alcoholCount > 0 do
        Wait(purgeTimer)
        removeAlcoholCount(1)
        if alcoholCount <= 0 then
            clearCurrentAlcoholEffect()
            alcoholThreadRun = false
            break
        end
	end
end

exports("getAlcoholCount",getAlcoholCount)
exports("addAlocholCount", addAlocholCount)
exports("removeAlcoholCount", removeAlcoholCount)


-- EFFECT Management

local currentAlcoholEffect = ""
local alcoholEffect = ""

function clearCurrentAlcoholEffect()
    local Ped = PlayerPedId()
    if alcoholEffect ~= "" then
        AnimpostfxStop(alcoholEffect)
        ResetPedMovementClipset(Ped, 0.0)
        ClearTimecycleModifier()
        ResetScenarioTypesEnabled()
        SetPedIsDrunk(Ped, false)
        SetPedMotionBlur(Ped, false)
    end
    currentAlcoholEffect = ""
    alcoholEffect = ""
end

function startAlcoholEffect(data, level)
    local Ped = PlayerPedId()
    if currentAlcoholEffect == level then
        return
    else
        clearCurrentAlcoholEffect()
        currentAlcoholEffect = level
    end

    -- Start effect using sent data
    if alcoholEffect ~= data.effect then
        alcoholEffect = data.effect
        AnimpostfxPlay(data.effect, 0, true)
        if data.movement then
            RequestAnimSet(data.movement)
            while not HasAnimSetLoaded(data.movement) do
                Wait(100)
            end
            SetPedMovementClipset(Ped, data.movement, 3.0)
        end
        SetPedCanRagdoll(Ped, true)
        if data.camShake then
            ShakeGameplayCam("DRUNK_SHAKE", data.camShake)
        end
        SetTimecycleModifier("Drunk")
        SetPedMotionBlur(Ped, true)
        SetPedIsDrunk(Ped, true)

        if data.drivingEffect or data.canStumble then

            CreateThread(function()
                local effectCheck = level
                local lastStumbleTime = GetGameTimer() + 1200
                local lastDriveTime = GetGameTimer() + 6000
                while effectCheck == currentAlcoholEffect do
                    if data.camStumble and GetGameTimer() > lastStumbleTime and math.random() > (data.stumbleChance or 0.8) then
                        lastStumbleTime = GetGameTimer() + 1200
                        SetPedToRagdoll(Ped, 5000, 5000, 0, true, true, false)
                    end
                    if data.driving and GetGameTimer() > lastDriveTime then
                        local inVeh, veh, seat = GetSeatPedIsIn()
                        if inVeh then
                            lastDriveTime = GetGameTimer() + 6000
                            if seat == -1 then
                                if math.random() < 0.62 then
                                    StartVehicleHorn(veh, 1000, "NORMAL", false)
                                end
                            end
                        end
                    end
                    Wait(1000)
                end
                --print("Effect loop broken")
            end)

        end
    end
end

-- Helper
function GetSeatPedIsIn()
    local inVeh, veh, seat = false, 0, 0
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
            inVeh = true
            seat = -1
        end
    end
    return inVeh, veh, seat
end


-- Drug thread
function addDrugCount(count, canOD)
    drugCount = drugCount + count
    --print("Drug count increased, current amount:", drugCount)
    if drugCount >= minDrugCount and drugCount <= maxDrugCount then
        startDrugEffect(drugEffectData.levels["min"], "min")
    elseif drugCount > maxDrugCount then
        if canOD then
            SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) - math.random(10, 15))
        end
        startDrugEffect(drugEffectData.levels["max"], "max")
    end
end

function getDrugCount()
    return drugCount
end

function removeDrugCount(count)
    --print("Drug count decreased, current amount:", drugCount)
    drugCount = drugCount - count
end

local drugThreadRun = false
function runDrugThread()
    if drugThreadRun == true then
        return
    else
        drugThreadRun = true
    end
    --print("Drug Thread triggered")
    while drugCount > 0 do
        Wait(purgeTimer)
        removeDrugCount(1)
        if drugCount <= 0 then
            drugThreadRun = false
            break
        end
	end
end

exports("getDrugCount", getDrugCount)
exports("addDrugCount", addDrugCount)
exports("removeDrugCount", removeDrugCount)


-- EFFECT Management

local currentDrugEffect = ""
local drugEffect = ""
function startDrugEffect(data, level)
    local Ped = PlayerPedId()
    if currentDrugEffect == level then
        return
    else
        clearCurrentAlcoholEffect()
        currentDrugEffect = level
    end

    -- Start effect using sent data
    if drugEffect ~= data.effect then
        drugEffect = data.effect
        AnimpostfxPlay(data.effect, 0, true)
        if data.movement then
            RequestAnimSet(data.movement)
            while not HasAnimSetLoaded(data.movement) do
                Wait(100)
            end
            SetPedMovementClipset(Ped, data.movement, 3.0)
        end
        SetPedCanRagdoll(Ped, true)
        if data.camShake then
            ShakeGameplayCam("DRUNK_SHAKE", data.camShake)
        end
        SetTimecycleModifier("Drunk")
        SetPedMotionBlur(Ped, true)
        SetPedIsDrunk(Ped, true)
    end
end