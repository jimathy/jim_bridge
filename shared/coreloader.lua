-- Create empty Variables --
Items, Vehicles, Jobs, Gangs, Core, ESX = {}, nil, nil, nil, nil, nil

-- Correct QB inventory export (if needed) from 'qb-inventory' to 'ps-inventory' or 'lj-inventory' --
Exports.QBInv = (isStarted("ps-inventory") and "ps-inventory") or (isStarted("lj-inventory") and "lj-inventory") or Exports.QBInv

-- Create simple variables based on the corresponding framework exports --
OXLibExport, QBXExport, QBExport, ESXExport, OXCoreExport = Exports.OXLibExport or "", Exports.QBXExport or "", Exports.QBExport or "", Exports.ESXExport or "", Exports.OXCoreExport or ""

-- Create simple variables based on the corresponding inventory names --
OXInv, QBInv, PSInv, QSInv, CoreInv, CodeMInv, OrigenInv = Exports.OXInv or "", Exports.QBInv or "", Exports.PSInv or "", Exports.QSInv or "", Exports.CoreInv or "", Exports.CodeMInv or "", Exports.OrigenInv or ""

-- QB-Menu export name grabbed from exports.lua --
QBMenuExport = Exports.QBMenuExport or ""

-- Target exports based on what is loaded --
QBTargetExport, OXTargetExport = Exports.QBTargetExport or "", Exports.OXTargetExport or ""

-- If Debug mode is on in the loading script, print the list of found exports --
-- Some may "lie", 'ox_target' attempts to use 'qb-target' exports and this print will say its loaded (which is technically true) --
for _, v in pairs(Exports) do
    if isStarted(v) then debugPrint("^6Bridge^7: '^3"..v.."^7' ^2export found ^7") end
end

local itemResource, jobResource, vehResource = "", "", ""

-- Load item lists --
-- Complies the items from ox_inventory, qb-core or esx into 'Items' and loads them in a layout similar to qb-core's Shared items.lua --
-- For example this makes it so instead of QBCore.Shared.Items[item], you can load 'Item[item]' in the script --
if isStarted(OXInv) then
    itemResource = OXInv
    Items = exports[OXInv]:Items()
    for k, v in pairs(Items) do
        if v.client and v.client.image then
            Items[k].image = (v.client.image):gsub("nui://"..OXInv.."/web/images/", "")
        else
            Items[k].image = k..".png"
        end
        Items[k].hunger = v.client and v.client.hunger or nil
        Items[k].thirst = v.client and v.client.thirst or nil
    end

elseif isStarted(QBExport) then
    itemResource = QBExport
    Core = Core or exports[QBExport]:GetCoreObject()
    Items = Core and Core.Shared.Items or nil
    if isStarted(QBExport) and not isStarted(QBXExport) then
        RegisterNetEvent('QBCore:Client:UpdateObject', function()
            Core = Core or exports[QBExport]:GetCoreObject()
            Items = Core and Core.Shared.Items or nil
        end)
    end

elseif isStarted(ESXExport) then
    itemResource = ESXExport
    ESX = exports[ESXExport]:getSharedObject()
    --Items = ESX and ESX.Items or nil
    while ESX == nil do
        print("Waiting for ESX")
        Wait(0)
    end
    if isServer() then
        Items = ESX.GetItems()
        debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Items).." ^3Items^2 from ^7" .. itemResource)
    end
    CreateThread(function()
        while not ESX do Wait(0) end
        if isServer() then
            createCallback(getScript()..":getItems", function(source)
                return Items
            end)
        end
        if not isServer() then
            Items = triggerCallback(getScript()..":getItems")
            debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Items).." ^3Items^2 from ^7" .. itemResource)
        end
    end)


end
-- If it fails to load items, then it will print the error below --
-- If it loads them and debug is on, print how many items and where from --
if not isStarted(ESXExport) then
    if not Items then
        print("^4ERROR^7: ^2No Core Items detected ^7- ^2Check ^3exports^1.^2lua^7")
    else
        debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Items).." ^3Items^2 from ^7" .. itemResource)
    end
end

-- Load Vehicles --
-- Complies the vehicles from the detected frameworks into a table in the style of qb-cores shared vehicles.lua --
-- For example, instead of using QBCore.Shared.Vehicles[vehicle] you can load 'Vehicles[vehicle]' in the script --
if isStarted(QBXExport) or isStarted(QBExport) then
    Core = Core or exports[QBExport]:GetCoreObject()
    Vehicles = Core and Core.Shared.Vehicles
    if isStarted(QBExport) and not isStarted(QBXExport) then
        RegisterNetEvent('QBCore:Client:UpdateObject', function()
            Core = Core or exports[QBExport]:GetCoreObject()
            Vehicles = Core and Core.Shared.Vehicles
        end)
    end
    vehResource = QBExport
elseif isStarted(OXCoreExport) then
    Vehicles = {}
    for k, v in pairs(Ox.GetVehicleData()) do
        Vehicles[k] = { model = k, price = v.price, name = v.name, brand = v.make }
    end
    vehResource = OXCoreExport
elseif isStarted(ESXExport) then
    -- print("^6Bridge^7: ^2Loading ^3Vehicles^2 from ^7"..ESXExport)
    -- print("^6Bridge^7: ^2Loading ^6"..countTable(Vehicles).." ^3Vehicles^2 from ^7"..ESXExport)
    CreateThread(function()
        if isServer() then
            createCallback(getScript()..":getVehiclesPrices", function(source)
                Vehicles = MySQL.query.await('SELECT model, price, name FROM vehicles')
                vehResource = ESXExport
                return Vehicles
            end)
        end
        if not isServer() then
            local TempVehicles = triggerCallback(getScript()..":getVehiclesPrices")
            for _, v in pairs(TempVehicles) do
                Vehicles = Vehicles or {}
                Vehicles[v.model] = { model = v.model, price = v.price, name = v.name, brand = GetMakeNameFromVehicleModel(v.model):lower():gsub("^%l", string.upper) }
            end
        end
    end)
end
if vehResource == nil then
    print("^4ERROR^7: ^2No Vehicle info detected ^7- ^2Check ^3exports^1.^2lua^7")
else
    debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Vehicles).." ^3Vehicles^2 from ^7"..vehResource)
end

-- Load Jobs --
-- Attempts to load the details of jobs and gangs and compile into tables --
-- For example, instead of using QBCore.Shared.Jobs[job] you can load 'Jobs[job]' in the script --
if isStarted(QBXExport) then jobResource = QBXExport
    Core = Core or exports[QBExport]:GetCoreObject()
    Jobs, Gangs = exports[QBXExport]:GetJobs(), exports[QBXExport]:GetGangs()

elseif isStarted(OXCoreExport) then  jobResource = OXExport
    CreateThread(function()
        if isServer() then
            createCallback(getScript()..":getOxGroups", function(source)
                Jobs = MySQL.query.await('SELECT * FROM `ox_groups`') return Jobs
            end)
        else
            local TempJobs = triggerCallback(getScript()..":getOxGroups")
            Jobs = TempJobs or {}
            for k, v in pairs(TempJobs) do
                local grades = {}
                for i = 1, #v.grades do grades[i] = { name = v.grades[i], isboss = (i == #v.grades)} end
                Jobs[v.name] = { label = v.label, grades = grades }
            end
            Gangs = Jobs
        end
    end)

elseif isStarted(QBExport) then jobResource = QBExport
    Core = Core or exports[QBExport]:GetCoreObject()
    Jobs, Gangs = Core.Shared.Jobs, Core.Shared.Gangs
    if isStarted(QBExport) and not isStarted(QBXExport) then
        RegisterNetEvent('QBCore:Client:UpdateObject', function()
            Core = exports[QBExport]:GetCoreObject()
            Jobs, Gangs = Core.Shared.Jobs, Core.Shared.Gangs
        end)
    end

elseif isStarted(ESXExport) then
    --print("^6Bridge^7: ^2Loading ^3Jobs^7/^3Gangs^2 from ^7"..ESXExport)
    ESX = exports[ESXExport]:getSharedObject()
    if isServer() then
        Jobs = ESX.GetJobs()
        for k, v in pairs(Jobs) do
            local count = countTable(Jobs[k].grades)-1
            Jobs[k].grades[tostring(count)].isBoss = true
        end
        Gangs = Jobs
    end
    CreateThread(function()
        while not ESX do Wait(0) end
        if isServer() then
            createCallback(getScript()..":getJobs", function(source)
                return Jobs
            end)
        end
        if not isServer() then
            Jobs = triggerCallback(getScript()..":getJobs")
            Gangs = Jobs
        end
    end)
end
if not isStarted(ESXExport) and Jobs then
    debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Jobs).." ^3Jobs^2 from ^7"..jobResource, "^6Bridge^7: ^2Loading ^6"..countTable(Gangs).." ^3Gangs^2 from ^7"..jobResource)
end