
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
    -- Name the options
    local optionTable = {
        helpInfo = options[1] or nil,           -- help info that pops up in chat box
        subText = options[2] or nil,            -- sub help info for each arg
        argsRequired = options[3] or nil,       -- command only works if you enter args
        funct = options[4] or nil,              -- function that will run when command is triggered
        restriction = options[5] or nil         -- admin group that can use the group or `nil`
    }

    local commandResource = ""
    if isStarted(OXLibExport) then
        commandResource = OXLibExport
        lib.addCommand(command,
            {
                help = optionTable.helpInfo,
                params = optionTable.subText,
                restricted = optionTable.restriction and "group."..optionTable.restriction or nil
            },
        optionTable.funct)

    elseif isStarted(QBExport) and not isStarted(QBXExport) then
        commandResource = QBExport
        Core.Commands.Add(command,
            optionTable.helpInfo,
            optionTable.subText,
            optionTable.argsRequired,
            optionTable.funt,
            optionTable.restriction or nil
        )

    elseif isStarted(RSGExport) then
        commandResource = RSGExport
        Core.Commands.Add(command,
            optionTable.helpInfo,
            optionTable.subText,
            optionTable.argsRequired,
            optionTable.funt,
            optionTable.restriction or nil
        )

    elseif isStarted(ESXExport) then
        commandResource = ESXExport
        ESX.RegisterCommand(command,
            optionTable.restriction or 'admin',
            function(xPlayer, args, showError)
                optionTable.funct(xPlayer.source, args, showError)
            end,
            false,
            { help = options[1] }
        )

    end
    if commandResource ~= "" then
        debugPrint("^6Bridge^7: ^2Registering ^3Command^2 with ^4"..commandResource.."^7:", "^7/"..command)
    else
        print("^1ERROR^7: ^1Couldn't find supported framework to register command^7:", "/"..command)
    end
end