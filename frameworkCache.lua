--[[
    Cached Resource Initialization Module
    --------------------------------------
    Initializes shared resource data (Items, Vehicles, Jobs, Gangs) once and caches it
    to improve performance and reduce redundant data fetching across scripts.
]]

-- Define resource names used in different frameworks
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
    JPRInv = "jpr-inventory",

    OXLibExport = "ox_lib",

    QBMenuExport = "qb-menu",

    QBTargetExport = "qb-target",
    OXTargetExport = "ox_target",

    -- REDM
    RSGExport = "rsg-core",
    RSGInv = "rsg-inventory"
}

-- Prevent reloading if cache is already initialized
if _G.__jimBridgeDataCache then return end
_G.__jimBridgeDataCache = {}
local cache = _G.__jimBridgeDataCache

-- Helper function to check if resource exists in server (instead of if it is already started)
local function checkExists(resourceName)
    return GetResourceState(resourceName):find("start") or GetResourceState(resourceName):find("stopped")
end

-- Ensure oxmysql resource is loaded
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

-- Initialize variables for caching
local Items, Vehicles, Jobs, Gangs, Core = {}, {}, {}, {}, nil
local itemResource, jobResource, vehResource = "N/A", "N/A", "N/A"

-- Print just to announce it knows the exports/scripts exist in the server
for _, v in pairs(Exports) do
    if checkExists(v) then
        print("^6Bridge^7: '^3"..v.."^7' detected")
    end
end

---------------------
---- Load Items -----
---------------------
-- Items initialization based on detected inventory system
if checkExists(Exports.OXInv) then
    -- Wait for OX Inventory to start if it's not already started
    while GetResourceState(Exports.OXInv) ~= "started" do Wait(100) end
    itemResource = Exports.OXInv

    local success, result = pcall(function()
        return exports[Exports.OXInv]:Items()
    end)
    if success and result then
        Items = result
    end

    if Items == nil or not next(Items) then
        print("^1--------------------------------------------^7")
        print("^1ERROR^7: ^1Can NOT find "..Exports.OXInv.." ^7Items ^1list^7, ^1possible error in that file^7?")
        print("^1--------------------------------------------^7")
        Items = {} -- Fallback to an empty table
    end

    -- Get Weapon info and duplicate them if they are uppercase
    -- (duplicate incase anything checks for the uppercase version)
    for k, v in pairs(Items) do
        if type(k) == "string" then
            if k:find("WEAPON") then
                Items[k:lower()] = Items[k]
            end
        else
            print("^1ERROR^7: ^1Possible table inside a table, check your items.lua^7?")
            print("^1Possible Issue found^7:")
            print(json.encode(Items[k], {indent = true}))
        end
    end

elseif checkExists(Exports.QBExport) then
    while GetResourceState(Exports.QBExport) ~= "started" do Wait(100) end
    itemResource = Exports.QBExport
    Core = exports[Exports.QBExport]:GetCoreObject()
    Items = Core.Shared.Items

    if Items == nil or not next(Items) then
        print("^1--------------------------------------------^7")
        print("^1ERROR^7: ^1Can NOT find "..Exports.QBExport.." ^7Items ^1list^7, ^1possible error in that file^7?")
        print("^1--------------------------------------------^7")
        Items = {} -- Fallback to an empty table
    end

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
    if Items == nil or not next(Items) then
        print("^1--------------------------------------------^7")
        print("^1ERROR^7: ^1Can NOT find "..Exports.RSGExport.." ^7Items ^1list^7, ^1possible error in that file^7?")
        print("^1--------------------------------------------^7")
        Items = {} -- Fallback to an empty table
    end

end

---------------------
--- Load Vehicles ---
---------------------
-- Vehicle loading depending on framework
if checkExists(Exports.QBXExport) or checkExists(Exports.QBExport) then
    vehResource = Exports.QBExport
    Core = Core or exports[Exports.QBExport]:GetCoreObject()
    Vehicles = Core.Shared.Vehicles
    if Vehicles == nil or not next(Vehicles) then
        print("^1--------------------------------------------^7")
        print("^1ERROR^7: ^1Can NOT find "..Exports.QBExport.." ^7Vehicles ^1list^7, ^1possible error in that file^7?")
        print("^1--------------------------------------------^7")
        Vehicles = {} -- Fallback to an empty table
    end

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
    if Vehicles == nil or not next(Vehicles) then
        print("^1--------------------------------------------^7")
        print("^1ERROR^7: ^1Can NOT find shared ^7Vehicles ^1table^7, ^1possible error in that file^7?")
        print("^1--------------------------------------------^7")
        Vehicles = {} -- Fallback to an empty table
    end

end

---------------------
----- Load Jobs -----
---------------------
-- Jobs loading based on framework
if checkExists(Exports.QBXExport) then
    jobResource = Exports.QBXExport
    Core = Core or exports[Exports.QBXExport]:GetCoreObject()
    Jobs, Gangs = exports[Exports.QBXExport]:GetJobs(), exports[Exports.QBXExport]:GetGangs()
    if Jobs == nil or not next(Jobs) then
        print("^1--------------------------------------------^7")
        print("^1ERROR^7: ^1Can NOT find shared ^7Jobs ^1table^7, ^1possible error in that file^7?")
        print("^1--------------------------------------------^7")
        Jobs = {} -- Fallback to an empty table
    end

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
    if Jobs == nil or not next(Jobs) then
        print("^1--------------------------------------------^7")
        print("^1ERROR^7: ^1Can NOT find shared ^7Jobs ^1table^7, ^1possible error in that file^7?")
        print("^1--------------------------------------------^7")
        Jobs = {} -- Fallback to an empty table
    end

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