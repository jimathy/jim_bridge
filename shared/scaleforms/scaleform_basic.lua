--[[
    Instructional Buttons & Debug Text Module
    -------------------------------------------
    This module provides functions for:
      • Displaying instructional buttons on-screen via a scaleform movie.
      • Drawing debug text with a background rectangle when debugMode is enabled.
      • Rendering 3D text in the world.
      • Displaying help messages and spinners.
]]

-------------------------------------------------------------
-- Instructional Buttons Functionality
-------------------------------------------------------------

--- Loads and draws instructional buttons on-screen using a scaleform movie.
---
--- Requests the "instructional_buttons" scaleform, clears previous data, sets clear space,
--- creates data slots for each button option provided in `info`, and then draws the scaleform fullscreen.
---
--- @param info table An array of tables, where each table represents a button option:
---     - keys (table): An array of key codes (e.g., {38, 29}) to display.
---     - text (string): The label for the button.
---
--- @usage
--- ```lua
---CreateThread(function()
---    while true do
---         makeInstructionalButtons({
---             { keys = {38, 29}, text = "Open Menu" },
---             { keys = {45}, text = "Close Menu" }
---         })
---         Wait(0)
---    end
---end)
--- ```
function makeInstructionalButtons(info)
    local build = RequestScaleformMovie("instructional_buttons")
    while not HasScaleformMovieLoaded(build) do Wait(0) end

    -- Draw the scaleform fullscreen (initial draw).
    DrawScaleformMovieFullscreen(build, 255, 255, 255, 0, 0)

    -- Clear previous instructions.
    BeginScaleformMovieMethod(build, "CLEAR_ALL")
    EndScaleformMovieMethod()

    -- Set clear spacing between buttons.
    BeginScaleformMovieMethod(build, "SET_CLEAR_SPACE")
    ScaleformMovieMethodAddParamInt(200)
    EndScaleformMovieMethod()

    -- Add each button option to the scaleform.
    for i = 1, #info do
        BeginScaleformMovieMethod(build, "SET_DATA_SLOT")
        ScaleformMovieMethodAddParamInt(i - 1)
        for k = 1, #info[i].keys do
            ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(2, info[i].keys[k], true))
        end
        BeginTextCommandScaleformString("STRING")
        AddTextComponentSubstringKeyboardDisplay(info[i].text)
        EndTextCommandScaleformString()
        EndScaleformMovieMethod()
    end

    -- Draw the instructional buttons.
    BeginScaleformMovieMethod(build, "DRAW_INSTRUCTIONAL_BUTTONS")
    EndScaleformMovieMethod()

    -- Set a translucent black background.
    BeginScaleformMovieMethod(build, "SET_BACKGROUND_COLOUR")
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(80)
    EndScaleformMovieMethod()

    -- Final full-screen draw with full opacity.
    DrawScaleformMovieFullscreen(build, 255, 255, 255, 255, 0)
end

-------------------------------------------------------------
-- Debug Text Display Functionality
-------------------------------------------------------------

--- Draws debug text on the screen if debugMode is enabled.
---
--- Calculates a background rectangle based on the number of text lines and renders each line on-screen.
---
--- @param textTable table An array of strings to display.
--- @param loc vector2 (Optional) Top-left coordinate for the text box (default: vec2(0.05, 0.65)).
---
--- @usage
--- ```lua
---CreateThread(function()
---    while true do
---         debugScaleForm(
---             {
---                 "Line 1: Debug info",
---                 "Line 2: More info"
---             }
---         )
---         Wait(0)
---    end
---end)
--- ```
function debugScaleForm(textTable, loc)
    if debugMode then
        loc = loc or vec2(0.05, 0.65)

        local lineHeight = 0.025        -- Height per line.
        local totalHeight = #textTable * lineHeight
        local boxPadding = 0.01         -- Padding around the text.
        local size = vec2(0.18, totalHeight + boxPadding * 2)

        -- Draw background rectangle.
        DrawRect(loc.x + size.x / 2, loc.y + size.y / 2, size.x, size.y, 0, 0, 0, 255)

        -- Render each line of text.
        for i = 1, #textTable do
            SetTextScale(0.30, 0.30)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringKeyboardDisplay(textTable[i])
            EndTextCommandDisplayText(loc.x + 0.005, loc.y + (i - 1) * lineHeight + 0.01)
        end
    end
end

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