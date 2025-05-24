### polyZone.lua

This module provides helpers for creating and removing polygon or circular zones using PolyZone-compatible data structures.

- **createPoly(data)**

  - Creates a polygonal zone using the detected polyzone library (ox_lib or PolyZone).
  - Automatically checks which polyzone script is active. When using ox_lib, it converts the provided 2D points to 3D (setting a constant z value) and sets a thickness value.
  - For PolyZone, it creates the zone and attaches onEnter and onExit callbacks for ease of use.
  - **Example:**
    ```lua
    createPoly({
        name = 'testZone',
        debug = true,
        points = { vec2(100.0, 100.0), vec2(200.0, 100.0), vec2(200.0, 200.0), vec2(100.0, 200.0) },
        onEnter = function() print("Entered Test Zone") end,
        onExit = function() print("Exited Test Zone") end,
    })
    ```

- **createCirclePoly(data)**

 - When using ox_lib, it creates a sphere zone. For PolyZone, it creates a CircleZone and attaches onEnter and onExit callbacks.
  - **Example:**
    ```lua
    createCirclePoly({
        name = 'circleZone',
        coords = vector3(150.0, 150.0, 20.0),
        radius = 50.0,
        onEnter = function() print("Entered Circle Zone") end,
        onExit = function() print("Exited Circle Zone") end,
    })
    ```

- **removePolyZone(Location)**

  - Removes a previously created polygon or circle zone by name.
  - Detects the active polyzone library and calls the appropriate removal method.
  - **Example:**
    ```lua
    local zone = createPoly({...})
    ---
    removePolyZone(zone)
    ```