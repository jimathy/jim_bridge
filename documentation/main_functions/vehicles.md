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