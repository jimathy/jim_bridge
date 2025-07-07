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

- **setPlayerMetadata(player, key, value)**

  ⚠️ Server side only
  - Updates or assigns a value to a specific metadata key for a player.
  - The function updates the player's metadata using the active core export.
  - **Example:**
    ```lua
    setPlayerMetadata(player, "stress", 0)
    ```