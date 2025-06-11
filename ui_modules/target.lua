-- Global Key Table, defined once.
---
local KEY_TABLE = { 38, 29, 47, 23, 45, 159, 162, 163 }

-- Mapping of key codes to human-readable key names.
local Keys = {
    [322] = "ESC", [288] = "F1", [289] = "F2", [170] = "F3", [166] = "F5",
    [167] = "F6", [168] = "F7", [169] = "F8", [56] = "F9", [57] = "F10",
    [243] = "~", [157] = "1", [158] = "2", [160] = "3", [164] = "4", [165] = "5",
    [159] = "6", [161] = "7", [162] = "8", [163] = "9", [84] = "-", [83] = "=",
    [177] = "BACKSPACE", [37] = "TAB",
    [44] = "Q", [32] = "W", [38] = "E", [45] = "R", [245] = "T", [246] = "Y",
    [303] = "U", [199] = "P",
    [39] = "[",  [40] = "]", [18] = "ENTER", [137] = "CAPS",
    [34] = "A", [8] = "S", [9] = "D", [23] = "F", [47] = "G",
    [74] = "H", [311] = "K", [182] = "L", [21] = "LEFTSHIFT",
    [20] = "Z", [73] = "X", [26] = "C", [0] = "V",  [29] = "B", [249] = "N",
    [244] = "M", [82] = ",", [81] = "."
}
-- Tables for storing created targets.
local TextTargets    = {}   -- For fallback DrawText3D targets.
local targetEntities = {}   -- For entity targets.

function createEntityTarget(entity, opts, dist)
    startTargetLoop()
    targetEntities[#targetEntities + 1] = entity
    local entityCoords = GetEntityCoords(entity)

    local existingTarget = nil
    for _, target in pairs(TextTargets) do
        if #(target.coords - entityCoords) < 0.01 then
            existingTarget = target
            break
        end
    end

    if existingTarget then
        for i = 1, #opts do
            local key = KEY_TABLE[#existingTarget.options + i]
            opts[i].key = key
            existingTarget.buttontext[#existingTarget.buttontext + 1] = " ~b~[~w~" .. Keys[key] .. "~b~] ~w~" .. opts[i].label
            existingTarget.options[#existingTarget.options + 1] = opts[i]
        end
        updateCachedText(existingTarget)
    else
        local tempText = {}
        for i = 1, #opts do
            opts[i].key = KEY_TABLE[i]
            tempText[#tempText + 1] = " ~b~[~w~" .. Keys[opts[i].key] .. "~b~] ~w~" .. opts[i].label
        end
        TextTargets[entity] = {
            coords = vec3(entityCoords.x, entityCoords.y, entityCoords.z),
            buttontext = tempText,
            options = opts,
            dist = dist,
            text = table.concat(tempText, "\n")
        }
    end
end

function createZoneTarget(data, opts, dist)
    startTargetLoop()
    local existingTarget = nil
    for _, target in pairs(TextTargets) do
        if #(target.coords - data[2]) < 0.01 then
            existingTarget = target
            break
        end
    end

    if existingTarget then
        for i = 1, #opts do
            local key = KEY_TABLE[#existingTarget.options + i]
            opts[i].key = key
            existingTarget.buttontext[#existingTarget.buttontext + 1] = " ~b~[~w~" .. Keys[key] .. "~b~] ~w~" .. opts[i].label
            existingTarget.options[#existingTarget.options + 1] = opts[i]
        end
        updateCachedText(existingTarget)
    else
        local tempText = {}
        for i = 1, #opts do
            opts[i].key = KEY_TABLE[i]
            tempText[#tempText + 1] = " ~b~[~w~" .. Keys[opts[i].key] .. "~b~] ~w~" .. opts[i].label
        end
        TextTargets[data[1]] = {
            coords = data[2],
            buttontext = tempText,
            options = opts,
            dist = dist,
            text = table.concat(tempText, "\n")
        }
    end
    return data[1]
end

function createModelTarget(models, opts, dist)
    startTargetLoop()
    if type(models) ~= "table" then
        models = { models }
    end

    local tempText = {}
    for i = 1, #opts do
        opts[i].key = KEY_TABLE[i]
        tempText[#tempText + 1] = " ~b~[~w~" .. Keys[opts[i].key] .. "~b~] ~w~" .. opts[i].label
    end

    local keyStr = ""
    for i, m in ipairs(models) do
        keyStr = keyStr .. tostring(m) .. (i < #models and "_" or "")
    end
    local targetKey = "model_" .. keyStr

    TextTargets[targetKey] = {
        models = models,
        buttontext = tempText,
        options = opts,
        dist = dist,
        coords = vec3(0, 0, 0),
        text = table.concat(tempText, "\n")
    }

    return targetKey
end

function removeEntityTarget(entity)
    TextTargets[entity] = nil
end

function removeZoneTarget(target)
    TextTargets[target] = nil
end

function removeModelTarget(model)
    TextTargets[model] = nil
end

exports("createEntityTarget", createEntityTarget)
exports("createZoneTarget", createZoneTarget)
exports("createModelTarget", createModelTarget)

exports("removeEntityTarget", removeEntityTarget)
exports("removeZoneTarget", removeZoneTarget)
exports("removeModelTarget", removeModelTarget)


-------------------------------------------------------------
-- Fallback: DrawText3D Targets (Experimental)
-------------------------------------------------------------
local started = false
function startTargetLoop()
    if started then return end
    Config = {
        System = {

        }
    }
    started = true
    local fileLoader = assert(load(LoadResourceFile("jim_bridge", ('starter.lua')), ('@@jim_bridge/starter.lua')))
    fileLoader()
    -- Model Entity Refresher
    CreateThread(function()
        while true do
            local pedCoords = GetEntityCoords(PlayerPedId())
            for _, target in pairs(TextTargets) do
                if target.models then
                    for _, model in ipairs(target.models) do
                        local entity = GetClosestObjectOfType(pedCoords.x, pedCoords.y, pedCoords.z, target.dist, model, false, false, false)
                        if entity and entity ~= 0 then
                            target.entity = entity
                            target.coords = GetEntityCoords(entity)
                            break
                        end
                    end
                end
            end
            Wait(3000) -- Refresh every 3s
        end
    end)

    -- Main Target Loop
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local camForward = RotationToDirection(camRot)

            local closestTarget, closestDist, targetEntity = nil, math.huge, nil

            for _, target in pairs(TextTargets) do
                local coords = target.coords
                if coords then
                    local dist = #(pedCoords - coords)
                    if dist <= target.dist then
                        local normVec = normalizeVector(coords - camCoords)
                        local dot = camForward.x * normVec.x + camForward.y * normVec.y + camForward.z * normVec.z

                        if dot > 0.5 and dist < closestDist then
                            closestTarget = target
                            closestDist = dist
                            targetEntity = target.entity
                        end
                    end
                end
            end

            for _, target in pairs(TextTargets) do
                if not target.coords then goto continue end
                local dist = #(pedCoords - target.coords)
                if dist > target.dist then goto continue end
                local isClosest = (target == closestTarget)

                for i, opt in ipairs(target.options) do
                    if IsControlJustPressed(0, opt.key) and isClosest then
                        if (not target.canInteract or target.canInteract()) and
                            (not opt.item or hasItem(opt.item)) and
                            (not opt.job or hasJob(opt.job, nil)) then
                            if opt.onSelect then opt.onSelect(targetEntity) end
                            if opt.action then opt.action(targetEntity) end
                        end
                    end
                end

                local baseZ, lineHeight = target.coords.z + 1.0, -0.16
                local lineOffset = 0

                for i, opt in ipairs(target.options) do
                    if (not target.canInteract or target.canInteract()) and
                        (not opt.item or hasItem(opt.item)) and
                        (not opt.job or hasJob(opt.job, nil)) then
                        DrawText3D(vec3(target.coords.x, target.coords.y, baseZ + lineHeight * lineOffset), target.buttontext[i], isClosest)
                        lineOffset = lineOffset + 1
                    end
                end

                ::continue::
            end

            Wait(1) -- Throttled
        end
    end)
end


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


function RotationToDirection(rot)
    local adjust = math.pi / 180
    return vec3(
        -math.sin(adjust * rot.z) * math.abs(math.cos(adjust * rot.x)),
         math.cos(adjust * rot.z) * math.abs(math.cos(adjust * rot.x)),
         math.sin(adjust * rot.x)
    )
end

function normalizeVector(vec)
    local len = math.sqrt(vec.x^2 + vec.y^2 + vec.z^2)
    if len ~= 0 then
        return vec3(vec.x / len, vec.y / len, vec.z / len)
    else
        return vec3(0, 0, 0)
    end
end

-- Helper to update cached text.
function updateCachedText(target)
    target.text = table.concat(target.buttontext, "\n")
end