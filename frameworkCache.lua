--[[
    Cached Resource Initialization Module
    --------------------------------------
    This module initializes shared data (Items, Vehicles, Jobs, Gangs)
    only once and stores it in _G.__jimBridgeDataCache for reuse across scripts.
]]

local Exports = {
    QBExport = "qb-core",
    QBXExport = "qbx_core",
    ESXExport = "es_extended",
    OXCoreExport = "ox_core",

    OXInv = "ox_inventory",
    QBInv = "qb-inventory",
    PSInv = "ps-inventory",
    QSInv = "qs-inventory",
    CoreInv = "core_inventory",
    CodeMInv = "codem-inventory",
    OrigenInv = "origen_inventory",
    TgiannInv = "tgiann-inventory",

    OXLibExport = "ox_lib",

    QBMenuExport = "qb-menu",

    QBTargetExport = "qb-target",
    OXTargetExport = "ox_target",

    -- REDM
    RSGExport = "rsg-core",
    RSGInv = "rsg-inventory"
}

-- Ensure cache only runs once
if _G.__jimBridgeDataCache then return end
_G.__jimBridgeDataCache = {}
local cache = _G.__jimBridgeDataCache

function checkExists(resourceName)
    return GetResourceState(resourceName):find("start") or GetResourceState(resourceName):find("stopped")
end

local fileLoader = assert(load(LoadResourceFile("oxmysql", ('lib/MySQL.lua')), ('@@oxmysql/lib/MySQL.lua')))
fileLoader()
if checkExists(Exports.OXCoreExport) then
    -- Detected OX_Core in server, wait for it to be started if needed
    while GetResourceState(Exports.OXCoreExport) ~= "started" do Wait(100) end
    local fileLoader = assert(load(LoadResourceFile(Exports.OXCoreExport, ('lib/init.lua')), ('@@'..Exports.OXCoreExport..'/lib/init.lua')))
    fileLoader()
end
if checkExists(Exports.ESXExport) then
    -- Detected ESX in server, wait for it to be started if needed
    while GetResourceState(Exports.ESXExport) ~= "started" do Wait(100) end
    local fileLoader = assert(load(LoadResourceFile(Exports.ESXExport, ('/imports.lua')), ('@@'..Exports.ESXExport..'/imports.lua')))
    fileLoader()
end

-- Init variables
local Items, Vehicles, Jobs, Gangs, Core = nil, nil, nil, nil, nil
local itemResource, jobResource, vehResource = "", "", ""

-- Print just to announce it knows the exports/scripts exist in the server
for _, v in pairs(Exports) do
    if checkExists(v) then
        print("^6Bridge^7: '^3"..v.."^7' detected")
    end
end

---------------------
---- Load Items -----
---------------------
if checkExists(Exports.OXInv) then
    -- Wait for OX Inventory to start if it's not already started
    while GetResourceState(Exports.OXInv) ~= "started" do Wait(100) end
    itemResource = Exports.OXInv
    Items = exports[Exports.OXInv]:Items()

    -- Get Weapon info and duplicate them if they are uppercase
    -- (duplicate incase anything checks for the uppercase version)
    for k, v in pairs(Items) do
        if k:find("WEAPON") then
            Items[k:lower()] = Items[k]
            Items[k:lower()].image = k..".png"
        end
        Items[k].image = (v.client and v.client.image) and v.client.image:gsub("nui://"..Exports.OXInv.."/web/images/", "") or k..".png"
        Items[k].hunger = v.client and v.client.hunger
        Items[k].thirst = v.client and v.client.thirst
    end

elseif checkExists(Exports.QBExport) then
    while GetResourceState(Exports.QBExport) ~= "started" do Wait(100) end
    itemResource = Exports.QBExport
    Core = exports[Exports.QBExport]:GetCoreObject()
    Items = Core.Shared.Items

elseif checkExists(Exports.ESXExport) then
    itemResource = Exports.ESXExport
    if GetResourceState(Exports.QSInv):find("start") then
        Items = exports[Exports.QSInv]:GetItemList()
    else
        Items = ESX.GetItems()
        while not next(Items) do
            Items = ESX.GetItems()
            Wait(1000)
        end
    end

elseif checkExists(Exports.RSGExport) then
    while GetResourceState(Exports.RSGExport) ~= "started" do Wait(100) end
    itemResource = Exports.RSGExport
    Core = exports[Exports.RSGExport]:GetCoreObject()
    Items = Core.Shared.Items
end

---------------------
--- Load Vehicles ---
---------------------
if checkExists(Exports.QBXExport) or checkExists(Exports.QBExport) then
    vehResource = Exports.QBExport
    Core = Core or exports[Exports.QBExport]:GetCoreObject()
    Vehicles = Core.Shared.Vehicles

elseif checkExists(Exports.OXCoreExport) then
    vehResource = Exports.OXCoreExport
    Vehicles = {}
    for k, v in pairs(Ox.GetVehicleData()) do
        Vehicles[k] = {
            model = k, hash = GetHashKey(k),
            price = v.price,
            name = v.name,
            brand = v.make
        }
    end

elseif checkExists(Exports.ESXExport) then
    vehResource = Exports.ESXExport
    while not MySQL do Wait(1000) end
    Vehicles = {}
    for _, v in pairs(MySQL.query.await('SELECT model, price, name FROM vehicles')) do
        Vehicles[v.model] = {
            model = v.model,
            hash = GetHashKey(v.model),
            price = v.price,
            name = v.name,
        }
    end

elseif checkExists(Exports.RSGExport) then
    vehResource = Exports.RSGExport
    Core = Core or exports[Exports.RSGExport]:GetCoreObject()
    Vehicles = Core.Shared.Vehicles
end

---------------------
----- Load Jobs -----
---------------------
if checkExists(Exports.QBXExport) then
    jobResource = Exports.QBXExport
    Core = Core or exports[Exports.QBXExport]:GetCoreObject()
    Jobs, Gangs = exports[Exports.QBXExport]:GetJobs(), exports[Exports.QBXExport]:GetGangs()

elseif checkExists(Exports.OXCoreExport) then
    jobResource = Exports.OXCoreExport
    Jobs = {}
    while not MySQL do Wait(1000) end
    local tempJobs = MySQL.query.await('SELECT * FROM `ox_groups`')
    local tempGrades = MySQL.query.await('SELECT * FROM `ox_group_grades`')
    local gradeMap = {}
    for _, grade in pairs(tempGrades) do
        gradeMap[grade.group] = gradeMap[grade.group] or {}
        gradeMap[grade.group][grade.grade] = { name = grade.label }
    end
    for _, job in pairs(tempJobs) do
        Jobs[job.name] = {
            label = job.label,
            grades = gradeMap[job.name] or {}
        }
    end
    Gangs = Jobs

elseif checkExists(Exports.QBExport) then
    jobResource = Exports.QBExport
    Core = Core or exports[Exports.QBExport]:GetCoreObject()
    Jobs, Gangs = Core.Shared.Jobs, Core.Shared.Gangs

elseif checkExists(Exports.ESXExport) then
    jobResource = Exports.ESXExport
    ESX = exports[Exports.ESXExport]:getSharedObject()
    Jobs = ESX.GetJobs()
    while not next(Jobs) do
        Wait(100)
        Jobs = ESX.GetJobs()
    end
    for Role, Grades in pairs(Jobs) do
        -- Check for if user has added grades
        if Grades.grades == nil or not next(Grades.grades) then
            goto continue
        end
        for grade, info in pairs(Grades.grades) do
            if info.label and info.label:find("[Bb]oss") then
                Jobs[Role].grades[grade].isBoss = true
                goto continue
            end
        end
        local highestGrade = nil
        for k in pairs(Grades.grades) do
            local num = tonumber(k)
            if num and (not highestGrade or num > highestGrade) then
                highestGrade = num
            end
        end

        if highestGrade then
            Jobs[Role].grades[tostring(highestGrade)].isBoss = true
        end
        ::continue::
    end
    Gangs = Jobs

elseif checkExists(Exports.RSGExport) then
    jobResource = Exports.RSGExport
    Core = Core or exports[Exports.RSGExport]:GetCoreObject()
    Jobs, Gangs = Core.Shared.Jobs, Core.Shared.Gangs
end

-- Save to global cache
cache.Items = Items
cache.Vehicles = Vehicles
cache.Jobs = Jobs
cache.Gangs = Gangs

CreateThread(function()
    local counts = {
        Items = 0,
        Vehicles = 0,
        Jobs = 0,
        Gangs = 0,
    }
    for k, v in pairs(cache) do
        for count in pairs(v) do
            counts[k] += 1
        end
    end
    print("^6FrameworkCache^7: ^2Loaded ^5"..tostring(counts.Items).."^2 Items from ^7"..itemResource)
    print("^6FrameworkCache^7: ^2Loaded ^5"..tostring(counts.Vehicles).."^2 Vehicles from ^7"..vehResource)
    print("^6FrameworkCache^7: ^2Loaded ^5"..tostring(counts.Jobs).."^2 Jobs from ^7"..jobResource)
    print("^6FrameworkCache^7: ^2Loaded ^5"..tostring(counts.Gangs).."^2 Gangs from ^7"..jobResource)
end)

--print(json.encode(cache.Items , { indent = true}))

RegisterNetEvent("jim_bridge:requestCache", function()
    local src = source
    TriggerClientEvent("jim_bridge:receiveCache", src, _G.__jimBridgeDataCache)
end)


exports("GetSharedData", function()
    -- Wait for data to be ready before returning it
    local timeout = GetGameTimer() + 5000
    while (
        not _G.__jimBridgeDataCache or
        (not _G.__jimBridgeDataCache.Items or next(_G.__jimBridgeDataCache.Items) == nil) or
        (not _G.__jimBridgeDataCache.Vehicles or next(_G.__jimBridgeDataCache.Vehicles) == nil) or
        (not _G.__jimBridgeDataCache.Jobs or next(_G.__jimBridgeDataCache.Jobs) == nil)
    ) and GetGameTimer() < timeout do
        Wait(50)
    end
    return _G.__jimBridgeDataCache
end)