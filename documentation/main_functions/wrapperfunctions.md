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