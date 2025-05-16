### jobfunctions.lua

This module provides functions for managing job-based logic, such as checking player roles, toggling duty status, and simulating job-related interactions.

- **makeBossRoles(role)**

  - Sets up boss-level permissions or access for the specified job role.
  - Often used to determine if a player can access job menus or perform administrative actions.
  - Used mainly for creating boss locked target tables
  - **Example:**
    ```lua
    makeBossRoles("police")
    ```

- **jobCheck(job)**

  - Simple check if the player has the specified job.
  - **Example:**
    ```lua
    if jobCheck("mechanic") then
        -- Allow mechanic features.
    else
        -- Deny access.
    end
    ```

- **toggleDuty()**

  - Toggles the player’s on/off duty status, typically used for jobs like police, EMS, etc.
  - **Example:**
    ```lua
    toggleDuty()
    ```

- **washHands(data)**

  - Simulates the action of washing hands, used in job scripts or medical job logic.
  - Currently only animation and a notfication
  - **Example:**
    ```lua
    washHands({ coords = vector3(200.0, 300.0, 40.0) })
    ```

- **useToilet(data)**

  - Triggers toilet-use interaction, likely includes animation or sound.
  - Currently only animation and a notfication
  - **Example:**
    ```lua
    useToilet({ urinal = true })
    -- Player uses a urinal with corresponding animations and notifications

    useToilet({ urinal = false, sitcoords = vector4(215.76, -810.12, 29.73, 90.0) })
    -- Player sits down to use a toilet with corresponding animations and notifications
    ```

- **useDoor(data)**

  - Handles interactions with doors that aren't openable and teleports the player
  - eg. Recycle Center, it's used to teleport the player from outside a building to the IPL
  - **Example:**
    ```lua
    useDoor({ telecoords = vector4(215.76, -810.12, 29.73, 90.0) })
    ```