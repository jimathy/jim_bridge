
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

    elseif isStarted(RSGExport) then
        debugPrint("^6Bridge^7: ^2Registering ^3Command^2 with ^7"..RSGExport, command)
        Core.Commands.Add(command, options[1], options[2], options[3], options[4], options[5] or nil)

    elseif isStarted(ESXExport) then
        debugPrint("^6Bridge^7: ^2Registering ^3Command^2 with ^7ESX Legacy", command)
        ESX.RegisterCommand(command, options[5] or 'admin', function(xPlayer, args, showError)
            options[4](xPlayer.source, args, showError)
        end, false, { help = options[1] })

    end
end