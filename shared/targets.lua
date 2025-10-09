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

local targetFunc = {
    {   targetName = OXTargetExport,
        entityTarget =
            function(entity, opts, dist)
                local options = {}
                for i = 1, #opts do
                    options[i] = {
                        icon = opts[i].icon,
                        label = opts[i].label,
                        items = opts[i].item or nil,
                        groups = opts[i].job or opts[i].gang,
                        onSelect = opts[i].action,
                        distance = dist,
                        canInteract = opts[i].canInteract or nil,
                    }
                end
                return exports[OXTargetExport]:addLocalEntity(entity, options)
            end,

        boxTarget =
            function(data, opts, dist)
                local options = {}
                for i = 1, #opts do
                    options[i] = {
                        icon = opts[i].icon,
                        label = opts[i].label,
                        items = opts[i].item or nil,
                        groups = opts[i].groups or opts[i].job or opts[i].gang,
                        onSelect = opts[i].onSelect or opts[i].action,
                        distance = dist,
                        canInteract = opts[i].canInteract or nil,
                    }
                end

                data[5].maxZ = data[5].maxZ or (data[2].z + 0.80)
                data[5].minZ = data[5].minZ or data[2].z - 1.05
                local thickness = ((data[5].maxZ / 2) - (data[5].minZ / 2)) * 2
                local mid = data[5].maxZ - ((data[5].maxZ / 2) - (data[5].minZ / 2))

                data[2] = vec3(data[2].x, data[2].y, mid) -- force the coord to middle of the minZ and maxZ

                local target = exports[OXTargetExport]:addBoxZone({
                    coords = data[2],
                    size = vec3(data[4], data[3], thickness), -- size uses the math to determine how high it needs to be
                    rotation = data[5].heading,
                    debug = data[5].debugPoly,
                    options = options
                })
                return target
            end,

        circleTarget =
            function(data, opts, dist)
                local options = {}
                for i = 1, #opts do
                    options[i] = {
                        icon = opts[i].icon,
                        label = opts[i].label,
                        items = opts[i].item or nil,
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
                return target
            end,

        modelTarget =
            function(models, opts, dist)
                local options = {}
                for i = 1, #opts do
                    options[i] = {
                        icon = opts[i].icon,
                        label = opts[i].label,
                        items = opts[i].item or nil,
                        groups = opts[i].job or opts[i].gang,
                        onSelect = opts[i].action,
                        distance = dist,
                        canInteract = opts[i].canInteract or nil,
                    }
                end
                return exports[OXTargetExport]:addModel(models, options)
            end,

        removeTargetEntity =
            function(entity)
                exports[OXTargetExport]:removeLocalEntity(entity, nil)
            end,

        removeTargetZone =
            function(target)
                exports[OXTargetExport]:removeZone(target, true)
            end,

        removeTargetModel =
            function(model)
                exports[OXTargetExport]:removeModel(model, nil)
            end,
    },

    {   targetName = QBTargetExport,
        entityTarget =
            function(entity, opts, dist)
                local options = { options = opts, distance = dist }
                return exports[QBTargetExport]:AddTargetEntity(entity, options)
            end,

        boxTarget =
            function(data, opts, dist)
                local options = { options = opts, distance = dist }
                local target = exports[QBTargetExport]:AddBoxZone(data[1], data[2], data[3], data[4], data[5], options)
                return data[1]
            end,

        circleTarget =
            function(data, opts, dist)
                local options = { options = opts, distance = dist }
                local target = exports[QBTargetExport]:AddCircleZone(data[1], data[2], data[3], data[4], options)
                return data[1]
            end,

        modelTarget =
            function(models, opts, dist)
                local options = { options = opts, distance = dist }
                return exports[QBTargetExport]:AddTargetModel(models, options)
            end,

        removeTargetEntity =
            function(entity)
                exports[QBTargetExport]:RemoveTargetEntity(entity)
            end,

        removeTargetZone =
            function(target)
                exports[QBTargetExport]:RemoveZone(target)
            end,

        removeTargetModel =
            function(model)
                exports[QBTargetExport]:RemoveTargetModel(model, "Test")
            end,
    },

    {   targetName = "jim_bridge",
        entityTarget =
            function(entity, opts, dist)
                return exports.jim_bridge:createEntityTarget(entity, opts, dist)
            end,

        boxTarget =
            function(data, opts, dist)
                return exports.jim_bridge:createZoneTarget(data, opts, dist)
            end,

        circleTarget =
            function(data, opts, dist)
                return exports.jim_bridge:createZoneTarget(data, opts, dist)
            end,

        modelTarget =
            function(models, opts, dist)
                return exports.jim_bridge:createModelTarget(models, opts, dist)
            end,

        removeTargetEntity =
            function(entity)
                exports.jim_bridge:removeEntityTarget(entity)
            end,

        removeTargetZone =
            function(target)
                exports.jim_bridge:removeZoneTarget(target)
            end,

        removeTargetModel =
            function(model)
                exports.jim_bridge:removeZoneTarget(model)
            end,
    },
}



-------------------------------------------------------------
-- Utility Data & Tables
-------------------------------------------------------------


-- Tables for storing created targets for the fallback system and zone management.
local targetEntities = {}   -- For entity targets.
local boxTargets     = {}   -- For box-shaped zone targets.
local circleTargets  = {}   -- For circular zone targets.
local modelTargets   = {}
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

    -- if force target off, use jim_bridge built in target functions
    if Config.System.DontUseTarget then
        exports.jim_bridge:createEntityTarget(entity, opts, dist)
        debugPrint("^6Bridge^7: ^2Creating new ^3Entity ^2target with ^6jim_bridge ^2for entity ^7"..entity)
        return
    end

    -- Check for target script and use that
    for i = 1, #targetFunc do
        local script = targetFunc[i]
        if isStarted(script.targetName) then
            debugPrint("^6Bridge^7: ^2Creating new ^3Entity ^2target with ^6"..script.targetName.." ^2for entity ^7"..entity)
            return script.entityTarget(entity, opts, dist)
        end
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
    -- if force target off, use jim_bridge built in target functions
    if Config.System.DontUseTarget then
        debugPrint("^6Bridge^7: ^2Creating new ^3Box ^2target with ^6jim_bridge ^7"..data[1])
        return exports.jim_bridge:createZoneTarget(data, opts, dist)
    end

    -- Check for target script and use that
    for i = 1, #targetFunc do
        local script = targetFunc[i]
        if isStarted(script.targetName) then
            debugPrint("^6Bridge^7: ^2Creating new ^3Box ^2target with ^6"..script.targetName.." ^7"..data[1])
            if data[5].minZ or data[5].maxZ then
                local adMinZ, adMaxZ
                data[5].minZ, data[5].maxZ, adMinZ, adMaxZ = adjustMinMaxZ(data[2], { minZ = data[5].minZ, maxZ = data[5].maxZ })
                if adMinZ or adMaxZ then
                    print("^5Debug^7: ^2Auto adjusted ^7'^4"..data[1].."^7' ^2minZ and maxZ because ^1they weren't set correctly ^2remove or fix them for this target")
                end
            end
            local target = script.boxTarget(data, opts, dist)
            boxTargets[#boxTargets + 1] = target
            return target
        end
    end
    return nil
end


function createPropTarget(data, opts, dist)
    -- Audo create a location based on a coord and a prop models dimensions
    local width, depth, _ = GetPropDimensions(data[3])
    local min, max = GetModelDimensions(data[3])
    local coordAdjustment = data[2] - vec4(0, 0, 1.03, 0)
    local newData = {
        [1] = data[1],
        [2] = coordAdjustment.xyz,
        [3] = width + 0.1,
        [4] = depth + 0.1,
        [5] = {
            name = data[1],
            heading = coordAdjustment.w - 90.0,
            debugPoly = debugMode,
            minZ = coordAdjustment.z + (min.z) - 0.1,
            maxZ = coordAdjustment.z + (max.z) + 0.1,
        }
    }
    -- if force target off, use jim_bridge built in target functions
    if Config.System.DontUseTarget then
        debugPrint("^6Bridge^7: ^2Creating new ^3Box ^2target with ^6jim_bridge ^7"..data[1])
        return exports.jim_bridge:createZoneTarget(newData, opts, dist)
    end

    -- Check for target script and use that
    for i = 1, #targetFunc do
        local script = targetFunc[i]
        if isStarted(script.targetName) then
            debugPrint("^6Bridge^7: ^2Creating new ^3Box ^2target with ^6"..script.targetName.." ^7"..data[1])
            local target = script.boxTarget(newData, opts, dist)
            boxTargets[#boxTargets + 1] = target
            return target
        end
    end
    return nil
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

    -- if force target off, use jim_bridge built in target functions
    if Config.System.DontUseTarget then
        debugPrint("^6Bridge^7: ^2Creating new ^3Sphere ^2target with ^6jim_bridge ^7"..data[1])
        return exports.jim_bridge:createZoneTarget(data, opts, dist)
    end

    -- Check for target script and use that
    for i = 1, #targetFunc do
        local script = targetFunc[i]
        if isStarted(script.targetName) then
            debugPrint("^6Bridge^7: ^2Creating new ^3Sphere ^2target with ^6"..script.targetName.." ^7"..data[1])
            local target = script.circleTarget(data, opts, dist)
            circleTargets[#circleTargets + 1] = target
            return target
        end
    end

    return nil
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

    -- if force target off, use jim_bridge built in target functions
    if Config.System.DontUseTarget then
        debugPrint("^6Bridge^7: ^2Creating new ^3Model ^2target with ^6jim_bridge^7")
        return exports.jim_bridge:createModelTarget(models, opts, dist)
    end

    -- Check for target script and use that
    for i = 1, #targetFunc do
        local script = targetFunc[i]
        if isStarted(script.targetName) then
            debugPrint("^6Bridge^7: ^2Creating new ^3Model ^2target with ^6"..script.targetName.."^7")
            local target = script.modelTarget(models, opts, dist)
            modelTargets[#modelTargets + 1] = target
            return target
        end
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

    if Config.System.DontUseTarget then
        exports.jim_bridge:removeEntityTarget(entity)
    end

    -- Check for target script and use that
    for i = 1, #targetFunc do
        local script = targetFunc[i]
        if isStarted(script.targetName) then
            script.removeTargetEntity(entity)
            break
        end
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

    if Config.System.DontUseTarget then
        exports.jim_bridge:removeZoneTarget(target)
    end

    -- Check for target script and use that
    for i = 1, #targetFunc do
        local script = targetFunc[i]
        if isStarted(script.targetName) then
            script.removeTargetZone(target)
            break
        end
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

    if Config.System.DontUseTarget then
        exports.jim_bridge:removeZoneTarget(model)
    end

    -- Check for target script and use that
    for i = 1, #targetFunc do
        local script = targetFunc[i]
        if isStarted(script.targetName) then
            script.removeTargetModel(model)
            break
        end
    end
end

function ShowFloatingHelpNotification(coord, text, highlight)
    AddTextEntry("FloatingText", text)
    SetFloatingHelpTextWorldPosition(1, coord.x, coord.y, coord.z)
    SetFloatingHelpTextStyle(1, 1, 62, -1, 3, 0)
    BeginTextCommandDisplayHelp("FloatingText")
    EndTextCommandDisplayHelp(2, false, false, -1)
end

-------------------------------------------------------------
-- Cleanup on Resource Stop
-------------------------------------------------------------

local function CleanupTargets()
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
            exports[QBTargetExport]:RemoveZone(boxTargets[i])
        end
    end
    -- Remove circle zone targets.
    for i = 1, #circleTargets do
        if isStarted(OXTargetExport) then
            exports[OXTargetExport]:removeZone(circleTargets[i], true)
        elseif isStarted(QBTargetExport) then
            exports[QBTargetExport]:RemoveZone(circleTargets[i])
        end
    end
end

onPlayerUnload(function()
    CleanupTargets()
end)

-- When the current resource stops, remove all targets.
onResourceStop(function()
    CleanupTargets()
end, true)