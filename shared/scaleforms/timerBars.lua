function createTimerHud(title, data, alpha)
    loadTextureDict("timerbars")

    local loc = vec2(0.89, 0.90)
    alpha = alpha or 255  -- Default to fully opaque if alpha is not provided

    if title then
        local x = loc.x+0.037
        local y = 0.1

        DrawSprite("timerbars", "all_black_bg", x, y, 0.12, 0.05, 0.0, 255, 255, 255, alpha)
        SetTextScale(0.80, 0.80)
        SetTextWrap(0.75, 0.985)
        SetTextJustification(2)
        SetTextFont(4)
        SetTextColour(255, 255, 255, alpha)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringKeyboardDisplay("~y~"..title)
        EndTextCommandDisplayText(x+0.06, y - 0.026)
    end

    local displayIndex = 0
    for i = #data, 1, -1 do
        local space = 0.044 * displayIndex

        DrawSprite("timerbars", "all_black_bg", loc.x+0.02, loc.y - space, 0.15, 0.04, 0.0, 255, 255, 255, alpha)
        SetTextScale(0.0, 0.35)
        SetTextWrap(0.5, 0.92)
        SetTextJustification(2)
        SetTextColour(255, 255, 255, alpha)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringKeyboardDisplay(data[i].stat:upper())
        EndTextCommandDisplayText(loc.x-0.05, (loc.y - space) - 0.0125)

        SetTextScale(0.55, 0.55)
        SetTextWrap(0.85, 0.98  - (data[i].multi and 0.026  or 0.0))
        SetTextFont(4)
        SetTextJustification(2)
        SetTextColour(255, 255, 255, alpha)
        if data[i].multi then
            local startX = 0.071
            DrawSprite("timerbars", "circle_checkpoints",
            loc.x + startX, (loc.y - space)+0.005,
            0.011, 0.018, 0.0, 255, 191, 0, 200)

            DrawSprite("timerbars", "circle_checkpoints",
            loc.x + (startX + 0.008), (loc.y - space)+0.005,
            0.011, 0.018, 0.0, 255, 191, 0, data[i].multi > 1 and 200 or 75)

            DrawSprite("timerbars", "circle_checkpoints",
            loc.x + (startX + 0.016), (loc.y - space)+0.005,
            0.011, 0.018, 0.0, 255, 191, 0, data[i].multi > 2 and 200 or 75)
        end
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringKeyboardDisplay(data[i].value)
        EndTextCommandDisplayText(loc.x - 0.02, (loc.y - space) - 0.017)
        displayIndex += 1
    end
    makeInstructionalButtons({ { text = "Exit", keys = { 194 }}})
end