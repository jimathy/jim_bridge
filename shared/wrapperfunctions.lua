
--- Registers a command with the active command system.
--- This function supports multiple command systems (OXLib, qb-core, ESX Legacy).
---
--- @param command string The name of the command to register.
--- @param options table A table containing command options.
---     - help (`string`): The help description for the command.
---     - params (`table`): A table of parameters for the command.
---     - callback (`function`): The function to execute when the command is called.
---     - autocomplete (`function|nil`): (Optional) A function for autocompletion.
---     - restrictedGroup (`string|nil`): (Optional) The user group required to execute the command.
---
--- @usage
--- ```lua
--- registerCommand("greet", {
---     "Greets the player",
---     { name = "name", help = "Name of the player to greet" },
---     function(source, args) print("Hello, "..args[1].."!") end,
---     nil,
---     "admin"
--- })
--- ```
function registerCommand(command, options)
    if isStarted(OXLibExport) then
        debugPrint("^6Bridge^7: ^2Registering ^3Command^2 with ^7"..OXLibExport, command)
        lib.addCommand(command, { help = options[1], restricted = options[5] and "group."..options[5] or nil }, options[4])
    elseif isStarted(QBExport) and not isStarted(QBXExport) then
        debugPrint("^6Bridge^7: ^2Registering ^3Command^2 with ^7"..QBExport, command)
        Core.Commands.Add(command, options[1], options[2], options[3], options[4], options[5] or nil)
    elseif isStarted(ESXExport) then
        debugPrint("^6Bridge^7: ^2Registering ^3Command^2 with ^7ESX Legacy", command)
        ESX.RegisterCommand(command, options[5] or 'admin', function(xPlayer, args, showError)
            options[4](xPlayer.source, args, showError)
        end, false, { help = options[1] })
    end
end

--- Registers a stash with the active inventory system.
--- Supports either OXInv or QSInv.
---
--- @param name string Unique stash identifier.
--- @param label string Display name for the stash.
--- @param slots number|nil (Optional) Number of slots (default 50).
--- @param weight number|nil (Optional) Maximum weight (default 4000000).
--- @param owner string|nil (Optional) Owner identifier for personal stashes.
--- @param coords table|nil (Optional) Coordinates for the stash location.
--- @usage
--- ```lua
--- registerStash(
---     "playerStash",
---     "Player Stash",
---     100,
---     8000000,
---     "player123",
---     { x = 100.0, y = 200.0, z = 30.0 }
--- )
--- ```
function registerStash(name, label, slots, weight, owner, coords)
    if isStarted(OXInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3OX ^2Stash^7:", name, label, owner or nil)
        exports[OXInv]:RegisterStash(name, label, slots or 50, weight or 4000000, owner or nil)
    elseif isStarted(QSInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3QS ^2Stash^7:", name, label)
        exports[QSInv]:RegisterStash(nil, name, slots or 50, weight or 4000000)

    --elseif isStarted(CoreInv) then
    --    debugPrint("^6Bridge^7: ^2Registering ^3CoreInv ^2Stash^7:", name, label)
    --    exports[CoreInv]:openHolder(nil, name, 'stash', nil, nil, false, nil)

    elseif isStarted(OrigenInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3OrigenInv ^2Stash^7:", name, label)
        exports["origen_inventory"]:registerStash(name, label, slots or 50, weight or 4000000)
    end
end

--- Registers a shop with the active inventory system.
--- Supports either OXInv or QBInv (with QBInvNew flag).
---
--- @param name string Unique shop identifier.
--- @param label string Display name for the shop.
--- @param items table List of available shop items.
--- @param society string|nil (Optional) Society identifier for shared shops.
--- @usage
--- ```lua
--- registerShop("weaponShop", "Weapon Shop", weaponItems, "society_weapons")
--- ```
function registerShop(name, label, items, society)
    if isStarted(OXInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3OX ^2Store^7:", name, label)
        exports[OXInv]:RegisterShop(name, {
            name = label,
            inventory = items,
            society = society,
        })
    elseif isStarted(QBInv) and QBInvNew then
        debugPrint("^6Bridge^7: ^2Registering ^3QB ^2Store^7:", name, label)
        exports[QBInv]:CreateShop({
            name = name,
            label = label,
            slots = #items,
            items = items,
            society = society,
        })
    end
end

if isServer() then
    --- Registers an event to create an OX stash from the server.
    --- When triggered, it calls registerStash with the provided parameters.
    ---
    --- @event server:makeOXStash
    --- @param name string Unique stash identifier.
    --- @param label string Display name for the stash.
    --- @param slots number|nil (Optional) Number of slots.
    --- @param weight number|nil (Optional) Maximum weight.
    --- @param owner string|nil (Optional) Owner identifier.
    --- @param coords table|nil (Optional) Stash coordinates.
    --- @usage
    --- ```lua
    --- TriggerEvent(getScript()..":server:makeOXStash", name, label, slots, weight, owner, coords)
    --- ```
    RegisterNetEvent(getScript()..":server:makeOXStash", function(name, label, slots, weight, owner, coords)
        registerStash(name, label, slots, weight, owner, coords)
    end)
end
