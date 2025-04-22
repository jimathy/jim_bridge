# Jim_Bridge

This script is intended to be used with my all my scripts (soon)

It was started due to wanting to bring the same features from some scripts into others with minimal work and without multiple updates fer script

It BRIDGES frameworks and cores together through this script and does it best to detect what is being used to automate the process
- Having certain functions in one place makes it easier to update, enchance and fix things already in place
- This brings the possibility of branching to mutliple frameworks as I've added some already:
    - `"qb-core"`
    - `"qbx-core"`
    - `"ox_core"`
    - `"es_extended"` - requires ox_lib and ox_inventory
    - `"rsg-core"` - basic support for RedM's RSG Core

All of my scripts will use this script and be added as a dependancy

This was originally designed to be used for my scripts but has grown into a whole framework of unified functions that anyone can use for their own, I encourage it

------

## I want this script to grow with help of others who know more about other cores, I'm not a book of framework knowledge
This script was designed by me through over a year of research and testing.
Some of it of it hasn't been personally tested but the information has been gathered through documentation on other scripts
I hope it works as well I intend, but feel free to do pull requests if you know how to fix an issue

(Please also keep it to a similar format to prevent breakages in other scripts)

------

## Installation

The installation of this script is simple
- REMOVE `-main` from the folder name, like any other github hosted script
- It just needs to start before any script that requires it
- It can start before core scripts if you want
- For example with `qb-core` I personally place this script in `resources > [standalone]`

### Optional

I've added the ability to add override server convars to your server.cfg
- This can be used to ensure you don't have silly mistakes like forgetting to change what inventory system you use
- Also it can force debug mode off, to ensure your live server doesn't accidently get polyzones and debug information showing
- This isn't required but helpful if you are like me

```
# Jim Config Settings
# These optional but forces settings for all jim scripts
#-------
# Add this to your live server.cfg and set to true to force debug mode off
# Set to false if to dev server to allow debug mode
setr jim_DisableDebug true
setr jim_DisableEventDebug true

# Force the default setting for what framework scripts should be used
setr jim_menuScript qb              # qb, ox, gta, jim
setr jim_notifyScript gta           # qb, ox, gta, esx, okok, red
setr jim_drawTextScript qb          # qb, ox, gta, esx
setr jim_progressBarScript qb       # qb, ox, gta, esx
setr jim_skillCheckScript qb        # qb, ox, gta
setr jim_dontUseTarget false         # Set to true to disable target systems and use draw text 3d
```

-----

## Support for different frameworks and scripts

In `starter.lua` is the list of script folder names, this is already setup but this is for people who have customised/renamed their cores or scripts

# WIP
## Documentation

## Usage

In your own resource, simply call the desired function exported from `jim_bridge`. Each function is built to work across multiple frameworks, offering compatibility and consistency.

```lua
-- Example usage:
createCallback("myCallback", function(data)
    print("Callback received:", data)
end)

triggerCallback("myCallback", "Hello World")
```

---

## Main Functions
### callback.lua

These functions wrap the native callback handling of the selected framework (e.g., OX, QBCore, ESX) instead of implementing a standalone callback system, ensuring full compatibility.

- **createCallback(callbackName, funct)**

  - Registers a callback function with the appropriate framework.
  - This function checks which framework is started (e.g., OX, QB, ESX) and registers the callback accordingly.
  - It adapts the callback function to match the expected signature for the framework.
  - **Example:**
    ```lua
    local table = { ["info"] = "HI" }
    createCallback('myCallback', function(source, ...)
        return table
    end)

    createCallback("callback:checkVehicleOwned", function(source, plate)
        local result = isVehicleOwned(plate)
        if result then
            return true
        else
            return false
        end
    end)
    ```

- **triggerCallback(callbackName, ...)**

  - Triggers a server callback and returns the result.
  - This function uses the appropriate framework's method to call the server-side callback and awaits the result.
  - **Example:**
    ```lua
    local result = triggerCallback('myCallback')
    jsonPrint(result)

    local result = triggerCallback("callback:checkVehicleOwned", plate)
    print(result)
    ```

### contextmenus.lua

These functions provide a unified way to interact with different context menu systems, such as OX and WarMenu, depending on what's available on the server.

- **openMenu(Menu, data)**

  - Opens a context menu using the preferred menu system.
  - Automatically selects between supported systems like OX or WarMenu based on availability.
  - The `Menu` parameter should be a list of menu entries, and the `data` parameter can be used to set headers, subtexts, and actions like `onBack`, `onExit`, and `canClose`.
  - **Example:**
    ```lua
    openMenu({
        { header = "Option 1", txt = "Description 1", onSelect = function() print("Option 1 selected") end },
        { header = "Option 2", txt = "Description 2", onSelect = function() print("Option 2 selected") end },
    }, {
        header = "Main Menu",
        headertxt = "Select an option",
        onBack = function() print("Return selected") end,
        onExit = function() print("Menu closed") end,
        canClose = true,
    })
    ```

- **isOx()**

  - Checks whether the OX context menu system is available on the server.
  - Allows to do specific things if ox_lib menu is in use
  - **Example:**
    ```lua
    if isOx() then
        print("OX Context Menu is available")
    end
    ```

- **isWarMenuOpen()**

  - Returns whether WarMenu is currently open.
  - Useful to prevent opening a new menu if one is already active.
  - **Example:**
    ```lua
    if not isWarMenuOpen() then
        openMenu("main_menu", menuData)
    end
    ```
  - Returns whether the WarMenu is currently open.

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

### drawText.lua

These functions handle drawing and hiding styled on-screen prompts or UI overlays, compatible with different styling frameworks such as OX Lib.

- **drawText(image, input, style, oxStyleTable)**

  - Displays styled text or prompts on screen.
  - Designed to adapt styling depending on which UI system (e.g., OX) is in use.
  - **Parameters:**
    - `image` (`string`): Optional icon or image path.
    - `input` (`string`): The main text to display.
    - `style` (`string|table`): Preset or custom styling.
    - `oxStyleTable` (`table`, optional): Extended style options if using OX UI.
  - **Example:**
    ```lua
    drawText("img_link", { "Test line 1", "Test Line 2" }, "~g~")
    ```

- **hideText()**

  - Hides any active text or UI element previously drawn with `drawText()`.
  - **Example:**
    ```lua
    hideText()
    ```

### duifunctions.lua

These functions support dynamic UI image rendering in 3D environments using runtime texture dictionaries. Ideal for integrating `nui://` or external `http://` image URLs into MLOs or world props.

- **createDui(name, http, size, txd))**

  - Sets up a runtime texture dictionary and links an image from a `nui://` or `http://` URL.
  - This function should be used once to create the texture dictionary needed for rendering Dui images.
  - **Example:**
    ```lua
    createDui("logo", "https://example.com/logo.png", { x = 512, y = 256 }, scriptTxd)
    ```

- **DuiSelect(data)**

  - Updates the URL on an existing texture dictionary to change the rendered image.
  - Can be used at runtime to swap out visuals in MLOs or props.
  - **Parameters:**
    - `textureDict` (`string`): The texture dictionary to target.
    - `texture` (`string`): The specific texture name to override.
    - `url` (`string`): The new image URL.
    - `width`, `height` (`number`): The texture resolution.
  - **Example:**
    ```lua
    DuiSelect({
        name = "logo",
        texn = "logoTex",
        texd = "someTxd",
        size = { x = 512, y = 256 }
    })
    ```

### input.lua

This function displays a customizable input dialog for user text or number entry. It supports both simple and complex input structures.

- **createInput(title, opts)**
  - Opens a styled input dialog with configurable fields, labels, input types, and validation.
  - Supports multiple field types including `text`, `number`, `password`, `checkbox`, `color`, `slider`, and more.
  - **Parameters:**
    - `title` (`string`): Title displayed at the top of the input box.
    - `opts` (`table`): A table of fields with attributes like `label`, `name`, `type`, `value`, and more.
  - **Example:**
    ```lua
    local userInput = createInput("Enter Details", {
        { type = "text", text = "Name", name = "playerName", isRequired = true },
        { type = "number", text = "Age", name = "playerAge", min = 18, max = 99 },
        { type = "radio", label = "Gender", name = "playerGender", options = {
            { text = "Male", value = "male" },
            { text = "Female", value = "female" },
            { text = "Other", value = "other" },
        }},
    })
    if userInput then
        print(json.encode(userInput))
    end
    ```

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

### metaHandlers.lua

This module provides access and control over player metadata, which is useful for storing temporary or persistent player-specific values like stats, states, or tags.

- **GetPlayer(source)**

  ⚠️ Server side only
  - Retrieves the player object (as defined by the framework in use) from the given `source` ID.
  - **Example:**
    ```lua
    local player = GetPlayer(playerId)
    ```

- **GetMetadata(player, key)**

  - Retrieves the value of a metadata field from the given player.
  - If called client-side (player is nil), it triggers a server callback to retrieve metadata.
  - **Example:**
    ```lua
    local stress = GetMetadata(player, "stress")
    print("Player stress level:", stress)
    ```

- **SetMetadata(player, key, value)**

  ⚠️ Server side only
  - Updates or assigns a value to a specific metadata key for a player.
  - The function updates the player's metadata using the active core export.
  - **Example:**
    ```lua
    SetMetadata(player, "stress", 0)
    ```

### notify.lua

This module provides a unified interface to trigger styled notifications across supported frameworks.

- **triggerNotify(title, message, type, src)**

  - Sends a notification to a player (or to the entire client if `src` is `nil`).
  - The notification style is determined by `type` (e.g., `success`, `error`, `info`).
  - **Parameters:**
    - `title` (`string`): The title or header of the notification.
    - `message` (`string`): The body or detail text.
    - `type` (`string`): Type of message (e.g., "success", "error", "info").
    - `src` (`number`, optional): Server ID of the player to notify (omit to notify locally).
  - **Example:**
    ```lua
    -- Client-side usage without specifying a player (shows to the current player)
    triggerNotify("Success", "You have completed the task!", "success")

    -- Server-side usage specifying a player by their server ID
    triggerNotify("Alert", "You have been warned for misconduct.", "error", source)
    ```

### phones.lua

This module allows you to send in-game mail/messages to player phones, depending on the phone system integrated (e.g., QB, NPWD).

- **sendPhoneMail(data)**

  - Sends a mail message to a player's in-game phone app.
  - Typically used to notify players about deliveries, missions, or reminders.
  - **Parameters:**
    - `data` (`table`): Must contain phone/mail system-compatible fields like `sender`, `subject`, `message`, and `receiver`.
  - **Example:**
    ```lua
    sendPhoneMail({
        subject = "Welcome!",
        sender = "Admin",
        message = "Thank you for joining our server.",
        actions = {
            { label = "Reply", action = replyFunction }
        }
    })
    ```

### playerfunctions.lua

This module contains helper functions for manipulating player states, interactions, and utility checks.

- **instantLookEnt(ent, ent2)**

  - Instantly turns an entity to face a target (entity or coordinates) without animation.
  - **Example:**
    ```lua
    instantLookEnt(nil, vector3(200.0, 300.0, 40.0))
    instantLookEnt(ped1, ped2)
    ```

- **lookEnt(entity)**

  - Makes the current player look toward the given entity.
  - Usually called after when opening a menu or something similar to make the player visually face the location
  - **Example:**
    ```lua
    lookEnt(vector3(200.0, 300.0, 40.0))
    lookEnt(pedEntity)
    ```

- **setThirst(src, thirst)**

  ⚠️ Server Side Only
  - Sets the thirst level of a player.
  - **Example:**
    ```lua
    setThirst(source, 75)
    ```

- **setHunger(src, hunger)**

  ⚠️ Server Side Only
  - Sets the hunger level of a player.
  - **Example:**
    ```lua
    setHunger(source, 50)
    ```

- **chargePlayer(cost, moneyType, newsrc)**

  ⚠️ Server Side Only
  - Deducts money from a player of the specified type (`cash`, `bank`, etc).
  - **Example:**
    ```lua
    chargePlayer(100, "cash", source)
    ```

- **fundPlayer(fund, moneyType, newsrc)**

  ⚠️ Server Side Only
  - Adds money to a player's balance of a given type.
  - **Example:**
    ```lua
    fundPlayer(250, "bank", source)
    ```

- **ConsumeSuccess(itemName, type, data)**

  - Handles logic when an item is successfully consumed (e.g., food, drink, etc).
  - Supports hunger and thirst info directly from table eg. `{ hunger = 10, thirst = 20 }`
  - **Example:**
    ```lua
    ConsumeSuccess("health_pack", "food", { hunger = 10 })

    ConsumeSuccess("beer", "alcohol", { thirst = 20 })
    ```

- **hasJob(job, source, grade)**

  - Checks if a player has a certain job and optionally checks for a specific grade.
  - Similar to `jobCheck()` but also retrieves as much player job info as possible
  - **Example:**
    ```lua
    -- Check if the player has the 'police' job and is on duty
    local hasPoliceJob, isOnDuty = hasJob("police")
    if hasPoliceJob and isOnDuty then
        -- Grant access to police-specific features
    end

    -- Check if a specific player has the 'gang_leader' job with at least grade 2
    local hasGangLeaderJob, _ = hasJob("gang_leader", playerId, 2)
    if hasGangLeaderJob then
        -- Allow gang leader actions
    end
    ```

- **getPlayer(source)**

  - Retrieves basic player information (name, cash, bank, job, etc.) based on the active core/inventory system.
  - Can be called server-side (passing a player source) or client-side (for current player).
  - Called often in my scripts as its makes use of frameworks "GetPlayerData" etc.
  - **Example:**
    ```lua
    -- Get information for a specific player
    local playerInfo = getPlayer(playerId)
    print(playerInfo.name, playerInfo.cash, playerInfo.bank)

    -- Get information for the current player (client-side)
    local myInfo = getPlayer()
    print(myInfo.name, myInfo.cash, myInfo.bank)
    ```

- **GetPlayersFromCoords(coords, radius)**

  - Returns a list of players within a specified radius of a set of coordinates.
  - **Example:**
    ```lua
    local nearby = GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), 10.0)
    for _, playerId in pairs(nearby) do
        print("Nearby player ID:", playerId)
    end
    ```

### polyZone.lua

This module provides helpers for creating and removing polygon or circular zones using PolyZone-compatible data structures.

- **createPoly(data)**

  - Creates a polygonal zone using the detected polyzone library (ox_lib or PolyZone).
  - Automatically checks which polyzone script is active. When using ox_lib, it converts the provided 2D points to 3D (setting a constant z value) and sets a thickness value.
  - For PolyZone, it creates the zone and attaches onEnter and onExit callbacks for ease of use.
  - **Example:**
    ```lua
    createPoly({
        name = 'testZone',
        debug = true,
        points = { vec2(100.0, 100.0), vec2(200.0, 100.0), vec2(200.0, 200.0), vec2(100.0, 200.0) },
        onEnter = function() print("Entered Test Zone") end,
        onExit = function() print("Exited Test Zone") end,
    })
    ```

- **createCirclePoly(data)**

 - When using ox_lib, it creates a sphere zone. For PolyZone, it creates a CircleZone and attaches onEnter and onExit callbacks.
  - **Example:**
    ```lua
    createCirclePoly({
        name = 'circleZone',
        coords = vector3(150.0, 150.0, 20.0),
        radius = 50.0,
        onEnter = function() print("Entered Circle Zone") end,
        onExit = function() print("Exited Circle Zone") end,
    })
    ```

- **removePolyZone(Location)**

  - Removes a previously created polygon or circle zone by name.
  - Detects the active polyzone library and calls the appropriate removal method.
  - **Example:**
    ```lua
    local zone = createPoly({...})
    ---
    removePolyZone(zone)
    ```

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

### societybank.lua

This module handles financial operations for society accounts, typically used for jobs or organizations.

- **getSocietyAccount(society)**

  - Retrieves the current balance for the specified society.
  - **Example:**
    ```lua
    local balance = getSocietyAccount("police")
    print("Police account balance: $"..balance)
    ```

- **chargeSociety(society, amount)**

  - Deducts a specified amount from the society's account.
  - **Example:**
    ```lua
    chargeSociety("police", 500)
    ```

- **fundSociety(society, amount)**

  - Adds funds to a society’s account.
  - **Example:**
    ```lua
    fundSociety("ambulance", 1200)
    ```

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

### targets.lua

⚠️ This module provides utility functions for adding and removing interaction targets with entities, models, zones, and coordinates. Supports common targeting frameworks like `ox_target`, `qb-target`, and more.

- **createEntityTarget(entity, opts, dist)**

  - Adds interaction targets to a specific in-world entity.
  - **Example:**
    ```lua
    createEntityTarget(entityId, {
       {
           action = function()
               openStorage()
           end,
           icon = "fas fa-box",
           job = "police",
           label = "Open Storage",
       },
    }, 2.0)
    ```

- **createBoxTarget(data, opts, dist)**

  - Creates an interactable box zone with configurable options.
  - **Example:**
    ```lua
    createBoxTarget(
       {
           'storageBox',
           vector3(100.0, 200.0, 30.0),
           2.0,
           2.0,
           {
               name = 'storageBox',
               heading = 100.0,
               debugPoly = true,
               minZ = 27.0,
               maxZ = 32.0,
           },
       },
    {
       {
           action = function()
               openStorage()
           end,
           icon = "fas fa-box",
           job = "police",
           label = "Open Storage",
       },
    }, 2.0)
    ```

- **createCircleTarget(data, opts, dist)**

  - Creates an interactable circular zone.
  - **Example:**
    ```lua
    createCircleTarget({
        name = 'centralPark',
        coords = vector3(200.0, 300.0, 40.0),
        radius = 50.0,
        options = { debugPoly = false }
    }, {
        { icon = "fas fa-tree", label = "Relax", action = relaxAction }
    }, 2.0)
    ```

- **createModelTarget(models, opts, dist)**

  - Adds interactions to all matching models globally.
  - **Example:**
    ```lua
    createModelTarget({ model1, model2 },
    {
       {
           action = function()
               openStorage()
           end,
           icon = "fas fa-box",
           job = "police",
           label = "Open Storage",
       },
    }, 2.0)
    ```

- **removeEntityTarget(entity)**

  - Removes all targets linked to the specified entity.
  - **Example:**
    ```lua
    removeEntityTarget(vehicle)
    ```

- **removeZoneTarget(target)**

  - Removes a named zone-based target.
  - **Example:**
    ```lua
    removeZoneTarget("shop_box")
    ```

- **removeModelTarget(model)**

  - Removes interactions tied to a model globally.
  - **Example:**
    ```lua
    removeModelTarget("prop_vend_soda")
    ```

### vehicles.lua

This module provides utilities for reading, modifying, and interacting with vehicle properties and positioning.

- **searchCar(vehicle)**

  - Searches the 'Vehicles' table for a specific vehicle's details.
  - If the vehicle differs from the last searched, it retrieves its model and updates the carInfo table.
  - The table includes the vehicle's name, price, and class information.
  - **Example:**
    ```lua
    local info = searchCar(vehicleEntity)
    print(info.name, info.price, info.class.name, info.class.index)
    ```

- **getVehicleProperties(vehicle)**

  - Retrieves the properties of a given vehicle using the active framework.
  - **Example:**
    ```lua
    local props = getVehicleProperties(vehicle)
    if props then
        print(json.encode(props))
    end
    ```

- **setVehicleProperties(vehicle, props)**

  - Sets the properties of a given vehicle if changes are detected.
  - It compares the current properties with the new ones and applies the update using the active framework.
  - **Example:**
    ```lua
    setVehicleProperties(vehicle, props)
    ```

- **checkDifferences(vehicle, newProps)**

  - Checks for differences between the current and new vehicle properties.
  - Compares properties using JSON encoding for deep comparison and logs differences.
  - **Example:**
    ```lua
    if checkDifferences(vehicleEntity, newProperties) then
        setVehicleProperties(vehicleEntity, newProperties)
    end
    ```

- **pushVehicle(entity)**

  - This function ensures that the vehicle is controlled by the current player and is set as a mission entity.
  - It requests network control and sets the vehicle accordingly to synchronize changes across clients.
  - **Example:**
    ```lua
    pushVehicle(vehicle)
    ```

- **getClosestVehicle(coords, src)**

  - Finds the closest vehicle to the specified coordinates.
  - The function uses different APIs based on whether a source is provided.
  - **Example:**
    ```lua
    local closestVeh, distance = getClosestVehicle({ x = 100, y = 200, z = 30 }, source)
    ```

### wrapperfunctions.lua

Provides wrapper compatibility functions for command and inventory stash systems across different frameworks (OX, QB, ESX, QS, etc).

- **registerCommand(command, options)**

  ⚠️ Server Side Only
  - Registers a command using the appropriate framework's API.
  - **Parameters:**
    - `command`: Command name (string)
    - `options`: Table including help, params, callback, autocomplete, restrictedGroup
  - **Example:**
    ```lua
    registerCommand("greet", {
        "Greets the player",
        { name = "name", help = "Name of the player to greet" },
        function(source, args) print("Hello, "..args[1].."!") end,
        nil,
        "admin"
    })
    ```

- **registerStash(name, label, slots?, weight?, owner?, coords?)**

  ⚠️ Server Side Only
  - Registers a stash using OX, QS, or Origen inventory systems.
  - **Example:**
    ```lua
    registerStash(
        "playerStash",
        "Player Stash",
        100,
        8000000,
        "player123",
        { x = 100.0, y = 200.0, z = 30.0 }
    )
    ```

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

### makeBlip.lua

This module provides simple utilities for adding static or entity-based blips to the minimap.

❔ This has basic support for RedM too
- **makeBlip(data)**

  - This function adds a map blip at the provided coordinates and sets various display properties such as sprite, color, scale, and more.
  - It also handles attaching a preview image to the blip if certain resources are running and a preview is provided.
  - **Example:**
    ```lua
    local blipData = {
        coords = vector3(123.4, 567.8, 90.1),
        sprite = 1,
        col = 2,
        scale = 0.8,
        disp = 4,
        category = 7,
        name = "My Blip",
        preview = "http://example.com/preview.png"
    }
    local blip = makeBlip(blipData)
    ```

- **makeEntityBlip(data)**

  - This function adds a map blip attached to the provided entity and sets various display properties such as sprite, color, scale, and more.
  - It also handles attaching a preview image to the blip if certain resources are running and a preview is provided.
  - **Example:**
    ```lua
    local blipData = {
        entity = myEntity,
        sprite = 1,
        col = 2,
        scale = 0.8,
        disp = 4,
        category = 7,
        name = "Entity Blip",
        preview = "http://example.com/preview.png"
    }
    local blip = makeEntityBlip(blipData)
    ```

### makePed.lua
This module provides tools to create persistent or distance-based NPCs with optional animations, scenarios, and config randomization.

- **makeDistPed(data, coords, freeze, collision, scenario, anim, synced)**

  - Creates a ped that only spawns when nearby (performance optimization).
  - **Example:**
    ```lua
    makeDistPed({model = "a_m_y_business_03" },                                 -- model data
        vector4(450.0, -980.0, 30.0, 100.0),                                    -- coords
        true,                                                                   -- freeze entity
        false,                                                                  -- collision
        'WORLD_HUMAN_STAND_IMPATIENT',                                          -- Scenario Animation
        { dict = "amb@world_human_clipboard@male@idle_a", anim = "idle_c" },    -- Anim Table
        true                                                                    -- Network Synced
    )
    ```

- **makePed(data, coords, freeze, collision, scenario, anim, synced)**

  - Spawns a ped with more persistent behavior at the given location.
  - Supports animation playback and freezing.
  - **Example:**
    ```lua
    makePed({model = "a_m_y_business_03" },                                 -- model data
        vector4(450.0, -980.0, 30.0, 100.0),                                    -- coords
        true,                                                                   -- freeze entity
        false,                                                                  -- collision
        'WORLD_HUMAN_STAND_IMPATIENT',                                          -- Scenario Animation
        { dict = "amb@world_human_clipboard@male@idle_a", anim = "idle_c" },    -- Anim Table
        true                                                                    -- Network Synced
    )
    ```

- **GenerateRandomPedData(data)**

  - Returns randomized ped model/configuration based on input table.
  - Useful for dynamic NPC generation.
  - **Example:**
    ```lua
    local pedData = GenerateRandomPedData({ model = `MP_M_Freemode_01`, custom = {} })
    ```

### makeProp.lua
This module allows you to spawn static or distance-loaded props in the world.

- **makeProp(data, freeze, synced)**

  - This function loads the model, creates the object, sets its heading, and freezes it if specified.
  - **Example:**
    ```lua
    local propData = {
        prop = 'prop_chair_01a',
        coords = vector4(123.4, 567.8, 90.1, 180.0)
    }
    local prop = makeProp(propData, true, false)
    ```

- **makeDistProp(data, freeze, synced, range)**
  - Same as `makeProp`, but only spawns if the player is within the specified range.
  - **Example:**
    ```lua
    local propData = {
        prop = 'prop_chair_01a',
        coords = vector4(123.4, 567.8, 90.1, 180.0)
    }
    makeDistProp(propData, true, false)
    ```

- **destroyProp(entity)**
  - Removes a previously created or targeted prop from the world.
  - **Example:**
    ```lua
    destroyProp(barrel)
    ```

### makeVeh.lua
This module provides functionality for spawning vehicles, including distance-based optimization and entity management.

- **makeVeh(model, coords)**

  - This function loads the vehicle model, creates the vehicle in the world at the given coordinates, sets initial properties, and returns the vehicle handle.
  - **Example:**
    ```lua
    local vehicle = makeVeh("adder", vector3(250.0, -1000.0, 30.0))
    ```

- **makeDistVehicle(data, radius, onEnter, onExit)**

  - Creates a vehicle that spawns when the player enters a designated polyzone area.
  - This is used for `jim-parking` to create a static vehicle that can't move
  - **Example:**
    ```lua
    makeDistVehicle({
        model = "blista",
        coords = vector3(400.0, -800.0, 30.0),
        heading = 180.0
    }, 50.0)
    ```

- **removeDistVehicleZone(zoneId)**
  - Removes a previously created distance-based vehicle zone.
  - **Example:**
    ```lua
    removeDistVehicleZone("garage_zone_1")
    ```

- **deleteVehicle(vehicle)**
  - Deletes a specified vehicle entity.
  - **Example:**
    ```lua
    deleteVehicle(vehicle)
    ```

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

## Scaleforms
### debugScaleform.lua
This module renders debug text in-game when `debugMode` is enabled. Useful for live diagnostics or UI placement feedback.

- **debugScaleForm(textTable, loc)**
  - Displays an overlay of lines of text at the specified screen location.
  - **Note:** This only works if `debugMode` is set to `true`.
  - **Parameters:**
    - `textTable` (`table`): A list of strings to display.
    - `loc` (`vector2`, optional): Top-left anchor point on screen (default: `vec2(0.05, 0.65)`).
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            debugScaleForm({
                "Line 1: Debug info",
                "Line 2: More info"
            })
            Wait(0)
        end
    end)
    ```

### instructionalButtons.lua
This module renders instructional button prompts using native scaleforms in GTA V and RedM.

⚠️ **Note:** Because it uses native scaleforms, it must be run inside a `while` loop to remain visible.

- **makeInstructionalButtons(info)**
  - Draws instructional buttons using the GTA scaleform `instructional_buttons`.
  - **Parameters:**
    - `info` (`table`): An array of tables, where each entry contains:
      - `keys` (`table`): Control key codes (e.g., `{38, 29}`).
      - `text` (`string`): The label for the button.
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            makeInstructionalButtons({
                { keys = {38, 29}, text = "Open Menu" },
                { keys = {45}, text = "Close Menu" }
            })
            Wait(0)
        end
    end)
    ```

- **makeRedInstructionalButtons(info, title)**
  - Experimental: Displays prompts using RedM-style `PromptSetGroup` API.
  - **Note:** Still must be run in a loop for visibility.
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            makeRedInstructionalButtons({
                { keys = {0x760A9C6F}, text = "Mount Horse" },
                { keys = {0x4CC0E2FE}, text = "Dismount" }
            }, "Horse Controls")
            Wait(0)
        end
    end)
    ```

### scaleform_basic.lua
This module includes helper functions for 3D text rendering and UI overlays using basic native scaleform techniques.

- **DrawText3D(coord, text, highlight)**

  - Draws 3D text in the world at the given coordinates, with optional highlight.
  - Includes a semi-transparent black background box for visibility.
  - **Parameters:**
    - `coord` (`vector3`): World position to draw text.
    - `text` (`string`): Text content.
    - `highlight` (`boolean`, optional): Highlights `~w~` sections with yellow.
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            DrawText3D(vector3(100, 200, 300), "Hello World", true)
            Wait(0)
        end
    end)
    ```

- **DisplayHelpMsg(text)**
  - Shows a help message in the top-left corner of the screen.
  - **Example:**
    ```lua
    DisplayHelpMsg("Press E to interact")
    ```

- **displaySpinner(text)**
  - Shows a busy spinner with a message (e.g., "Saving...").
  - **Example:**
    ```lua
    displaySpinner("Saving data...")
    ```

- **stopSpinner()**
  - Hides any active busy spinner (client-only).
  - **Example:**
    ```lua
    stopSpinner()
    ```

### timerBars.lua
This module provides a native scaleform-based timer bar HUD. Ideal for displaying tasks, loading indicators, or time-sensitive objectives.

- **createTimerHud(title, data, alpha)**

  ⚠️ This was an attempt to recreate the gta native shooting ranges )fairly specific use case)
  - Draws a timer bar with custom label and right-aligned values using the native GTA HUD system.
  - **Parameters:**
    - `title` (`string`): Title/header displayed on the bar.
    - `data` (`table`): List of `label = value` entries to display (max 4 rows).
    - `alpha` (`number`, optional): Opacity of the bar (0-255).
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            createTimerHud("Timer Bar", {
                { stat = "Health", value = "85%" },
                { stat = "Armor", value = "50%", multi = 2 },
                { stat = "Stamina", value = "100%" },
            }, 180)
            Wait(0)
        end
    end)
    ```

## Animal Ped Support
### isAnimal.lua
This module provides logic to detect if a Ped or model is an animal and classify it into specific categories (cat, dog, coyote, etc.). Useful for wildlife, animal roles, or pet systems.

❔At player load in, it attempts to get what kind of ped/animal you are but there are functions to double check in scripts

❔Alot of this is used to determine what models/animations are available

Global flags:
- `isCat`, `isDog`, `isBigDog`, `isSmallDog`, `isCoyote`, `isAnimal` — used to store classification of the player's current ped.

- **isPedAnimal(ped?)**

  - Checks if a ped is an animal based on predefined animal models.
  - Sets global `isAnimal` to true if matched.
  - **Example:**
    ```lua
    local isPlayerAnimal = isPedAnimal()
    local isOtherPedAnimal = isPedAnimal(GetPedInVehicleSeat(vehicle, -1))
    ```

- **isCat(ped)**

  - Returns true if the ped model matches a cat.
  - **Example:**
    ```lua
    if isCat() then print("You're a cat!") end
    ```

- **isDog(ped)**

  - Returns two values:
    - `true`, `true` — if ped is a big dog
    - `true`, `false` — if ped is a small dog
    - `false`, `nil` — if not a dog
  - **Example:**
    ```lua
    local isDog, isBig = isDog()
    if isDog then print(isBig and "Big Dog" or "Small Dog") end
    ```

- **getAnimalModels()**

  - Returns a flat list of all registered animal model hashes.
  - Can be used to check ped models against
  - **Example:**
    ```lua
    for _, model in pairs(getAnimalModels()) do print(model) end
    ```

- **getAnimalAnims(ped)**

  - Returns the animation set defined for the given animal model.
  - **Example:**
    ```lua
    local anims = getAnimalAnims(PlayerPedId())
    if anims then playAnim(anims.sitDict, anims.sitAnim) end
    ```

## Helpful functions

### loaders.lua
This module provides loading utilities for common asset types such as models, animations, texture dictionaries, and audio banks. It also provides animation and sound helpers.

- **loadModel(model)**
  - Loads a model into memory if valid and not already loaded.
  - **Example:**
    ```lua
    loadModel('prop_chair_01a')
    ```

- **unloadModel(model)**
  - Unloads a model from memory.
  - **Example:**
    ```lua
    unloadModel('prop_chair_01a')
    ```

- **loadAnimDict(animDict)**
  - Loads an animation dictionary into memory.
  - **Example:**
    ```lua
    loadAnimDict('amb@world_human_hang_out_street@male_c@base')
    ```

- **unloadAnimDict(animDict)**
  - Removes an animation dictionary from memory.
  - **Example:**
    ```lua
    unloadAnimDict('amb@world_human_hang_out_street@male_c@base')
    ```

- **loadPtfxDict(ptFxName)**
  - Loads a particle effect (ptfx) dictionary.
  - **Example:**
    ```lua
    loadPtfxDict('core')
    ```

- **unloadPtfxDict(dict)**
  - Unloads a particle effect dictionary from memory.
  - **Example:**
    ```lua
    unloadPtfxDict('core')
    ```

- **loadTextureDict(dict)**
  - Loads a streamed texture dictionary.
  - **Example:**
    ```lua
    loadTextureDict('commonmenu')
    ```

- **loadScriptBank(bank)**
  - Loads a script audio bank.
  - Returns true on success.
  - **Example:**
    ```lua
    local success = loadScriptBank('DLC_HEISTS_GENERAL_FRONTEND_SOUNDS')
    ```

- **loadAmbientBank(bank)**
  - Loads an ambient audio bank.
  - Returns true on success.
  - **Example:**
    ```lua
    local success = loadAmbientBank('AMB_REVERB_GENERIC')
    ```

- **playAnim(animDict, animName, duration?, flag?, ped?, speed?)**
  - Plays an animation on a ped.
  - Loads the dictionary if not already loaded.
  - **Example:**
    ```lua
    playAnim('amb@world_human_hang_out_street@male_c@base', 'base', 5000, 1, PlayerPedId(), 1.0)
    ```

- **stopAnim(animDict, animName, ped?)**
  - Stops an animation and unloads the dictionary.
  - **Example:**
    ```lua
    stopAnim('amb@world_human_hang_out_street@male_c@base', 'base', PlayerPedId())
    ```

- **playGameSound(audioBank, soundSet, soundRef, coords, synced, range?)**
  - Plays a game sound from a coordinate or entity.
  - **Example:**
    ```lua
    playGameSound('DLC_HEIST_HACKING_SNAKE_SOUNDS', 'Beep', vector3(0, 0, 0), false, 15.0)
    ```

### helpers.lua
This utility module provides functions for resource checks, debugging, formatting, coordinate math, vector calculations, progress bars, and drawing tools.

- **isStarted(script)**
  - Returns `true` if a resource is started.
  - **Example:**
    ```lua
    if isStarted("myResource") then print("Resource is running") end
    ```

- **getScript()**
  - Caches and returns the name of the current resource.
  - Easier than typing `GetCurrentResourceName()` over and over
  - **Example:**
    ```lua
    print("Current script:", getScript())
    ```

- **isServer()**
  - Returns true if running on the server.
  - This was mainly made becuase `IsDuplicityVersion()` kept confusing me
  - **Example:**
    ```lua
    if isServer() then print("Server-side!") end
    ```

- **debugPrint(...)** / **eventPrint(...)**
  - Prints messages with debug context if debugMode is enabled.
  - **Example:**
    ```lua
    debugPrint("Loaded object:", objName)
    ```

- **jsonPrint(table)**
  - Pretty-prints a table with colorized JSON if debugMode is enabled.
  - **Example:**
    ```lua
    jsonPrint(myData)
    ```

- **keyGen()**
  - Generates a 3-character unique ID.
  - Good grabbing randomly generated strings
  - **Example:**
    ```lua
    print("Generated Key:", keyGen())
    ```

- **cv(amount)**
  - Comma-separates a number (e.g., `1000000` to `1,000,000`).
  - **Example:**
    ```lua
    print(cv(1000000)) -- "1,000,000"
    ```

- **formatCoord(vec)**
  - Outputs a formatted string from vector types.
  - Compacts and adds console colours to the vector to be printed
  - **Example:**
    ```lua
    print(formatCoord(vector3(123.45, 678.9, 10.0)))
    ```

- **getCenterOfZones(coords)**
  - Returns average center position of a vector3 list.
  - A few use cases, but I used it to see how well spaced blips were together
  - **Example:**
    ```lua
    local center = getCenterOfZones({vector3(0,0,0), vector3(10,10,0)})
    ```

- **countTable(tbl)**
  - Returns the number of entries in a table.
  - Simple function to print how many "entires" are in a table
  - **Example:**
    ```lua
    print(countTable({a=1,b=2,c=3})) -- 3
    ```

- **pairsByKeys(tbl)**
  - Iterator for sorted keys.
  - **Example:**
    ```lua
    for k, v in pairsByKeys(myTable) do print(k, v) end
    ```

- **concatenateText(tbl)**
  - Joins string table entries with newlines.
  - **Example:**
    ```lua
    print(concatenateText({"Line 1", "Line 2"}))
    ```

- **RotationToDirection(rot)**
  - Converts a heading vector to a directional vector.
  - **Example:**
    ```lua
    local dir = RotationToDirection(rotation)
    ```

- **basicBar(percent)**
  - Returns a bar like `████░░░░░` at 50%.
  - Basically a progress bar but as a string, I use this in drawTexts when progressbars aren't able to be used
  - **Example:**
    ```lua
    print(basicBar(50))
    ```

- **normalizeVector(vec)**
  - Returns a normalized version of a vector3.
  - **Example:**
    ```lua
    local norm = normalizeVector(vector3(3,4,0))
    ```

- **drawLine(start, end, color)** / **drawSphere(pos, color)**
  - Debug drawing helpers.
  - Stays visible for more than one frame
  - **Example:**
    ```lua
    drawLine(vector3(0,0,0), vector3(10,10,10), vector4(255,0,0,255))
    drawSphere(vector3(5,5,5), vector4(0,255,0,255))
    ```

- **PerformRaycast(start, end, entity?, flags?)**
  - Raycast with material detection. Returns ray hit data.
  - **Example:**
    ```lua
    local hit, hitPos, material = PerformRaycast(startVec, endVec, playerPed, 1)
    if hit == 1 then
        print("Hit at position:", hitPos)
        print("Material:", material)
    end
    ```

- **adjustForGround(coords)**
  - Adjusts a z-coordinate to ground height.
  - **Example:**
    ```lua
    coords = adjustForGround(vector3(100, 200, 300))
    ```

- **ensureNetToVeh(id)** / **ensureNetToEnt(id)**
  - Resolves net ID to entity safely.
  - **Example:**
    ```lua
    local veh = ensureNetToVeh(netId)
    ```

- **sendLog(text)** / **sendServerLog(data)**
  - Logging helpers, includes player name, coords, script source.
  - **Example:**
    ```lua
    sendLog("Suspicious activity detected")
    ```

- **GetGroundMaterialAtPosition(coords)**
  - Returns the material hash + readable name from the surface below coords.
  - **Example:**
    ```lua
    local hash, name = GetGroundMaterialAtPosition(vector3(0,0,0))
    ```

- **GetPropDimensions(model)**
  - Loads a model and returns width, depth, height.
  - I use this to parse a model to create a box target instead of entity target when creating distProps/distPeds
  - **Example:**
    ```lua
    local w,d,h = GetPropDimensions("prop_barrel_01a")
    ```

- **GetEntityForwardVector(entity)**
  - Returns the forward direction vector based on entity heading.
  - **Example:**
    ```lua
    local fwd = GetEntityForwardVector(PlayerPedId())
    ```