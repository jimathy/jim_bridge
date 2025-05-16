### targets.lua

⚠️ This module provides utility functions for adding and removing interaction targets with entities, models, zones, and coordinates. Supports common targeting frameworks like `ox_target`, `qb-target`, and more.

- **createEntityTarget(entity, opts, dist)**

  - Adds interaction targets to a specific in-world entity.
  - **Example:**
    ```lua
    createEntityTarget(entityId, {
       {
           action = function()
               openStorage()
           end,
           icon = "fas fa-box",
           job = "police",
           label = "Open Storage",
       },
    }, 2.0)
    ```

- **createBoxTarget(data, opts, dist)**

  - Creates an interactable box zone with configurable options.
  - **Example:**
    ```lua
    createBoxTarget(
       {
           'storageBox',
           vector3(100.0, 200.0, 30.0),
           2.0,
           2.0,
           {
               name = 'storageBox',
               heading = 100.0,
               debugPoly = true,
               minZ = 27.0,
               maxZ = 32.0,
           },
       },
    {
       {
           action = function()
               openStorage()
           end,
           icon = "fas fa-box",
           job = "police",
           label = "Open Storage",
       },
    }, 2.0)
    ```

- **createCircleTarget(data, opts, dist)**

  - Creates an interactable circular zone.
  - **Example:**
    ```lua
    createCircleTarget({
        name = 'centralPark',
        coords = vector3(200.0, 300.0, 40.0),
        radius = 50.0,
        options = { debugPoly = false }
    }, {
        { icon = "fas fa-tree", label = "Relax", action = relaxAction }
    }, 2.0)
    ```

- **createModelTarget(models, opts, dist)**

  - Adds interactions to all matching models globally.
  - **Example:**
    ```lua
    createModelTarget({ model1, model2 },
    {
       {
           action = function()
               openStorage()
           end,
           icon = "fas fa-box",
           job = "police",
           label = "Open Storage",
       },
    }, 2.0)
    ```

- **removeEntityTarget(entity)**

  - Removes all targets linked to the specified entity.
  - **Example:**
    ```lua
    removeEntityTarget(vehicle)
    ```

- **removeZoneTarget(target)**

  - Removes a named zone-based target.
  - **Example:**
    ```lua
    removeZoneTarget("shop_box")
    ```

- **removeModelTarget(model)**

  - Removes interactions tied to a model globally.
  - **Example:**
    ```lua
    removeModelTarget("prop_vend_soda")
    ```