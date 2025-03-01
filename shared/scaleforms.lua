function makeInstructionalButtons(info)
    local build = RequestScaleformMovie("instructional_buttons")
    while not HasScaleformMovieLoaded(build) do Wait(0) end

    DrawScaleformMovieFullscreen(build, 255, 255, 255, 0, 0)
    BeginScaleformMovieMethod(build, "CLEAR_ALL")
    EndScaleformMovieMethod()
    BeginScaleformMovieMethod(build, "SET_CLEAR_SPACE")
    ScaleformMovieMethodAddParamInt(200)
    EndScaleformMovieMethod()

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

    BeginScaleformMovieMethod(build, "DRAW_INSTRUCTIONAL_BUTTONS")
    EndScaleformMovieMethod()
    BeginScaleformMovieMethod(build, "SET_BACKGROUND_COLOUR")
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(80)
    EndScaleformMovieMethod()

    DrawScaleformMovieFullscreen(build, 255, 255, 255, 255, 0)
end

-- Testing showing variables on the screen instead of only in f8
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