isCat, isDog, isBigDog, isSmallDog, isCoyote, isAnimal = false, false, false, false, false, false

if not isServer() then
    onPlayerLoaded(function()
        Wait(2000)
        isCat, isDog, isBigDog, isSmallDog, isCoyote = false, false, false, false, false
        isPedAnimal()
        if isAnimal then
            local ped = PlayerPedId()
            local pedModel = GetEntityModel(ped)

            isCat = (isCat(ped) or pedModel == `ft-raccoon`) and (pedModel ~= `ft-sphynx`)

            isDog, isBigDog = isDog(ped)
            isSmallDog = not isBigDog
            if isDog and pedModel == `a_c_coyote` then isDog = false end

            isCoyote = (pedModel == `ft-sphynx` or pedModel == `a_c_coyote`)

            if pedModel == `ft-capmonkey2` then isDog = true end
        end
    end, true)


    --- Determines if a given Ped is classified as an animal.
    ---
    --- This function checks whether the specified Ped (or the player's Ped if none is provided)
    --- is listed within the predefined `AnimalPeds` tables. It iterates through all animal types
    --- to verify if the Ped's model hash matches any known animal models.
    ---
    ---@param ped number|nil Optional. The Ped entity to check. Defaults to the player's Ped (`PlayerPedId()`).
    ---
    ---@return boolean `true` if the Ped is an animal, otherwise `false`.
    ---
    --- @usage
    --- ```lua
    --- local isPlayerAnimal = isAnimal()
    --- local isSpecificPedAnimal = isAnimal(somePedEntity)
    --- ```
    function isPedAnimal(ped)
        local PedModel = GetEntityModel(ped or PlayerPedId())

        for _, animalTypeTable in pairs(AnimalPeds) do
            for animalModelHash, _ in pairs(animalTypeTable) do
                if PedModel == animalModelHash then
                    isAnimal = true
                    break
                end
            end
            if isAnimal then
                debugPrint("^6Debug^7: ^2Ped is Animal^1")
                break
            end
        end

        return isAnimal
    end

    --- Checks if a given Ped is classified specifically as a cat.
    ---
    --- This function verifies whether the specified Ped (or the player's Ped if none is provided)
    --- matches any of the model hashes listed under `AnimalPeds.CatPeds`. It returns `true` if a match is found.
    ---
    ---@param ped number|nil Optional. The Ped entity to check. Defaults to the player's Ped (`PlayerPedId()`).
    ---
    ---@return boolean `true` if the Ped is a cat, otherwise `false`.
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
        for k, v in pairs(AnimalPeds.CatPeds) do
            if PedModel == k then
                return true
            end
        end
        return false
    end

    --- Determines if a given Ped is classified as a dog and identifies its size category.
    ---
    --- This function checks whether the specified Ped (or the player's Ped if none is provided)
    --- matches any model hashes listed under `AnimalPeds.BigDogs` or `AnimalPeds.SmallDogs`. It returns
    --- two values: the first indicates if the Ped is a dog, and the second specifies whether it's a
    --- large dog (`true`) or a small dog (`false`). If the Ped is not a dog, the second return value is `nil`.
    ---
    ---@param ped number|nil Optional. The Ped entity to check. Defaults to the player's Ped (`PlayerPedId()`).
    ---
    ---@return boolean, boolean|nil Returns `true` and `true` if the Ped is a big dog,
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
        for k, v in pairs(AnimalPeds.BigDogs) do
            if PedModel == k then
                return true, true
            end
        end

        for k, v in pairs(AnimalPeds.SmallDogs) do
            if PedModel == k then
                return true, false
            end
        end
        return false, nil
    end

    --- Retrieves a list of all animal model hashes.
    ---
    --- This function compiles and returns a flat table containing all model hashes
    --- from the various animal categories defined within the `AnimalPeds` table.
    --- It's useful for iterating over or performing bulk operations on all animal models.
    ---
    ---@return table table A table containing all animal model hashes.
    ---
    ---@usage
    --- ```lua
    --- local allAnimalModels = getAnimalModels()
    --- for _, modelHash in ipairs(allAnimalModels) do
    ---     print("Animal Model Hash:", modelHash)
    --- end
    --- ```
    function getAnimalModels()
        local animalTable = {}
        for k in pairs(AnimalPeds) do
            for v in pairs(AnimalPeds[k]) do
                animalTable[#animalTable+1] = v
            end
        end
        return animalTable
    end
end

AnimalPeds = {
    BigDogs = {
    -- Big Dogs
        [`a_c_chop`] = {
            deathAnim = "dead_right", deathDict = "creatures@chop@move",
            exitAnim = "getup_r", exitDict = "creatures@chop@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`a_c_k9`] = {
            deathAnim = "dead_right", deathDict = "creatures@chop@move",
            exitAnim = "getup_r", exitDict = "creatures@chop@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`a_c_husky`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`a_c_retriever`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`a_c_shepherd`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`a_c_rottweiler`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`ft-aushep`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`golden_r`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`ft-dobermanv2`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`doberman`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`ft-gs`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`k9_husky`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`ft-bloodhound`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`bernard`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`ft-pterrier`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`ft-labrador`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`dane`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`ft_malinois`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`abdog`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`dalmatian`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`a_c_dalmatian`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`ft-boxer`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`ft-bs`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`chowchow`] = {
            deathAnim = "dead_right", deathDict = "creatures@rottweiler@move",
            exitAnim = "getup_r", exitDict = "creatures@rottweiler@getup",
            sitAnim = "sit", sitDict = "creatures@rottweiler@in_vehicle@std_car"
        },
        [`a_c_coyote`] = {
            deathAnim = "dead_right", deathDict = "creatures@coyote@move",
            exitAnim = "getup_r", exitDict = "creatures@coyote@getup",
            sitAnim = "base", sitDict = "creatures@coyote@amb@world_coyote_howl@base"
        },
        [`a_c_coyote_02`] = {
            deathAnim = "dead_right", deathDict = "creatures@coyote@move",
            exitAnim = "getup_r", exitDict = "creatures@coyote@getup",
            sitAnim = "base", sitDict = "creatures@coyote@amb@world_coyote_howl@base"
        },
    },
    SmallDogs = {
    --   Small Dogs
        [`a_c_poodle`] = {
            deathAnim = "dead_right", deathDict = "creatures@pug@move",
            exitAnim = "getup_r", exitDict = "creatures@pug@getup",
            sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base"
        },
        [`ft-chihuahua`] = {
            deathAnim = "dead_right", deathDict = "creatures@pug@move",
            exitAnim = "getup_r", exitDict = "creatures@pug@getup",
            sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base"
        },
        [`a_c_pug`] = {
            deathAnim = "dead_right", deathDict = "creatures@pug@move",
            exitAnim = "getup_r", exitDict = "creatures@pug@getup",
            sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base"
        },
        [`a_c_pug_02`] = {
            deathAnim = "dead_right", deathDict = "creatures@pug@move",
            exitAnim = "getup_r", exitDict = "creatures@pug@getup",
            sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base"
        },
        [`a_c_westy`] = {
            deathAnim = "dead_right", deathDict = "creatures@pug@move",
            exitAnim = "getup_r", exitDict = "creatures@pug@getup",
            sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base"
        },
        [`ft-pretriever`] = {
            deathAnim = "dead_right", deathDict = "creatures@pug@move",
            exitAnim = "getup_r", exitDict = "creatures@pug@getup",
            sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base"
        },
        [`ft-shepk9`] = {
            deathAnim = "dead_right", deathDict = "creatures@pug@move",
            exitAnim = "getup_r", exitDict = "creatures@pug@getup",
            sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base"
        },
    },
    CatPeds = {
        --   Cat
        [`bshorthair`] = {
            deathAnim = "dead_right", deathDict = "creatures@cat@move",
            exitAnim = "getup_r", exitDict = "creatures@cat@getup",
            sitAnim = "base", sitDict = "creatures@cat@amb@world_cat_sleeping_ledge@base"
        },
        [`a_c_cat_01`] = {
            deathAnim = "dead_right", deathDict = "creatures@cat@move",
            exitAnim = "getup_r", exitDict = "creatures@cat@getup",
            sitAnim = "base", sitDict = "creatures@cat@amb@world_cat_sleeping_ledge@base"
        },
        [`ft-sphynx`] = {
            deathAnim = "dead_right", deathDict = "creatures@coyote@move",
            exitAnim = "getup_r", exitDict = "creatures@coyote@getup",
            sitAnim = "base", sitDict = "creatures@coyote@amb@world_coyote_howl@base"
        },
    },
    OtherPeds = {
        --   Other Animals
        [`ft-raccoon`] = {
            deathAnim = "dead_right", deathDict = "creatures@cat@move",
            exitAnim = "getup_r", exitDict = "creatures@cat@getup",
            sitAnim = "base", sitDict = "creatures@cat@amb@world_cat_sleeping_ledge@base"
        },
        [`a_c_hen`] = {
            deathAnim = "dead_right", deathDict = "creatures@hen@move",
            exitAnim = "getup_r", exitDict = "creatures@hen@getup"
        },
        [`a_c_rabbit_01`] = {
            deathAnim = "dead_right", deathDict = "creatures@rabbit@move",
            exitAnim = "getup_r", exitDict = "creatures@rabbit@getup",
            sitAnim = "idle_c", sitDict = "creatures@coyote@amb@world_coyote_howl@base"
        },
        [`a_c_rabbit_02`] = {
            deathAnim = "dead_right", deathDict = "creatures@rabbit@move",
            exitAnim = "getup_r", exitDict = "creatures@rabbit@getup",
            sitAnim = "idle_c", sitDict = "creatures@coyote@amb@world_coyote_howl@base"
        },
        [`a_c_rat`] = {
            deathAnim = "dead_right", deathDict = "creatures@rat@move",
            exitAnim = "getup_r", exitDict = "creatures@rat@getup"
        },
        [`a_c_deer`] = {
            deathAnim = "dead_right", deathDict = "creatures@deer@move",
            exitAnim = "getup_r", exitDict = "creatures@deer@getup"
        },
        [`a_c_boar`] = {
            deathAnim = "dead_right", deathDict = "creatures@boar@move",
            exitAnim = "getup_r", exitDict = "creatures@boar@getup"
        },
        [`a_c_boar_02`] = {
            deathAnim = "dead_right", deathDict = "creatures@boar@move",
            exitAnim = "getup_r", exitDict = "creatures@boar@getup"
        },
        [`a_c_chicken`] = {
            deathAnim = "dead_right", deathDict = "creatures@chicken@move",
            exitAnim = "getup_r", exitDict = "creatures@chicken@getup"
        },
        [`a_c_pig`] = {
            deathAnim = "dead_right", deathDict = "creatures@pig@move",
            exitAnim = "getup_r", exitDict = "creatures@pig@getup"
        },
        [`a_c_sharkhammer`] = {
            deathAnim = "dead_right", deathDict = "creatures@sharkhammer@move",
            exitAnim = "getup_r", exitDict = "creatures@sharkhammer@getup"
        },
        [`a_c_sharktiger`] = {
            deathAnim = "dead_right", deathDict = "creatures@sharktiger@move",
            exitAnim = "getup_r", exitDict = "creatures@sharktiger@getup"
        },
        [`a_c_crow`] = {
            deathAnim = "dead_down", deathDict = "creatures@crow@move",
            exitAnim = "nill", exitDict = "creatures@pug@move", -- no get up anim
        },
        [`a_c_pigeon`] = {
            deathAnim = "dead_down", deathDict = "creatures@pigeon@move",
            exitAnim = "nill", exitDict = "creatures@pug@move", -- no get up anim
        },
    },
    Monekys = {
        [`ft-chimpanzee`] = {
            deathAnim = "dead", deathDict = "dead_a",
            exitAnim = "get_up@sat_on_floor@to_stand", exitDict = "getup_0"
        },
        [`a_c_chimp`] = {
            deathAnim = "dead", deathDict = "dead_a",
            exitAnim = "get_up@sat_on_floor@to_stand", exitDict = "getup_0"
        },
        [`a_c_chimp_02`] = {
            deathAnim = "dead", deathDict = "dead_a",
            exitAnim = "get_up@sat_on_floor@to_stand", exitDict = "getup_0"
        },
        [`a_c_rhesus`] = {
            deathAnim = "dead", deathDict = "dead_a",
            exitAnim = "get_up@sat_on_floor@to_stand", exitDict = "getup_0"
        },
        [`ft-capmonkey2`] = {
            deathAnim = "dead_right", deathDict = "creatures@pug@move",
            exitAnim = "getup_r", exitDict = "creatures@pug@getup",
            sitAnim = "base", sitDict = "creatures@pug@amb@world_dog_sitting@base"
        },
    }
}