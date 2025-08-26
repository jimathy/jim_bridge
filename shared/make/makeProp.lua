local Props = {}
local distProps = {}

--- Creates a prop (object) in the game world at specified coordinates.
---
--- This function loads the model, creates the object, sets its heading, and freezes it if specified.
---
---@param data table A table containing prop data.
--- - **prop** `string`: The model name or hash of the prop to create.
--- - **coords** `vector4`: The coordinates where the prop will be placed. Should include x, y, z, and w (heading).
---@param freeze boolean (optional) Whether to freeze the prop in place. Defaults to `false`.
---@param synced boolean (optional) Whether the prop should be synced across clients. Defaults to `false`.
---
---@return number entityID The handle of the created prop object.
---
---@usage
--- ```lua
--- local propData = {
---     prop = 'prop_chair_01a',
---     coords = vector4(123.4, 567.8, 90.1, 180.0)
--- }
--- local prop = makeProp(propData, true, false)
--- ```
function makeProp(data, freeze, synced, fade)
    loadModel(data.prop)
    local prop = CreateObject(data.prop, data.coords.x, data.coords.y, data.coords.z-1.03, synced and synced or false, synced and synced or false, false)
    SetEntityHeading(prop, (data.coords.w or 0) + 180.0)
    FreezeEntityPosition(prop, freeze or false)

    debugPrint("^6Bridge^7: ^1Prop ^2Created^7: '^6"..prop.."^7' | ^2Hash^7: ^7'^6"..data.prop.."^7' | ^2Coord^7: "..formatCoord(data.coords))
    SetModelAsNoLongerNeeded(data.prop)
    Props[keyGen()..keyGen()] = prop
    if fade ~= false and gameName ~= "rdr3" then
        SetEntityAlpha(prop, 0, false)
        CreateThread(function()
            fadeInEnt(prop)
        end)
    end
    return prop
end

--- Creates a prop that appears when the player is within a certain distance.
---
--- This function sets up a proximity area, and when the player enters it, the prop is created.
--- When the player exits the area, the prop is destroyed.
---
---@param data table A table containing prop data.
--- - **prop** `string`: The model name or hash of the prop to create.
--- - **coords** `vector4`: The coordinates where the prop will be placed. Should include x, y, z, and w (heading).
---@param freeze boolean (optional) Whether to freeze the prop in place. Defaults to `false`.
---@param synced boolean (optional) Whether the prop should be synced across clients. Defaults to `false`.
---
---@usage
--- ```lua
--- local propData = {
---     prop = 'prop_chair_01a',
---     coords = vector4(123.4, 567.8, 90.1, 180.0)
--- }
--- makeDistProp(propData, true, false)
--- ```
function makeDistProp(data, freeze, synced, range, func)
    local name = keyGen()..keyGen()
    distProps[#distProps + 1] = createCirclePoly({
        name = name,
        coords = vec3(data.coords.x, data.coords.y, data.coords.z - 1.03),
        radius = range or 50.0,
        onEnter = function()
            Props[name] = makeProp(data, freeze, synced)
            if func then
                func(Props[name])
            end
        end,
        onExit = function()
            destroyProp(Props[name])
            Props[name] = nil
        end,
        debug = debugMode,
    })
end

--- Destroys a prop, detaching it if attached to the player beforehand.
---
---@param entity number The handle of the prop entity to destroy.
---
---@usage
--- ```lua
--- destroyProp(prop)
--- ```
function destroyProp(entity)
    if entity then
        debugPrint("^6Bridge^7: ^2Destroying Prop^7: '^6"..entity.."^7'")
        if IsEntityAttachedToEntity(entity, PlayerPedId()) then
            SetEntityAsMissionEntity(entity)
            DetachEntity(entity, true, true)
        end
        DeleteObject(entity)
    end
end

onPlayerUnload(function()
    for k in pairs(Props) do
        DeleteObject(Props[k])
    end
    for i = 1, #distProps do
        removeZoneTarget(distProps[i])
    end
    distProps = {}
end)

--- Cleans up all created props when the resource stops.
onResourceStop(function()
    for k in pairs(Props) do
        destroyProp(Props[k])
    end
end, true)
