Items, Vehicles, Jobs, Gangs, Core = {}, nil, nil, nil, nil

-- Shared Exports Initialization
Exports.PSInv = isStarted("lj-inventory") and "lj-inventory" or Exports.PSInv

OXLibExport, QBXExport, QBExport, ESXExport, OXCoreExport =
    Exports.OXLibExport or "",
    Exports.QBXExport or "",
    Exports.QBExport or "",
    Exports.ESXExport or "",
    Exports.OXCoreExport or ""

OXInv, QBInv, PSInv, QSInv, CoreInv, CodeMInv, OrigenInv, TgiannInv, JPRInv =
    Exports.OXInv or "",
    Exports.QBInv or "",
    Exports.PSInv or "",
    Exports.QSInv or "",
    Exports.CoreInv or "",
    Exports.CodeMInv or "",
    Exports.OrigenInv or "",
    Exports.TgiannInv or "",
    Exports.JPRInv or ""

RSGExport, RSGInv = Exports.RSGExport or "", Exports.RSGInv or ""
QBMenuExport = Exports.QBMenuExport or ""
QBTargetExport, OXTargetExport = Exports.QBTargetExport or "", Exports.OXTargetExport or ""

if isStarted(QBXExport) or isStarted(QBExport) then
    Core = Core or exports[QBExport]:GetCoreObject()
elseif isStarted(RSGExport) then
    Core = Core or exports[RSGExport]:GetCoreObject()
end


if IsDuplicityVersion() then
    CreateThread(function()
        local cache = nil
        local timeout = GetGameTimer() + 5000 -- 5 seconds max wait

        -- Wait until jim_bridge is started and export is available
        while not cache and GetGameTimer() < timeout do
            if GetResourceState("jim_bridge"):find("start") then
                local success, result = pcall(function()
                    return exports["jim_bridge"]:GetSharedData()
                end)
                if success and result then
                    cache = result
                    --print(json.encode(cache, {indent = true}))
                end
            end
            Wait(100)
        end

        if not cache then
            print("^1ERROR^7: ^2jim_bridge export not available after timeout^7.")
            return
        end

        Items    = cache.Items
        Vehicles = cache.Vehicles
        Jobs     = cache.Jobs
        Gangs    = cache.Gangs

        debugPrint("^6Bridge^7: ^2Shared cache successfully loaded from export^7.")
    end)
else
    local hasCache = false
    -- 🔹 Client Side: Request from server
    _G.__jimBridgeDataCache = {}

    RegisterNetEvent("jim_bridge:receiveCache", function(data)
        if not hasCache then
            _G.__jimBridgeDataCache = data
            hasCache = true
        else
            return
        end
    end)

    TriggerServerEvent("jim_bridge:requestCache")

    CreateThread(function()
        while not _G.__jimBridgeDataCache or not next(_G.__jimBridgeDataCache) do Wait(50) end
        local cache = _G.__jimBridgeDataCache
        Items = cache.Items or {}
        Vehicles = cache.Vehicles or {}
        Jobs = cache.Jobs or {}
        Gangs = cache.Gangs or {}

        if isStarted(ESXExport) then
            for _, v in pairs(Vehicles) do
                Vehicles[v.model] = {
                    model = v.model,
                    hash = v.hash,
                    price = v.price,
                    name = v.name,
                    brand = GetMakeNameFromVehicleModel(v.model):lower():gsub("^%l", string.upper)
                }
            end
        end
        if isStarted(OXInv) then
            for k, v in pairs(Items) do
                local tempInfo = exports[OXInv]:Items(v.name)
                if tempInfo.client then
                    Items[k].image = (tempInfo.client and tempInfo.client.image) and tempInfo.client.image:gsub("nui://"..OXInv.."/web/images/", "") or k..".png"
                    Items[k].hunger = tempInfo.client and tempInfo.client.hunger
                    Items[k].thirst = tempInfo.client and tempInfo.client.thirst
                end
            end
        end
    end)
end
