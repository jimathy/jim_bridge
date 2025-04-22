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

-- EXPERIMENTAL --
-- RedM Button Prompts --
-- Creates the promot, then shows it, this needs to be run in a loop
local promptGroups = {}

function makeRedInstructionalButtons(info, title)
    if not promptGroups[title] then  -- Create group if not exists
        promptGroups[title] = {
            title = CreateVarString(10, 'LITERAL_STRING', title),
            id = GetRandomIntInRange(0, 0xffffff),
            prompts = {},
        }
        for i = 1, #info do
            promptGroups[title].prompts[i] = {
                keys = info[i].keys,
                text = info[i].text,
            }
            local keyTitle = CreateVarString(10, 'LITERAL_STRING', info[i].text)
            -- Create one prompt per entry
            local promptSet = UiPromptRegisterBegin()
            -- Register all keys for this prompt
            for k = 1, #info[i].keys do
                PromptSetControlAction(promptSet, info[i].keys[k])
            end
            PromptSetText(promptSet, keyTitle)
            PromptSetEnabled(promptSet, true)
            PromptSetVisible(promptSet, true)
            PromptSetGroup(promptSet, promptGroups[title].id)
            PromptRegisterEnd(promptSet)
        end
    end
    PromptSetActiveGroupThisFrame(promptGroups[title].id, promptGroups[title].title)
end

onResourceStop(function()
    for k, v in pairs(promptGroups) do
        print("^5Bridge^7: ^2Removing Prompt Group^7: ^3" .. k .. "^7")
        PromptDelete(promptGroups[k].id, 1)
    end
end, true)