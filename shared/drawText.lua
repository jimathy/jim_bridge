--[[
    Text Drawing Module
    ---------------------
    This module provides functions to display and hide text on screen using
    various frameworks: QB, OX, GTA, and ESX.
]]

-- Text system handlers
local textHandlers = {
    qb = {
        show = function(text, image)
            if image then
                text = '<img src="'..(radarTable[image] or "")..'" style="width:12px;height:12px">'..text
            end
            exports[QBExport]:DrawText(text, 'left')
        end,
        hide = function()
            exports[QBExport]:HideText()
        end
    },

    ox = {
        show = function(input, image, oxStyleTable)
            local inputCount = #input
            for i = 1, inputCount do
                input[i] = input[i] .. (i ~= inputCount and "   \n" or "")
            end
            lib.showTextUI(table.concat(input), {
                icon = (image and radarTable[image] or image) or nil,
                position = 'left-center',
                style = oxStyleTable
            })
        end,
        hide = function()
            lib.hideTextUI()
        end
    },

    lation = {
        show = function(input, image)
            local inputCount = #input
            for i = 1, inputCount do
                input[i] = input[i] .. (i ~= inputCount and "   \n" or "")
            end
            exports.lation_ui:showText({
                description = table.concat(input),
                keybind = nil,
                icon = (image and radarTable[image] or image) or nil,
                iconColor = '#3B82F6',
                position = 'left-center'
            })
        end,
        hide = function()
            exports.lation_ui:hideText()
        end
    },

    gta = {
        show = function(input, image, style)
            local text = ""
            for i = 1, #input do
                if input[i] ~= "" then
                    text = text .. input[i] .. "\n~s~"
                end
            end
            if image then
                text = "~BLIP_" .. image .. "~ " .. text
            end
            DisplayHelpMsg(text:gsub("%:", ":~" .. (style or "g") .. "~"))
        end,
        hide = function()
            ClearAllHelpMessages()
        end
    },

    esx = {
        show = function(text, image)
            if image then
                text = '<img src="'..(radarTable[image] or "")..'" style="width:12px;height:12px">'..text
            end
            ESX.TextUI(text, nil)
        end,
        hide = function()
            ESX.HideUI()
        end
    },

    red = {
        show = function(input)
            local text = ""
            for i = 1, #input do
                if input[i] ~= "" then
                    text = text .. input[i] .. "\n~q~"
                end
            end
            TriggerEvent("jim-redui:DrawText", text)
        end,
        hide = function()
            TriggerEvent("jim-redui:HideText")
        end
    }
}

--- Displays text on the screen using the configured draw text system.
---
--- Depending on Config.System.drawText, this function will use different methods to
--- display text along with optional images/icons.
---
--- @param image string|nil Optional image/icon identifier to display with the text.
--- @param input table An array of strings; each string is a line of text to display.
--- @param style string|nil Optional style code for default GTA popups (e.g., "~g~" for green).
--- @param oxStyleTable table|nil Optional table specifying style parameters for the OX text UI.
---
---@usage
--- ```lua
--- drawText("img_link", { "Test line 1", "Test Line 2" }, "~g~")
--- ```
function drawText(image, input, style, oxStyleTable)
    if not radarTable then radarTable = {} end

    local systemType = Config.System.drawText
    local handler = textHandlers[systemType]

    if not handler then return end

    if systemType == "qb" or systemType == "esx" then
        -- Concatenate lines for QB/ESX system with HTML line breaks.
        local text = ""
        for i = 1, #input do
            text = text .. input[i] .. "</span>" .. (input[i + 1] and "<br>" or "")
        end
        text = text:gsub("%:", ":<span style='color:yellow'>")
        handler.show(text, image)

    elseif systemType == "ox" then
        handler.show(input, image, oxStyleTable)

    elseif systemType == "lation" then
        handler.show(input, image)

    elseif systemType == "gta" then
        handler.show(input, image, style)

    elseif systemType == "red" then
        handler.show(input)
    end
end

--- Hides any text currently displayed on the screen.
---
--- Clears the text using the appropriate method for the configured draw text system.
---
---	@usage
--- ```lua
--- hideText()
--- ```
function hideText()
    local handler = textHandlers[Config.System.drawText]
    if handler and handler.hide then
        handler.hide()
    end
end