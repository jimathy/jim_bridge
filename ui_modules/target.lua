-- Global Key Table, defined once.
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


-- ===== Ownership + indexes =====
-- TextTargets: key -> target data (coords/entity/models/options/etc.)
local TextTargets = {}
-- targetEntities kept for parity (not strictly required)
local targetEntities = {}

-- registry: key -> owner, owner -> set(keys)
local TargetRegistry = { byKey = {}, byResource = {} }

local function getOwnerResource()
    return GetInvokingResource() or GetCurrentResourceName() or "unknown"
end

local function registerTarget(owner, key)
    -- move key across owners if replacing
    local prev = TargetRegistry.byKey[key]
    if prev and TargetRegistry.byResource[prev] then
        TargetRegistry.byResource[prev][key] = nil
    end
    TargetRegistry.byKey[key] = owner
    TargetRegistry.byResource[owner] = TargetRegistry.byResource[owner] or {}
    TargetRegistry.byResource[owner][key] = true
end

local function removeTargetKey(key, reason)
    local owner = TargetRegistry.byKey[key]
    if TextTargets[key] then
        TextTargets[key] = nil
        -- print("^6Bridge^7:^5 Target^7: ^2Removed target '%s'%s", key, reason and (" ("..reason..")") or "")
    end
    if owner then
        if TargetRegistry.byResource[owner] then
            TargetRegistry.byResource[owner][key] = nil
        end
        TargetRegistry.byKey[key] = nil
    end
end

AddEventHandler("onResourceStop", function(res)
    local owned = TargetRegistry.byResource[res]
    if not owned then return end
    local cnt = 0
    for key in pairs(owned) do
        removeTargetKey(key, "resource stopped: "..res)
        cnt = cnt + 1
    end
    TargetRegistry.byResource[res] = nil
    -- print("^6Bridge^7:^5 Target^7: ^2Cleared "..cnt.." target(s) from '"..res.."'")
end)

-- ===== Helpers =====
local function vecKey(v)
    -- stable rounded coord string for entity dedupe when name isn't provided
    return ("%.3f,%.3f,%.3f"):format(v.x, v.y, v.z)
end

local function bakeButtons(opts)
    local tempText = {}
    for i = 1, #opts do
        opts[i].key = KEY_TABLE[i]
        tempText[#tempText + 1] =
            (" ~b~[~w~%s~b~] ~w~%s"):format(Keys[opts[i].key] or ("K"..opts[i].key), opts[i].label or ("Option "..i))
    end
    return tempText
end

-- Update cached text blob
local function updateCachedText(target)
    target.text = table.concat(target.buttontext, "\n")
end

-- ===== Public API: Create targets =====
-- ENTITY: createEntityTarget(entity, opts, dist, nameOpt?)
function createEntityTarget(entity, opts, dist, name)
    startTargetLoop()

    if not entity or entity == 0 then return end
    targetEntities[#targetEntities + 1] = entity

    local owner = getOwnerResource()
    local coords = GetEntityCoords(entity)
    local key    = tostring(name) or ("entity@" .. vecKey(coords))

    -- Always overwrite on same key
    local buttontext = bakeButtons(opts)
    TextTargets[key] = {
        _key   = key,
        _type  = "entity",
        _owner = owner,
        entity = entity,
        coords = vec3(coords.x, coords.y, coords.z),
        buttontext = buttontext,
        options    = opts,
        dist       = dist,
    }
    updateCachedText(TextTargets[key])
    registerTarget(owner, key)
    -- print("^6Bridge^7:^5 Target^7: ^2Added/Updated ENTITY target '"..key.."' by '"..owner.."' @ "..formatCoord(coords))
    return key
end

-- ZONE: createZoneTarget(data, opts, dist)
-- Expect data[1] = id/name, data[2] = vec3 coords (as in your original)
function createZoneTarget(data, opts, dist)
    startTargetLoop()

    local owner = getOwnerResource()
    local zname = tostring(data[1] or ("zone@"..vecKey(data[2] or vec3(0,0,0))))
    local coords = data[2]

    local buttontext = bakeButtons(opts)
    TextTargets[zname] = {
        _key   = zname,
        _type  = "zone",
        _owner = owner,
        coords = coords,
        buttontext = buttontext,
        options    = opts,
        dist       = dist,
    }
    updateCachedText(TextTargets[zname])
    registerTarget(owner, zname)
    -- print("^6Bridge^7:^5 Target^7: ^2Added/Updated ZONE target '"..zname.."' by '"..owner.."' @ "..formatCoord(coords))
    return zname
end

-- MODEL: createModelTarget(models, opts, dist, nameOpt?)
function createModelTarget(models, opts, dist, name)
    startTargetLoop()

    local owner = getOwnerResource()
    if type(models) ~= "table" then models = { models } end

    local key
    if name then
        key = tostring(name)
    else
        local parts = {}
        for i, m in ipairs(models) do parts[i] = tostring(m) end
        key = "model_" .. table.concat(parts, "_")
    end

    local buttontext = bakeButtons(opts)
    TextTargets[key] = {
        _key   = key,
        _type  = "model",
        _owner = owner,
        models = models,
        buttontext = buttontext,
        options    = opts,
        dist       = dist,
        coords     = vec3(0, 0, 0), -- will be updated by the refresher
    }
    updateCachedText(TextTargets[key])
    registerTarget(owner, key)
    -- print("^6Bridge^7:^5 Target^7: ^2Added/Updated MODEL target '"..key.."' by '"..owner.."' (models: "..table.concat(models, ",")..")")
    return key
end

-- ===== Public API: Remove targets =====
-- Entity removal accepts entity handle or key string.
function removeEntityTarget(entityOrKey)
    local key = nil
    if type(entityOrKey) == "string" then
        key = entityOrKey
    elseif type(entityOrKey) == "number" then
        for k, t in pairs(TextTargets) do
            if t._type == "entity" and t.entity == entityOrKey then key = k break end
        end
        if not key then
            -- Fallback: try coord-key match
            local c = GetEntityCoords(entityOrKey)
            local guess = "entity@"..vecKey(c)
            if TextTargets[guess] then key = guess end
        end
    end
    if key then removeTargetKey(key, "removeEntityTarget") end
end

function removeZoneTarget(key)
    if not key then return end
    removeTargetKey(key, "removeZoneTarget")
end

-- For models, pass the returned key from createModelTarget (recommended).
function removeModelTarget(key)
    if not key then return end
    removeTargetKey(key, "removeModelTarget")
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
    started = true

    -- lazy include (unchanged from your original)
    Config = { System = {} }
    local fileLoader = assert(load(LoadResourceFile("jim_bridge", ('starter.lua')), ('@@jim_bridge/starter.lua')))
    fileLoader()

    -- Model Entity Refresher (kept)
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

    -- Main Target Loop (unchanged logic, just uses new TextTargets entries)
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
                            if opt.action   then opt.action(targetEntity)   end
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

            Wait(1)
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
    local textMaxLength = 99
    local txt = totalLength > textMaxLength and text:sub(1, textMaxLength) or text
    AddTextComponentString(highlight and txt:gsub("%~w~", "~y~") or txt)
    SetDrawOrigin(coord.x, coord.y, coord.z, 0)
    DrawText(0.0, 0.0)
    local count, length = GetLineCountAndMaxLength(txt)

    local padding = 0.005
    local heightFactor = (count / 43) + padding
    local weightFactor = (length / 150) + padding

    local height = (heightFactor / 2) - padding / 1
    local width  = (weightFactor / 2) - padding / 1

    DrawRect(0.0, height, width, heightFactor, 0, 0, 0, 150)
    ClearDrawOrigin()
end

function GetLineCountAndMaxLength(text)
    local lineCount, maxLength = 0, 0
    for line in text:gmatch("[^\n]+") do
        lineCount = lineCount + 1
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
