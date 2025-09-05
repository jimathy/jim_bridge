local skillCheckFunc = {
    qb = {
        start = function(data)
            local Skillbar = exports["qb-minigames"]:Skillbar()
            if Skillbar then
                return true
            else
                return false
            end
        end,
    },
    ox = {
        start = function(data)
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
                }
            )
            if Skillbar then
                return true
            else
                return false
            end
        end,
    },
    gta = {
        start = function(data)
            local Skillbar = exports.jim_bridge:skillCheck()
            if Skillbar then
                return true
            else
                return false
            end
        end,
    },
    lation = {
        start = function(data)
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
                return true
            else
                return false
            end
        end,
    },

}

function skillCheck(data)
    if Config.System.skillCheck then
        return skillCheckFunc[Config.System.skillCheck].start(data)
    end
    return true
end