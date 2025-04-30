--[[
    Phone Mails Module
    ------------------
    This module handles sending phone mails using different phone systems.
    Supported systems include:
      - gksphone
      - yflip-phone
      - qs-smartphone
      - qs-smartphone-pro
      - roadphone
      - lb-phone
      - qb-phone
      - jpr-phonesystem
]]

--- Sends a phone mail using the detected phone system.
--- The function iterates through a prioritized list of supported phone systems.
--- Once an active system is found (via `isStarted`), the corresponding mail function is executed.
---
--- @param data table A table containing the mail data.
---   - subject (string): The email subject.
---   - sender (string): The sender identifier.
---   - message (string): The email body content.
---   - actions (table|nil): Optional action buttons for the email.
--- @usage
--- sendPhoneMail({
---     subject = "Welcome!",
---     sender = "Admin",
---     message = "Thank you for joining our server.",
---     actions = {
---         { label = "Reply", action = replyFunction }
---     }
--- })
function sendPhoneMail(data)
    -- Define each supported phone system and its corresponding mail-sending function.
    local phoneSystems = {
        {   name = "gksphone",
            send = function(mailData)
                exports["gksphone"]:SendNewMail(mailData)
            end,
        },
        {   name = "yflip-phone",
            send = function(mailData)
                TriggerServerEvent(getScript()..":yflip:SendMail", mailData)
            end,
        },
        {   name = "qs-smartphone",
            send = function(mailData)
                TriggerServerEvent('qs-smartphone:server:sendNewMail', mailData)
            end,
        },
        {   name = "qs-smartphone-pro",
            send = function(mailData)
                TriggerServerEvent('phone:sendNewMail', mailData)
            end,
        },
        {   name = "roadphone",
            send = function(mailData)
                -- Convert HTML line breaks to newlines for roadphone.
                mailData.message = mailData.message:gsub("%<br>", "\n")
                exports["roadphone"]:sendMail(mailData)
            end,
        },
        {   name = "lb-phone",
            send = function(mailData)
                -- Convert HTML line breaks to newlines for lb-phone.
                mailData.message = mailData.message:gsub("%<br>", "\n")
                TriggerServerEvent(getScript()..":lbphone:SendMail", mailData)
            end,
        },
        {   name = "qb-phone",
            send = function(mailData)
                TriggerServerEvent('qb-phone:server:sendNewMail', mailData)
            end,
        },
        {   name = "jpr-phonesystem",
            send = function(mailData)
                TriggerServerEvent(getScript()..":jpr:SendMail", mailData)
            end,
        },
        {   name = "ef-phone",
            send = function(mailData)
                TriggerServerEvent('qb-phone:server:sendNewMail', mailData)
            end,
        },
    }

    local activePhone = nil
    -- Check each phone system in order and use the first active one.
    for _, phone in ipairs(phoneSystems) do
        if isStarted(phone.name) then
            activePhone = phone.name
            phone.send(data)
            break
        end
    end

    if activePhone then
        debugPrint("^6Bridge^7[^3"..activePhone.."^7]: ^2Sending mail to player")
    else
        print("^6Bridge^7: ^1ERROR ^2Sending mail to player ^7- ^2No supported phone found")
    end
end

-------------------------------------------------------------
-- Phone System Event Handlers
-------------------------------------------------------------

--- Handles sending mail for lb-phone.
--- Listens for the `lbphone:SendMail` event and sends an email using lb-phone's API.
---
--- @event lbphone:SendMail
--- @param data table The mail data.
---   - subject (string): The email subject.
---   - message (string): The email content.
---   - buttons (table|nil): Optional action buttons (mapped from data.actions if present).
RegisterNetEvent(getScript()..":lbphone:SendMail", function(data)
    local src = source
    local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(src)
    local emailAddress = exports["lb-phone"]:GetEmailAddress(phoneNumber)
    -- Map actions to buttons if provided.
    data.buttons = data.actions or data.buttons

    exports["lb-phone"]:SendMail({
        to = emailAddress,
        subject = data.subject,
        message = data.message,
        actions = data.buttons,
    })
end)

--- Handles sending mail for yflip-phone.
--- Listens for the `yflip:SendMail` event and sends an email using yflip-phone's API.
---
--- @event yflip:SendMail
--- @param data table The mail data.
---   - subject (string): The email subject.
---   - sender (string): The sender identifier.
---   - message (string): The email content.
---   - buttons (table|nil): Optional action buttons.
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
--- Listens for the `jpr:SendMail` event and sends an email using jpr-phonesystem's API.
---
--- @event jpr:SendMail
--- @param data table The mail data.
---   - subject (string): The email subject.
---   - sender (string): The sender identifier.
---   - message (string): The email content.
---   - buttons (table|nil): Optional action buttons.
RegisterNetEvent(getScript()..":jpr:SendMail", function(data)
    local src = source
    local Player = Core.Functions.GetPlayer(src)
    TriggerEvent('jpr-phonesystem:server:sendEmail', {
        Assunto = data.subject,                     -- Email subject
        Conteudo = data.message,                    -- Email content
        Enviado = data.sender,                      -- Sender information
        Destinatario = Player.PlayerData.citizenid, -- Recipient identifier
        Event = {},                                 -- Optional event details
    })
end)