PedGenerator = {
    Helpers = {}
}
local debug = true
local debugPrint = function(...)
    if debug then
        print("^5PedGen^7:^2", ..., "^7")
    end
end
local currentPed = nil
local pedPreview = nil
debugPrint("Module loaded")
PedGenerator.Start = function()
    currentPed = PedGenerator.Helpers.pedHandler("mp_m_freemode_01")
end

PedGenerator.Helpers.pedHandler = function(model, properties)
    if currentPed then
        PedGenerator.Helpers.removeHandlerPed(currentPed)
    end
    ---
    local hash = type(model) == 'string' and GetHashKey(model) or model
    debugPrint("Requesting Model", "^7"..hash)
    RequestModel(hash)

    debugPrint("Loading Model...")
    while not HasModelLoaded(hash) do Wait(1) end

    debugPrint("Creating new ped")
    local tempPed = CreatePed(4, hash, 0.0, 0.0, 0.0, 0.0, false, false)

    debugPrint("Forcing ped invisiblity")
    SetEntityCollision(tempPed, false, true)
    SetEntityInvincible(tempPed, true)
    NetworkSetEntityInvisibleToNetwork(tempPed, true)
    SetEntityCanBeDamaged(tempPed, false)
    SetBlockingOfNonTemporaryEvents(tempPed, true)
    FreezeEntityPosition(tempPed, true)
    SetEntityAlpha(tempPed, 255, false)
    SetEntityVisible(tempPed, true, false)

    if properties then
        debugPrint("Properties found, starting changes")

    end

    PedGenerator.Helpers.sendPedToFrontend(tempPed)

    return tempPed
end

PedGenerator.Helpers.sendPedToFrontend = function(ped)
    if pedPreview then
        debugPrint("ped exists, triggering removePedFromFrontend")
        PedGenerator.Helpers.removePedFromFrontend(pedPreview)
        Wait(500)
    end

    debugPrint("Cloning created ped", ped)
    pedPreview = ClonePed(ped, false, true, false)

    debugPrint("Activating frontend")
    SetFrontendActive(true)
    ActivateFrontendMenu(`FE_MENU_VERSION_EMPTY_NO_BACKGROUND`, true, -1)
    Wait(100)
    SetMouseCursorVisible(false)

    local x, y, z = table.unpack(GetEntityCoords(ped))

    SetEntityCoords(pedPreview, x, y, z - 10)
    FreezeEntityPosition(pedPreview, true)
    SetEntityVisible(pedPreview, false, false)
    --NetworkSetEntityInvisibleToNetwork(pedPreview, false)
    SetPedAsNoLongerNeeded(pedPreview)

    debugPrint("Sending Ped to Pausemenu")
    GivePedToPauseMenu(pedPreview, 2)
    SetPauseMenuPedLighting(true)
    SetPauseMenuPedSleepState(true)
end

PedGenerator.Helpers.removePedFromFrontend = function(ped)
    DeleteEntity(ped)
    SetFrontendActive(false)
end

PedGenerator.Helpers.removeHandlerPed = function(ped)
    debugPrint("Removing old ped", ped)
    DeletePed(ped)
end

RegisterCommand("pedgen", function(source, args, rawCommand)
	PedGenerator.Start()
end, false)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    print("test")
    PedGenerator.Helpers.removePedFromFrontend(pedPreview)
    SetFrontendActive(false)
end)