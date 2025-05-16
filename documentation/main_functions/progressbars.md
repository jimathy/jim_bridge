### progressBars.lua
This module provides a unified progress bar system compatible with various UI frameworks.

❔It also contains an experimental "Shared Progressbar" system which was created for things like "giving an item to another player"

- **progressBar(data)**
  - Displays a progress bar using the current configured system (e.g., ox_lib, qb, etc).
  - **Example:**
    ```lua
    local success = progressBar({
        label = "Processing...",
        time = 5000,
        dict = "amb@world_human_hang_out_street@female_hold_arm@base",
        anim = "base",
        flag = 49,
        cancel = true,
    })
    if success then
        print("Success!")
    else
        print("Cancelled")
    end
    ```