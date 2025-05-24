### stashcontrol.lua

This module handles logic for interacting with stashes—shared inventories for crafting, jobs, or storage systems.

- **checkStashItem(stashes, itemTable)**

  - Retrieves (or updates) a local stash cache entry with a timeout.
  - **Example:**
    ```lua
    local found, foundinStash = checkStashItem({"crafting_stash"}, { item = "steel", amount = 2 })
    if found then print("Found item in "..foundInStash) end
    ```

- **openStash(data)**

  - Opens a stash using the active inventory system.
  - Checks for job or gang restrictions before opening the stash.
  - **Example:**
    ```lua
    openStash({
        stash = "playerStash",
        label = "Player Stash",
        coords = vector3(100, 200, 30)
    })
    ```

- **getStash(stashName)**

  - Retrieves the stash data by name (usually used for querying contents).
  - **Example:**
    ```lua
    local items = getStash("playerStash")
    for k, v in pairs(items) do
        print(k)
    end
    ```

- **stashRemoveItem(stashItems, stashName, items)**

  - Removes specified items from a stash. Used during crafting or transfers.
  - **Example:**
    ```lua
    stashRemoveItem(currentItems, "playerStash", { iron = 2, wood = 5 })
    ```
