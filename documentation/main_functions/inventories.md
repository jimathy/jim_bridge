### inventories.lua

These functions manage inventory locking, item checking, and player inventory retrieval.

- **lockInv(toggle)**

  - Locks or unlocks the player's inventory.
  - Freezes/unfreezes movement and toggles hotbar state.
  - **Example:**
    ```lua
    lockInv(true)  -- Lock inventory
    lockInv(false) -- Unlock inventory
    ```

- **hasItem(items, amount, src)**

  - Checks if a player has the specified item(s) in sufficient quantity.
  - **Returns:**
    - `boolean`: Whether the player has the item(s).
    - `table`: Details of available item counts.
  - **Example:**
    ```lua
    local hasAll, details = hasItem({"health_potion", "mana_potion"}, 2, playerId)
    if hasAll then
        -- Proceed with action
    else
        -- Inform the player about missing items
    end
    ```

- **getPlayerInv(src)**

  - Retrieves the player’s current inventory.
  - May be used for inventory UI, logging, or crafting systems.
  - **Example:**
    ```lua
    local inventory = getPlayerInv(playerId)
    for k, item in pairs(inventory) do
        print(item.name, item.amount)
    end
    ```

### itemcontrol.lua

This module includes a variety of utility functions for managing items in player inventories, including giving, removing, durability, and use logic.

- **createUseableItem(item, funct)**

  ⚠️ This doesn't work for `ox_inv`, you will need to add the event info to it's `items.lua`
  - Registers a useable item and binds it to a callback function.
  - **Example:**
    ```lua
    createUseableItem("bandage", function(source)
        -- Heal logic here
    end)
    ```

- **invImg(item)**

  - Returns the inventory image path for an item.
  - Automatically grabs the inventory image link based on inventory script
  - **Example:**
    ```lua
    local imagePath = invImg("water_bottle")
    print(imagePath)
    ```

- **addItem(item, amount, info, src)**

  ⚠️ Requires Auth callback if called from client side
  - Adds a specific amount of an item to a player's inventory.
  - Automatically attempts to add items using detected inventory script
  - **Example:**
    ```lua
    -- Client Side
    addItem("lockpick", 3, {})

    -- Server Side
    addItem("lockpick", 3, {}, source)
    ```

- **removeItem(item, amount, src, slot)**

  - Removes a specific amount of an item from a player’s inventory.
  - Automatically attempts to remove item using detected inventory script
  - **Example:**
    ```lua
    -- Client Side
    removeItem(
        "ammo_pistol",
        30,
        nil,
        slot --[[optional]]--
    )

    -- Server Side
    removeItem(
        "ammo_pistol",
        30,
        source,
        slot --[[optional]]--
    )
    ```

- **dupeWarn(src, item, amount)**

  - Logs or handles a potential duplication exploit involving an item.
  - This is called automatically if a player has been triggered exploit detection
  - Disabled if debugMode is enabled

- **breakTool(data)**

  - Breaks a tool or item, often due to exceeding durability.
  - **Example:**
    ```lua
    breakTool({ item = "drill", damage = 10 })
    ```

- **getDurability(item)**

  - Returns the current durability value of a given item.
  - Searched for the lowest slot number (eg. slot 1) and retreives that items durability
  - **Example:**
    ```lua
    local durability, slot = getDurability("drill")
    if durability then
        print("Durability:", durability)
        print("Slot:", slot)
    end
    ```

- **canCarry(itemTable, src)**

  ⚠️ Currently server side only
  - Checks if a player can carry the item(s) specified in `itemTable`.
  - **Example:**
    ```lua
    local carryCheck = canCarry({ ["health_potion"] = 2, ["mana_potion"] = 3 }, playerId)
    if carryCheck["health_potion"] and carryCheck["mana_potion"] then
        -- Player can carry items.
    else
        -- Notify player.
    end
    ```
