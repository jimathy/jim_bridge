local activeSkillCheck = false

function skillCheck(data)
    local result = false

    if Config.System.skillCheck == "qb" then
        local Skillbar = exports["qb-minigames"]:Skillbar()
        if Skillbar then
            result = true
        else
            result = false
        end

    elseif Config.System.skillCheck == "ox" then
        local Skillbar = exports[OXLibExport]:skillCheck(
            {
                "easy",
                "easy",
                "easy"
            },
            {
                "1",
                "2",
                "3",
                "4"
            })
        if Skillbar then
            result = true
        else
            result = false
        end
    elseif Config.System.skillCheck == "gta" then
        exports.jim_bridge:skillCheck()

    elseif Config.System.skillCheck == "lation" then
        local Skillbar = exports.lation_ui:skillCheck("",
            {
                "easy",
                "easy",
                "easy"
            },
            {
                "1",
                "2",
                "3",
                "4"
            })

        if Skillbar then
            result = true
        else
            result = false
        end
    else
        result = true
    end
    return result
end