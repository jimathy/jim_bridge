
--- Displays debug information on the player's screen.
---
--- This function renders a semi-transparent box with multiple lines of text for debugging purposes.
--- It is controlled by the `debugMode` flag and can be positioned dynamically on the screen.
---
--- @param textTable table A table containing strings to display.
--- @param loc vector2|nil Optional. The screen position to display the debug box. Defaults to `vec2(0.05, 0.65)`.
---
--- @usage
--- ```lua
--- debugScaleForm({
---     "Player Position: X=123.45 Y=678.90 Z=12.34",
---     "Current Action: Running",
--- })
--- ```
function debugScaleForm(textTable, loc)
    if debugMode then
        -- Define the display position (top left corner)
        local loc = loc or vec2(0.05, 0.65)

        -- Calculate dynamic height based on the number of lines in the textTable
        local lineHeight = 0.025  -- Height of each line of text
        local totalHeight = #textTable * lineHeight  -- Dynamic height based on number of lines
        local boxPadding = 0.01  -- Padding to add around the text inside the box
        local size = vec2(0.18, totalHeight + boxPadding * 2)  -- Width remains fixed, height is dynamic

        DrawRect(loc.x + size.x / 2, loc.y + size.y / 2, size.x, size.y, 0, 0, 0, 255)

        for i = 1, #textTable do
            local textLine = textTable[i]

            SetTextScale(0.30, 0.30)

            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringKeyboardDisplay(textLine)

            EndTextCommandDisplayText(loc.x + 0.005, loc.y + (i - 1) * lineHeight + 0.01)
        end
    end
end
