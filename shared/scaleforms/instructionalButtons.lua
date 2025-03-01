--- Creates instructional buttons using the detected polyzone library (ox_lib or PolyZone).
---
--- This function generates instructional buttons on the player's screen based on the provided information.
--- It supports different polyzone libraries by automatically detecting which one is active.
---
---@param info table A table containing the instructional buttons configuration.
--- - **keys** (`table`): A list of control keys to display.
--- - **text** (`string`): The description text for the buttons.
---
---@usage
--- ```lua
--- makeInstructionalButtons({
---     { keys = { 38 }, text = "Interact" },
---     { keys = { 47 }, text = "Pick Up" },
--- })
--- ```
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