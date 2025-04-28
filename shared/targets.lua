--[[
    Experimental GTA In-World Text Prompts Targets Module
    -------------------------------------------------------
    This module handles the creation, removal, and management of in-world text targets
    for interacting with entities and zones using GTA text prompts. It supports multiple
    targeting systems: OX Target, QB Target, or a fallback using DrawText3D.

    Available functionalities:
      • createEntityTarget   - Creates a target for a specific entity.
      • createBoxTarget      - Creates a box-shaped zone target.
      • createCircleTarget   - Creates a circular zone target.
      • createModelTarget    - Creates a target for specified models.
      • removeEntityTarget   - Removes a target from an entity.
      • removeZoneTarget     - Removes a zone target.

    Fallback: If no targeting system is detected (or if disabled via Config.System.DontUseTarget),
              the module uses DrawText3D prompts. This is experimental and may not work as expected.
]]

-------------------------------------------------------------
-- Utility Data & Tables
-------------------------------------------------------------
---
local KEY_TABLE = { 38, 29, 47, 23, 45, }

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

-- Tables for storing created targets for the fallback system and zone management.
local TextTargets    = {}   -- For fallback DrawText3D targets.
local targetEntities = {}   -- For entity targets.
local boxTargets     = {}   -- For box-shaped zone targets.
local circleTargets  = {}   -- For circular zone targets.

-------------------------------------------------------------
-- Entity Target Creation
-------------------------------------------------------------

--- Creates a target for an entity with specified options and interaction distance.
--- Supports different targeting systems (OX Target, QB Target, or custom DrawText3D)
--- based on the server configuration.
---
--- @param entity number The entity ID for which the target is created.
--- @param opts table Array of option tables. Each option should include:
---        - icon (string): The icon to display.
---        - label (string): The text label for the option.
---        - item (string|nil): (Optional) An associated item.
---        - job (string|nil): (Optional) The job required to interact.
---        - gang (string|nil): (Optional) The gang required to interact.
---        - action (function|nil): (Optional) The function executed on selection.
--- @param dist number The interaction distance for the target.
---
--- @usage
--- ```lua
---createEntityTarget(entityId, {
---   {
---       action = function()
---           openStorage()
---       end,
---       icon = "fas fa-box",
---       job = "police",
---       label = "Open Storage",
---   },
---}, 2.0)
--- ```
function createEntityTarget(entity, opts, dist)
    -- Store the target entity for later cleanup.
    targetEntities[#targetEntities + 1] = entity

    -- Fallback: Use DrawText3D if targeting systems are disabled or unavailable.
    if Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport)) then
        local entityCoords = GetEntityCoords(entity)
        debugPrint("^6Bridge^7: ^2Creating new ^3Entity^2 target with DrawText for entity ^7"..entity)
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
    elseif isStarted(OXTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Entity ^2target with ^6"..OXTargetExport.." ^2for entity ^7"..entity)
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].action,
                distance = dist,
                canInteract = opts[i].canInteract or nil,
            }
        end
        exports[OXTargetExport]:addLocalEntity(entity, options)
    elseif isStarted(QBTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Entity ^2target with ^6"..QBTargetExport.." ^2for entity ^7"..entity)
        local options = { options = opts, distance = dist }
        exports[QBTargetExport]:AddTargetEntity(entity, options)
    end
end

-------------------------------------------------------------
-- Box Zone Target Creation
-------------------------------------------------------------

--- Creates a box-shaped target zone with specified options and interaction distance.
--- Supports different targeting systems based on the server configuration.
---@param data table A table containing the box zone configuration.
---     - name (`string`): The name identifier for the zone.
---     - coords (`vector3`): The center coordinates of the box.
---     - width (`number`): The width of the box.
---     - height (`number`): The height of the box.
---     - options (`table`): A table with additional options:
---     - heading (`number`): The rotation angle of the box.
---     - debugPoly (`boolean`): Whether to enable debug mode for the zone.
---
---@param opts table A table of option configurations for the target.
---     - icon (`string`): The icon to display for the option.
---     - label (`string`): The label text for the option.
---     - item (`string|nil`): (Optional) The item associated with the option.
---     - job (`string|nil`): (Optional) The job required to interact with the option.
---     - gang (`string|nil`): (Optional) The gang required to interact with the option.
---     - onSelect (`function|nil`): (Optional) The function to execute when the option is selected.
---@param dist number The interaction distance for the target.
---
---@return string|table name identifier or target object of the created zone.
---
---@usage
---```lua
---createBoxTarget(
---   {
---       'storageBox',
---       vector3(100.0, 200.0, 30.0),
---       2.0,
---       2.0,
---       {
---           name = 'storageBox',
---           heading = 100.0,
---           debugPoly = true,
---           minZ = 27.0,
---           maxZ = 32.0,
---       },
---   },
---{
---   {
---       action = function()
---           openStorage()
---       end,
---       icon = "fas fa-box",
---       job = "police",
---       label = "Open Storage",
---   },
---}, 2.0)
---```
function createBoxTarget(data, opts, dist)
    if Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport)) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Box^2 target with ^6DrawText ^2 for zone ^7"..data[1])
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
    elseif isStarted(OXTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Box^2 target with ^6"..OXTargetExport.." ^2for zone ^7"..data[1])
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].onSelect or opts[i].action,
                distance = dist,
                canInteract = opts[i].canInteract or nil,
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
        boxTargets[#boxTargets + 1] = target
        return target
    elseif isStarted(QBTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Box^2 target with ^6"..QBTargetExport.." ^2for zone ^7"..data[1])
        local options = { options = opts, distance = dist }
        local target = exports[QBTargetExport]:AddBoxZone(data[1], data[2], data[3], data[4], data[5], options)
        boxTargets[#boxTargets + 1] = target
        return data[1]
    end
end

-------------------------------------------------------------
-- Circle Zone Target Creation
-------------------------------------------------------------

--- Creates a circular target zone with specified options and interaction distance.
--- Supports different targeting systems based on server configuration.
---
---@param data table A table containing the circle zone configuration.
---     - name (`string`): The name identifier for the zone.
---     - coords (`vector3`): The center coordinates of the circle.
---     - radius (`number`): The radius of the circle.
---     - options (`table`): A table with additional options:
---     - debugPoly (`boolean`): Whether to enable debug mode for the zone.
---
---@param opts table A table of option configurations for the target.
---     - icon (`string`): The icon to display for the option.
---     - label (`string`): The label text for the option.
---     - item (`string|nil`): (Optional) The item associated with the option.
---     - job (`string|nil`): (Optional) The job required to interact with the option.
---     - gang (`string|nil`): (Optional) The gang required to interact with the option.
---     - onSelect (`function|nil`): (Optional) The function to execute when the option is selected.
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
        debugPrint("^6Bridge^7: ^2Creating new ^3Circle ^2target with ^6DrawText ^2for zone ^7"..data[1])
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
    elseif isStarted(OXTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Circle ^2target with ^6"..OXTargetExport.." ^2for zone ^7"..data[1])
        local options = {}
        for i = 1, #opts do
            options[i] = {
                icon = opts[i].icon,
                label = opts[i].label,
                item = opts[i].item or nil,
                groups = opts[i].job or opts[i].gang,
                onSelect = opts[i].onSelect or opts[i].action,
                distance = dist,
                canInteract = opts[i].canInteract or nil,
            }
        end
        local target = exports[OXTargetExport]:addSphereZone({
            coords = data[2],
            radius = data[3],
            debug = data[4].debugPoly,
            options = options
        })
        circleTargets[#circleTargets + 1] = target
        return target
    elseif isStarted(QBTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Circle ^2target with ^6"..QBTargetExport.." ^2for zone ^7"..data[1])
        local options = { options = opts, distance = dist }
        local target = exports[QBTargetExport]:AddCircleZone(data[1], data[2], data[3], data[4], options)
        circleTargets[#circleTargets + 1] = target
        return data[1]
    end
end

-------------------------------------------------------------
-- Model Target Creation
-------------------------------------------------------------

--- Creates a target for models with specified options and interaction distance.
--- Supports different targeting systems (OX Target, QB Target) based on server configuration.
---
--- @param models table Array of model identifiers.
--- @param opts table Array of option tables (same structure as in createEntityTarget).
--- @param dist number The interaction distance for the target.
---
--- @usage
--- ```lua
---createModelTarget({ model1, model2 },
---{
---   {
---       action = function()
---           openStorage()
---       end,
---       icon = "fas fa-box",
---       job = "police",
---       label = "Open Storage",
---   },
---}, 2.0)
---```
function createModelTarget(models, opts, dist)
    if Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport)) then
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
                distance = dist,
                canInteract = opts[i].canInteract or nil,
            }
        end
        exports[OXTargetExport]:addModel(models, options)
    elseif isStarted(QBTargetExport) then
        debugPrint("^6Bridge^7: ^2Creating new ^3Model^2 target with ^6"..QBTargetExport)
        local options = { options = opts, distance = dist }
        exports[QBTargetExport]:AddTargetModel(models, options)
    end
end

-------------------------------------------------------------
-- Target Removal Functions
-------------------------------------------------------------

--- Removes a previously created entity target.
---
--- @param entity number The entity ID whose target should be removed.
---
--- @usage
--- ```lua
--- removeEntityTarget(entityId)
--- ```
function removeEntityTarget(entity)
    if isStarted(QBTargetExport) then
        exports[QBTargetExport]:RemoveTargetEntity(entity)
    end
    if isStarted(OXTargetExport) then
        exports[OXTargetExport]:removeLocalEntity(entity, nil)
    end
    if Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport)) then
        TextTargets[entity] = nil
    end
end

--- Removes a previously created zone target.
---
--- @param target string|table The name identifier or target object of the zone to remove.
---
--- @usage
--- ```lua
--- removeZoneTarget('centralPark')
--- removeZoneTarget(targetObject)
--- ```
function removeZoneTarget(target)
    if isStarted(QBTargetExport) then
        exports[QBTargetExport]:RemoveZone(target)
    end
    if isStarted(OXTargetExport) then
        exports[OXTargetExport]:removeZone(target, true)
    end
    if Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport)) then
        TextTargets[target] = nil
    end
end

--- Removes a previously created model target.
---
--- @param model table The model ID whose target should be removed.
---
--- @usage
--- ```lua
--- removeModelTarget(model)
--- ```
function removeModelTarget(model)
    if isStarted(QBTargetExport) then
        exports[QBTargetExport]:RemoveTargetModel(model, "Test")
    end
    if isStarted(OXTargetExport) then
        exports[OXTargetExport]:removeModel(model, nil)
    end
    if Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport)) then
        TextTargets[entity] = nil
    end
end
-------------------------------------------------------------
-- Fallback: DrawText3D Targets (Experimental)
-------------------------------------------------------------

-- If no targeting system is detected and this is a client script, use DrawText3D for targets.
if (Config.System.DontUseTarget or (not isStarted(OXTargetExport) and not isStarted(QBTargetExport))) and not isServer() then
    CreateThread(function()
        local wait = 1000
        while true do
            local pedCoords = GetEntityCoords(PlayerPedId())
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local camForward = RotationToDirection(camRot)
            local closestTarget, closestDist = nil, math.huge
            local notificationShown = false
            local targetEntity = nil
            -- Update model targets and determine the closest target.
            for _, target in pairs(TextTargets) do
                if target.models then
                    for _, model in ipairs(target.models) do
                        local entity = GetClosestObjectOfType(pedCoords.x, pedCoords.y, pedCoords.z, target.dist, model, false, false, false)
                        if entity and entity ~= 0 then
                            target.coords = GetEntityCoords(entity)
                            targetEntity = entity
                            break
                        end
                    end
                end

                local dist = #(pedCoords - target.coords)
                if dist <= target.dist then
                    local vecToTarget = target.coords - camCoords
                    local normVec = normalizeVector(vecToTarget)
                    local dot = camForward.x * normVec.x + camForward.y * normVec.y + camForward.z * normVec.z
                    if dot > 0.5 and dist < closestDist then
                        closestDist = dist
                        closestTarget = target
                    end
                end
            end

            -- Render targets, listen for key presses and display the help notification.
            for key, target in pairs(TextTargets) do
                if #(pedCoords - target.coords) <= target.dist then
                    local isClosest = (target == closestTarget)
                    for i, opt in ipairs(target.options) do
                        if IsControlJustPressed(0, opt.key) and isClosest then
                            if opt.onSelect then opt.onSelect(targetEntity) end
                            if opt.action then opt.action(targetEntity) end
                        end
                    end

                    notificationShown = true
                    ShowFloatingHelpNotification(vec3(target.coords.x, target.coords.y, target.coords.z + 0.7), target.text)
                end
            end

            -- If no notification was drawn this frame, clear help messages.
            if notificationShown then
                wait = 0
            else
                ClearAllHelpMessages()
                wait = 1000
            end

            Wait(wait)
        end
    end)
end

function ShowFloatingHelpNotification(coord, text, highlight)
    AddTextEntry("FloatingText", text)
    SetFloatingHelpTextWorldPosition(1, coord.x, coord.y, coord.z)
    SetFloatingHelpTextStyle(1, 1, 62, -1, 3, 0)
    BeginTextCommandDisplayHelp("FloatingText")
    EndTextCommandDisplayHelp(2, false, false, -1)
end

function updateCachedText(target)
    target.text = table.concat(target.buttontext, "\n")
end

-------------------------------------------------------------
-- Cleanup on Resource Stop
-------------------------------------------------------------

-- When the current resource stops, remove all targets.
onResourceStop(function()
    -- Remove entity targets.
    for i = 1, #targetEntities do
        if isStarted(OXTargetExport) then
            exports[OXTargetExport]:removeLocalEntity(targetEntities[i], nil)
        elseif isStarted(QBTargetExport) then
            exports[QBTargetExport]:RemoveTargetEntity(targetEntities[i])
        end
    end
    -- Remove box zone targets.
    for i = 1, #boxTargets do
        if isStarted(OXTargetExport) then
            exports[OXTargetExport]:removeZone(boxTargets[i], true)
        elseif isStarted(QBTargetExport) then
            exports[QBTargetExport]:RemoveZone(boxTargets[i].name)
        end
    end
    -- Remove circle zone targets.
    for i = 1, #circleTargets do
        if isStarted(OXTargetExport) then
            exports[OXTargetExport]:removeZone(circleTargets[i], true)
        elseif isStarted(QBTargetExport) then
            exports[QBTargetExport]:RemoveZone(circleTargets[i].name)
        end
    end
end, true)