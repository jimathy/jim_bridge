Items, Vehicles, Jobs, Gangs, Core, ESX = {}, nil, nil, nil, nil, nil

OXLibExport = Exports and Exports.OXLibExport or ""

QBXExport = Exports and Exports.QBXExport or ""
QBExport = Exports and Exports.QBExport or ""
ESXExport = Exports and Exports.ESXExport or ""
OXCoreExport = Exports and Exports.OXCoreExport or ""

OXInv = Exports and Exports.OXInv or ""
QBInv = Exports and Exports.QBInv or ""
QSInv = Exports and Exports.QSInv or ""
CoreInv = Exports and Exports.CoreInv or ""
CodeMInv = Exports and Exports.CodeMInv or ""

QBMenuExport = Exports and Exports.QBMenuExport or ""

QBTargetExport = Exports and Exports.QBTargetExport or ""
OXTargetExport = Exports and Exports.OXTargetExport or ""

function CheckBridgeVersion()
	if IsDuplicityVersion() then
        local currentVersion = "^3"..GetResourceMetadata("jim_bridge", 'version'):gsub("%.", "^7.^3").."^7"
        PerformHttpRequest('https://raw.githubusercontent.com/jimathy/jim_bridge/master/version.txt', function(err, newestVersion, headers)
            if not newestVersion then print("^1Currently unable to run a version check for ^7'^3jim_bridge^7' ("..currentVersion.."^7)") return end
            newestVersion = "^3"..newestVersion:sub(1, -2):gsub("%.", "^7.^3").."^7"
            print(newestVersion == currentVersion and "^7'^3jim_bridge^7' - ^6You are running the latest version.^7 ("..currentVersion..")" or "^7'^3jim_bridge^7' - ^1You are currently running an outdated version^7, ^1please update^7!")
		end)
	end
end
CheckBridgeVersion()

for k, v in pairs(Exports) do
    if GetResourceState(v):find("start") then print("^6Bridge^7: '^3"..v.."^7' ^2export found ^7") end
end

-- Load item lists
if GetResourceState(OXInv):find("start") then
    print("^6Bridge^7: ^2Loading ^3Items^2 from ^7"..OXInv)
    Items = exports[OXInv]:Items()
    for k, v in pairs(Items) do
        if v.client then
            if v.client.image then Items[k].image = (Items[k].client.image):gsub("nui://"..OXInv.."/web/images/","")
            else Items[k].image = k..".png" end
            if v.client.hunger then Items[k].hunger = v.client.hunger end
            if v.client.thirst then Items[k].thirst = v.client.thirst end
        end
    end
elseif GetResourceState(QBExport):find("start") then
    print("^6Bridge^7: ^2Loading ^3Items^2 from ^7"..QBExport)
    Core = Core or exports[QBExport]:GetCoreObject()
    Items = Core.Shared.Items
elseif GetResourceState(ESXExport):find("start") then
    print("^6Bridge^7: ^2Loading ^3Items^2 from ^7"..ESXExport)
    ESX = exports[ESXExport]:getSharedObject()
    Items = ESX.Items
else
    print("^4ERROR^7: ^2No Core Items detected ^7- ^2Check ^3exports^1.^2lua^7")
end

-- Load Vehicles
if GetResourceState(QBXExport):find("start") then
    Core = Core or exports[QBXExport]:GetCoreObject()
    print("^6Bridge^7: ^2Loading ^3Vehicles^2 from ^7"..QBXExport)
    Vehicles = exports[QBXExport]:GetVehiclesByHash()
elseif GetResourceState(QBExport):find("start") then
    print("^6Bridge^7: ^2Loading ^3Vehicles^2 from ^7"..QBExport)
    Core = Core or exports[QBExport]:GetCoreObject()
    RegisterNetEvent('QBCore:Client:UpdateObject', function()
        Core = Core or exports[QBExport]:GetCoreObject()
    end)
    Vehicles = Core.Shared.Vehicles
elseif GetResourceState(OXCoreExport):find("start") then
    print("^6Bridge^7: ^2Loading ^3Vehicles^2 from ^7"..OXCoreExport)
    for k, v in pairs(Ox.GetVehicleData()) do
        Vehicles = Vehicles or {}
        Vehicles[k] = { model = k, price = v.price, name = v.name, brand = v.make }
    end
elseif GetResourceState(ESXExport):find("start") then
    print("^6Bridge^7: ^2Loading ^3Vehicles^2 from ^7"..ESXExport)
    CreateThread(function()
        if IsDuplicityVersion() then
            createCallback(GetCurrentResourceName()..":getVehiclesPrices", function(source)
                Vehicles = MySQL.query.await('SELECT model, price, name FROM vehicles')
                return Vehicles
            end)
        end
        if not IsDuplicityVersion() then
            local TempVehicles = triggerCallback(GetCurrentResourceName()..":getVehiclesPrices")
            for _, v in pairs(TempVehicles) do
                Vehicles = Vehicles or {}
                Vehicles[v.model] = { model = v.model, price = v.price, name = v.name, brand = GetMakeNameFromVehicleModel(v.model):lower():gsub("^%l", string.upper) }
            end
        end
    end)
else
    print("^4ERROR^7: ^2No Vehicle info detected ^7- ^2Check ^3exports^1.^2lua^7")
end

-- Load Jobs
if GetResourceState(QBXExport):find("start") then
    Core = Core or exports[QBExport]:GetCoreObject()
    print("^6Bridge^7: ^2Loading ^3Jobs^7/^3Gangs^2 from ^7"..QBXExport)
    Jobs = exports[QBXExport]:GetJobs()
    Gangs = exports[QBXExport]:GetGangs()

elseif GetResourceState(OXCoreExport):find("start") then
    print("^6Bridge^7: ^2Loading ^3Jobs^7/^3Gangs^2 from ^7"..OXCoreExport)
    CreateThread(function()
        if IsDuplicityVersion() then
            createCallback(GetCurrentResourceName()..":getOxGroups", function(source)
                Jobs = MySQL.query.await('SELECT * FROM `ox_groups`')
                return Jobs
            end)
        else
            local TempJobs = triggerCallback(GetCurrentResourceName()..":getOxGroups")
            for k, v in pairs(TempJobs) do
                local grades = {}
                for i = 1, #v.grades do grades[i] = { name = grades[i], isboss = (i == #v.grades)} end
                Jobs = Jobs or {}
                Jobs[v.name] = { label = v.label, grades = grades, }
            end
        end
    end)

elseif GetResourceState(QBExport):find("start") then
    print("^6Bridge^7: ^2Loading ^3Jobs^7/^3Gangs^2 from ^7"..QBExport)
    Core = Core or Core or exports[QBExport]:GetCoreObject()
    RegisterNetEvent('QBCore:Client:UpdateObject', function() Core = Core or exports[QBExport]:GetCoreObject() end)
    Jobs = Core.Shared.Jobs
    Gangs = Core.Shared.Gangs

elseif GetResourceState(ESXExport):find("start") then
    print("^6Bridge^7: ^2Loading ^3Jobs^7/^3Gangs^2 from ^7"..ESXExport)
    ESX = exports[ESXExport]:getSharedObject()
    if IsDuplicityVersion() then
        Jobs = ESX.GetJobs()
        for k, v in pairs(Jobs) do
            local count = countTable(Jobs[k].grades)-1
            Jobs[k].grades[tostring(count)].isBoss = true
        end
        Gangs = Jobs
    end
    CreateThread(function()
        while not ESX do Wait(0) end
        if IsDuplicityVersion() then
            createCallback(GetCurrentResourceName()..":getJobs", function(source)
                return Jobs
            end)
        end
        if not IsDuplicityVersion() then
            Jobs = triggerCallback(GetCurrentResourceName()..":getJobs")
            Gangs = Jobs
        end
    end)
else
    print("^4ERROR^7: ^2No Job/Gang ifo detected ^7- ^2Check ^3exports^1.^2lua^7")
end

function makeBossRoles(role)
	local boss = {}
	if Jobs and Jobs[role] then
		for grade in pairs(Jobs[role].grades) do
			if Jobs[role].grades[grade].isboss then
				if boss[role] then
					if boss[role] > tonumber(grade) then boss[role] = tonumber(grade) end
				else boss[role] = tonumber(grade) end
			end
		end
	elseif Gangs and Gangs[role] then
		for grade in pairs(Gangs[role].grades) do
			if Gangs[role].grades[grade].isboss then
				if boss[role] then
					if boss[role] > tonumber(grade) then boss[role] = tonumber(grade) end
				else boss[role] = tonumber(grade) end
			end
		end
	end
    return boss
end

function createPoly(data) local Location = nil
    if GetResourceState(OXLibExport):find("start") then -- if it finds ox_lib, use it instead of PolyZone
        if Config.System.Debug then print("^6Bridge^7: ^2Creating new poly with ^7 "..OXLibExport.." "..data.name) end
        for i = 1, #data.points do
            data.points[i] = vec3(data.points[i].x, data.points[i].y, 12.0)
        end
        data.thickness = 1000
        Location = lib.zones.poly(data)
    elseif GetResourceState("PolyZone"):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Creating new poly with ^7PolyZone "..data.name) end
        Location = PolyZone:Create(data.points, { name = data.name, debugPoly = data.debug })
        Location:onPlayerInOut(function(isPointInside)
            if isPointInside then
                data.onEnter()
            else
                data.onExit()
            end
        end)
    else
        print("^4ERROR^7: ^2No PolyZone creation script detected ^7- ^2Check ^3exports^1.^2lua^7")
    end
end

function createCirclePoly(data) local Location = nil
    if GetResourceState(OXLibExport):find("start") then -- if it finds ox_lib, use it instead of PolyZone
        if Config.System.Debug then print("^6Bridge^7: ^2Creating new ^3Cricle^2 poly with ^7"..OXLibExport.." "..data.name) end
		Location = lib.zones.sphere(data)
    elseif GetResourceState("PolyZone"):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Creating new ^3Cricle^2 poly with ^7PolyZone ".. data.name) end
		Location = CircleZone:Create(data.coords, data.radius, { name = data.name, debugPoly = Config.System.Debug})
		Location:onPlayerInOut(function(isPointInside)
			if isPointInside then
                data.onEnter()
            else
                data.onExit()
            end
        end)
    else
        print("^4ERROR^7: ^2No PolyZone creation script detected ^7- ^2Check ^3exports^1.^2lua^7")
    end
end

function openMenu(Menu, data)
    if Config.System.Menu == "ox" then
        if data.onBack then
            table.insert(Menu, 1, { icon = "fas fa-circle-arrow-left",
                title = "Return",
                onSelect = data.onBack,
            })
        end
        for k in pairs(Menu) do
            if not Menu[k].title then
                if Menu[k].header ~= nil and Menu[k].header ~= "" then
                    Menu[k].title = Menu[k].header
                    if Menu[k].txt then Menu[k].description = Menu[k].txt else Menu[k].description = "" end
                else
                    Menu[k].title = Menu[k].txt
                end
            end
            if Menu[k].params then
                Menu[k].event = Menu[k].params.event
                Menu[k].args = Menu[k].params.args or {}
            end
            if Menu[k].isMenuHeader then
                Menu[k].disabled = true
            end
        end
        lib.registerContext({id = 'Menu', title = data.header..br..br..(data.headertxt and data.headertxt or ""), position = 'top-right', options = Menu, canClose = data.canClose and data.canClose or nil, onExit = data.onExit and data.onExit or nil, })
        lib.showContext("Menu")
    elseif Config.System.Menu == "qb" then
        if data.onBack then
            table.insert(Menu, 1, { icon = "fas fa-circle-arrow-left",
                header = " ", txt = "Return",
                params = {
                    isAction = true,
                    event = data.onBack,
                }
            })
        elseif data.canClose then
            table.insert(Menu, 1, { icon = "fas fa-circle-xmark",
                header = " ", txt = "Close",
                params = {
                    isAction = true,
                    event = data.onExit and data.onExit or (function() exports[QBMenuExport]:closeMenu() end),
                }
            })
        end
        if data.header ~= nil then
            local tempMenu = {}
            for k, v in pairs(Menu) do tempMenu[k+1] = v end
            tempMenu[1] = { header = data.header, txt = data.headertxt and data.headertxt or "", isMenuHeader = true }
            Menu = tempMenu
        end
        for k in pairs(Menu) do
            if Menu[k].onSelect then
                Menu[k].params = {
                    isAction = true,
                    event = Menu[k].onSelect,
                }
            end
            if not Menu[k].header then Menu[k].header = " " end
            if Menu[k].arrow then Menu[k].icon = "fas fa-angle-right" end
        end
        exports[QBMenuExport]:openMenu(Menu)
    elseif Config.System.Menu == "gta" then
        WarMenu.CreateMenu(tostring(Menu),
            data.header,
            data.headertxt or " ",
            {   titleColor = { 222, 255, 255 },
                maxOptionCountOnScreen = 15,
                width = 0.25,
                x = 0.7,
            })
        if WarMenu.IsAnyMenuOpened() then return end
        WarMenu.OpenMenu(tostring(Menu))
        CreateThread(function()
            local close = true
            while true do
                if WarMenu.Begin(tostring(Menu)) then
                    if data.onBack then
                        if WarMenu.SpriteButton("Return", 'commonmenu', "arrowleft", 127, 127, 127) then
                            WarMenu.CloseMenu()
                            Wait(10)
                            data.onBack()
                        end
                    end
                    for k in pairs(Menu) do
                        local pressed = WarMenu.Button(Menu[k].header)
                        if not Menu[k].header then
                            Menu[k].header = Menu[k].txt
                            Menu[k].txt = nil
                        end
                        if Menu[k].txt and Menu[k].txt ~= "" and WarMenu.IsItemHovered() then
                            if Menu[k].disabled or Menu[k].isMenuHeader then
                                WarMenu.ToolTip("~r~"..Menu[k].txt, 0.18, true)
                            else
                                WarMenu.ToolTip(
                                    (Menu[k].blip and "~BLIP_".."8".."~ " or "")..
                                    Menu[k].txt:gsub("%:", ":~g~"):gsub("%\n", "\n~s~"), 0.18,
                                    true)
                            end
                        end
                        if pressed and not Menu[k].isMenuHeader then
                            WarMenu.CloseMenu()
                            close = false
                            Menu[k].onSelect()
                        end
                    end
                    WarMenu.End()
                else
                    return
                end
                if not WarMenu.IsAnyMenuOpened() and close then
                    stopTempCam(cam)
                    if data.onExit then data.onExit() end
                end
                Wait(0)
            end
        end)
    elseif Config.System.Menu == "esx" then -- can't display more than one line - BIG problem for crafting menus mainly
        for k in pairs(Menu) do
            Menu[k].label = Menu[k].header
            Menu[k].name = "button"..k
        end
        if data.canClose then
            table.insert(Menu, 1, {
                icon = "fas fa-circle-xmark",
                label = "Close",
                name = "close",
                onSelect = data.onExit
            })
        end
        if data.onBack then
            table.insert(Menu, 1, {
                icon = "fas fa-circle-arrow-left",
                label = "Return",
                name = "return",
                onSelect = data.onback
            })
        end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "Example_Menu", {
            title = data.header,
            align = 'top-right',
            elements = Menu
        },
        function(menuData, menu) -- OnSelect Function
            for k in pairs(Menu) do
                if menuData.current.name == Menu[k].name then
                    menu.close()
                    Wait(10)
                    Menu[k].onSelect()
                end
            end
        end,
        function(data, menu)
            menu.close() -- close menu
        end)
    end
end

br = (Config.System.Menu == "ox" or Config.System.Menu == "gta") and "\n" or "<br>"

function isOx() return (Config.System.Menu == "ox" or Config.System.Menu == "gta") end

function isWarMenuOpen() if Config.System.Menu == "gta" then return WarMenu.IsAnyMenuOpened() else return false end end

local TextTargets = {}
local Keys = {
    [322] = "ESC", [288] = "F1", [289] = "F2", [170] = "F3", [166] = "F5",
    [167] = "F6", [168] = "F7", [169] = "F8", [56] = "F9", [57] = "F10",
    [243] = "~", [157] = "1", [158] = "2", [160] = "3", [164] = "4",  [165] = "5", [159] = "6", [161] = "7", [162] = "8", [163] = "9", [84] = "-", [83] = "=",  [177] = "BACKSPACE", [37] = "TAB",
    [44] = "Q", [32] = "W", [38] = "E", [45] = "R", [245] = "T", [246] = "Y", [303] = "U", [199] = "P",
    [39] = "[",  [40] = "]", [18] = "ENTER", [137] = "CAPS",
    [34] = "A", [8] = "S", [9] = "D", [23] = "F", [47] = "G",
    [74] = "H", [311] = "K", [182] = "L", [21] = "LEFTSHIFT",
    [20] = "Z", [73] = "X", [26] = "C", [0] = "V",  [29] = "B", [249] = "N",
    [244] = "M", [82] = ",", [81] = "."
}
-- Targets --
local targetEntities = {}
function createEntityTarget(entity, opts, dist)
    targetEntities[#targetEntities+1] = entity
    if GetResourceState(OXTargetExport):find("start") then
        if Config.System.Debug then
            print("^6Bridge^7: ^2Creating new ^3Entity^2 target with ^6"..OXTargetExport.." ^7"..entity)
        end
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].action,
                canInteract = function(_, distance)
                    return distance < dist and true or false
                end
            }
        end
        exports[OXTargetExport]:addLocalEntity(entity, options)
    elseif GetResourceState(QBTargetExport):find("start") then
        if Config.System.Debug then
            print("^6Bridge^7: ^2Creating new ^3Entity^2 target with ^6"..QBTargetExport.." ^7"..entity)
        end
        local options = { options = opts, distance = dist }
        exports[QBTargetExport]:AddTargetEntity(entity, options)
    else
        local tempText = ""
        local keyTable = { 38, 29, 303, }
        for i = 1, #opts do
            opts[i].key = keyTable[i]
            tempText = tempText.."~b~["..Keys[opts[i].key].."] ~w~"..opts[i].label.." "
        end
        TextTargets[entity] = { coords = GetEntityCoords(entity), buttontext = tempText, options = opts, dist = dist }
    end
end

local boxTargets = {}
function createBoxTarget(data, opts, dist)
    if GetResourceState(OXTargetExport):find("start") then
        if Config.System.Debug then
            print("^6Bridge^7: ^2Creating new ^3Box^2 target with ^6"..OXTargetExport.." ^7"..data[1])
        end
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].onSelect or opts[i].action,
                canInteract = function(_, distance)
                    return distance < dist and true or false
                end
            }
        end
        if not data[5].useZ then
            local z = data[2].z + math.abs(data[5].maxZ - data[5].minZ) / 2
            data[2] = vec3(data[2].x, data[2].y, z)
        end
        local target = exports[OXTargetExport]:addBoxZone({
            coords = data[2],
            size = vec3(data[4], data[3], (data[5].useZ or not data[5].maxZ) and data[2].z or math.abs(data[5].maxZ - data[5].minZ)),
            rotation = data[5].heading,
            debug = data[5].debugPoly,
            options = options
        })
        boxTargets[#boxTargets+1] = target
        return target
    elseif GetResourceState(QBTargetExport):find("start") then
        if Config.System.Debug then
            print("^6Bridge^7: ^2Creating new ^3Box^2 target with ^6"..QBTargetExport.." ^7"..data[1])
        end
        local options = { options = opts, distance = dist }
        local target = exports[QBTargetExport]:AddBoxZone(data[1], data[2], data[3], data[4], data[5], options)
        boxTargets[#boxTargets+1] = target
        return target
    else
        local tempText = ""
        local keyTable = { 38, 29, 303, }
        for i = 1, #opts do
            opts[i].key = keyTable[i]
            tempText = tempText.."~b~["..Keys[opts[i].key].."] ~w~"..opts[i].label.." "
        end
        TextTargets[data[1]] = { coords = data[2], buttontext = tempText, options = opts, dist = dist }
        return data[1]
    end
end

local circleTargets = {}
function createCircleTarget(data, opts, dist)
    if GetResourceState(OXTargetExport):find("start") then
        if Config.System.Debug then
            print("^6Bridge^7: ^2Creating new ^3Sphere^2 target with ^6"..OXTargetExport.." ^7"..data[1])
        end
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].onSelect or opts[i].action,
                canInteract = function(_, distance)
                    return distance < dist and true or false
                end
            }
        end
        local target = exports[OXTargetExport]:addSphereZone({
            coords = data[2],
            radius = data[3],
            debug = data[4].debugPoly,
            options = options
        })
        circleTargets[#circleTargets+1] = target
        return target
    elseif GetResourceState(QBTargetExport):find("start") then
        if Config.System.Debug then
            print("^6Bridge^7: ^2Creating new ^3Circle^2 target with ^6"..QBTargetExport.." ^7"..data[1])
        end
        local options = { options = opts, distance = dist }

        local target = exports[QBTargetExport]:AddCircleZone(data[1], data[2], data[3], data[4], options)

        circleTargets[#circleTargets+1] = target
        return target
    else
        local tempText = ""
        local keyTable = { 38, 29, 303, }
        for i = 1, #opts do
            opts[i].key = keyTable[i]
            tempText = tempText.."~b~["..Keys[opts[i].key].."] ~w~"..opts[i].label.." "
        end
        TextTargets[data[1]] = { coords = data[2], buttontext = tempText, options = opts, dist = dist }
        return data[1]
    end
end

function removeEntityTarget(entity)
    if GetResourceState(QBTargetExport):find("start") then exports[QBTargetExport]:RemoveTargetEntity(entity) end
    if GetResourceState(OXTargetExport):find("start") then exports[OXTargetExport]:removeLocalEntity(entity, nil) end
    if not GetResourceState(OXTargetExport):find("start") and not GetResourceState(QBTargetExport):find("start") then
        TextTargets[entity] = nil
    end
end

function removeZoneTarget(target)
    if GetResourceState(QBTargetExport):find("start") then exports[QBTargetExport]:RemoveZone(target) end
    if GetResourceState(OXTargetExport):find("start") then exports[OXTargetExport]:removeZone(target, true) end
    if not GetResourceState(OXTargetExport):find("start") and not GetResourceState(QBTargetExport):find("start") then
        TextTargets[target] = nil
    end
end

if not GetResourceState(OXTargetExport):find("start") and not GetResourceState(QBTargetExport):find("start") and not IsDuplicityVersion() then
    CreateThread(function()
        while true do
            local pedCoords = GetEntityCoords(PlayerPedId())
            for k, v in pairs (TextTargets) do
                if #(pedCoords - v.coords) <= v.dist then
                    DrawText3D(
                        v.coords.x,
                        v.coords.y,
                        v.coords.z + 1.0,
                        v.buttontext
                    )
                    for i = 1, #v.options do
                        if IsControlJustPressed(0, v.options[i].key) then
                            if  v.options[i].onSelect then  v.options[i].onSelect() end
                            if  v.options[i].action then  v.options[i].action() end
                        end
                    end
                end
            end
            Wait(0)
        end
    end)
end

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for i = 1, #targetEntities do
        if GetResourceState(OXTargetExport):find("start") then exports[OXTargetExport]:removeLocalEntity(targetEntities[i], nil)
        elseif GetResourceState(QBTargetExport):find("start") then exports[QBTargetExport]:RemoveTargetEntity(targetEntities[i]) end
    end
    for i = 1, #boxTargets do
        if GetResourceState(OXTargetExport):find("start") then exports[OXTargetExport]:removeZone(boxTargets[i], true)
        elseif GetResourceState(QBTargetExport):find("start") then exports[QBTargetExport]:RemoveZone(boxTargets[i].name) end
    end
    for i = 1, #circleTargets do
        if GetResourceState(OXTargetExport):find("start") then exports[OXTargetExport]:removeZone(circleTargets[i], true)
        elseif GetResourceState(QBTargetExport):find("start") then exports[QBTargetExport]:RemoveZone(circleTargets[i].name) end
    end
end)

-- NOTIFICATIONS --
function triggerNotify(title, message, type, src)
	if Config.System.Notify == "okok" then
		if not src then TriggerEvent('okokNotify:Alert', title, message, 6000, type)
		else TriggerClientEvent('okokNotify:Alert', src, title, message, 6000, type) end
	elseif Config.System.Notify == "qb" then
		if not src then	TriggerEvent("QBCore:Notify", message, type)
		else TriggerClientEvent("QBCore:Notify", src, message, type) end
	elseif Config.System.Notify == "ox" then
		if not src then TriggerEvent('ox_lib:notify', {title = title, description = message, type = type or "success"})
		else TriggerClientEvent('ox_lib:notify', src, { type = type or "success", title = title, description = message }) end
	elseif Config.System.Notify == "gta" then
		if not src then TriggerEvent(GetCurrentResourceName()..":DisplayGTANotify", title, message)
		else TriggerClientEvent(GetCurrentResourceName()..":DisplayGTANotify", src, title, message) end
    elseif Config.System.Notify == "esx" then
		if not src then exports["esx_notify"]:Notify(type, 4000, message)
		else TriggerClientEvent(GetCurrentResourceName()..":DisplayESXNotify", src, type, title, message) end
	end
end

RegisterNetEvent(GetCurrentResourceName()..":DisplayESXNotify", function(type, title, text)
    exports["esx_notify"]:Notify(type, 4000, message)
end)

RegisterNetEvent(GetCurrentResourceName()..":DisplayGTANotify", function(title, text) local iconTable = {}
    if GetCurrentResourceName() == "jim-npcservice" then
        iconTable = {
            [Loc[Config.Lan].notify["taxiname"]] = "CHAR_TAXI",
            [Loc[Config.Lan].notify["limoname"]] = "CHAR_CASINO",
            [Loc[Config.Lan].notify["ambiname"]] = "CHAR_CALL911",
            [Loc[Config.Lan].notify["pilotname"]] = "CHAR_DEFAULT",
            [Loc[Config.Lan].notify["planename"]] = "CHAR_BOATSITE2",
            [Loc[Config.Lan].notify["heliname"]] = "CHAR_BOATSITE2",
        }
    end
	BeginTextCommandThefeedPost("STRING")
	AddTextComponentSubstringKeyboardDisplay(text)
	EndTextCommandThefeedPostMessagetext(iconTable[title] or "CHAR_DEFAULT", iconTable[title] or "CHAR_DEFAULT", true, 1, title, nil, text);
	EndTextCommandThefeedPostTicker(true, false)
end)

--DrawText
function drawText(image, input, style) local text = ""
	if Config.System.drawText == "qb" then
		for i = 1, #input do
			text = text..input[i].."</span>"..(input[i+1] ~= nil and "<br>" or "") end
		local text = text:gsub("%:", ":<span style='color:yellow'>")
		if image then
			text = '<img src="'..radarTable[image]..'" style="width:12px;height:12px">'..text
		end
		exports[CoreExport]:DrawText(text, 'left')

	elseif Config.System.drawText == "ox" then
		for k, v in pairs(input) do
			input[k] = v.."   \n"
		end
		lib.showTextUI(table.concat(input), { icon = radarTable[image], position = 'left-center' })

	elseif Config.System.drawText == "gta" then
		for i = 1, #input do if input[i] ~= "" then text = text..input[i].."\n~s~" end end
		if image then text = "~BLIP_"..image.."~ "..text end

		DisplayHelpMsg(text:gsub("%:", ":~"..style.."~"))
    elseif Config.System.drawText == "esx" then
        for i = 1, #input do
			text = text..input[i].."</span>"..(input[i+1] ~= nil and "<br>" or "") end
		local text = text:gsub("%:", ":<span style='color:yellow'>")
		if image then
			text = '<img src="'..radarTable[image]..'" style="width:12px;height:12px">'..text
		end
		ESX.TextUI(text, nil)
	end
end

function hideText()
	if Config.System.drawText == "qb" then
        exports[CoreExport]:HideText()
	elseif Config.System.drawText == "ox" then
        lib.hideTextUI()
	elseif Config.System.drawText == "gta" then
        ClearAllHelpMessages()
    elseif Config.System.drawText == "esx" then
        ESX.HideUI()
    end
end

function DisplayHelpMsg(text)
	BeginTextCommandDisplayHelp("STRING")
	AddTextComponentScaleform(text)
	EndTextCommandDisplayHelp(0, true, false, -1)
end

-- Callbacks
function createCallback(callbackName, funct)
    if GetResourceState(OXLibExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering ^3Callback^2 with ^7"..OXLibExport, callbackName) end
        lib.callback.register(callbackName, funct)
    elseif GetResourceState(QBExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering ^3Callback^2 with ^7"..QBExport, callbackName) end
        Core = Core or exports[QBExport]:GetCoreObject()
        Core.Functions.CreateCallback(callbackName, funct)
    elseif GetResourceState(ESXExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering ^3Callback^2 with ^7"..ESXExport, callbackName) end
        ESX.RegisterServerCallback(callbackName, funct)
    else
        print("^6Bridge^7: ^1ERROR^7: ^3Can't find any script to register callback with", callbackName)
    end
end

function triggerCallback(callBackName, value) local result = nil
    if GetResourceState(OXLibExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Triggering ^3Callback^2 with ^7"..OXLibExport, callBackName) end
        result = lib.callback.await(callBackName, false, value)
    elseif GetResourceState(QBExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Triggering ^3Callback^2 with ^7"..QBExport, callBackName) end
        local p = promise.new()
        Core.Functions.TriggerCallback(callBackName, function(cb) p:resolve(cb) end, value)
        result = Citizen.Await(p)
    elseif GetResourceState(ESXExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Triggering ^3Callback^2 with ^7"..ESXExport, callBackName) end
        local p = promise.new()
        ESX.TriggerServerCallback(callBackName, function(cb) p:resolve(cb) end, value)
        result = Citizen.Await(p)
    else
        print("^6Bridge^7: ^1ERROR^7: ^3Can't find any script to trigger callback with", callBackName)
    end
    return result
end

-- onPlayerLoaded events
function onPlayerLoaded(func)
    if GetResourceState(QBExport):find("start") or GetResourceState(QBXExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering ^3onPlayerLoaded^2 with ^7"..QBExport) end
        AddEventHandler('QBCore:Client:OnPlayerLoaded', func)
    elseif GetResourceState(ESXExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering ^3onPlayerLoaded^2 with ^7"..ESXExport) end
        AddEventHandler('esx:playerLoaded', func)
    elseif GetResourceState(OXCoreExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering ^3onPlayerLoaded^2 with ^7"..OXLibExport) end
        AddEventHandler('ox:playerLoaded', func)
    else
        print("^4ERROR^7: ^2No Core detected for onPlayerLoaded ^7- ^2Check ^3exports^1.^2lua^7")
    end
end


-- INPUT --
function createInput(title, opts)
    local dialog = nil
    local options = {}
    if Config.System.Menu == "ox" then
        for i = 1, #opts do
            if opts[i].type == "radio" then
                for k in pairs(opts[i].options) do
                    opts[i].options[k].label = opts[i].options[k].text
                end
                options[i] = {
                    type = "select",
                    isRequired = opts[i].isRequired,
                    label = opts[i].label or opts[i].text,
                    name = opts[i].name,
                    default = opts[i].options[1].value,
                    options = opts[i].options,
                }
            end
            if opts[i].type == "number" then
                options[i] = {
                    type = "number",
                    label = opts[i].text ..(opts[i].txt and " - "..opts[i].txt or ""),
                    isRequired = opts[i].isRequired,
                    name = opts[i].name,
                    options = opts[i].options,
                }
            end
            if opts[i].type == "text" then
                options[i] = {
                    type = "input",
                    label = opts[i].text ..(opts[i].txt and " - "..opts[i].txt or ""),
                    isRequired = opts[i].isRequired,
                }
            end
            if opts[i].type == "select" then
                options[i] = {
                    type = "select",
                    label = opts[i].text ..(opts[i].txt and " - "..opts[i].txt or ""),
                    isRequired = opts[i].isRequired,
                    name = opts[i].name,
                    options = opts[i].options,
                    min = opts[i].min,
                    max = opts[i].max,
                    default = opts[i].default,
                }
            end
        end
        dialog = exports[OXLibExport]:inputDialog(title, options)
        return dialog
    end
    if Config.System.Menu == "qb" then
        dialog = exports['qb-input']:ShowInput({ header = title, submitText = "Accept", inputs = opts })
        return dialog
    end
    if Config.System.Menu == "gta" then
        WarMenu.CreateMenu(tostring(opts),
        title,
        " ",
        {   titleColor = { 222, 255, 255 },
            maxOptionCountOnScreen = 15,
            width = 0.25,
            x = 0.7,
        })
        if WarMenu.IsAnyMenuOpened() then return end
        WarMenu.OpenMenu(tostring(opts))
        local close = true
        local _comboBoxItems = { }
        local _comboBoxIndex = { 1, 1 }
        while true do
            if WarMenu.Begin(tostring(opts)) then
                for i = 1, #opts do
                    if opts[i].type == "radio" then
                        for k in pairs(opts[i].options) do
                            if not _comboBoxItems[i] then _comboBoxItems[i] = {} end
                            _comboBoxItems[i][k] = opts[i].options[k].text
                        end
                        local _, comboBoxIndex = WarMenu.ComboBox(opts[i].label, _comboBoxItems[i], _comboBoxIndex[i])
                        if _comboBoxIndex[i] ~= comboBoxIndex then
                            _comboBoxIndex[i] = comboBoxIndex
                        end
                    end
                    if opts[i].type == "number" then
                        for b = 1, opts[i].max do
                            if not _comboBoxItems[i] then _comboBoxItems[i] = {} end
                            _comboBoxItems[i][b] = b
                        end
                        local _, comboBoxIndex = WarMenu.ComboBox(opts[i].text, _comboBoxItems[i], _comboBoxIndex[i])
                        if _comboBoxIndex[i] ~= comboBoxIndex then
                            _comboBoxIndex[i] = comboBoxIndex
                        end
                    end
                end
                local pressed = WarMenu.Button("Pay")
                if pressed then
                    WarMenu.CloseMenu()
                    close = false
                    local result = {}
                    for i = 1, #_comboBoxIndex do
                        result[i] = _comboBoxItems[i][_comboBoxIndex[i]]
                    end
                    return result
                end
                WarMenu.End()
            else
                return
            end
            if not WarMenu.IsAnyMenuOpened() and close then
                if data.onExit then data.onExit() end
            end
            Wait(0)
        end
    end
end

-- Get Vehile Info --
local lastCar = nil
local carInfo = {}
function searchCar(vehicle)
	if lastCar ~= vehicle then -- If same car, use previous info
		lastCar = vehicle
		carInfo = {}
        local model = GetEntityModel(vehicle)
        local classlist = {
            "Compacts", 		--1
            "Sedans", 			--2
            "SUVs", 			--3
            "Coupes", 			--4
            "Muscle", 			--5
            "Sports Classics", 	--6
            "Sports", 			--7
            "Super", 			--8
            "Motorcycles", 		--9
            "Off-road", 		--10
            "Industrial", 		--11
            "Utility", 			--12
            "Vans", 			--13
            "Cycles", 			--14
            "Boats", 			--15
            "Helicopters", 		--16
            "Planes", 			--17
            "Service", 			--18
            "Emergency", 		--19
            "Military", 		--20
            "Commercial", 		--21
            "Trains", 			--22
        }
        if Vehicles then
            for k, v in pairs(Vehicles) do
                if tonumber(v.hash) == model or GetHashKey(v.hash) == model or GetHashKey(v.model) == model then
                    if Config.System.Debug then
                        print("^6Bridge^7: ^2Vehicle info found in^7 ^4Vehicles^7 ^2table^7: ^6"..(v.hash and v.hash or v.model).. " ^7(^6"..Vehicles[k].name.."^7)")
                    end
                    carInfo.name = Vehicles[k].name.." "..Vehicles[k].brand
                    carInfo.price = Vehicles[k].price
                    carInfo.class = classlist[GetVehicleClass(vehicle) + 1], GetVehicleClass(vehicle)
                    break
                end
            end

            if not carInfo.name then
                if Config.System.Debug then
                    print("^6Bridge^7: ^2Vehicle ^1not ^2found in ^4vehicles^7 ^2table^7: ^6"..model.." ^7(^6"..GetDisplayNameFromVehicleModel(model):lower().."^7)")
                end
                carInfo.name = string.upper(GetMakeNameFromVehicleModel(model).." "..GetDisplayNameFromVehicleModel(model))
                carInfo.price = 0
                carInfo.class = classlist[GetVehicleClass(vehicle) + 1], GetVehicleClass(vehicle)
            end
            return carInfo
        else
            if not carInfo.name then
                if Config.System.Debug then
                    print("^6Bridge^7: ^2Vehicle ^1not ^2found in ^4vehicles^7 ^2table^7: ^6"..model.." ^7(^6"..GetDisplayNameFromVehicleModel(model):lower().."^7)")
                end
                carInfo.name = string.upper(GetMakeNameFromVehicleModel(model).." "..GetDisplayNameFromVehicleModel(model))
                carInfo.price = 0
                carInfo.class = classlist[GetVehicleClass(vehicle) + 1], GetVehicleClass(vehicle)
            end
        end
	else
		return carInfo
	end
end

-- Vehicle Properties --
function getVehicleProperties(vehicle)
    local properties = {}
    if vehicle == nil then return nil end
    if GetResourceState(OXLibExport):find("start") then
        properties = lib.getVehicleProperties(vehicle)
    elseif GetResourceState(QBExport):find("start") then
        properties = Core.Functions.GetVehicleProperties(vehicle)
    end
    return properties
end

function setVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) then
        print(("Unable to set vehicle properties for '%s' (entity does not exist)"):
        format(vehicle))
    end
    if GetResourceState(OXLibExport):find("start") then
        lib.setVehicleProperties(vehicle, props)
    elseif GetResourceState(QBExport):find("start") then
        Core.Functions.SetVehicleProperties(vehicle, props)
    end
end

RegisterNetEvent(GetCurrentResourceName()..":server:ChargePlayer", function(cost, type) local src = source
    if Config.System.Debug then print("^6Bridge^7: ^2Charging ^2Player: '^6"..cost.."^7'", type) end
    if type == "cash" then
        if GetResourceState(OXInv):find("start") then
            exports[OXInv]:RemoveItem(src, "money", cost)
            if Config.System.Debug then print("^6Bridge^7: ^2Charging ^2Player: '^6"..cost.."^7'", type, OXInv) end
        elseif GetResourceState(QBExport):find("start") then
            Core.Functions.GetPlayer(src).Functions.RemoveMoney("cash", cost)
            if Config.System.Debug then print("^6Bridge^7: ^2Charging ^2Player: '^6"..cost.."^7'", type, QBExport) end
        elseif GetResourceState(ESXExport):find("start") then
            local Player = ESX.GetPlayerFromId(src)
            Player.removeMoney(cost, "")
            if Config.System.Debug then print("^6Bridge^7: ^2Charging ^2Player: '^6"..cost.."^7'", type, ESXExport) end
        end
    end
    if type == "bank" then
        if GetResourceState(QBExport):find("start") or GetResourceState(QBXExport):find("start") then
            Core.Functions.GetPlayer(src).Functions.RemoveMoney("bank", cost)
            if Config.System.Debug then print("^6Bridge^7: ^2Charging ^2Player: '^6"..cost.."^7'", type, QBExport) end
        elseif GetResourceState(ESXExport):find("start") then
            local Player = ESX.GetPlayerFromId(src)
            Player.removeMoney(cost, "")
            if Config.System.Debug then print("^6Bridge^7: ^2Charging ^2Player: '^6"..cost.."^7'", type, ESXExport) end
        end
    end
end)

function createUseableItem(item, funct)
    if GetResourceState(ESXExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering item as ^3Useable^2 with ^7es_extended", item) end
        while not ESX do Wait(0) end
        ESX.RegisterUsableItem(item, funct)
    elseif GetResourceState(QBExport):find("start") and not GetResourceState(QBXExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering item as ^3Useable^2 with ^7qb-core", item) end
        Core.Functions.CreateUseableItem(item, funct)
    elseif GetResourceState(QBXExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering item as ^3Useable^2 with ^7qbx_core", item) end
        exports[QBXExport]:CreateUseableItem(item, funct)
    end
end

function hasJob(job, source, grade) local hasJob = false
    if source then
        local src = tonumber(source)
        if GetResourceState(ESXExport):find("start") then
            local info = ESX.GetPlayerFromId(src).job
            while not info do
                info = ESX.GetPlayerData(src).job
                Wait(100)
            end
            if info.name == job then hasJob = true end

        elseif GetResourceState(OXCoreExport):find("start") then
            local chunk = assert(load(LoadResourceFile('ox_core', ('imports/%s.lua'):format('server')), ('@@ox_core/%s'):format(file)))
            chunk()
            local player = Ox.GetPlayer(tonumber(src))
            for k, v in pairs(player.getGroups()) do
                if k == job then hasJob = true end
            end

        elseif GetResourceState(QBXExport):find("start") then
            local jobinfo = exports[QBXExport]:GetPlayer(src).PlayerData.job
            if jobinfo.name == job then hasJob = true
                if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
            end
            local ganginfo = exports[QBXExport]:GetPlayer(src).PlayerData.gang
            if ganginfo.name == job then hasJob = true
                if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
            end
        elseif GetResourceState(QBExport):find("start") and not GetResourceState(QBXExport):find("start") then
            if Core.Functions.GetPlayer then -- support older qb-core functions
                local jobinfo = Core.Functions.GetPlayer(src).PlayerData.job
                if jobinfo.name == job then hasJob = true
                    if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
                end
                local ganginfo = Core.Functions.GetPlayer(src).PlayerData.gang
                if ganginfo.name == job then hasJob = true
                    if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
                end
            else -- support newer qb-core exports
                local jobinfo = exports[QBExport]:GetPlayer(src).PlayerData.job
                if jobinfo.name == job then hasJob = true
                    if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
                end
                local ganginfo = exports[QBExport]:GetPlayer(src).PlayerData.gang
                if ganginfo.name == job then hasJob = true
                    if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
                end
            end
        else
            print("^4ERROR^7: ^2No Core detected for hasJob ^7- ^2Check ^3exports^1.^2lua^7")
        end
    else
        if GetResourceState(ESXExport):find("start") then
            while not ESX do Wait(10) end
            local info = ESX.GetPlayerData().job
            while not info do
                info = ESX.GetPlayerData().job
                Wait(100)
            end
            if info.name == job then hasJob = true end

        elseif GetResourceState(OXCoreExport):find("start") then
            for k, v in pairs(exports[OXCoreExport]:GetPlayerData().groups) do
                if k == job then hasJob = true end break
            end

        elseif GetResourceState(QBXExport):find("start") then
            local jobinfo = QBX.PlayerData.job
            if jobinfo.name == job then hasJob = true
                if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
            end
            local ganginfo = QBX.PlayerData.gang
            if ganginfo.name == job then hasJob = true
                if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
            end
        elseif GetResourceState(QBExport):find("start") and not GetResourceState(QBXExport):find("start") then
            local info = nil
            Core.Functions.GetPlayerData(function(PlayerData)
                info = PlayerData
            end)
            local jobinfo = info.job
            if jobinfo.name == job then
                hasJob = true
                if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
            end
            local ganginfo = info.gang
            if ganginfo.name == job then
                hasJob = true
                if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
            end
        else
            print("^4ERROR^7: ^2No Core detected for hasJob() ^7- ^2Check ^3exports^1.^2lua^7")
        end
    end
    return hasJob
end

function getPlayer(source) local Player = {}
    if Config.System.Debug then print("^6Bridge^7: ^2Getting ^3Player^2 info^7") end
    if source then -- If called from server
        local src = tonumber(source)
        if GetResourceState(ESXExport):find("start") then
            local info = ESX.GetPlayerFromId(src)
            Player = {
                name = info.getName(),
                cash = info.getMoney(),
                bank = info.getAccount("bank").money,
            }
        elseif GetResourceState(OXCoreExport):find("start") then
            local file = ('imports/%s.lua'):format('server')
            local import = LoadResourceFile('ox_core', file)
            local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))
            chunk()
            local player = Ox.GetPlayer(tonumber(src))
            Player = {
                name = ('%s %s'):format(player.firstName, player.lastName),
                cash = exports[OXInv]:Search(src, 'count', "money"),
                bank = 0,
            }
        elseif GetResourceState(QBXExport):find("start") then
            local info = exports[QBXExport]:GetPlayer(src)
            Player = {
                name = info.PlayerData.charinfo.firstname.." "..info.PlayerData.charinfo.lastname,
                cash = exports[OXInv]:Search(src, 'count', "money"),
                bank = info.Functions.GetMoney("bank"),
            }
        elseif GetResourceState(QBExport):find("start") and not GetResourceState(QBXExport):find("start") then
            if Core.Functions.GetPlayer ~= nil then -- support older qb-core functions
                local info = Core.Functions.GetPlayer(src).PlayerData
                Player = {
                    name = info.charinfo.firstname.." "..info.charinfo.lastname,
                    cash = info.money["cash"],
                    bank = info.money["bank"],
                }
            else
                local info = exports[QBExport]:GetPlayer(src).PlayerData
                Player = {
                    name = info.charinfo.firstname.." "..info.charinfo.lastname,
                    cash = info.money["cash"],
                    bank = info.money["bank"],
                }
            end
        else
            print("^4ERROR^7: ^2No Core detected for getPlayer() ^7- ^2Check ^3exports^1.^2lua^7")
        end
    else
        if GetResourceState(ESXExport):find("start") and ESX ~= nil then
            local info = ESX.GetPlayerData()
            local cash, bank = 0, 0
            for k, v in pairs(ESX.GetPlayerData().accounts) do
                if v.name == "money" then cash = v.money end
                if v.name == "bank" then bank = v.money end
            end
            Player = {
                name = ('%s %s'):format(info.firstName, info.lastName),
                cash = cash,
                bank = bank,
            }
        elseif GetResourceState(OXCoreExport):find("start") then
            local info = exports[OXCoreExport]:GetPlayerData()
            Player = {
                name = info.firstName.." "..info.lastName,
                cash = exports[OXInv]:Search('count', "money"),
                bank = 0,
            }
        elseif GetResourceState(QBXExport):find("start") then
            local info = exports[QBXExport]:GetPlayerData()
            Player = {
                name = info.charinfo.firstname.." "..info.charinfo.lastname,
                cash = info.money["cash"],
                bank = info.money["bank"],
            }
        elseif GetResourceState(QBExport):find("start") and not GetResourceState(QBXExport):find("start") then
            local info = nil
            Core.Functions.GetPlayerData(function(PlayerData) info = PlayerData end)
            Player = {
                name = info.charinfo.firstname.." "..info.charinfo.lastname,
                cash = info.money["cash"],
                bank = info.money["bank"],
            }
        else
            print("^4ERROR^7: ^2No Core detected for hasJob ^7- ^2Check ^3exports^1.^2lua^7")
        end
    end
    return Player
end

function registerCommand(command, options)
    if GetResourceState(OXLibExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering ^3Command^2 with ^7"..OXLibExport, command) end
        lib.addCommand(command, { help = options[1], restricted = options[5] and "group."..options[5] or nil }, options[4])
    elseif GetResourceState(QBExport):find("start") and not GetResourceState(QBXExport):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Registering ^3Command^2 with ^7qb-core"..QBExport, command) end
        Core.Commands.Add(command, options[1], options[2], options[3], options[4], options[5] and options[5] or nil)
    end
end

function invImg(item)
    local imgLink = ""
    if item ~= "" and Items[item] then
        if GetResourceState(OXInv):find("start") then
            imgLink = "nui://"..OXInv.."/web/images/"..(Items[item].image or "")
        elseif GetResourceState(QSInv and QSInv or ""):find("start") then
            imgLink = "nui://"..QSInv.."/html/images/"..(Items[item].image or "")
        elseif GetResourceState(CoreInv and CoreInv or ""):find("start") then
            imgLink = "nui://"..CoreInv.."/html/img/"..(Items[item].image or "")
        elseif GetResourceState(QBInv and QBInv or ""):find("start") then
            imgLink = "nui://"..QBInv.."/html/images/"..(Items[item].image or "")
        else
            print("^4ERROR^7: ^2No Inventory detected for invImg ^7- ^2Check ^3exports^1.^2lua^7")
        end
    end
    return imgLink
end

function registerStash(name, label)
    if GetResourceState(OXInv):find("start") then
        --print("Registering OX Stash:", name, label)
        exports[OXInv]:RegisterStash(name, label, 50, 4000000)
    elseif GetResourceState(QSInv):find("start") then
        --print("Registering QS Stash:", name, label)
        exports[QSInv]:RegisterStash(name, 50, 4000000)
    end
end
-- IN NO WAY PERFECT --
