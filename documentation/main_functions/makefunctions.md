### makeBlip.lua

This module provides simple utilities for adding static or entity-based blips to the minimap.

❔ This has basic support for RedM too
- **makeBlip(data)**

  - This function adds a map blip at the provided coordinates and sets various display properties such as sprite, color, scale, and more.
  - It also handles attaching a preview image to the blip if certain resources are running and a preview is provided.
  - **Example:**
    ```lua
    local blipData = {
        coords = vector3(123.4, 567.8, 90.1),
        sprite = 1,
        col = 2,
        scale = 0.8,
        disp = 4,
        category = 7,
        name = "My Blip",
        preview = "http://example.com/preview.png"
    }
    local blip = makeBlip(blipData)
    ```

- **makeEntityBlip(data)**

  - This function adds a map blip attached to the provided entity and sets various display properties such as sprite, color, scale, and more.
  - It also handles attaching a preview image to the blip if certain resources are running and a preview is provided.
  - **Example:**
    ```lua
    local blipData = {
        entity = myEntity,
        sprite = 1,
        col = 2,
        scale = 0.8,
        disp = 4,
        category = 7,
        name = "Entity Blip",
        preview = "http://example.com/preview.png"
    }
    local blip = makeEntityBlip(blipData)
    ```

### makePed.lua
This module provides tools to create persistent or distance-based NPCs with optional animations, scenarios, and config randomization.

- **makeDistPed(data, coords, freeze, collision, scenario, anim, synced)**

  - Creates a ped that only spawns when nearby (performance optimization).
  - **Example:**
    ```lua
    makeDistPed({model = "a_m_y_business_03" },                                 -- model data
        vector4(450.0, -980.0, 30.0, 100.0),                                    -- coords
        true,                                                                   -- freeze entity
        false,                                                                  -- collision
        'WORLD_HUMAN_STAND_IMPATIENT',                                          -- Scenario Animation
        { dict = "amb@world_human_clipboard@male@idle_a", anim = "idle_c" },    -- Anim Table
        true                                                                    -- Network Synced
    )
    ```

- **makePed(data, coords, freeze, collision, scenario, anim, synced)**

  - Spawns a ped with more persistent behavior at the given location.
  - Supports animation playback and freezing.
  - **Example:**
    ```lua
    makePed({model = "a_m_y_business_03" },                                 -- model data
        vector4(450.0, -980.0, 30.0, 100.0),                                    -- coords
        true,                                                                   -- freeze entity
        false,                                                                  -- collision
        'WORLD_HUMAN_STAND_IMPATIENT',                                          -- Scenario Animation
        { dict = "amb@world_human_clipboard@male@idle_a", anim = "idle_c" },    -- Anim Table
        true                                                                    -- Network Synced
    )
    ```

- **GenerateRandomPedData(data)**

  - Returns randomized ped model/configuration based on input table.
  - Useful for dynamic NPC generation.
  - **Example:**
    ```lua
    local pedData = GenerateRandomPedData({ model = `MP_M_Freemode_01`, custom = {} })
    ```

### makeProp.lua
This module allows you to spawn static or distance-loaded props in the world.

- **makeProp(data, freeze, synced)**

  - This function loads the model, creates the object, sets its heading, and freezes it if specified.
  - **Example:**
    ```lua
    local propData = {
        prop = 'prop_chair_01a',
        coords = vector4(123.4, 567.8, 90.1, 180.0)
    }
    local prop = makeProp(propData, true, false)
    ```

- **makeDistProp(data, freeze, synced, range)**
  - Same as `makeProp`, but only spawns if the player is within the specified range.
  - **Example:**
    ```lua
    local propData = {
        prop = 'prop_chair_01a',
        coords = vector4(123.4, 567.8, 90.1, 180.0)
    }
    makeDistProp(propData, true, false)
    ```

- **destroyProp(entity)**
  - Removes a previously created or targeted prop from the world.
  - **Example:**
    ```lua
    destroyProp(barrel)
    ```

### makeVeh.lua
This module provides functionality for spawning vehicles, including distance-based optimization and entity management.

- **makeVeh(model, coords)**

  - This function loads the vehicle model, creates the vehicle in the world at the given coordinates, sets initial properties, and returns the vehicle handle.
  - **Example:**
    ```lua
    local vehicle = makeVeh("adder", vector3(250.0, -1000.0, 30.0))
    ```

- **makeDistVehicle(data, radius, onEnter, onExit)**

  - Creates a vehicle that spawns when the player enters a designated polyzone area.
  - This is used for `jim-parking` to create a static vehicle that can't move
  - **Example:**
    ```lua
    makeDistVehicle({
        model = "blista",
        coords = vector3(400.0, -800.0, 30.0),
        heading = 180.0
    }, 50.0)
    ```

- **removeDistVehicleZone(zoneId)**
  - Removes a previously created distance-based vehicle zone.
  - **Example:**
    ```lua
    removeDistVehicleZone("garage_zone_1")
    ```

- **deleteVehicle(vehicle)**
  - Deletes a specified vehicle entity.
  - **Example:**
    ```lua
    deleteVehicle(vehicle)
    ```
