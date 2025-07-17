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
local cache = {
    Items = {},
    Vehicles = {},
    Jobs = {},
    Gangs = {},
}
local cacheReady = false
local timers = {}
local function startTimer(label)
    timers[label] = GetGameTimer()
end

local function endTimer(label)
    timers[label] = GetGameTimer() - (timers[label] or GetGameTimer())
    timers[label] = "("..(timers[label] / 1000).."s)"
end
startTimer("Cache") startTimer("Items") startTimer("Vehicles") startTimer("Jobs") startTimer("InvWeight") startTimer("InvSlots")
-- Helper function to check if resource exists in server (instead of if it is already started)
local function checkExists(resourceName)
    return GetResourceState(resourceName):find("start") or GetResourceState(resourceName):find("stopped")
end

-- Ensure oxmysql resource is loaded
if checkExists(Exports.OXCoreExport) or checkExists(Exports.ESXExport) then
    local fileLoader = assert(load(LoadResourceFile("oxmysql", ('lib/MySQL.lua')), ('@@oxmysql/lib/MySQL.lua')))
    fileLoader()
end

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
        cache.Items = result
    end

    -- Get Weapon info and duplicate them if they are uppercase
    -- (duplicate incase anything checks for the uppercase version)
    for k, v in pairs(cache.Items) do
        if type(k) == "string" then
            if k:find("WEAPON") then
                cache.Items[k:lower()] = cache.Items[k]
            end
        else
            print("^1ERROR^7: ^1Possible table inside a table, check your items.lua^7?")
            print("^1Possible Issue found^7:")
            print(json.encode(Items[k], {indent = true}))
        end
    end

elseif checkExists(Exports.QBXExport) then
    while GetResourceState(Exports.QBXExport) ~= "started" do Wait(100) end
    itemResource = Exports.QBXExport
    cache.Items = exports[Exports.QBExport]:GetCoreObject().Shared.Items
    -- If this is nil, they need to update to qbx_core 1.23.0+
    if not cache.Items then
        -- if their inventory doesn't allow that (they refuse to update their butchered core replacement):
        if GetResourceState(Exports.QSInv):find("start") then
            itemResource = Exports.QSInv
            cache.Items = exports[Exports.QSInv]:GetItemList()

        elseif GetResourceState(Exports.OrigenInv):find("start") then
            itemResource = Exports.OrigenInv
            cache.Items = exports[Exports.OrigenInv]:Items()

        elseif GetResourceState(Exports.CodeMInv):find("start") then
            itemResource = Exports.CodeMInv
            cache.Items = exports[Exports.CodeMInv]:GetItemList()

        elseif GetResourceState(Exports.CoreInv):find("start") then
            itemResource = Exports.CoreInv
            cache.Items = exports[Exports.CoreInv]:getItemsList()

        elseif GetResourceState(Exports.TgiannInv):find("start") then
            itemResource = Exports.TgiannInv
            cache.Items = exports[Exports.TgiannInv]:Items()
        end
    end

elseif checkExists(Exports.QBExport) then
    while GetResourceState(Exports.QBExport) ~= "started" do Wait(100) end
    itemResource = Exports.QBExport
    cache.Items = exports[Exports.QBExport]:GetCoreObject().Shared.Items

elseif checkExists(Exports.ESXExport) then
    itemResource = Exports.ESXExport
    if GetResourceState(Exports.QSInv):find("start") then
        cache.Items = exports[Exports.QSInv]:GetItemList()
    else
        cache.Items = ESX.GetItems()
        while not next(cache.Items) do
            cache.Items = ESX.GetItems()
            Wait(1000)
        end
    end

elseif checkExists(Exports.RSGExport) then
    while GetResourceState(Exports.RSGExport) ~= "started" do Wait(100) end
    itemResource = Exports.RSGExport
    cache.Items = exports[Exports.RSGExport]:GetCoreObject().Shared.Items
end
endTimer("Items")

---------------------
--- Load Vehicles ---
---------------------
-- Vehicle loading depending on framework
if checkExists(Exports.QBXExport) then
    vehResource = Exports.QBXExport
    cache.Vehicles = exports[Exports.QBExport]:GetCoreObject().Shared.Vehicles

elseif checkExists(Exports.QBExport)then
    vehResource = Exports.QBExport
    cache.Vehicles = exports[Exports.QBExport]:GetCoreObject().Shared.Vehicles

elseif checkExists(Exports.OXCoreExport) then
    vehResource = Exports.OXCoreExport
    cache.Vehicles = {}
    for k, v in pairs(Ox.GetVehicleData()) do
        cache.Vehicles[k] = {
            model = k, hash = GetHashKey(k),
            price = v.price,
            name = v.name,
            brand = v.make
        }
    end

elseif checkExists(Exports.ESXExport) then
    vehResource = Exports.ESXExport
    while not MySQL do Wait(1000) end
    for _, v in pairs(MySQL.query.await('SELECT model, price, name FROM vehicles')) do
        cache.Vehicles[v.model] = {
            model = v.model,
            hash = GetHashKey(v.model),
            price = v.price,
            name = v.name,
        }
    end

elseif checkExists(Exports.RSGExport) then
    vehResource = Exports.RSGExport
    cache.Vehicles = exports[Exports.RSGExport]:GetCoreObject().Shared.Vehicles

end
endTimer("Vehicles")

---------------------
----- Load Jobs -----
---------------------
-- Jobs loading based on framework
if checkExists(Exports.QBXExport) then
    jobResource = Exports.QBXExport
    cache.Jobs, cache.Gangs = exports[Exports.QBXExport]:GetJobs(), exports[Exports.QBXExport]:GetGangs()

elseif checkExists(Exports.QBExport) then
    jobResource = Exports.QBExport
    cache.Jobs, cache.Gangs = exports[Exports.QBExport]:GetCoreObject().Shared.Jobs, exports[Exports.QBExport]:GetCoreObject().Shared.Gangs

elseif checkExists(Exports.OXCoreExport) then
    jobResource = Exports.OXCoreExport
    while not MySQL do Wait(1000) end
    local tempJobs = MySQL.query.await('SELECT * FROM `ox_groups`')
    local tempGrades = MySQL.query.await('SELECT * FROM `ox_group_grades`')
    local gradeMap = {}
    for _, grade in pairs(tempGrades) do
        gradeMap[grade.group] = gradeMap[grade.group] or {}
        gradeMap[grade.group][grade.grade] = { name = grade.label }
    end
    for _, job in pairs(tempJobs) do
        cache.Jobs[job.name] = {
            label = job.label,
            grades = gradeMap[job.name] or {}
        }
    end
    cache.Gangs = cache.Jobs

elseif checkExists(Exports.ESXExport) then
    jobResource = Exports.ESXExport
    ESX = exports[Exports.ESXExport]:getSharedObject()
    cache.Jobs = ESX.GetJobs()
    while not next(cache.Jobs) do
        Wait(100)
        cache.Jobs = ESX.GetJobs()
    end
    for Role, Grades in pairs(cache.Jobs) do
        -- Check for if user has added grades
        if Grades.grades == nil or not next(Grades.grades) then
            goto continue
        end
        for grade, info in pairs(Grades.grades) do
            if info.label and info.label:find("[Bb]oss") then
                cache.Jobs[Role].grades[grade].isBoss = true
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
            cache.Jobs[Role].grades[tostring(highestGrade)].isBoss = true
        end
        ::continue::
    end
    cache.Gangs = cache.Jobs

elseif checkExists(Exports.RSGExport) then
    jobResource = Exports.RSGExport
    cache.Jobs, cache.Gangs = exports[Exports.RSGExport]:GetCoreObject().Shared.Jobs, exports[Exports.RSGExport]:GetCoreObject().Shared.Gangs

end
endTimer("Jobs")

-- Fallback if nil or empty
if cache.Items == nil or not next(cache.Items) then
    print("^1--------------------------------------------^7")
    print("^1ERROR^7: ^1Can NOT find "..itemResource.." ^7Items ^1list^7, ^1possible error in that file or is it empty^7?")
    print("^1--------------------------------------------^7")
    cache.Items = {} -- Fallback to an empty table
end
if cache.Vehicles == nil or not next(cache.Vehicles) then
    print("^1--------------------------------------------^7")
    print("^1ERROR^7: ^1Can NOT find "..vehResource.." ^7Vehicles ^1list^7, ^1possible error in that file or is it empty^7?")
    print("^1--------------------------------------------^7")
    cache.Vehicles = {} -- Fallback to an empty table
end
if cache.Jobs == nil or not next(cache.Jobs) then
    print("^1--------------------------------------------^7")
    print("^1ERROR^7: ^1Can NOT find "..jobResource.." ^7job ^1list^7, ^1possible error in that file or is it empty^7?")
    print("^1--------------------------------------------^7")
    cache.Jobs = {} -- Fallback to an empty table
end

-- Auto Detection of Inventory Weight -- **EXPERIMENTAL**
-- Forcefully load the the specified config file from inventory scripts
-- This allows to get information required for certain functions that need to detect how much space is left in a players inventory
-- This is born from too many tickets of me needing to explain that they need to change "InventoryWeight" to match their inv setting
local function getInventoryConfig(resource, data)
    if data.convars then
        return function(path)
            local key = path[1]
            local convar = key == "MaxWeight" and data.convars.weight or key == "MaxSlots" and data.convars.slots
            return convar and GetConvarInt(convar.key, convar.default) or nil, "Unsupported convar path: " .. table.concat(path, ".")
        end
    end

    local content = LoadResourceFile(resource, data.file)
    if not content then return nil, "Failed to load file" end

    local env = {
        GetConvar = GetConvar,
        vector3 = vector3,
        vector4 = vector4,
        Citizen = Citizen,
        GetResourceState = GetResourceState,
        exports = exports,
        DependencyCheck = function() return nil end,
    }

    local fn, err = load(content, '@'..data.file, 't', env)
    --local success, err = xpcall(fn, function(e)
    --    print(debug.traceback("Error while executing qs-inventory config:\n" .. tostring(e), 2))
    --end)
    if not fn then return nil, "Failed to compile config: " .. err end
    if not pcall(fn) then return nil, "Error executing config file" end

    local cfg = env.Config or env.config
    if not cfg then return nil, "Config table not found" end

    return function(path)
        local ref = cfg
        for _, k in ipairs(path) do
            if type(ref) ~= "table" then return nil, "Path invalid at: " .. tostring(k) end
            ref = ref[k]
        end
        return ref
    end
end

-- Inventory table
local invWeightTable = {
    [Exports.OXInv] = { convars = {
        weight = { key = "inventory:weight", default = 30000 },
        slots  = { key = "inventory:slots",  default = 40 }
    }},
    [Exports.QBInv] = {
        fallback = {
            { file = "config.lua",              path = { "MaxInventoryWeight" }, slotPath = { "MaxInventorySlots" } }, -- old version
            { file = "config/config.lua",       path = { "MaxWeight" },       slotPath = { "MaxSlots" } },       -- new version
        }
    },
    [Exports.JPRInv] =      { file = "configs/main_config.lua", path = { "MaxInventoryWeight" }, slotPath = { "MaxInventorySlots" } },
    [Exports.PSInv] =       { file = "config.lua",              path = { "MaxInventoryWeight" }, slotPath = { "MaxInventorySlots" } },
    [Exports.QSInv] =       { file = "config/config.lua",       path = { "InventoryWeight", "weight" }, slotPath = { "InventoryWeight", "slots" } },
    [Exports.TgiannInv] =   { file = "configs/config.lua",      path = { "slotsMaxWeights", "player", "maxWeight" }, slotPath = { "slotsMaxWeights", "player", "slots" } },
    [Exports.CodeMInv] =    { file = "config/config.lua",       path = { "MaxWeight" }, slotPath = { "MaxSlots" } },
    [Exports.RSGInv] =      { file = "config/config.lua",       path = { "MaxWeight" }, slotPath = { "MaxSlots" } },
    --[Exports.OrigenInv] = { file = "config.lua", path = { "MaxWeight" } },
}

-- Run config detection
local invResource = ""
for script, data in pairs(invWeightTable) do
    if checkExists(script) then
        if script == Exports.QBInv and GetResourceState(Exports.JPRInv):find("start") then goto skip end

        while GetResourceState(script) ~= "started" and GetResourceState(script) ~= "stopped" do
            Wait(100)
            print("Waiting for script start")
        end
        local attempts = data.fallback or { data }
        local lookup, used, err

        for _, option in ipairs(attempts) do
            local try, e = getInventoryConfig(script, option)
            if try then
                lookup = try
                used = option
                break
            end
            err = e
        end

        if not lookup then
            print(("^1ERROR^7: ^1Config loader failed from ^5%s^7: ^1%s^7"):format(script, err or "unknown"))
            break
        end

        local function resolve(label, path)
            local val, perr = lookup(path)
            if val then
                cache["Inventory"..label] = val
                return
            end
            local warnType = label == "Weight" and "^1ERROR" or "^3WARNING"
            print(("%s^7: ^1Failed to get ^7Inventory%s ^1from ^5%s^7: ^1%s^7"):format(warnType, label, script, perr or "unknown"))
        end

        resolve("Weight", used.path or { "MaxWeight" })
        resolve("Slots",  used.slotPath or { "MaxSlots" })

        invResource = script:gsub("-", "^7-^4"):gsub("_", "^7_^4")
        break
    end
    ::skip::
end
endTimer("InvWeight")
endTimer("InvSlots")

CreateThread(function()
    local counts = {
        Items = 0, Vehicles = 0, Jobs = 0, Gangs = 0,
    }
    for k, v in pairs(cache) do
        if type(v) ~= "number" then for count in pairs(v) do counts[k] += 1 end end
    end
    if cache.InventoryWeight then
        print("^6FrameWorkCache^7: ^4"..invResource.."^2 InventoryWeight^7: ^3"..cache.InventoryWeight.."^7 (^3"..(cache.InventoryWeight / 1000).."kg^7) ^7"..timers["InvWeight"])
    end
    if cache.InventorySlots then
        print("^6FrameWorkCache^7: ^4"..invResource.."^2 InventorySlots^7: ^3"..cache.InventorySlots.." ^7"..timers["InvSlots"])
    end
    print("^6FrameworkCache^7: ^4"..itemResource:gsub("-", "^7-^4"):gsub("_", "^7_^4").."^2 Loaded ^3"..tostring(counts.Items).."^2 Items ^7"..timers["Items"])
    print("^6FrameworkCache^7: ^4"..vehResource:gsub("-", "^7-^4"):gsub("_", "^7_^4").."^2 Loaded ^3"..tostring(counts.Vehicles).."^2 Vehicles ^7"..timers["Vehicles"])
    print("^6FrameworkCache^7: ^4"..jobResource:gsub("-", "^7-^4"):gsub("_", "^7_^4").."^2 Loaded ^3"..tostring(counts.Jobs).."^2 Jobs ^7"..timers["Jobs"])
    print("^6FrameworkCache^7: ^4"..jobResource:gsub("-", "^7-^4"):gsub("_", "^7_^4").."^2 Loaded ^3"..tostring(counts.Gangs).."^2 Gangs ^7"..timers["Jobs"])
    endTimer("Cache")
    print("^6FrameworkCache^7: ^2Cache Ready ^7"..timers["Cache"])
    cacheReady = true
end)

RegisterNetEvent("jim_bridge:requestCache", function()
    local src = source
    TriggerClientEvent("jim_bridge:receiveCache", src, cache)
end)

exports("GetSharedData", function()
    -- Wait indefinitely (with periodic checks) until cacheReady is true
    local timeout = GetGameTimer() + 20000  -- 20 second failsafe timeout
    while not cacheReady and GetGameTimer() < timeout do
        Wait(100)
    end

    if not cacheReady then
        print("^1ERROR^7: jim_bridge cache timed out waiting for data.")
        return nil  -- Signal clearly if cache never became ready
    end

    return cache
end)