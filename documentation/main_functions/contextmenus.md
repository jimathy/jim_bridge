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
