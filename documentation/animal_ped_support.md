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
