### helpers.lua
This utility module provides functions for resource checks, debugging, formatting, coordinate math, vector calculations, progress bars, and drawing tools.

- **isStarted(script)**
  - Returns `true` if a resource is started.
  - **Example:**
    ```lua
    if isStarted("myResource") then print("Resource is running") end
    ```

- **getScript()**
  - Caches and returns the name of the current resource.
  - Easier than typing `GetCurrentResourceName()` over and over
  - **Example:**
    ```lua
    print("Current script:", getScript())
    ```

- **isServer()**
  - Returns true if running on the server.
  - This was mainly made becuase `IsDuplicityVersion()` kept confusing me
  - **Example:**
    ```lua
    if isServer() then print("Server-side!") end
    ```

- **debugPrint(...)** / **eventPrint(...)**
  - Prints messages with debug context if debugMode is enabled.
  - **Example:**
    ```lua
    debugPrint("Loaded object:", objName)
    ```

- **jsonPrint(table)**
  - Pretty-prints a table with colorized JSON if debugMode is enabled.
  - **Example:**
    ```lua
    jsonPrint(myData)
    ```

- **keyGen()**
  - Generates a 3-character unique ID.
  - Good grabbing randomly generated strings
  - **Example:**
    ```lua
    print("Generated Key:", keyGen())
    ```

- **cv(amount)**
  - Comma-separates a number (e.g., `1000000` to `1,000,000`).
  - **Example:**
    ```lua
    print(cv(1000000)) -- "1,000,000"
    ```

- **formatCoord(vec)**
  - Outputs a formatted string from vector types.
  - Compacts and adds console colours to the vector to be printed
  - **Example:**
    ```lua
    print(formatCoord(vector3(123.45, 678.9, 10.0)))
    ```

- **getCenterOfZones(coords)**
  - Returns average center position of a vector3 list.
  - A few use cases, but I used it to see how well spaced blips were together
  - **Example:**
    ```lua
    local center = getCenterOfZones({vector3(0,0,0), vector3(10,10,0)})
    ```

- **countTable(tbl)**
  - Returns the number of entries in a table.
  - Simple function to print how many "entires" are in a table
  - **Example:**
    ```lua
    print(countTable({a=1,b=2,c=3})) -- 3
    ```

- **pairsByKeys(tbl)**
  - Iterator for sorted keys.
  - **Example:**
    ```lua
    for k, v in pairsByKeys(myTable) do print(k, v) end
    ```

- **concatenateText(tbl)**
  - Joins string table entries with newlines.
  - **Example:**
    ```lua
    print(concatenateText({"Line 1", "Line 2"}))
    ```

- **RotationToDirection(rot)**
  - Converts a heading vector to a directional vector.
  - **Example:**
    ```lua
    local dir = RotationToDirection(rotation)
    ```

- **basicBar(percent)**
  - Returns a bar like `████░░░░░` at 50%.
  - Basically a progress bar but as a string, I use this in drawTexts when progressbars aren't able to be used
  - **Example:**
    ```lua
    print(basicBar(50))
    ```

- **normalizeVector(vec)**
  - Returns a normalized version of a vector3.
  - **Example:**
    ```lua
    local norm = normalizeVector(vector3(3,4,0))
    ```

- **drawLine(start, end, color)** / **drawSphere(pos, color)**
  - Debug drawing helpers.
  - Stays visible for more than one frame
  - **Example:**
    ```lua
    drawLine(vector3(0,0,0), vector3(10,10,10), vector4(255,0,0,255))
    drawSphere(vector3(5,5,5), vector4(0,255,0,255))
    ```

- **PerformRaycast(start, end, entity?, flags?)**
  - Raycast with material detection. Returns ray hit data.
  - **Example:**
    ```lua
    local hit, hitPos, material = PerformRaycast(startVec, endVec, playerPed, 1)
    if hit == 1 then
        print("Hit at position:", hitPos)
        print("Material:", material)
    end
    ```

- **adjustForGround(coords)**
  - Adjusts a z-coordinate to ground height.
  - **Example:**
    ```lua
    coords = adjustForGround(vector3(100, 200, 300))
    ```

- **ensureNetToVeh(id)** / **ensureNetToEnt(id)**
  - Resolves net ID to entity safely.
  - **Example:**
    ```lua
    local veh = ensureNetToVeh(netId)
    ```

- **sendLog(text)** / **sendServerLog(data)**
  - Logging helpers, includes player name, coords, script source.
  - **Example:**
    ```lua
    sendLog("Suspicious activity detected")
    ```

- **GetGroundMaterialAtPosition(coords)**
  - Returns the material hash + readable name from the surface below coords.
  - **Example:**
    ```lua
    local hash, name = GetGroundMaterialAtPosition(vector3(0,0,0))
    ```

- **GetPropDimensions(model)**
  - Loads a model and returns width, depth, height.
  - I use this to parse a model to create a box target instead of entity target when creating distProps/distPeds
  - **Example:**
    ```lua
    local w,d,h = GetPropDimensions("prop_barrel_01a")
    ```

- **GetEntityForwardVector(entity)**
  - Returns the forward direction vector based on entity heading.
  - **Example:**
    ```lua
    local fwd = GetEntityForwardVector(PlayerPedId())
    ```