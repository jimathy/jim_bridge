-- This automatically detects what polyzone script it should use to create a polyzone --
-- if ox_lib is detected, it will automatically use that instead of PolyZone --
-- createPoly({ name = 'name', debug = true, points = { vec2(), vec2() }, onEnter = function() end, onExit = function() end, })
---
--- Creates a polygonal zone using the detected polyzone library (ox_lib or PolyZone).
---
--- This function automatically detects whether `ox_lib` or `PolyZone` is active and creates a polygonal zone accordingly.
--- It supports setting up entry and exit callbacks for the zone.
---
---@param data table A table containing the zone configuration.
--- - **name** (`string`): The name of the zone.
--- - **debug** (`boolean`): Whether to enable debug mode for the zone.
--- - **points** (`table`): A list of `vec2` points defining the polygon.
--- - **onEnter** (`function`): Callback function to execute when a player enters the zone.
--- - **onExit** (`function`): Callback function to execute when a player exits the zone.
---
---@return table|nil table Returns the created zone object or `nil` if creation failed.
---
---@usage
--- ```lua
--- createPoly({
---     name = 'testZone',
---     debug = true,
---     points = { vec2(100.0, 100.0), vec2(200.0, 100.0), vec2(200.0, 200.0), vec2(100.0, 200.0) },
---     onEnter = function() print("Entered Test Zone") end,
---     onExit = function() print("Exited Test Zone") end,
--- })
--- ```
function createPoly(data)
    local Location = nil
    if isStarted(OXLibExport) then -- if it finds ox_lib, use it instead of PolyZone
        debugPrint("^6Bridge^7: ^2Creating new poly with ^7'^4"..OXLibExport.."^7': "..data.name)
        for i = 1, #data.points do
            data.points[i] = vec3(data.points[i].x, data.points[i].y, 12.0)
        end
        data.thickness = 1000
        Location = lib.zones.poly(data)
    elseif isStarted("PolyZone") then
        debugPrint("^6Bridge^7: ^2Creating new poly with ^7'^4PolyZone^7': "..data.name)
        Location = PolyZone:Create(data.points, { name = data.name, debugPoly = data.debug })
        Location:onPlayerInOut(function(isPointInside)
            if isPointInside then data.onEnter() else data.onExit() end
        end)
    else
        print("^4ERROR^7: ^2No PolyZone creation script detected ^7- ^2Check ^3exports^1.^2lua^7")
    end
    return Location
end

--- Creates a circular zone using the detected polyzone library (ox_lib or PolyZone).
---
--- This function automatically detects whether `ox_lib` or `PolyZone` is active and creates a circular zone accordingly.
--- It supports setting up entry and exit callbacks for the zone.
---
---@param data table A table containing the circular zone configuration.
--- - **name** (`string`): The name of the circular zone.
--- - **coords** (`vector3`): The center coordinates of the circle.
--- - **radius** (`number`): The radius of the circle.
--- - **onEnter** (`function`): Callback function to execute when a player enters the zone.
--- - **onExit** (`function`): Callback function to execute when a player exits the zone.
---
---@return table|nil table Returns the created circular zone object or `nil` if creation failed.
---
---@usage
--- ```lua
--- createCirclePoly({
---     name = 'circleZone',
---     coords = vector3(150.0, 150.0, 20.0),
---     radius = 50.0,
---     onEnter = function() print("Entered Circle Zone") end,
---     onExit = function() print("Exited Circle Zone") end,
--- })
--- ```
function createCirclePoly(data)
    local Location = nil
    if isStarted(OXLibExport) then -- if it finds ox_lib, use it instead of PolyZone
        debugPrint("^6Bridge^7: ^2Creating new ^3Cricle^2 poly with ^7"..OXLibExport.." "..data.name)
        Location = lib.zones.sphere(data)
    elseif isStarted("PolyZone") then
        debugPrint("^6Bridge^7: ^2Creating new ^3Cricle^2 poly with ^7PolyZone ".. data.name)
        Location = CircleZone:Create(data.coords, data.radius, { name = data.name, debugPoly = debugMode })
        Location:onPlayerInOut(function(isPointInside)
            if isPointInside then
                data.onEnter()
            else
                data.onExit()
            end
        end)
    else
        print("^4ERROR^7: ^2No PolyZone creation script detected ^7- ^2Check ^3exports^1.^2lua^7")
    end
    debugPrint("^6Bridge^7: ^2Zone Stats - Coords: "..formatCoord(data.coords).." Radius: "..data.radius)
    return Location
end

--- Removes a previously created polyzone.
---
--- This function detects the active polyzone library (`ox_lib` or `PolyZone`) and removes the specified zone accordingly.
---
--- @param Location table The zone object to be removed.
---
--- @usage
--- ```lua
--- local zone = createPoly({...})
--- -- Later in the code
--- removePolyZone(zone)
--- ```
function removePolyZone(Location)
    if isStarted(OXLibExport) then -- if it finds ox_lib, use it instead of PolyZone
        debugPrint("^6Bridge^7: ^2Removing ^2poly with ^7"..OXLibExport)
        Location:remove()
    elseif isStarted("PolyZone") then
        debugPrint("^6Bridge^7: ^2poly with ^7PolyZone")
        Location:destroy()
    end
end