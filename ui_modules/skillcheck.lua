local activeSkillCheck = false

function gtaSkillCheck()
    if activeSkillCheck then return end
    local result = false
    local successes = 0
    local barsRequired = 3

    for bar = 1, barsRequired do
        activeSkillCheck = true
        local width, height = 0.2, 0.01
        local x, y = 0.5, 0.8

        -- Random highlighted zone
        local highlightSize = math.random(10, 20) / 100
        local highlightStart = math.random(10, 50) / 100
        local highlightEnd = highlightStart + highlightSize
        local highlightAlpha = 0
        local cursorPos = 0.0
        local cursorSpeed = 0.025
        local movingRight = true

        while activeSkillCheck do
            Wait(0)

            createScaleBars(x, y, width, height)

            local pulse = (math.sin(GetGameTimer() / 250) + 1) / 2 -- Creates a pulsing effect
            highlightAlpha = math.floor(150 + (pulse * 105)) -- Pulsing between 150 and 255 alpha

            -- Draw highlighted zone (success area) with pulsing effect
            DrawRect(x - width / 2 + (highlightStart + highlightSize / 2) * width, y, highlightSize * width, height+0.001, 93, 182, 229, highlightAlpha )
            -- Draw moving cursor
            DrawRect(x - width / 2 + cursorPos * width, y, 0.002, height + 0.01, 255, 255, 255, 255)

            -- Move cursor
            if movingRight then
                cursorPos += cursorSpeed
                if cursorPos >= 1.0 then movingRight = false end
            else
                cursorPos -= cursorSpeed
                if cursorPos <= 0.0 then movingRight = true end
            end

            if IsControlJustPressed(0, 177) then        -- Backspace to cancel
                local displayTime = GetGameTimer() + 2000
                PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', 1)
                while GetGameTimer() < displayTime do
                    Wait(0)

                    createScaleBars(x, y, width, height)

                    DrawRect(x - width / 2 + (highlightStart + highlightSize / 2) * width, y, highlightSize * width, height+0.001, 228, 52, 52, 255)
                    DrawRect(x - width / 2 + cursorPos * width, y, 0.002, height + 0.01, 255, 255, 255, 255)

                    drawSuccessText(x, y, "Failed", 228, 52, 52)
                end
                return false
            end

            -- Check for keypress (E)
            if IsControlJustPressed(0, 38) then
                activeSkillCheck = false
                result = cursorPos >= highlightStart and cursorPos <= highlightEnd
                if result then
                    PlaySoundFrontend(-1, "YES", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                else
                    PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', 1)
                end
                local displayTime = GetGameTimer() + 2000
                while GetGameTimer() < displayTime do
                    Wait(0)

                    createScaleBars(x, y, width, height)

                    -- Draw highlighted zone
                    DrawRect(x - width / 2 + (highlightStart + highlightSize / 2) * width, y, highlightSize * width, height+0.001, result and 93 or 228, result and 182 or 52, result and 229 or 52, 180)

                    -- Draw stationary cursor at result position
                    DrawRect(x - width / 2 + cursorPos * width, y, 0.002, height + 0.01, 255, 255, 255, 255)
                    -- Display result text
                    drawGTASuccessText(x, y, result and "Success" or "Failed", result and 114 or 228, result and 204 or 52, result and 144 or 52)
                end
                if result then
                    successes += 1
                else
                    return false
                end
            end
        end
    end
    activeSkillCheck = false
    print("^5GTAUI^7: ^2Skill Check Result^7: ^3" .. successes .. "^7/^3" .. barsRequired.."^7")
    return successes == barsRequired
end

function drawGTASuccessText(x, y, text, r, g, b)
    SetTextFont(8)
    SetTextScale(0.45, 0.45)
    SetTextColour(r, g, b, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y + 0.03)
end

function createScaleBars(x, y, width, height)
    -- Draw background box
    DrawSprite("timerbars", "all_black_bg", x - (width / 4) - 0.006, y, (width / 2) + 0.08, height + 0.04, 0.0, 255, 255, 255, 255)
    DrawSprite("timerbars", "all_black_bg", x + (width / 4) + 0.006, y, (width / 2) + 0.08, height + 0.04, 180.0, 255, 255, 255, 255)
    -- Draw full bar (dark background)
    DrawRect(x, y, width, height, 100, 100, 100, 255)
end

exports("skillCheck", function(...)
    if GetCurrentGameName() == "rdr3" then
        --redSkillCheck(...)
    else
        gtaSkillCheck(...)
    end
end)