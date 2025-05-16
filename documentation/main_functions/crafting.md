### crafting.lua

These functions support crafting logic, such as opening crafting menus, handling multi-craft operations, and creating item data from recipes.

- **craftingMenu(data)**

  - Opens a menu for selecting the quantity to craft.
  - Presents the player with multiple crafting quantities based on `Config.Crafting.MultiCraftAmounts`.
  - **Parameters:**
    - `item` (`string`): The item to craft.
    - `craft` (`table`): The crafting recipe.
    - `craftable` (`table`): Crafting options.
    - `coords` (`vector3`): Where crafting occurs.
    - `stashName` (`string`): The stash name(s) for item availability.
    - `onBack` (`function`): Callback when returning.
    - `metadata` (`table`, optional): Metadata for the crafted item.
  - **Example:**
    ```lua
    craftingMenu({
         craftable = {
             Header = "Weapon Crafting",
             Recipes = {
                 [1] = {
                     ["weapon_pistol"] = { ["steel"] = 5, ["plastic"] = 2 },
                     amount = 1,
                 },
                 -- More recipes...
             },
             Anims = {
                 animDict = "amb@prop_human_parking_meter@male@idle_a",
                 anim = "idle_a",
             },
         },
         coords = vector3(100.0, 200.0, 300.0),
         stashTable = "crafting_stash",
         job = "mechanic",
         onBack = function() print("Returning to previous menu") end,
    })
    ```
