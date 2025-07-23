--[[
    PolyZone Management Module
    ----------------------------
    This module automatically detects the available polyzone library (ox_lib or PolyZone)
    and creates polygonal and circular zones accordingly. It also provides a function to remove
    previously created zones.

    Functions:
      • createPoly(data)       - Creates a polygonal zone.
      • createCirclePoly(data) - Creates a circular zone.
      • removePolyZone(Location) - Removes a created zone.
]]

-------------------------------------------------------------
-- Polygonal Zone Creation
-------------------------------------------------------------

--- Creates a polygonal zone using the detected polyzone library (ox_lib or PolyZone).
---
--- Automatically checks which polyzone script is active. When using ox_lib, it converts the provided
--- 2D points to 3D (setting a constant z value) and sets a thickness value. For PolyZone, it creates the zone
--- and attaches onEnter and onExit callbacks.
---
--- @param data table Zone configuration table with the following keys:
---     - name (string): The zone's identifier.
---     - debug (boolean): Whether debug mode is enabled.
---     - points (table): A list of vec2 points defining the polygon.
---     - onEnter (function): Callback when a player enters the zone.
---     - onExit (function): Callback when a player exits the zone.
---
--- @return table|nil table Returns the created zone object or nil if creation failed.
---
---@usage
---```lua
---createPoly({
---    name = 'testZone',
---    debug = true,
---    points = { vec2(100.0, 100.0), vec2(200.0, 100.0), vec2(200.0, 200.0), vec2(100.0, 200.0) },
---    onEnter = function() print("Entered Test Zone") end,
---    onExit = function() print("Exited Test Zone") end,
---})
---```
function createPoly(data)
    local Location = nil
    if isStarted(OXLibExport) then
        debugPrint("^6Bridge^7: ^2Creating new poly with ^7'^4"..OXLibExport.."^7': "..data.name)

        data.minZ = data.minZ or 12.0
        data.maxZ = data.maxZ or 1000.0
        data.thickness = ((data.maxZ / 2) - (data.minZ / 2)) * 2

        local mid = data.maxZ - ((data.maxZ / 2) - (data.minZ / 2))
        for i = 1, #data.points do
            data.points[i] = vec3(data.points[i].x, data.points[i].y, mid)
        end

        Location = lib.zones.poly(data)

    elseif isStarted("PolyZone") then
        debugPrint("^6Bridge^7: ^2Creating new poly with ^7'^4PolyZone^7': "..data.name)
        Location = PolyZone:Create(data.points, {
            name = data.name,
            minZ = data.minZ or nil,
            maxZ = data.maxZ or nil,
            debugPoly = data.debug
        })
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
    return Location
end

-------------------------------------------------------------
-- Circular Zone Creation
-------------------------------------------------------------

--- Creates a circular zone using the detected polyzone library (ox_lib or PolyZone).
---
--- When using ox_lib, it creates a sphere zone. For PolyZone, it creates a CircleZone and attaches
--- onEnter and onExit callbacks.
---
--- @param data table Zone configuration with the following keys:
---     - name (string): The zone's identifier.
---     - coords (vector3): The center of the circle.
---     - radius (number): The radius of the circle.
---     - onEnter (function): Callback when a player enters the zone.
---     - onExit (function): Callback when a player exits the zone.
---
--- @return table|nil table Returns the created circular zone object or nil if creation failed.
---
--- @usage
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
    if isStarted(OXLibExport) then
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
        print("^4ERROR^7: ^2No PolyZone creation script detected ^7- ^2Check ^3starter^1.^2lua^7")
    end
    debugPrint("^6Bridge^7: ^2Zone Stats - Coords: "..formatCoord(data.coords).." Radius: "..data.radius)
    return Location
end

-------------------------------------------------------------
-- PolyZone Removal Function
-------------------------------------------------------------

--- Removes a previously created polyzone.
---
--- Detects the active polyzone library and calls the appropriate removal method.
---
--- @param Location table The zone object to be removed.
---
--- @usage
--- ```lua
--- local zone = createPoly({...})
---
--- removePolyZone(zone)
--- ```
function removePolyZone(Location)
    if isStarted(OXLibExport) then
        debugPrint("^6Bridge^7: ^2Removing ^2poly with ^7"..OXLibExport)
        Location:remove()
    elseif isStarted("PolyZone") then
        debugPrint("^6Bridge^7: ^2poly with ^7PolyZone")
        Location:destroy()
    end
end