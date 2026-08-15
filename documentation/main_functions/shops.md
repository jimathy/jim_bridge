### shops.lua

This module provides functions to open, sell to, and register in-game shops and markets.

- **registerSellShop(name, coords, items)**

  - Registers a sell shop on the **server**, sales are validated against this registration.
  - The prices paid out always come from this table, prices sent by clients are ignored.
  - Call it again with another coords to add more locations for the same shop.
  - Pass the same table you give to sellMenu() as `items` (nested categories are flattened automatically).
  - **Example:**
    ```lua
    -- server side
    registerSellShop("pawnshop", vector3(100.0, 200.0, 300.0), {
        Header = "Sell Items",
        Items = {
            ["gold_ring"] = 100,
            ["diamond"] = 500,
        },
    })
    ```

- **sellMenu(data)**

  - Opens a UI menu for selling items to a vendor or market system.
  - A simple system for the ability to sell all of an item in a players inventory
  - Good for money making eg. pawn shops
  - `name` must match a shop registered with registerSellShop() on the server.
  - **Example:**
    ```lua
    sellMenu({
        name = "pawnshop",
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
  - `shop` must match a shop registered with registerSellShop(), the server pays the price registered there.
  - **Example:**
    ```lua
    sellAnim({
       item = "gold_ring",
       price = 100,
       shop = "pawnshop",
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