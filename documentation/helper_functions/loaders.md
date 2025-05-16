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