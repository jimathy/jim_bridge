Config = Config or { System = {} }

CreateThread(function()
    local fileLoader = assert(load(LoadResourceFile('jim_bridge', ('starter.lua')), ('@@jim_bridge/starter.lua')))
    fileLoader()
end)

local headerShown = false
local sendData = nil
local sendModifiers = nil


--Colours for progressbar
local colours = {
    ["dark.0"] = "#C1C2C5", ["dark.1"] = "#A6A7AB", ["dark.2"] = "#909296", ["dark.3"] = "#5C5F66", ["dark.4"] = "#373A40", ["dark.5"] = "#2C2E33", ["dark.6"] = "#25262B", ["dark.7"] = "#1A1B1E", ["dark.8"] = "#141517", ["dark.9"] = "#101113",
    ["gray.0"] = "#F8F9FA", ["gray.1"] = "#F1F3F5", ["gray.2"] = "#E9ECEF", ["gray.3"] = "#DEE2E6", ["gray.4"] = "#CED4DA", ["gray.5"] = "#ADB5BD", ["gray.6"] = "#868E96", ["gray.7"] = "#495057", ["gray.8"] = "#343A40", ["gray.9"] = "#212529",
    ["red.0"] = "#FFF5F5", ["red.1"] = "#FFE3E3", ["red.2"] = "#FFC9C9", ["red.3"] = "#FFA8A8", ["red.4"] = "#FF8787", ["red.5"] = "#FF6B6B", ["red.6"] = "#FA5252", ["red.7"] = "#F03E3E", ["red.8"] = "#E03131", ["red.9"] = "#C92A2A",
    ["pink.0"] = "#FFF0F6", ["pink.1"] = "#FFDEEB", ["pink.2"] = "#FCC2D7", ["pink.3"] = "#FAA2C1", ["pink.4"] = "#F783AC", ["pink.5"] = "#F06595", ["pink.6"] = "#E64980", ["pink.7"] = "#D6336C", ["pink.8"] = "#C2255C", ["pink.9"] = "#A61E4D",
    ["grape.0"] = "#F8F0FC", ["grape.1"] = "#F3D9FA", ["grape.2"] = "#EEBEFA", ["grape.3"] = "#E599F7", ["grape.4"] = "#DA77F2", ["grape.5"] = "#CC5DE8", ["grape.6"] = "#BE4BDB", ["grape.7"] = "#AE3EC9", ["grape.8"] = "#9C36B5", ["grape.9"] = "#862E9C",
    ["violet.0"] = "#F3F0FF", ["violet.1"] = "#E5DBFF", ["violet.2"] = "#D0BFFF", ["violet.3"] = "#B197FC", ["violet.4"] = "#9775FA", ["violet.5"] = "#845EF7", ["violet.6"] = "#7950F2", ["violet.7"] = "#7048E8", ["violet.8"] = "#6741D9", ["violet.9"] = "#5F3DC4",
    ["indigo.0"] = "#EDF2FF", ["indigo.1"] = "#DBE4FF", ["indigo.2"] = "#BAC8FF", ["indigo.3"] = "#91A7FF", ["indigo.4"] = "#748FFC", ["indigo.5"] = "#5C7CFA", ["indigo.6"] = "#4C6EF5", ["indigo.7"] = "#4263EB", ["indigo.8"] = "#3B5BDB", ["indigo.9"] = "#364FC7",
    ["blue.0"] = "#E7F5FF", ["blue.1"] = "#D0EBFF", ["blue.2"] = "#A5D8FF", ["blue.3"] = "#74C0FC", ["blue.4"] = "#4DABF7", ["blue.5"] = "#339AF0", ["blue.6"] = "#228BE6", ["blue.7"] = "#1C7ED6", ["blue.8"] = "#1971C2", ["blue.9"] = "#1864AB",
    ["cyan.0"] = "#E3FAFC", ["cyan.1"] = "#C5F6FA", ["cyan.2"] = "#99E9F2", ["cyan.3"] = "#66D9E8", ["cyan.4"] = "#3BC9DB", ["cyan.5"] = "#22B8CF", ["cyan.6"] = "#15AABF", ["cyan.7"] = "#1098AD", ["cyan.8"] = "#0C8599", ["cyan.9"] = "#0B7285",
    ["teal.0"] = "#E6FCF5", ["teal.1"] = "#C3FAE8", ["teal.2"] = "#96F2D7", ["teal.3"] = "#63E6BE", ["teal.4"] = "#38D9A9", ["teal.5"] = "#20C997", ["teal.6"] = "#12B886", ["teal.7"] = "#0CA678", ["teal.8"] = "#099268", ["teal.9"] = "#087F5B",
    ["green.0"] = "#EBFBEE", ["green.1"] = "#D3F9D8", ["green.2"] = "#B2F2BB", ["green.3"] = "#8CE99A", ["green.4"] = "#69DB7C", ["green.5"] = "#51CF66", ["green.6"] = "#40C057", ["green.7"] = "#37B24D", ["green.8"] = "#2F9E44", ["green.9"] = "#2B8A3E",
    ["lime.0"] = "#F4FCE3", ["lime.1"] = "#E9FAC8", ["lime.2"] = "#D8F5A2", ["lime.3"] = "#C0EB75", ["lime.4"] = "#A9E34B", ["lime.5"] = "#94D82D", ["lime.6"] = "#82C91E", ["lime.7"] = "#74B816", ["lime.8"] = "#66A80F", ["lime.9"] = "#5C940D",
    ["yellow.0"] = "#FFF9DB", ["yellow.1"] = "#FFF3BF", ["yellow.2"] = "#FFEC99", ["yellow.3"] = "#FFE066", ["yellow.4"] = "#FFD43B", ["yellow.5"] = "#FCC419", ["yellow.6"] = "#FAB005", ["yellow.7"] = "#F59F00", ["yellow.8"] = "#F08C00", ["yellow.9"] = "#E67700",
    ["orange.0"] = "#FFF4E6", ["orange.1"] = "#FFE8CC", ["orange.2"] = "#FFD8A8", ["orange.3"] = "#FFC078", ["orange.4"] = "#FFA94D", ["orange.5"] = "#FF922B", ["orange.6"] = "#FD7E14", ["orange.7"] = "#F76707",["orange.8"] = "#E8590C",["orange.9"] = "#D9480F"
}

-- Functions
function openNuiMenu(data, modifiers)
    if not data or not next(data) then return end
	for _, v in pairs(data) do
        v["icon"] = v["arrow"] and "fas fa-angle-right" or v["icon"] or nil
        v["colorScheme"] = v["colourScheme"] and colours[v["colourScheme"]] or (v["colorScheme"] and colours[v["colorScheme"]] or colours["green.7"])
        if v["onSelect"] then
            v.params = { isAction = true, event = v["onSelect"] }
        end
    end
    SetNuiFocus(true, true)
    headerShown = false
    sendData = data
    sendModifiers = modifiers or {}
    SendNUIMessage({ action = 'OPEN_MENU', data = table.clone(data) })
end

local function closeMenu()
    sendData = nil
    sendModifiers = nil
    headerShown = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE_MENU' })
end

local function showHeader(data)
    if not data or not next(data) then return end
    headerShown = true
    sendData = data
    SendNUIMessage({ action = 'SHOW_HEADER', data = table.clone(data) })
end

-- Events

RegisterNetEvent("jim_bridge:client:openMenu", function(data) openNuiMenu(data) end)

RegisterNetEvent("jim_bridge:client:closeMenu", function() closeMenu() end)

-- NUI Callbacks

RegisterNUICallback('clickedButton', function(option)
    if headerShown then headerShown = false end
    PlaySound(-1, "CLICK_BACK", "WEB_NAVIGATION_SOUNDS_PHONE", 0, 0, 1)
    SetNuiFocus(false, false)
    if sendData then
        local data = sendData[tonumber(option)]
        sendData = nil
        if data then
            if data.params and data.params.event then
                if data.params.isServer then
                    TriggerServerEvent(data.params.event, data.params.args)
                elseif data.params.isCommand then
                    ExecuteCommand(data.params.event)
                elseif data.params.isQBCommand then
                    TriggerServerEvent('QBCore:CallCommand', data.params.event, data.params.args)
                elseif data.params.isAction then
                    data.params.event(data.params.args)
                else
                    TriggerEvent(data.params.event, data.params.args)
                end
            end
        end
    end
end)

RegisterNUICallback('closeMenu', function()
    if sendModifiers and sendModifiers.onExit then sendModifiers.onExit() end -- when close menu is triggered (with esc or using a button to close it) trigger onExit function
    headerShown = false
    sendModifiers = nil
    sendData = nil
    SetNuiFocus(false, false)
end)

-- Command and Keymapping
RegisterCommand('playerfocus', function() if headerShown then SetNuiFocus(true, true) end end)
RegisterKeyMapping('playerFocus', 'Give Menu Focus', 'keyboard', 'LMENU')

-- Exports
exports('openMenu', function(data) openNuiMenu(data) end)
exports('closeMenu', function() closeMenu() end)
exports('showHeader', function(data) showHeader(data) end)


-- Input Dialog
-- function inputDialog(title, config)
--     local p = promise.new()
--     local cbId = math.random(111111, 999999)
--
--     RegisterNUICallback("inputResult", function(data, cb)
--         if data.cbId == cbId then
--             cb({})
--             SetNuiFocus(false, false)
--             p:resolve(data.result)
--         end
--     end)
--
--     SendNUIMessage({
--         action = "SHOW_INPUT",
--         title = title,
--         data = config,
--         cbId = cbId
--     })
--
--     SetNuiFocus(true, true)
--     return Citizen.Await(p)
-- end
--
-- exports('inputDialog', inputDialog)