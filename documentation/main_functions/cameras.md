### cameras.lua
This module provides utilities for managing temporary in-game cameras, useful for cutscenes, cinematic views, or scripted perspectives.

- **createTempCam(ent, coords)**

  - Creates a temporary camera at the specified coordinates or relative to an entity.
  - If `ent` is an entity, the camera position is calculated as an offset from the entity's position using `GetOffsetFromEntityInWorldCoords`.
  - If `ent` is a `vector3`, it is used directly as the camera's position.
  - **Example:**
    ```lua
    local cam = createTempCam(PlayerPedId(), GetEntityCoords(PlayerPedId()) + vector3(0, 2.0, 1.0))
    ```

- **startTempCam(cam)**

  - Activates and renders the temporary camera.
  - **Example:**
    ```lua
    startTempCam(cam)
    ```

- **stopTempCam()**

  - Deactivates and deletes all currently running custom camera, restoring normal view.
  - **Example:**
    ```lua
    stopTempCam()
    ```