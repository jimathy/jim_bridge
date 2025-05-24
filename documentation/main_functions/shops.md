### shops.lua

This module provides functions to open, sell to, and register in-game shops and markets.

- **sellMenu(data)**

  - Opens a UI menu for selling items to a vendor or market system.
  - A simple system for the ability to sell all of an item in a players inventory
  - Good for money making eg. pawn shops
  - **Example:**
    ```lua
    sellMenu({
        sellTable = {
            Header = "Sell Items",
            Items = {
                ["gold_ring"] = 100,
                ["diamond"] = 500,
            },
        },
        ped = pedEntity,
        onBack = function() print("Returning to previous menu") end,
    })
    ```

- **sellAnim(data)**

  - Plays an animation during the selling process for immersion.
  - Used in sellMenu, but can be called externally if needed
  - **Example:**
    ```lua
    sellAnim({
       item = "gold_ring",
       price = 100,
       ped = pedEntity,
       onBack = function() print("Sold Items") end,
    )
    ```

- **openShop(data)**

  - Opens a shop interface for purchasing items.
  - Checks job/gang restrictions, then uses the active inventory system to open the shop.
  - **Example:**
    ```lua
    openShop({
        shop = "weapon_shop",
        items = weaponShopItems,
        coords = vector3(100.0, 200.0, 300.0),
        job = "police",
    })
    ```

- **registerShop(name, label, items, society)**

  - Registers a named shop with associated items and an optional society for fund handling.
  - Supports either OXInv or QBInv (with QBInvNew flag).
  - **Example:**
    ```lua
    registerShop("fishing_shop", "Bait & Tackle", {
        { item = "fishing_rod", price = 50 },
        { item = "bait", price = 5 }
    }, "fishing_society")
    ```