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
    RSGInv = "rsg-inventory",

    VorpExport = "vorp_core",
    VorpInv = "vorp_inventory",
    VorpMenu = "vorp_menu",
}

-- Prevent reloading if cache is already initialized
local cache = { Items = {}, Vehicles = {}, Jobs = {}, Gangs = {}, }
local cacheReady = false

-- Timer info, for debugging more then anything
local timers = {}
local function startTimer(label)
    timers[label] = GetGameTimer()
end

local function endTimer(label)
    timers[label] = GetGameTimer() - (timers[label] or GetGameTimer())
    timers[label] = "("..(timers[label] / 1000).."s)"
end
startTimer("Cache") startTimer("Items") startTimer("Vehicles") startTimer("Jobs") startTimer("InvWeight") startTimer("InvSlots")

-- Helper functions --
local function checkExists(resourceName)
    local state = GetResourceState(resourceName)
    return state and (state:find("start") or state:find("stopped"))
end

local function waitStarted(resourceName)
    while GetResourceState(resourceName) ~= "started" do Wait(100) end
end

local function waitStartedOrStopped(resourceName)
    local state = GetResourceState(resourceName)
    while state ~= "started" and state ~= "stopped" do
        Wait(100)
        state = GetResourceState(resourceName)
    end
end

local function dupLowercaseWeapons(items)
    for k, v in pairs(items or {}) do
        if type(k) == "string" then
            if k:find("WEAPON") then
                items[k:lower()] = v
            end
        else
            print("^1ERROR^7: ^1Possible table inside a table, check your items.lua^7?")
            print("^1Possible Issue found^7:")
            print(json.encode(items[k], { indent = true }))
        end
    end
end

-- Forceload libs --

-- Ensure oxmysql resource is loaded for jim_bridge internally
-- For some core's it needs to get data from the database
if checkExists(Exports.OXCoreExport) or checkExists(Exports.ESXExport) or checkExists(Exports.VorpExport) then
    local fileLoader = assert(load(LoadResourceFile("oxmysql", ('lib/MySQL.lua')), ('@@oxmysql/lib/MySQL.lua')))
    fileLoader()
end

if checkExists(Exports.OXCoreExport) then
    -- Detected OX_Core in server, wait for it to be started if needed
    waitStartedOrStopped(Exports.OXCoreExport)
    local fileLoader = assert(load(LoadResourceFile(Exports.OXCoreExport, ('lib/init.lua')), ('@@'..Exports.OXCoreExport..'/lib/init.lua')))
    fileLoader()
end
if checkExists(Exports.ESXExport) then
    -- Detected ESX in server, wait for it to be started if needed
    waitStarted(Exports.ESXExport)
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

local itemFunc = {
    {   script = Exports.OXInv,
        cacheItem = function()
            local success, result = pcall(function()
                return exports[Exports.OXInv]:Items()
            end)
            if success and result then
                cache.Items = result
            end
        end,
    },
    {   script = Exports.TgiannInv,
        cacheItem = function()
            local success, result = pcall(function()
                return exports[Exports.TgiannInv]:Items()
            end)
            if success and result then
                cache.Items = result
            end
        end,
    },
    {   script = Exports.QBXExport,
        cacheItem = function()
            cache.Items = exports[Exports.QBExport]:GetCoreObject().Shared.Items
            -- If this is nil, they need to update to qbx_core 1.23.0+
            if not cache.Items then
                -- if their inventory doesn't allow that (they refuse to update their butchered core replacement):

                if GetResourceState(Exports.OrigenInv):find("start") then
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
        end,
    },
    {   script = Exports.QBExport,
        cacheItem = function()
            cache.Items = exports[Exports.QBExport]:GetCoreObject().Shared.Items
        end,
    },
    {   script = Exports.ESXExport,
        cacheItem = function()
            cache.Items = ESX.GetItems()
            while not next(cache.Items) do
                cache.Items = ESX.GetItems()
                Wait(1000)
            end
        end,
    },
    {   script = Exports.RSGExport,
        cacheItem = function()
            cache.Items = exports[Exports.RSGExport]:GetCoreObject().Shared.Items
        end,
    },
    {   script = Exports.VorpInv,
        cacheItem = function()
            local dbItems = MySQL.query.await('SELECT * FROM `items`')
            local tempItems = {}
            for i = 1, #dbItems do
                local v = dbItems[i]
                tempItems[v.item] = {
                    name = v.item,
                    label = v.label,
                    weight = v.weight,
                    info = v.metadata,
                    usable = v.usable,
                    type = v.type,
                    description = v.desc,
                }
            end
            cache.Items = tempItems
        end,
    },
}

for i = 1, #itemFunc do
    local data = itemFunc[i]
    if checkExists(data.script) then
        waitStarted(data.script)            -- Wait for detected script to start fully
        data.cacheItem()                    -- run tablized function for core/inv
        dupLowercaseWeapons(cache.Items)    -- make usable weapon item names for jim_bridge
        itemResource = data.script          -- Grab script name to announce later
        endTimer("Items")                   -- end timer
        break                               -- break loop so it doesn't keep checking
    end
end

---------------------
--- Load Vehicles ---
---------------------
---
local vehicleFunc = {

    {   script = Exports.QBXExport,
        cacheVehicle = function()
            cache.Vehicles = exports[Exports.QBExport]:GetCoreObject().Shared.Vehicles
        end,
    },
    {   script = Exports.QBExport,
        cacheVehicle = function()
            cache.Vehicles = exports[Exports.QBExport]:GetCoreObject().Shared.Vehicles
        end,
    },
    {   script = Exports.OXCoreExport,
        cacheVehicle = function()
            cache.Vehicles = {}
            for k, v in pairs(Ox.GetVehicleData()) do
                cache.Vehicles[k] = {
                    model = k, hash = joaat(k),
                    price = v.price,
                    name = v.name,
                    brand = v.make
                }
            end
        end,
    },
    {   script = Exports.ESXExport,
        cacheVehicle = function()
            while not MySQL do Wait(100) end
            for _, v in pairs(MySQL.query.await('SELECT model, price, name FROM vehicles')) do
                cache.Vehicles[v.model] = {
                    model = v.model,
                    hash = joaat(v.model),
                    price = v.price,
                    name = v.name,
                }
            end
        end,
    },
    {   script = Exports.RSGExport,
        cacheVehicle = function()
            cache.Vehicles = exports[Exports.RSGExport]:GetCoreObject().Shared.Vehicles
        end,
    },
    {   script = Exports.VorpExport,
        cacheVehicle = function()
            cache.Vehicles = { ["unkown"] = {} }
        end,
    },
}

for i = 1, #vehicleFunc do
    local data = vehicleFunc[i]
    if checkExists(data.script) then
        waitStarted(data.script)            -- Wait for detected script to start fully
        data.cacheVehicle()                    -- run tablized function for core
        vehResource = data.script          -- Grab script name to announce later
        endTimer("Vehicles")                   -- end timer
        break                               -- break loop so it doesn't keep checking
    end
end

---------------------
----- Load Jobs -----
---------------------

local jobFunc = {

    {   script = Exports.QBXExport,
        cacheJob = function()
            cache.Jobs, cache.Gangs = exports[Exports.QBXExport]:GetJobs(), exports[Exports.QBXExport]:GetGangs()
        end,
    },
    {   script = Exports.QBExport,
        cacheJob = function()
            Core = exports[Exports.QBExport]:GetCoreObject()
            cache.Jobs, cache.Gangs = Core.Shared.Jobs, Core.Shared.Gangs
        end,
    },
    {   script = Exports.OXCoreExport,
        cacheJob = function()
            while not MySQL do Wait(100) end
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
        end,
    },
    {   script = Exports.ESXExport,
        cacheJob = function()
            ESX = ESX or exports[Exports.ESXExport]:getSharedObject()
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
        end,
    },
    {   script = Exports.RSGExport,
        cacheJob = function()
            Core = exports[Exports.RSGExport]:GetCoreObject()
            cache.Jobs, cache.Gangs = Core.Shared.Jobs, Core.Shared.Gangs
        end,
    },
    {   script = Exports.VorpExport,
        cacheJob = function()
            cache.Jobs = { ["unkown"] = {} }
            cache.Gangs = cache.Jobs
        end,
    },
}

for i = 1, #jobFunc do
    local data = jobFunc[i]
    if checkExists(data.script) then
        waitStarted(data.script)            -- Wait for detected script to start fully
        data.cacheJob()                    -- run tablized function for core
        jobResource = data.script          -- Grab script name to announce later
        endTimer("Jobs")                   -- end timer
        break                               -- break loop so it doesn't keep checking
    end
end


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

        waitStartedOrStopped(script)

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