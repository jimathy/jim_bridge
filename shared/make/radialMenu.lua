local activeRadials = {}


local radialFunc = {

    qb = {
        add = function(data)
            exports['qb-radialmenu']:AddOption(data, data.id)
            return true
        end,

        remove = function(id)
            exports['qb-radialmenu']:RemoveOption(id)
        end,
    },

    ox = {
        add = function(data)
            if data.event then
                if data.type and data.type == "server" then
                    data.onSelect = function()
                        TriggerServerEvent(data.event)
                    end
                else
                    data.onSelect = function()
                        TriggerEvent(data.event)
                    end
                end
            end
            lib.addRadialItem(data)
            return true
        end,

        remove = function(id)
            lib.removeRadialItem(id)
        end,
    },

    qbx = {
        add = function(data)
            exports['qbx_radialmenu']:AddOption(data, data.id)
            return true
        end,

        remove = function(id)
            exports['qbx_radialmenu']:RemoveOption(id)
        end,
    },

}


--- Adds a radial menu option using the configured radial system
---
---@param data table A table containing the radial menu configuration.
--- - **id** (`string`): A unique identifier for the radial menu option.
--- - **label** (`string`): The display label for the radial menu option.
--- - **icon** (`string`, optional): The icon to display.
--- - **type** (`string`, optional): The type of radial option (e.g., 'client', 'server').
--- - **event** (`string`, optional): The event to trigger when the option is selected.
--- - **onSelect** (`function`, optional): The function to call when the option is selected.
--- - **canInteract** (`function`, optional): A function to determine if the option can be interacted with.
--- - **menu** (`string`, optional, ox submenu support)
---
---@usage
--- ```lua
--- addRadial({
---   id = 'tss_example',
---   label = 'Example',
---   icon = 'circle',
---   onSelect = function()
---     print('clicked')
---   end
--- })
--- ```

function addRadial(data)
    if not data or not data.id then
        debugPrint("^6Bridge^7: ^1Radial missing id")
        return
    end

    local system = Config.System.RadialMenu
    if not radialFunc[system] then
        debugPrint("^6Bridge^7: ^1Unsupported Radial System^7: "..tostring(system))
        return
    end

    if radialFunc[system].add(data) then
        activeRadials[data.id] = true
        debugPrint("^6Bridge^7: ^2Radial Added^7: '^6"..data.id.."^7'")
        return data.id
    end
end

--- Removes a radial menu option
---
---@param id string
---
---@usage
--- removeRadial('tss_example')
function removeRadial(id)
    if not id or not activeRadials[id] then 
        debugPrint("^6Bridge^7: ^1Radial missing id")
        return 
    end

    local system = Config.System.RadialMenu
    if not radialFunc[system] then return end

    radialFunc[system].remove(id)
    activeRadials[id] = nil

    debugPrint("^6Bridge^7: ^1Radial Removed^7: '^6"..id.."^7'")
end

-- Clean up on player unload / resource stop

onPlayerUnload(function()
    for id in pairs(activeRadials) do
        removeRadial(id)
    end
    activeRadials = {}
end)

onResourceStop(function()
    for id in pairs(activeRadials) do
        removeRadial(id)
    end
end, true)
