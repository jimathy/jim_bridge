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