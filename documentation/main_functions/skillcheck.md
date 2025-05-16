### skillcheck.lua

This module provides a UI-based skill check system, useful for crafting, hacking, or other interactive gameplay scenarios.

- **skillCheck()**

  - Starts a skill check minigame sequence using the provided configuration.
  - Configuration may define speed, difficulty, bar size, or success zones.
  - **Example:**
    ```lua
    if skillCheck() then
        print("Success!")
    else
        print("Failed :(")
    end
    ```