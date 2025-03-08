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
---     while true do
---         debugScaleForm({
---             "Line 1: Debug info",
---             "Line 2: More info"
---         })
---         Wait(0)
---     end
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