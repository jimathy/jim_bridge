### scaleEntity.lua

This utility provides a simple interface to scale an entity (ped, object, vehicle) in the world.

⚠️ **Important:** Unless the model's collision is removed or modified, the scale will reset when interacted with by other entities (e.g., walking into it, driving over it).

- **scaleEntity(entity, scale)**

  - Scales the specified entity by the given factor.
  - **Parameters:**
    - `entity` (`number`): Entity handle (ped, object, vehicle).
    - `scale` (`number`): Scale factor (e.g., `1.0` is normal size, `0.5` is half size).
  - **Example:**
    ```lua
    scaleEntity(PlayerPedId(), 0.8) -- Shrinks player slightly
    ```

- **resetScale(entity)**

  - Resets the entity's scale back to its original default.
  - **Example:**
    ```lua
    resetScale(PlayerPedId()) -- Return to default size
    ```
