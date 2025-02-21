--Screen Effects
local alienEffect = false
function AlienEffect()
    if alienEffect then return else alienEffect = true end
    debugPrint("^5Debug^7: ^3AlienEffect^7() ^2activated")
    AnimpostfxPlay("DrugsMichaelAliensFightIn", 3.0, 0)
    Wait(math.random(5000, 8000))
    local Ped = PlayerPedId()
    local animDict = "MOVE_M@DRUNK@VERYDRUNK"
    loadAnimDict(animDict)
    SetPedCanRagdoll(Ped, true)
    ShakeGameplayCam('DRUNK_SHAKE', 2.80)
    SetTimecycleModifier("Drunk")
    SetPedMovementClipset(Ped, animDict, 1)
    SetPedMotionBlur(Ped, true)
    SetPedIsDrunk(Ped, true)
    Wait(1500)
    SetPedToRagdoll(Ped, 5000, 1000, 1, 0, 0, 0)
    Wait(13500)
    SetPedToRagdoll(Ped, 5000, 1000, 1, 0, 0, 0)
    Wait(120500)
    ClearTimecycleModifier()
    ResetScenarioTypesEnabled()
    ResetPedMovementClipset(Ped, 0)
    SetPedIsDrunk(Ped, false)
    SetPedMotionBlur(Ped, false)
    AnimpostfxStopAll()
    ShakeGameplayCam('DRUNK_SHAKE', 0.0)
    AnimpostfxPlay("DrugsMichaelAliensFight", 3.0, 0)
    Wait(math.random(45000, 60000))
    AnimpostfxPlay("DrugsMichaelAliensFightOut", 3.0, 0)
    AnimpostfxStop("DrugsMichaelAliensFightIn")
    AnimpostfxStop("DrugsMichaelAliensFight")
    AnimpostfxStop("DrugsMichaelAliensFightOut")
    alienEffect = false
    debugPrint("^5Debug^7: ^3AlienEffect^7() ^2stopped")
end
local weedEffect = false
function WeedEffect()
    if weedEffect then return else weedEffect = true end
    debugPrint("^5Debug^7: ^3WeedEffect^7() ^2activated")
    AnimpostfxPlay("DrugsMichaelAliensFightIn", 3.0, 0)
    Wait(math.random(3000, 20000))
    AnimpostfxPlay("DrugsMichaelAliensFight", 3.0, 0)
    Wait(math.random(15000, 20000))
    AnimpostfxPlay("DrugsMichaelAliensFightOut", 3.0, 0)
    AnimpostfxStop("DrugsMichaelAliensFightIn")
    AnimpostfxStop("DrugsMichaelAliensFight")
    AnimpostfxStop("DrugsMichaelAliensFightOut")
    weedEffect = false
    debugPrint("^5Debug^7: ^3WeedEffect^7() ^2stopped")
end
local trevorEffect = false
function TrevorEffect()
    if trevorEffect then return else trevorEffect = true end
    debugPrint("^5Debug^7: ^3TrevorEffect^7() ^2activated")
    AnimpostfxPlay("DrugsTrevorClownsFightIn", 3.0, 0)
    Wait(3000)
    AnimpostfxPlay("DrugsTrevorClownsFight", 3.0, 0)
    Wait(30000)
	AnimpostfxPlay("DrugsTrevorClownsFightOut", 3.0, 0)
	AnimpostfxStop("DrugsTrevorClownsFight")
	AnimpostfxStop("DrugsTrevorClownsFightIn")
	AnimpostfxStop("DrugsTrevorClownsFightOut")
    trevorEffect = false
    debugPrint("^5Debug^7: ^3TrevorEffect^7() ^2stopped")
end
local turboEffect = false
function TurboEffect()
    if turboEffect then return else turboEffect = true end
    debugPrint("^5Debug^7: ^3TurboEffect^7() ^2activated")
    AnimpostfxPlay('RaceTurbo', 0, true)
    SetTimecycleModifier('rply_motionblur')
    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.25)
    Wait(30000)
    StopGameplayCamShaking(true)
    SetTransitionTimecycleModifier('default', 0.35)
    Wait(1000)
    ClearTimecycleModifier()
    AnimpostfxStop('RaceTurbo')
    turboEffect = false
    debugPrint("^5Debug^7: ^3TurboEffect^7() ^2stopped")
end
local rampageEffect = false
function RampageEffect()
    if rampageEffect then return else rampageEffect = true end
    debugPrint("^5Debug^7: ^3RampageEffect^7() ^2activated")
    AnimpostfxPlay('Rampage', 0, true)
    SetTimecycleModifier('rply_motionblur')
    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.25)
    Wait(30000)
    StopGameplayCamShaking(true)
    SetTransitionTimecycleModifier('default', 0.35)
    Wait(1000)
    ClearTimecycleModifier()
    AnimpostfxStop('Rampage')
    rampageEffect = false
    debugPrint("^5Debug^7: ^3RampageEffect^7() ^2stopped")
end
local focusEffect = false
function FocusEffect()
    if focusEffect then return else focusEffect = true end
    debugPrint("^5Debug^7: ^3FocusEffect^7() ^2activated")
    Wait(1000)
    AnimpostfxPlay('FocusIn', 0, true)
    Wait(30000)
    AnimpostfxStop('FocusIn')
    focusEffect = false
    debugPrint("^5Debug^7: ^3FocusEffect^7() ^2stopped")
end
local nightVisionEffect = false
function NightVisionEffect()
    if nightVisionEffect then return else nightVisionEffect = true end
    debugPrint("^5Debug^7: ^3NightVisionEffect^7() ^2activated")
    SetNightvision(true)
    Wait(math.random(3000, 4000))  -- FEEL FREE TO CHANGE THIS
    SetNightvision(false)
    SetSeethrough(false)
    nightVisionEffect = false
    debugPrint("^5Debug^7: ^3NightVisionEffect^7() ^2stopped")
end
local thermalEffect = false
function ThermalEffect()
    if thermalEffect then return else thermalEffect = true end
    debugPrint("^5Debug^7: ^3ThermalEffect^7() ^2activated")
    SetNightvision(true)
    SetSeethrough(true)
    Wait(math.random(2000, 3000))  -- FEEL FREE TO CHANGE THIS
    SetNightvision(false)
    SetSeethrough(false)
    thermalEffect = false
    debugPrint("^5Debug^7: ^3ThermalEffect^7() ^2stopped")
end

--Built-in Buff effects
local healEffect = false
function HealEffect(data)
    if healEffect then return end
    debugPrint("^5Debug^7: ^3HealEffect^7() ^2activated")
    healEffect = true
    local count = (data[1] / 1000)
    while count > 0 do
        Wait(1000)
        count -= 1
        SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + data[2])
    end
    healEffect = false
    debugPrint("^5Debug^7: ^3HealEffect^7() ^2stopped")
end

local staminaEffect = false
function StaminaEffect(data)
    if staminaEffect then return end
    debugPrint("^5Bridge^7: ^3StaminaEffect^7() ^2activated")
    staminaEffect = true
    local startStamina = (data[1] / 1000)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
    while startStamina > 0 do
        Wait(1000)
        if math.random(5, 100) < 10 then RestorePlayerStamina(PlayerId(), data[2]) end
        startStamina -= 1
        if math.random(5, 100) < 51 then end
    end
    startStamina = 0
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    staminaEffect = false
    debugPrint("^5Bridge^7: ^3StaminaEffect^7() ^2stopped")
end

function StopEffects() -- Used to clear up any effects stuck on screen
    debugPrint("^5Bridge^7: ^2All screen effects stopped")
    ShakeGameplayCam('DRUNK_SHAKE', 0.0)
    SetPedToRagdoll(PlayerPedId(), 5000, 1000, 1, 0, 0, 0)
    ClearTimecycleModifier()
    ResetScenarioTypesEnabled()
    ResetPedMovementClipset(PlayerPedId(), 0)
    SetPedIsDrunk(PlayerPedId(), false)
    SetPedMotionBlur(PlayerPedId(), false)
    SetNightvision(false)
    SetSeethrough(false)
    AnimpostfxStop("DrugsMichaelAliensFightIn")
    AnimpostfxStop("DrugsMichaelAliensFight")
    AnimpostfxStop("DrugsMichaelAliensFightOut")
	AnimpostfxStop("DrugsTrevorClownsFight")
	AnimpostfxStop("DrugsTrevorClownsFightIn")
	AnimpostfxStop("DrugsTrevorClownsFightOut")
    AnimpostfxStop('RaceTurbo')
    AnimpostfxStop('FocusIn')
    AnimpostfxStop('Rampage')
end