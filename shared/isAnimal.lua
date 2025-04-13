--[[
    Animal Detection Module
    -------------------------
    This module determines whether a Ped is an animal and categorizes it as a cat, dog,
    or other type (e.g., coyote). It uses predefined model hashes stored in the AnimalPeds table.

    Global Flags:
      - isCat, isDog, isBigDog, isSmallDog, isCoyote, isAnimal: Booleans to track the player's
        current animal classification.

    When running client-side (not on the server), the module checks the player's Ped after they load.

    Usage Examples:
      -- Check if the player's Ped is an animal:
      local animalStatus = isPedAnimal()

      -- Check if a given Ped is a cat:
      if isCat(somePed) then print("This is a cat!") end

      -- Determine if a Ped is a dog and whether it's big or small:
      local isDogFlag, isBig = isDog(somePed)

      -- Retrieve a flat list of all animal model hashes:
      local allAnimalModels = getAnimalModels()

    File Separation Suggestion:
      For scalability, consider separating this module into two files:
        • AnimalDetection.lua (for functions and callbacks)
        • AnimalPedsData.lua (for the AnimalPeds table)
]]

-- Global animal classification flags.
isCat, isDog, isBigDog, isSmallDog, isCoyote, isAnimal = false, false, false, false, false, false

if not isServer() then
    onPlayerLoaded(function()
        Wait(2000)
        -- Reset classification flags
        isCat, isDog, isBigDog, isSmallDog, isCoyote = false, false, false, false, false
        -- Check if the player's Ped is an animal.
        isPedAnimal()
        if isAnimal then
            local ped = PlayerPedId()
            local pedModel = GetEntityModel(ped)

            -- Determine if the Ped is a cat:
            -- Also treat 'ft-raccoon' as a cat unless it is 'ft-sphynx'
            isCat = (isCat(ped) or pedModel == `ft-raccoon`) and (pedModel ~= `ft-sphynx`)

            -- Determine if the Ped is a dog and whether it's big:
            isDog, isBigDog = isDog(ped)
            isSmallDog = not isBigDog
            if isDog and pedModel == `a_c_coyote` then isDog = false end

            -- Determine if the Ped is a coyote (special case):
            isCoyote = (pedModel == `ft-sphynx` or pedModel == `a_c_coyote`)

            -- Special override: if model is 'ft-capmonkey2', treat as a dog.
            if pedModel == `ft-capmonkey2` then isDog = true end
        end
    end, true)


    -------------------------------------------------------------
    -- Animal Classification Functions
    -------------------------------------------------------------

    --- Determines whether a given Ped is classified as an animal.
    ---
    --- Checks if the Ped's model hash appears in any of the animal categories defined in AnimalPeds.
    ---
    --- @param ped number|nil Optional. The Ped entity to check. Defaults to the player's Ped.
    --- @return boolean boolean True if the Ped is an animal, otherwise false.
    ---
    --- @usage
    --- ```lua
    --- local isPlayerAnimal = isAnimal()
    --- local isSpecificPedAnimal = isAnimal(somePedEntity)
    --- ```
    function isPedAnimal(ped)
        local PedModel = GetEntityModel(ped or PlayerPedId())
        for _, animalCategory in pairs(AnimalPeds) do
            for animalModelHash, _ in pairs(animalCategory) do
                if PedModel == animalModelHash then
                    isAnimal = true
                    debugPrint("^6Bridge^7: ^2Ped is Animal")
                    return true
                end
            end
        end
        return false
    end

    --- Checks if a given Ped is classified as a cat.
    ---
    --- Iterates through the CatPeds table and returns true if the Ped's model matches.
    ---
    --- @param ped number|nil Optional. The Ped entity to check. Defaults to the player's Ped.
    --- @return boolean True if the Ped is a cat, otherwise false.
    ---
    ---@usage
    --- ```lua
    --- if isCat() then
    ---     print("Player is a cat!")
    --- end
    ---
    --- local anotherPed = GetPedInVehicleSeat(vehicle, -1)
    --- if isCat(anotherPed) then
    ---     print("Driver is a cat!")
    --- end
    --- ```
    function isCat(ped)
        local PedModel = GetEntityModel(ped or PlayerPedId())
        for modelHash, _ in pairs(AnimalPeds.CatPeds) do
            if PedModel == modelHash then
                return true
            end
        end
        return false
    end

    --- Determines if a given Ped is a dog and identifies its size category.
    ---
    --- Checks the BigDogs and SmallDogs tables to see if the Ped's model matches any dog model.
    ---
    --- @param ped number|nil Optional. The Ped entity to check. Defaults to the player's Ped.
    ---@return boolean, boolean|nil boolean Returns `true` and `true` if the Ped is a big dog,
    ---                            `true` and `false` if it's a small dog,
    ---                            or `false` and `nil` if it's not a dog.
    ---
    ---@usage
    --- ```lua
    --- local isDog, isBigDog = isDog()
    --- if isDog then
    ---     if isBigDog then
    ---         print("Player is a big dog!")
    ---     else
    ---         print("Player is a small dog!")
    ---     end
    --- else
    ---     print("Player is not a dog.")
    --- end
    ---
    --- local somePed = GetPedInVehicleSeat(vehicle, 0)
    --- local isPetDog, isLargeDog = isDog(somePed)
    --- if isPetDog then
    ---     if isLargeDog then
    ---         print("Passenger is a big dog!")
    ---     else
    ---         print("Passenger is a small dog!")
    ---     end
    --- end
    --- ```
    function isDog(ped)
        local PedModel = GetEntityModel(ped or PlayerPedId())
        for modelHash, _ in pairs(AnimalPeds.BigDogs) do
            if PedModel == modelHash then
                return true, true
            end
        end
        for modelHash, _ in pairs(AnimalPeds.SmallDogs) do
            if PedModel == modelHash then
                return true, false
            end
        end
        return false, nil
    end

    --- Compiles and returns a flat table of all animal model hashes.
    ---
    --- Iterates through every category in AnimalPeds and collects all model hashes.
    ---
    --- @return table table A table containing all animal model hashes.
    ---
    ---@usage
    --- ```lua
    --- local allAnimalModels = getAnimalModels()
    --- for _, modelHash in ipairs(allAnimalModels) do
    ---     print("Animal Model Hash:", modelHash)
    --- end
    --- ```
    function getAnimalModels()
        local animalModels = {}
        for _, animalCategory in pairs(AnimalPeds) do
            for modelHash, _ in pairs(animalCategory) do
                table.insert(animalModels, modelHash)
            end
        end
        return animalModels
    end

    --- Compiles and returns a table of animal animations for the ped model.
    ---
    --- Iterates through every category in AnimalPeds and collects all anims.
    ---
    --- @return table table A table containing all current model anims.
    ---
    ---@usage
    --- ```lua
    --- local getAnim = getAnimalAnims(ped)
    --- playAnim(getAnim.sitDict, getAnim.sitAnim, -1, 1)
    --- ```
    function getAnimalAnims(ped)
        local model = GetEntityModel(ped)
        local animalTable = {}
        for _, animalCategory in pairs(AnimalPeds) do
            for k, v in pairs(animalCategory) do
                if k == model then
                    animalTable = v
                    break
                end
            end
        end
        return animalTable
    end
end

-------------------------------------------------------------
-- Animal Models Data
-------------------------------------------------------------
-- Define the animal models and their associated animations.
AnimalPeds = {
    BigDogs = {
        [`a_c_chop`] = { deathAnim = "dead_right", deathDict = "creatures@chop@move", exitAnim = "getup_r", exitDict = "creatures@chop@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`a_c_k9`] = { deathAnim = "dead_right", deathDict = "creatures@chop@move", exitAnim = "getup_r", exitDict = "creatures@chop@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`a_c_husky`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`a_c_retriever`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`a_c_shepherd`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`a_c_rottweiler`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`ft-aushep`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`golden_r`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`ft-dobermanv2`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`doberman`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`ft-gs`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`k9_husky`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`ft-bloodhound`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`bernard`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`ft-pterrier`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`ft-labrador`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`dane`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`ft_malinois`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`abdog`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`dalmatian`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`a_c_dalmatian`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`ft-boxer`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`ft-bs`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`chowchow`] = { deathAnim = "dead_right", deathDict = "creatures@rottweiler@move", exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup", sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car" },
        [`a_c_coyote`] = { deathAnim = "dead_right", deathDict = "creatures@coyote@move", exitAnim = "getup_r", exitDict = "creatures@coyote@getup", sitAnim = "base", sitDict = "creatures@coyote@amb@world_coyote_howl@base" },
        [`a_c_coyote_02`] = { deathAnim = "dead_right", deathDict = "creatures@coyote@move", exitAnim = "getup_r", exitDict = "creatures@coyote@getup", sitAnim = "base", sitDict = "creatures@coyote@amb@world_coyote_howl@base" },
    },
    SmallDogs = {
        [`a_c_poodle`] = { deathAnim = "dead_right", deathDict = "creatures@pug@move", exitAnim = "getup_r", exitDict = "creatures@pug@getup", sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base" },
        [`ft-chihuahua`] = { deathAnim = "dead_right", deathDict = "creatures@pug@move", exitAnim = "getup_r", exitDict = "creatures@pug@getup", sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base" },
        [`a_c_pug`] = { deathAnim = "dead_right", deathDict = "creatures@pug@move", exitAnim = "getup_r", exitDict = "creatures@pug@getup", sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base" },
        [`a_c_pug_02`] = { deathAnim = "dead_right", deathDict = "creatures@pug@move", exitAnim = "getup_r", exitDict = "creatures@pug@getup", sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base" },
        [`a_c_westy`] = { deathAnim = "dead_right", deathDict = "creatures@pug@move", exitAnim = "getup_r", exitDict = "creatures@pug@getup", sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base" },
        [`ft-pretriever`] = { deathAnim = "dead_right", deathDict = "creatures@pug@move", exitAnim = "getup_r", exitDict = "creatures@pug@getup", sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base" },
        [`ft-shepk9`] = { deathAnim = "dead_right", deathDict = "creatures@pug@move", exitAnim = "getup_r", exitDict = "creatures@pug@getup", sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base" },
    },
    CatPeds = {
        [`bshorthair`] = { deathAnim = "dead_right", deathDict = "creatures@cat@move", exitAnim = "getup_r", exitDict = "creatures@cat@getup", sitAnim = "base", sitDict = "creatures@cat@amb@world_cat_sleeping_ledge@base" },
        [`a_c_cat_01`] = { deathAnim = "dead_right", deathDict = "creatures@cat@move", exitAnim = "getup_r", exitDict = "creatures@cat@getup", sitAnim = "base", sitDict = "creatures@cat@amb@world_cat_sleeping_ledge@base" },
        [`ft-sphynx`] = { deathAnim = "dead_right", deathDict = "creatures@coyote@move", exitAnim = "getup_r", exitDict = "creatures@coyote@getup", sitAnim = "base", sitDict = "creatures@coyote@amb@world_coyote_howl@base" },
    },
    OtherPeds = {
        [`ft-raccoon`] = { deathAnim = "dead_right", deathDict = "creatures@cat@move", exitAnim = "getup_r", exitDict = "creatures@cat@getup", sitAnim = "base", sitDict = "creatures@cat@amb@world_cat_sleeping_ledge@base" },
        [`a_c_hen`] = { deathAnim = "dead_right", deathDict = "creatures@hen@move", exitAnim = "getup_r", exitDict = "creatures@hen@getup" },
        [`a_c_rabbit_01`] = { deathAnim = "dead_right", deathDict = "creatures@rabbit@move", exitAnim = "getup_r", exitDict = "creatures@rabbit@getup", sitAnim = "idle_c", sitDict = "creatures@coyote@amb@world_coyote_howl@base" },
        [`a_c_rabbit_02`] = { deathAnim = "dead_right", deathDict = "creatures@rabbit@move", exitAnim = "getup_r", exitDict = "creatures@rabbit@getup", sitAnim = "idle_c", sitDict = "creatures@coyote@amb@world_coyote_howl@base" },
        [`a_c_rat`] = { deathAnim = "dead_right", deathDict = "creatures@rat@move", exitAnim = "getup_r", exitDict = "creatures@rat@getup" },
        [`a_c_deer`] = { deathAnim = "dead_right", deathDict = "creatures@deer@move", exitAnim = "getup_r", exitDict = "creatures@deer@getup" },
        [`a_c_boar`] = { deathAnim = "dead_right", deathDict = "creatures@boar@move", exitAnim = "getup_r", exitDict = "creatures@boar@getup" },
        [`a_c_boar_02`] = { deathAnim = "dead_right", deathDict = "creatures@boar@move", exitAnim = "getup_r", exitDict = "creatures@boar@getup" },
        [`a_c_chicken`] = { deathAnim = "dead_right", deathDict = "creatures@chicken@move", exitAnim = "getup_r", exitDict = "creatures@chicken@getup" },
        [`a_c_pig`] = { deathAnim = "dead_right", deathDict = "creatures@pig@move", exitAnim = "getup_r", exitDict = "creatures@pig@getup" },
        [`a_c_sharkhammer`] = { deathAnim = "dead_right", deathDict = "creatures@sharkhammer@move", exitAnim = "getup_r", exitDict = "creatures@sharkhammer@getup" },
        [`a_c_sharktiger`] = { deathAnim = "dead_right", deathDict = "creatures@sharktiger@move", exitAnim = "getup_r", exitDict = "creatures@sharktiger@getup" },
        [`a_c_crow`] = { deathAnim = "dead_down", deathDict = "creatures@crow@move", exitAnim = "nill", exitDict = "creatures@pug@move" },
        [`a_c_pigeon`] = { deathAnim = "dead_down", deathDict = "creatures@pigeon@move", exitAnim = "nill", exitDict = "creatures@pug@move" },
    },
    Monekys = {
        [`ft-chimpanzee`] = { deathAnim = "dead", deathDict = "dead_a", exitAnim = "get_up@sat_on_floor@to_stand", exitDict = "getup_0" },
        [`a_c_chimp`] = { deathAnim = "dead", deathDict = "dead_a", exitAnim = "get_up@sat_on_floor@to_stand", exitDict = "getup_0" },
        [`a_c_chimp_02`] = { deathAnim = "dead", deathDict = "dead_a", exitAnim = "get_up@sat_on_floor@to_stand", exitDict = "getup_0" },
        [`a_c_rhesus`] = { deathAnim = "dead", deathDict = "dead_a", exitAnim = "get_up@sat_on_floor@to_stand", exitDict = "getup_0" },
        [`ft-capmonkey2`] = { deathAnim = "dead_right", deathDict = "creatures@pug@move", exitAnim = "getup_r", exitDict = "creatures@pug@getup", sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base" },
    }
}