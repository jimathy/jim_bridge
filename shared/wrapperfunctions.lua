-- Phone Mails

--- Sends a phone mail using the detected phone system.
---
--- This function detects the active phone resource (e.g., gksphone, yflip-phone, qb-phone, etc.)
--- and sends a mail using the appropriate method for that phone system.
---
--- @param data table A table containing the mail data.
--- - **subject** (`string`): The subject of the email.
--- - **sender** (`string`): The sender of the email.
--- - **message** (`string`): The body content of the email.
--- - **actions** (`table|nil`): (Optional) Action buttons associated with the email.
---
--- @usage
--- ```lua
--- sendPhoneMail({
---     subject = "Welcome!",
---     sender = "Admin",
---     message = "Thank you for joining our server.",
---     actions = {
---         { label = "Reply", action = replyFunction }
---     }
--- })
--- ```
function sendPhoneMail(data) local phoneResource = ""
    if isStarted("gksphone") then phoneResource = "gksphone"
        exports["gksphone"]:SendNewMail(data)

    elseif isStarted("yflip-phone") then phoneResource = "yflip-phone"
        TriggerServerEvent(getScript()..":yflip:SendMail", data)

    elseif isStarted("qs-smartphone") then phoneResource = "qs-smartphone"
        TriggerServerEvent('qs-smartphone:server:sendNewMail', data)

    elseif isStarted("qs-smartphone-pro") then phoneResource = "qs-smartphone-pro"
        TriggerServerEvent('phone:sendNewMail', data)

    elseif isStarted("roadphone") then phoneResource = "roadphone"
        data.message = data.message:gsub("%<br>", "\n")
        exports['roadphone']:sendMail(data)

    elseif isStarted("lb-phone") then phoneResource = "lb-phone"
        data.message = data.message:gsub("%<br>", "\n")
        TriggerServerEvent(getScript()..":lbphone:SendMail", data)

    elseif isStarted("qb-phone") then phoneResource = "qb-phone"
        TriggerServerEvent('qb-phone:server:sendNewMail', data)

    elseif isStarted("jpr-phonesystem") then phoneResource = "jpr-phonesystem"
        TriggerServerEvent(getScript()..":jpr:SendMail", data)
    end

    if phoneResource ~= "" then debugPrint("^6Bridge^7[^3"..phoneResource.."^7]: ^2Sending mail to player")
    else print("^6Bridge^7: ^1ERROR ^2Sending mail to player ^7 - ^2No supported phone found") end
end

--- Handles sending mail for lb-phone.
---
--- This event listens for the `lbphone:SendMail` event and sends an email using lb-phone's API.
---
--- @event
--- @param data table The mail data.
--- - **subject** (`string`): The subject of the email.
--- - **message** (`string`): The body content of the email.
--- - **buttons** (`table|nil`): (Optional) Action buttons associated with the email.
---
--- @usage
--- ```
--- -- Server-side:
--- TriggerClientEvent(getScript()..":lbphone:SendMail", data)
--- ```
RegisterNetEvent(getScript()..":lbphone:SendMail", function(data)
    local src = source
    local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(src)
    local emailAddress = exports["lb-phone"]:GetEmailAddress(phoneNumber)
    if data.actions then data.buttons = data.actions end
    exports["lb-phone"]:SendMail({
        to = emailAddress,
        subject = data.subject,
        message = data.message,
        actions = data.buttons,
    })
end)

--- Handles sending mail for yflip-phone.
---
--- This event listens for the `yflip:SendMail` event and sends an email using yflip-phone's API.
---
--- @event
--- @param data table The mail data.
--- - **subject** (`string`): The subject of the email.
--- - **sender** (`string`): The sender of the email.
--- - **message** (`string`): The body content of the email.
--- - **buttons** (`table|nil`): (Optional) Action buttons associated with the email.
---
--- @usage
--- ```lua
--- -- Server-side:
--- TriggerClientEvent(getScript()..":yflip:SendMail", data)
--- ```
RegisterNetEvent(getScript()..":yflip:SendMail", function(data)
    local src = source
    exports["yflip-phone"]:SendMail({
        title = data.subject,
        sender = data.sender,
        senderDisplayName = data.sender,
        content = data.message,
        actions = data.buttons,
    }, 'source', src)
end)

--- Handles sending mail for jpr-phonesystem.
---
--- This event listens for the `jpr:SendMail` event and sends an email using jpr-phonesystem's API.
---
--- @event
--- @param data table The mail data.
--- - **subject** (`string`): The subject of the email.
--- - **sender** (`string`): The sender of the email.
--- - **message** (`string`): The body content of the email.
--- - **buttons** (`table|nil`): (Optional) Action buttons associated with the email.
---
--- @return void
---
--- @usage
--- ```lua
--- -- Server-side:
--- TriggerClientEvent(getScript()..":jpr:SendMail", data)
--- ```
RegisterNetEvent(getScript()..":jpr:SendMail", function(data)
    local src = source
    local Player = Core.Functions.GetPlayer(src)
    TriggerEvent('jpr-phonesystem:server:sendEmail', {
        Assunto = data.subject, -- Subject
        Conteudo = data.message, -- Content
        Enviado = data.sender, -- Submitted by
        Destinatario = Player.PlayerData.citizenid, -- Target
        Event = {}, -- Optional
    })
end)

-- Server-Side Functions for Registering Commands, Stashes, and Shops

--- Registers a command with the active command system.
---
--- This function detects whether the server is using OXLib or qb-core for command registration
--- and registers the command accordingly.
---
--- @param command string The name of the command to register.
--- @param options table A table containing command options.
--- - **help** (`string`): The help description for the command.
--- - **params** (`table`): A table of parameters for the command.
--- - **callback** (`function`): The function to execute when the command is called.
--- - **autocomplete** (`function|nil`): (Optional) A function for autocompletion.
--- - **restrictedGroup** (`string|nil`): (Optional) The user group required to execute the command.
---
--- @usage
--- ````lua
--- -- Server Side:
--- registerCommand("greet", {
---     "Greets the player",
---     { name = "name", help = "Name of the player to greet" },
---     function(source, args) print("Hello, " .. args[1] .. "!") end,
---     nil,
---     "admin"
--- })
--- ```
function registerCommand(command, options)
    if isStarted(OXLibExport) then
        debugPrint("^6Bridge^7: ^2Registering ^3Command^2 with ^7"..OXLibExport, command)
        lib.addCommand(command, { help = options[1], restricted = options[5] and "group."..options[5] or nil }, options[4])
    elseif isStarted(QBExport) and not isStarted(QBXExport) then
        debugPrint("^6Bridge^7: ^2Registering ^3Command^2 with ^7 "..QBExport, command)
        Core.Commands.Add(command, options[1], options[2], options[3], options[4], options[5] and options[5] or nil)
    elseif isStarted(ESXExport) then
        debugPrint("^6Bridge^7: ^2Registering ^3Command^2 with ^7 ESX Legacy", command)
        ESX.RegisterCommand(command, options[5] or 'admin', function(xPlayer, args, showError)
            options[4](xPlayer.source, args, showError)
        end, false, { help = options[1] })
    end
end

--- Registers a stash with the active inventory system.
---
--- This function detects whether the server is using OXInv or QSInv and registers the stash accordingly.
---
--- @param name string The unique identifier for the stash.
--- @param label string The display name for the stash.
--- @param slots number|nil (Optional) The number of slots in the stash. Defaults to 50.
--- @param weight number|nil (Optional) The maximum weight the stash can hold. Defaults to 4,000,000.
--- @param owner string|nil (Optional) The owner identifier for personal stashes.
--- @param coords table|nil (Optional) The coordinates for the stash location.
---
--- @usage
--- ```lua
--- registerStash("playerStash", "Player Stash", 100, 8000000, "player123", { x = 100.0, y = 200.0, z = 30.0 })
--- ```
function registerStash(name, label, slots, weight, owner, coords)
    if isStarted(OXInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3OX ^2Stash^7:", name, label, owner or nil)
        exports[OXInv]:RegisterStash(name, label, slots or 50, weight or 4000000, owner or nil)
    elseif isStarted(QSInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3QS ^2Stash^7:", name, label)
        exports[QSInv]:RegisterStash(name, slots or 50, weight or 4000000)
    end
end

--- Registers a shop with the active inventory system.
---
--- This function detects whether the server is using OXInv or QBInv and registers the shop accordingly.
---
--- @param name string The unique identifier for the shop.
--- @param label string The display name for the shop.
--- @param items table The list of items available in the shop.
--- @param society string|nil (Optional) The society identifier for shared shops.
---
--- @usage
--- ```lua
--- registerShop("weaponShop", "Weapon Shop", weaponItems, "society_weapons")
--- ```
function registerShop(name, label, items, society)
    if isStarted(OXInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3OX ^2Store^7:", name, label)
        exports[OXInv]:RegisterShop(
            name, {
                name = label,
                inventory = items,
                society = society,
            }
        )
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

-- Server-Side Event Registration

if isServer() then
    --- Registers an event to create an OX stash from the server.
    ---
    --- @event
    --- @param name string The unique identifier for the stash.
    --- @param label string The display name for the stash.
    --- @param slots number|nil (Optional) The number of slots in the stash.
    --- @param weight number|nil (Optional) The maximum weight the stash can hold.
    --- @param owner string|nil (Optional) The owner identifier for personal stashes.
    --- @param coords table|nil (Optional) The coordinates for the stash location.
    ---
    --- @usage
    --- ```lua
    --- -- Server-side:
    --- TriggerEvent(getScript()..":server:makeOXStash", name, label, slots, weight, owner, coords)
    --- ```
    RegisterNetEvent(getScript()..":server:makeOXStash", function(name, label, slots, weight, owner, coords)
        registerStash(name, label, slots, weight, owner, coords)
    end)
end