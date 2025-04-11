--[[
    Input Dialog Module
    ---------------------
    This module provides a function to create a simple input dialog compatible with
    multiple menu systems (OX, QB, GTA/WarMenu, and ESX). It supports various input
    types such as radio buttons, numbers, text, and select dropdowns.

]]

--- Creates a simple input dialog using the configured menu system.
---
--- @param title string The title or header of the input dialog.
--- @param opts table A table of input option definitions. Each option should include:
---     - type (string): The input type ("radio", "number", "text", "select").
---     - label (string, optional): A label for the input (used in radio/select for OX).
---     - text (string, optional): The text prompt for the input.
---     - name (string): The identifier for the input.
---     - isRequired (boolean, optional): Whether input is mandatory.
---     - default (any, optional): The default value.
---     - options (table, optional): A table of choices for "radio" and "select" types.
---     - min (number, optional): Minimum value (for "number" and "select").
---     - max (number, optional): Maximum value.
---     - txt (string, optional): Additional description.
---
--- @return table|nil table Returns the user's input as a table if submitted, otherwise nil.
---
---@usage
--- ```lua
--- local userInput = createInput("Enter Details", {
---     { type = "text", text = "Name", name = "playerName", isRequired = true },
---     { type = "number", text = "Age", name = "playerAge", min = 18, max = 99 },
---     { type = "radio", label = "Gender", name = "playerGender", options = {
---         { text = "Male", value = "male" },
---         { text = "Female", value = "female" },
---         { text = "Other", value = "other" },
---     }},
--- })
--- ```
function createInput(title, opts)
    local dialog = nil
    local options = {}
    local currentNum = 0
    if Config.System.Menu == "ox" then
        for i = 1, #opts do
            currentNum += 1
            if opts[i] == nil then currentNum -= 1 goto skip end
            if opts[i].type == "radio" then
                -- Convert radio options to select type for OX
                for k in pairs(opts[i].options) do
                    opts[i].options[k].label = opts[i].options[k].text
                end
                options[currentNum] = {
                    type = "select",
                    isRequired = opts[i].isRequired,
                    label = opts[i].label or opts[i].text,
                    name = opts[i].name,
                    default = opts[i].default or opts[i].options[1].value,
                    options = opts[i].options,
                }
            end
            if opts[i].type == "number" then
                options[currentNum] = {
                    type = opts[i].type,
                    label = (opts[i].label or opts[i].text)..(opts[i].txt and " - "..opts[i].txt or ""),
                    isRequired = opts[i].isRequired,
                    name = opts[i].name,
                    options = opts[i].options,
                }
            end
            if opts[i].type == "text" then
                options[currentNum] = {
                    type = "input",
                    label = opts[i].text..(opts[i].txt and " - "..opts[i].txt or ""),
                    default = opts[i].default,
                    isRequired = opts[i].isRequired,
                }
            end
            if opts[i].type == "select" then
                options[currentNum] = {
                    type = opts[i].type,
                    label = opts[i].text..(opts[i].txt and " - "..opts[i].txt or ""),
                    isRequired = opts[i].isRequired,
                    name = opts[i].name,
                    options = opts[i].options,
                    min = opts[i].min,
                    max = opts[i].max,
                    default = opts[i].default,
                }
            end

            if opts[i].type == "checkbox" then
                jsonPrint(opts[i])
                for k in pairs(opts[i].options) do
                    if options[currentNum] then currentNum += 1 end
                    options[currentNum] = {
                        type = opts[i].type,
                        label = opts[i].options[k].text..(opts[i].txt and " - "..opts[i].txt or ""),
                        name = opts[i].options[k].value,
                    }

                end
            end

            if opts[i].type == "color" then
                options[currentNum] = {
                    type = opts[i].type,
                    label = opts[i].label,
                    isRequired = opts[i].isRequired,
                    format = opts[i].format,
                    default = opts[i].default,
                }
            end
            if opts[i].type == "slider" then
                options[currentNum] = {
                    type = opts[i].type,
                    label = opts[i].label,
                    isRequired = opts[i].required,
                    min = opts[i].min,
                    max = opts[i].max,
                    default = opts[i].default,
                }
            end
            ::skip::
        end
        dialog = exports[OXLibExport]:inputDialog(title, options)
        return dialog
    elseif Config.System.Menu == "qb" then
        for k, v in pairs(opts) do
            currentNum += 1
            if opts[k] == nil then
                currentNum -= 1
            else
                options[currentNum] = opts[k]
            end
        end
        dialog = exports['qb-input']:ShowInput(
            { header = title, submitText = "Accept", inputs = options }
        )
        return dialog

    elseif Config.System.Menu == "gta" then
        WarMenu.CreateMenu(tostring(opts),
            title,
            " ",
            {
                titleColor = { 222, 255, 255 },
                maxOptionCountOnScreen = 15,
                width = 0.25,
                x = 0.7,
            })
        if WarMenu.IsAnyMenuOpened() then return end
        WarMenu.OpenMenu(tostring(opts))

        local close = true
        local _comboBoxItems = {}
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
    elseif Config.System.Menu == "esx" then -- horrible input dialog, not even worth using, get OX

        local results = {}
        for i, opt in ipairs(opts) do
            local prompt = opt.text or opt.label or "Enter value"
            -- For radio/select types, append available options in the prompt.
            if (opt.type == "radio" or opt.type == "select") and opt.options then
                local choices = ""
                for j, choice in ipairs(opt.options) do
                    choices = choices .. choice.text .. " (" .. tostring(choice.value) .. ")"
                    if j < #opt.options then choices = choices .. ", " end
                end
                prompt = prompt .. " [" .. choices .. "]"
            elseif opt.type == "number" then
                prompt = prompt .. " (number between " .. (opt.min or 0) .. " and " .. (opt.max or 100) .. ")"
            end

            local value = nil
            ESX.UI.Menu.Open('dialog', getScript(), 'input_' .. i, {
                title = prompt
            }, function(data, menu)
                value = data.value
                menu.close()
            end, function(data, menu)
                menu.close()
            end)

            -- Wait until the player submits a value.
            while value == nil do
                Wait(0)
            end

            -- Convert to a number if needed.
            if opt.type == "number" then
                value = tonumber(value)
            end
            results[opt.name or i] = value
        end
        return results
    end
end