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

local phoneFunc = {
    {   phone = "gksphone",
        sendMail = function(mailData)
            exports["gksphone"]:SendNewMail(mailData)
        end,
        sendInvoice =
            function(mailData)
                -- Defensive check for required fields
                local required = { "billedCitizenid", "amount", "job", "name", "billerCitizenid", "label" }
                for _, field in ipairs(required) do
                    if mailData[field] == nil then
                        print("^1[jim-payments] ERROR:^0 Missing field '" .. field .. "' in mailData")
                        return
                    end
                end

                MySQL.Async.execute(
                    'INSERT INTO gksphone_invoices (citizenid, amount, society, sender, sendercitizenid, label) VALUES (@citizenid, @amount, @society, @sender, @sendercitizenid, @label)',
                    {
                        ['@citizenid'] = mailData.billedCitizenid,
                        ['@amount'] = mailData.amount,
                        ['@society'] = mailData.job,
                        ['@sender'] = mailData.name,
                        ['@sendercitizenid'] = mailData.billerCitizenid,
                        ['@label'] = mailData.label
                    }
                )
            end,
    },
    {   name = "yflip-phone",
        sendMail =
            function(mailData)
                TriggerServerEvent(getScript()..":yflip:SendMail", mailData)
            end,
    },
    {   name = "qs-smartphone",
        sendMail =
            function(mailData)
                TriggerServerEvent('qs-smartphone:server:sendNewMail', mailData)
            end,
    },
    {   name = "qs-smartphone-pro",
        sendMail =
            function(mailData)
                TriggerServerEvent('phone:sendNewMail', mailData)
            end,
    },
    {   name = "roadphone",
        sendMail =
            function(mailData)
                -- Convert HTML line breaks to newlines for roadphone.
                mailData.message = mailData.message:gsub("%<br>", "\n")
                exports["roadphone"]:sendMail(mailData)
            end,
    },
    {   name = "lb-phone",
        sendMail =
            function(mailData)
                -- Convert HTML line breaks to newlines for lb-phone.
                mailData.message = mailData.message:gsub("%<br>", "\n")
                TriggerServerEvent(getScript()..":lbphone:SendMail", mailData)
            end,
    },
    {   name = "qb-phone",
        sendMail =
            function(mailData)
                TriggerServerEvent('qb-phone:server:sendNewMail', mailData)
            end,
        sendInvoice =
            function(mailData)
                -- Defensive check for required fields
                local required = { "billedCitizenid", "amount", "job", "name", "billerCitizenid", "src" }
                for _, field in ipairs(required) do
                    if mailData[field] == nil then
                        print("^1[jim-payments] ERROR:^0 Missing field '" .. field .. "' in mailData")
                        return
                    end
                end

                -- Safe insert with all parameters present
                MySQL.Async.insert(
                    'INSERT INTO phone_invoices (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
                    {
                        mailData.billedCitizenid,
                        mailData.amount,
                        mailData.job,
                        mailData.name,
                        mailData.billerCitizenid
                    },
                    function(id)
                        if id then
                            TriggerClientEvent('qb-phone:client:AcceptorDenyInvoice', mailData.src, id, mailData.name, mailData.job, mailData.billerCitizenid, mailData.amount, GetInvokingResource())
                        end
                    end
                )
                TriggerClientEvent('qb-phone:RefreshPhone', mailData.src)
            end,
    },
    {   name = "npwd_qbx_mail",
        sendMail =
            function(mailData)
                TriggerServerEvent('qb-phone:server:sendNewMail', mailData)
            end,
    },
    {   name = "jpr-phonesystem",
        sendMail =
            function(mailData)
                TriggerServerEvent(getScript()..":jpr:SendMail", mailData)
            end,
    },
    {   name = "ef-phone",
        sendMail =
            function(mailData)
                TriggerServerEvent('qb-phone:server:sendNewMail', mailData)
            end,
    },

}


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
function sendPhoneMail(mailData)
    -- Check each phone system in order and use the first active one.
    for i = 1, #phoneFunc do
        local script = phoneFunc[i]
        if isStarted(script.phone) and script.sendMail then
            debugPrint("^6Bridge^7[^3"..script.phone.."^7]: ^2Sending mail to player")
            script.sendMail(mailData)
            return true
        end
    end
    print("^6Bridge^7: ^1ERROR ^2Sending mail to player ^7- ^2No supported phone found")
    return false
end

function sendPhoneInvoice(data)
    if not data.src then return end

    -- Check each phone system in order and use the first active one.

    for i = 1, #phoneFunc do
        local script = phoneFunc[i]
        if isStarted(script.phone) and script.sendInvoice then
            debugPrint("^6Bridge^7[^3"..script.phone.."^7]: ^2Sending mail to player^7", data.src)
            script.sendInvoice(data)
            return true
        end
    end
    print("^6Bridge^7: ^1ERROR ^2Sending mail to player ^7- ^2No supported phone found")
    return false
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