-------------------------------------------------------------
-- 3D Text Rendering
-------------------------------------------------------------

--- Draws 3D text at specified world coordinates.
---
--- Configures text properties, draws the text, and displays a background rectangle behind it.
---
--- @param coord table A vector3 with x, y, and z coordinates.
--- @param text string The text to display.
--- @param highlight boolean (Optional) If true, highlights parts of the text.
---
--- @usage
--- ```lua
--- CreateThread(function()
---     while true do
---         DrawText3D(vector3(100, 200, 300), "Hello World", true)
---         Wait(0)
---     end
--- end)
--- ```
function DrawText3D(coord, text, highlight)
    SetTextScale(0.30, 0.30)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)

    local totalLength = string.len(text)
    local textMaxLength = 99 -- max 99
    local text = totalLength > textMaxLength and text:sub(1, totalLength - (totalLength - textMaxLength)) or text
    AddTextComponentString(highlight and text:gsub("%~w~", "~y~") or text)
    SetDrawOrigin(coord.x, coord.y, coord.z, 0)
    DrawText(0.0, 0.0)
    local count, length = GetLineCountAndMaxLength(text)

    local padding = 0.005
    local heightFactor = (count / 43) + padding
    local weightFactor = (length / 150) + padding

    local height = (heightFactor / 2) - padding / 1
    local width = (weightFactor / 2) - padding / 1

    DrawRect(0.0, height, width, heightFactor, 0, 0, 0, 150)
    ClearDrawOrigin()
end

--- Calculates the number of lines and the maximum line length from the given text.
---
--- @param text string The text to analyze.
--- @return number, number The line count and maximum line length.
---
--- @usage
--- ```lua
--- local count, maxLen = GetLineCountAndMaxLength("Hello World")
--- ```
function GetLineCountAndMaxLength(text)
    local lineCount, maxLength = 0, 0
    for line in text:gmatch("[^\n]+") do
        lineCount += 1
        local lineLength = string.len(line)
        if lineLength > maxLength then
            maxLength = lineLength
        end
    end
    if lineCount == 0 then lineCount = 1 end
    return lineCount, maxLength
end

-------------------------------------------------------------
-- Additional UI Helpers
-------------------------------------------------------------

--- Displays a help message on the screen.
---
--- @param text string The message to display.
---
--- @usage
--- ```lua
--- DisplayHelpMsg("Press E to interact")
--- ```
function DisplayHelpMsg(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandDisplayHelp(0, true, false, -1)
end

--- Displays a "Saving/Loading" spinner with a custom message.
---
--- @param text string The message to display alongside the spinner.
---
--- @usage
--- ```lua
--- displaySpinner("Saving data...")
--- ```
function displaySpinner(text)
    BeginTextCommandBusyspinnerOn('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandBusyspinnerOn(4)
end

--- Stops the "Saving/Loading" spinner.
---
--- This function should only be called client-side.
---
--- @usage
--- ```lua
--- stopSpinner()
--- ```
function stopSpinner()
    if not isServer() then
        BusyspinnerOff()
    end
end