--[[
    Text Drawing Module
    ---------------------
    This module provides functions to display and hide text on screen using
    various frameworks: QB, OX, GTA, and ESX.
]]

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
    local text = ""
    if not radarTable then radarTable = {} end
    if Config.System.drawText == "qb" then
        -- Concatenate lines for QB system with HTML line breaks.
        for i = 1, #input do
            text = text..input[i].."</span>"..(input[i + 1] and "<br>" or "")
        end
        text = text:gsub("%:", ":<span style='color:yellow'>")
        if image then
            text = '<img src="'..(radarTable[image] or "")..'" style="width:12px;height:12px">'..text
        end
        exports[QBExport]:DrawText(text, 'left')

    elseif Config.System.drawText == "ox" then
        -- Append newline spacing to each input line.
        for k, v in pairs(input) do
            input[k] = v.."   \n"
        end
        lib.showTextUI(table.concat(input), { icon = (image and radarTable[image] or image) or nil, position = 'left-center', style = oxStyleTable })

    elseif Config.System.drawText == "gta" then
        -- Concatenate input lines and apply GTA style formatting.
        for i = 1, #input do
            if input[i] ~= "" then
                text = text..input[i].."\n~s~"
            end
        end
        if image then
            text = "~BLIP_"..image.."~ "..text
        end
        DisplayHelpMsg(text:gsub("%:", ":~"..(style or "g").."~"))

    elseif Config.System.drawText == "esx" then
        -- ESX-based text UI uses similar HTML formatting as QB.
        for i = 1, #input do
            text = text..input[i].."</span>"..(input[i + 1] and "<br>" or "")
        end
        text = text:gsub("%:", ":<span style='color:yellow'>")
        if image then
            text = '<img src="'..(radarTable[image] or "")..'" style="width:12px;height:12px">'..text
        end
        ESX.TextUI(text, nil)

    elseif Config.System.drawText == "red" then
        -- Concatenate input lines and apply GTA style formatting.
        for i = 1, #input do
            if input[i] ~= "" then
                text = text..input[i].."\n~q~"
            end
        end
        TriggerEvent("jim-redui:DrawText", text)

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
    if Config.System.drawText == "qb" then
        exports[QBExport]:HideText()
    elseif Config.System.drawText == "ox" then
        lib.hideTextUI()
    elseif Config.System.drawText == "gta" then
        ClearAllHelpMessages()
    elseif Config.System.drawText == "esx" then
        ESX.HideUI()
    elseif Config.System.drawText == "red" then
        TriggerEvent("jim-redui:HideText")
    end
end