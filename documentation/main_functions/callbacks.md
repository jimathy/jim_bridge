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
