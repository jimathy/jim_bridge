-- This is for experimental targets based on GTA in-world text prompts --
local TextTargets = {}
local Keys = {
    [322] = "ESC", [288] = "F1", [289] = "F2", [170] = "F3", [166] = "F5",
    [167] = "F6", [168] = "F7", [169] = "F8", [56] = "F9", [57] = "F10",
    [243] = "~", [157] = "1", [158] = "2", [160] = "3", [164] = "4",  [165] = "5",
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

-- Target Creation --
-- Target Entities, this is more based on qb-target's style of target creation, and translates those into ox or qb-target code --
local targetEntities = {}

--- Creates a target for an entity with specified options and interaction distance.
---
--- This function supports different targeting systems (OX Target, QB Target, or custom DrawText3D targets)
--- based on the server configuration. It translates qb-target style options into the appropriate format
--- for the detected targeting system.
---
---@param entity number The entity ID to create a target for.
---@param opts table A table of option configurations for the target.
--- - **icon** (`string`): The icon to display for the option.
--- - **label** (`string`): The label text for the option.
--- - **item** (`string|nil`): (Optional) The item associated with the option.
--- - **job** (`string|nil`): (Optional) The job required to interact with the option.
--- - **gang** (`string|nil`): (Optional) The gang required to interact with the option.
--- - **action** (`function|nil`): (Optional) The function to execute when the option is selected.
---@param dist number The interaction distance for the target.
---
---@usage
--- ```lua
--- createEntityTarget(entityId, {
---     { icon = "fas fa-car", label = "Open Vehicle", action = openVehicle },
---     { icon = "fas fa-lock", label = "Lock Vehicle", action = lockVehicle }
--- }, 2.5)
--- ```
function createEntityTarget(entity, opts, dist)
    targetEntities[#targetEntities + 1] = entity
    local entityCoords = GetEntityCoords(entity)
    if Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport)) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Entity^2 target with ^6DrawText ^7"..entity)
        local existingTarget = nil
        for key, target in pairs(TextTargets) do
            if #(target.coords - entityCoords) < 0.01 then -- Adjust the threshold for coordinate matching
                existingTarget = target
                break
            end
        end

        if existingTarget then
            -- Combine options
            local keyTable = { 38, 29, 303, 45, 46, 47, 48 } -- Extend key table as needed
            for i = 1, #opts do
                local key = keyTable[#existingTarget.options + i]
                opts[i].key = key
                existingTarget.buttontext[#existingTarget.buttontext + 1] = " ~b~[~w~"..Keys[key].."~b~] ~w~"..opts[i].label
                existingTarget.options[#existingTarget.options + 1] = opts[i]
            end
        else
            -- Create new target
            local tempText = {}
            local keyTable = { 38, 29, 303, 45, 46, 47, 48 }
            for i = 1, #opts do
                opts[i].key = keyTable[i]
                tempText[#tempText + 1] = " ~b~[~w~"..Keys[opts[i].key].."~b~] ~w~"..opts[i].label
            end
            TextTargets[entity] = { coords = vec3(entityCoords.x, entityCoords.y, entityCoords.z), buttontext = tempText, options = opts, dist = dist }
        end
    elseif isStarted(OXTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Entity^2 target with ^6"..OXTargetExport.." ^7"..entity)
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].action,
                canInteract = function(_, distance)
                    return distance < dist and true or false
                end
            }
        end
        exports[OXTargetExport]:addLocalEntity(entity, options)
    elseif isStarted(QBTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Entity^2 target with ^6"..QBTargetExport.." ^7"..entity)
        local options = { options = opts, distance = dist }
        exports[QBTargetExport]:AddTargetEntity(entity, options)
    end
end

local boxTargets = {}

--- Creates a box-shaped target zone with specified options and interaction distance.
---
--- This function supports different targeting systems (OX Target, QB Target, or custom DrawText3D targets)
--- based on the server configuration. It translates qb-target style options into the appropriate format
--- for the detected targeting system.
---
---@param data table A table containing the box zone configuration.
--- - **name** (`string`): The name identifier for the zone.
--- - **coords** (`vector3`): The center coordinates of the box.
--- - **width** (`number`): The width of the box.
--- - **height** (`number`): The height of the box.
--- - **options** (`table`): A table with additional options:
---   - **heading** (`number`): The rotation angle of the box.
---   - **debugPoly** (`boolean`): Whether to enable debug mode for the zone.
---
---@param opts table A table of option configurations for the target.
--- - **icon** (`string`): The icon to display for the option.
--- - **label** (`string`): The label text for the option.
--- - **item** (`string|nil`): (Optional) The item associated with the option.
--- - **job** (`string|nil`): (Optional) The job required to interact with the option.
--- - **gang** (`string|nil`): (Optional) The gang required to interact with the option.
--- - **onSelect** (`function|nil`): (Optional) The function to execute when the option is selected.
---@param dist number The interaction distance for the target.
---
---@return string|table name identifier or target object of the created zone.
---
---@usage
--- ```lua
--- createBoxTarget({
---     name = 'storageBox',
---     coords = vector3(100.0, 200.0, 30.0),
---     width = 2.0,
---     height = 2.0,
---     options = { heading = 0, debugPoly = false }
--- }, {
---     { icon = "fas fa-box", label = "Open Storage", action = openStorage }
--- }, 1.5)
--- ```
function createBoxTarget(data, opts, dist)
    if Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport)) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Box^2 target with ^6DrawText ^7"..data[1])
        local existingTarget = nil
        for key, target in pairs(TextTargets) do
            if #(target.coords - data[2]) < 0.01 then -- Adjust the threshold as needed for coordinate precision
                existingTarget = target
                break
            end
        end
        local keyTable = { 38, 29, 303, 45, 46, 47, 48 }

        if existingTarget then
            -- Combine options
            for i = 1, #opts do
                local key = keyTable[#existingTarget.options + i]
                opts[i].key = key
                existingTarget.buttontext[#existingTarget.buttontext+1] = " ~b~[~w~"..Keys[key].."~b~] ~w~"..opts[i].label
                existingTarget.options[#existingTarget.options+1] = opts[i]
            end
        else
            -- Create new target
            local tempText = {}
            for i = 1, #opts do
                opts[i].key = keyTable[i]
                tempText[#tempText+1] = " ~b~[~w~"..Keys[opts[i].key].."~b~] ~w~"..opts[i].label
            end
            TextTargets[data[1]] = { coords = data[2], buttontext = tempText, options = opts, dist = 1.5 }
        end
        return data[1]
    elseif isStarted(OXTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Box^2 target with ^6"..OXTargetExport.." ^7"..data[1])
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].onSelect or opts[i].action,
                canInteract = function(_, distance)
                    return distance < dist and true or false
                end
            }
        end
        if not data[5].useZ then
            local z = data[2].z + math.abs(data[5].maxZ - data[5].minZ) / 2
            data[2] = vec3(data[2].x, data[2].y, z)
        end
        local target = exports[OXTargetExport]:addBoxZone({
            coords = data[2],
            size = vec3(data[4], data[3], (data[5].useZ or not data[5].maxZ) and data[2].z or math.abs(data[5].maxZ - data[5].minZ)),
            rotation = data[5].heading,
            debug = data[5].debugPoly,
            options = options
        })
        boxTargets[#boxTargets+1] = target
        return target
    elseif isStarted(QBTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Box^2 target with ^6"..QBTargetExport.." ^7"..data[1])
        local options = { options = opts, distance = dist }
        local target = exports[QBTargetExport]:AddBoxZone(data[1], data[2], data[3], data[4], data[5], options)
        boxTargets[#boxTargets+1] = target
        return data[1]
    end
end

local circleTargets = {}

--- Creates a circular target zone with specified options and interaction distance.
---
--- This function supports different targeting systems (OX Target, QB Target, or custom DrawText3D targets)
--- based on the server configuration. It translates qb-target style options into the appropriate format
--- for the detected targeting system.
---
---@param data table A table containing the circle zone configuration.
--- - **name** (`string`): The name identifier for the zone.
--- - **coords** (`vector3`): The center coordinates of the circle.
--- - **radius** (`number`): The radius of the circle.
--- - **options** (`table`): A table with additional options:
---   - **debugPoly** (`boolean`): Whether to enable debug mode for the zone.
---
---@param opts table A table of option configurations for the target.
--- - **icon** (`string`): The icon to display for the option.
--- - **label** (`string`): The label text for the option.
--- - **item** (`string|nil`): (Optional) The item associated with the option.
--- - **job** (`string|nil`): (Optional) The job required to interact with the option.
--- - **gang** (`string|nil`): (Optional) The gang required to interact with the option.
--- - **onSelect** (`function|nil`): (Optional) The function to execute when the option is selected.
---@param dist number The interaction distance for the target.
---
---@return string|table name identifier or target object of the created zone.
---
---@usage
--- ```lua
--- createCircleTarget({
---     name = 'centralPark',
---     coords = vector3(200.0, 300.0, 40.0),
---     radius = 50.0,
---     options = { debugPoly = false }
--- }, {
---     { icon = "fas fa-tree", label = "Relax", action = relaxAction }
--- }, 2.0)
--- ```
function createCircleTarget(data, opts, dist)
    if Config.System.DontUseTarget then
        debugPrint("^6Bridge^7: ^2Creating new ^3Circle^2 target with ^6DrawText ^7"..data[1])
        local existingTarget = nil
        for key, target in pairs(TextTargets) do
            if #(target.coords - data[2]) < 0.01 then -- Adjust the threshold for precision
                existingTarget = target
                break
            end
        end

        if existingTarget then
            -- Combine options
            local keyTable = { 38, 29, 303, 45, 46, 47, 48 } -- Extend key table as needed
            for i = 1, #opts do
                local key = keyTable[#existingTarget.options + i]
                opts[i].key = key
                existingTarget.buttontext[#existingTarget.buttontext+1] = " ~b~[~w~"..Keys[key].."~b~] ~w~"..opts[i].label
                existingTarget.options[#existingTarget.options+1] = opts[i]
            end
        else
            -- Create new target
            local tempText = {}
            local keyTable = { 38, 29, 303, 45, 46, 47, 48 }
            for i = 1, #opts do
                opts[i].key = keyTable[i]
                tempText[#tempText+1] = " ~b~[~w~"..Keys[opts[i].key].."~b~] ~w~"..opts[i].label
            end
            TextTargets[data[1]] = { coords = data[2], buttontext = tempText, options = opts, dist = dist }
        end
        return data[1]
    elseif isStarted(OXTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Sphere^2 target with ^6"..OXTargetExport.." ^7"..data[1])
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].onSelect or opts[i].action,
                canInteract = function(_, distance)
                    return distance < dist and true or false
                end
            }
        end
        local target = exports[OXTargetExport]:addSphereZone({
            coords = data[2],
            radius = data[3],
            debug = data[4].debugPoly,
            options = options
        })
        circleTargets[#circleTargets+1] = target
        return target
    elseif isStarted(QBTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Circle^2 target with ^6"..QBTargetExport.." ^7"..data[1])
        local options = { options = opts, distance = dist }
        local target = exports[QBTargetExport]:AddCircleZone(data[1], data[2], data[3], data[4], options)
        circleTargets[#circleTargets+1] = target
        return data[1]
    end
end

local targetEntities = {}

--- Creates a target for an entity with specified options and interaction distance.
---
--- This function supports different targeting systems (OX Target, QB Target, or custom DrawText3D targets)
--- based on the server configuration. It translates qb-target style options into the appropriate format
--- for the detected targeting system.
---
---@param entity number The entity ID to create a target for.
---@param opts table A table of option configurations for the target.
--- - **icon** (`string`): The icon to display for the option.
--- - **label** (`string`): The label text for the option.
--- - **item** (`string|nil`): (Optional) The item associated with the option.
--- - **job** (`string|nil`): (Optional) The job required to interact with the option.
--- - **gang** (`string|nil`): (Optional) The gang required to interact with the option.
--- - **action** (`function|nil`): (Optional) The function to execute when the option is selected.
---@param dist number The interaction distance for the target.
---
---@usage
--- ```lua
--- createEntityTarget(entityId, {
---     { icon = "fas fa-car", label = "Open Vehicle", action = openVehicle },
---     { icon = "fas fa-lock", label = "Lock Vehicle", action = lockVehicle }
--- }, 2.5)
--- ```
function createModelTarget(models, opts, dist)
    if Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport)) then
        --
    elseif isStarted(OXTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Model^2 target with ^6"..OXTargetExport)
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].action,
                canInteract = function(_, distance)
                    return distance < dist and true or false
                end
            }
        end
        exports[OXTargetExport]:addModel(models, options)
    elseif isStarted(QBTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Entity^2 target with ^6"..QBTargetExport)
        local options = { options = opts, distance = dist }
        exports[QBTargetExport]:AddTargetModel(models, options)
    end
end



-- Simple function to remove an entity target created within the script --
--- Removes a previously created entity target.
---
--- This function removes the target associated with the specified entity based on the active targeting system.
---
--- @param entity number The entity ID whose target should be removed.
---
--- @usage
--- removeEntityTarget(entityId)
function removeEntityTarget(entity)
    if isStarted(QBTargetExport) then exports[QBTargetExport]:RemoveTargetEntity(entity) end
    if isStarted(OXTargetExport) then exports[OXTargetExport]:removeLocalEntity(entity, nil) end
    if (Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport))) then TextTargets[entity] = nil end
end

-- Simple function to remove circle or box targets in the script --
--- Removes a previously created zone target.
---
--- This function removes the target associated with the specified zone based on the active targeting system.
---
--- @param target string|table The name identifier or target object of the zone to remove.
---
--- @usage
--- ```lua
--- removeZoneTarget('centralPark')
--- removeZoneTarget(targetObject)
--- ```
function removeZoneTarget(target)
    if isStarted(QBTargetExport) then exports[QBTargetExport]:RemoveZone(target) end
    if isStarted(OXTargetExport) then exports[OXTargetExport]:removeZone(target, true) end
    if (Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport))) then TextTargets[target] = nil end
end

-- If no target script is found, default to DrawText3D targets -- * experimental *
if (Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport))) and not isServer() then
    CreateThread(function()
        while true do
            local pedCoords = GetEntityCoords(PlayerPedId())
            local camCoords = GetGameplayCamCoord()
            local camRotation = GetGameplayCamRot(2) -- Get camera rotation in degrees
            local camForwardVector = RotationToDirection(camRotation) -- Convert rotation to direction vector

            local closestTarget = nil
            local closestDist = math.huge

            for k, v in pairs(TextTargets) do
                local targetCoords = v.coords
                local dist = #(pedCoords - targetCoords)
                local vecToTarget = targetCoords - camCoords

                -- Normalize the vector to the target
                local vecToTargetNormalized = normalizeVector(vecToTarget)

                -- Dot product to check if facing the target
                local dot = camForwardVector.x * vecToTargetNormalized.x + camForwardVector.y * vecToTargetNormalized.y + camForwardVector.z * vecToTargetNormalized.z

                local isFacingTarget = dot > 0.5 -- Adjust threshold as needed

                if dist <= v.dist and isFacingTarget then
                    if dist < closestDist then
                        closestDist = dist
                        closestTarget = v
                    end
                end
            end

            for k, v in pairs(TextTargets) do
                local isClosest = (v == closestTarget)
                if #(pedCoords - v.coords) <= v.dist then
                    for i = 1, #v.options do
                        if IsControlJustPressed(0, v.options[i].key) and isClosest then
                            if v.options[i].onSelect then v.options[i].onSelect() end
                            if v.options[i].action then v.options[i].action() end
                        end
                    end
                    DrawText3D(vec3(v.coords.x, v.coords.y, v.coords.z + 0.7), concatenateText(v.buttontext), isClosest)
                end
            end
            Wait(0)
        end
    end)
end

-- If the current loaded script is stopped, automatically remove targets --
onResourceStop(function()
    for i = 1, #targetEntities do
        if isStarted(OXTargetExport) then exports[OXTargetExport]:removeLocalEntity(targetEntities[i], nil)
        elseif isStarted(QBTargetExport) then exports[QBTargetExport]:RemoveTargetEntity(targetEntities[i]) end
    end
    for i = 1, #boxTargets do
        if isStarted(OXTargetExport) then exports[OXTargetExport]:removeZone(boxTargets[i], true)
        elseif isStarted(QBTargetExport) then exports[QBTargetExport]:RemoveZone(boxTargets[i].name) end
    end
    for i = 1, #circleTargets do
        if isStarted(OXTargetExport) then exports[OXTargetExport]:removeZone(circleTargets[i], true)
        elseif isStarted(QBTargetExport) then exports[QBTargetExport]:RemoveZone(circleTargets[i].name) end
    end
end, true)