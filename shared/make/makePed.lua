--- A table to keep track of all created Peds.
local Peds = {}

--- Creates a distance-based Ped (pedestrian) that spawns when the player enters a specified area.
--
-- This function sets up a circular area using `createCirclePoly`. When the player enters this area, a Ped is created using `makePed`.
-- When the player exits the area, the Ped is deleted.
--
---@param data table A table containing Ped data and properties. Should include at least `model` and `coords`.
---@param coords vector4 A `vector3` or `vector4` specifying the coordinates where the Ped will be placed.
---@param freeze boolean (optional) Boolean indicating whether the Ped should be frozen in place. Default is `true`.
---@param collision boolean (optional) Boolean indicating whether collision with the Ped is enabled. Default is `false`.
---@param scenario boolean (optional) String specifying the scenario the Ped should perform.
---@param anim table (optional) A table containing animation dictionary and name `{animDict, animName}`.
---@param synced boolean (optional) Boolean indicating whether the Ped is synced across clients. Default is `false`.
--
---@usage
-- ```lua
-- makeDistPed(pedData, pedCoords, true, false, 'WORLD_HUMAN_STAND_IMPATIENT', nil, true)
-- ```
function makeDistPed(data, coords, freeze, collision, scenario, anim, synced)
    local zoneCoords = type(data) == "table" and data.coords or coords
    local randName = keyGen()..keyGen()
    createCirclePoly({
        name = randName,
        coords = vec3(zoneCoords.x, zoneCoords.y, zoneCoords.z - 1.03),
        radius = 50.0,
        onEnter = function()
            Peds[randName] = makePed(data, coords, freeze, collision, scenario, anim, synced)
        end,
        onExit = function()
            DeletePed(Peds[randName])
        end,
        debug = debugMode,
    })
end

--- Creates a Ped (pedestrian character) with specified properties.
--
-- This function creates a Ped at the given coordinates and applies appearance and clothing based on the provided data.
--
-- If `data` is a table with `custom` properties, it customizes the Ped's appearance accordingly.
--
---@param data modelHash|table Either a string/model hash of the Ped model to use, or a table containing `model` and `custom` data.
---@param coords vector4 `vector3` or `vector4` specifying the coordinates where the Ped will be placed.
---@param freeze boolean (optional) Boolean indicating whether the Ped should be frozen in place. Default is `true`.
---@param collision boolean (optional) Boolean indicating whether collision with the Ped is enabled. Default is `false`.
---@param scenario string (optional) String specifying the scenario the Ped should perform.
---@param anim table (optional) A table containing animation dictionary and name `{animDict, animName}`.
---@param synced boolean (optional) Boolean indicating whether the Ped is synced across clients. Default is `false`.
--
---@return ped entityID The handle of the created Ped.
--
---@usage
-- ```lua
-- local ped = makePed(pedData, pedCoords, true, false, nil, {'animDict', 'animName'}, true)
-- ```
function makePed(data, coords, freeze, collision, scenario, anim, synced)
    local ped = nil
    local model = nil
    if type(data) == "table" then
        model = data.model
        loadModel(data.model)
        ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.03, coords.w, synced and synced or false, false)
        SetEntityAplha(ped, 0, false)
        -- Inheritance
        SetPedHeadBlendData(ped, data.custom.faceFather, data.custom.faceMother, data.custom.raceShape, data.custom.skinFather, data.custom.skinMother, data.custom.raceSkin, data.custom.faceMix or 0, data.custom.skinMix or 0, data.custom.raceMix or 0, false)

        -- Face Features
        for k, v in pairs({
            "noseWidth", "noseHeight", "noseSize", "noseBoneHeight", "nosePeakHeight", "noseBoneTwist",
            "eyebrowHeight", "eyebrowDepth",
            "cheekBoneHeight", "cheekBoneWidth", "cheeckWidth",
            "eyeOpening", "lipThickness",
            "jawWidth", "jawSize",
            "chinLowering", "chinLength", "chinSize", "chinHole",
            "neckThickness"
        }) do
            SetPedFaceFeature(ped, k - 1, data.custom[v])
        end

        -- Appearance
        SetPedComponentVariation(ped, 2, data.custom.Hair, 0, 0)
        SetPedHairColor(ped, data.custom.HairTexture, data.custom.HairHighlight or 0)
        SetPedHeadOverlay(ped, 2, data.custom.Eyebrows, data.custom.EyebrowsOpacity)
        SetPedHeadOverlayColor(ped, 2, 1, data.custom.EyebrowsColor, 0)
        SetPedEyeColor(ped, data.custom.Eyecolor)
        SetPedHeadOverlay(ped, 4, data.custom.Makeup, data.custom.MakeupOpacity)
        SetPedHeadOverlayColor(ped, 4, 1, data.custom.MakeupColor, 0)
        SetPedHeadOverlay(ped, 8, data.custom.Lipstick, data.custom.LipstickOpacity)
        SetPedHeadOverlayColor(ped, 8, 1, data.custom.LipstickColor, 0)
        SetPedHeadOverlay(ped, 1, data.custom.Beard, data.custom.BeardOpacity)
        SetPedHeadOverlayColor(ped, 1, 1, data.custom.BeardColor, 0)

        -- Clothes
        SetPedComponentVariation(ped, 1, data.custom.Mask, data.custom.MaskVariant, 0)
        SetPedComponentVariation(ped, 7, data.custom.Scarf, data.custom.ScarfVariant, 0)
        SetPedComponentVariation(ped, 11, data.custom.Jacket, data.custom.JacketVariant, 0)
        SetPedComponentVariation(ped, 8, data.custom.Shirt, data.custom.ShirtVariant, 0)
        SetPedComponentVariation(ped, 9, data.custom.Vest, data.custom.VestVariant, 0)
        SetPedComponentVariation(ped, 5, data.custom.Bags, data.custom.BagsVariant, 0)
        SetPedComponentVariation(ped, 3, data.custom.Arms, data.custom.ArmsVariant, 0)
        SetPedComponentVariation(ped, 4, data.custom.Pants, data.custom.PantsVariant, 0)
        SetPedComponentVariation(ped, 6, data.custom.Shoes, data.custom.ShoesVariant, 0)
        SetPedComponentVariation(ped, 10, data.custom.Decal, data.custom.DecalVariant, 0)

        -- Accessories
        SetPedPropIndex(ped, 0, data.custom.Hat, data.custom.HatVariant, true)
        SetPedPropIndex(ped, 1, data.custom.Glasses, data.custom.GlassesVariant, true)

        SetPedPropIndex(ped, 2, data.custom.Ear, data.custom.EarVariant, true)
        SetPedPropIndex(ped, 6, data.custom.Watches, data.custom.WatchesVariant, true)
        SetPedPropIndex(ped, 7, data.custom.Bracelets, data.custom.BraceletsVariant, true)
    else
        model = data
        loadModel(model)
        if gameName == "rdr3" then
            ped = CreatePed(model, coords.x, coords.y, coords.z - 1.03, coords.w, synced or false, false)
            SetEntityAplha(ped, 0, false)
            SetEntityVisible(ped, 1) -- SetEntityVisible
            SetEntityAlpha(ped, 255, false) -- SetEntityAlpha
            SetRandomOutfitVariation(ped, true) -- Invisible without
        else
            ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.03, coords.w, synced or false, false)
        end
    end

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
	FreezeEntityPosition(ped, freeze and freeze or true)

    if collision then SetEntityNoCollisionEntity(ped, PlayerPedId(), false) end
    if scenario then TaskStartScenarioInPlace(ped, scenario, 0, true) end
    if anim then
        loadAnimDict(anim[1])
        TaskPlayAnim(ped, anim[1], anim[2], 0.5, 1.0, -1, 1, 0.2, 0, 0, 0)
    end
    if DoesEntityExist(ped) then
        debugPrint("^6Bridge^7: ^1Ped ^2Created^7: '^6"..ped.."^7' | ^2Hash^7: ^7'^5"..(model).."^7' | ^2Coord^7: "..formatCoord(coords))
    else
        print("error ped")
    end
    unloadModel(model)
    Peds[keyGen()..keyGen()] = ped

    CreateThread(function()
        fadeInEnt(ped)
    end)
    return ped
end

--- Generates random Ped data by filling in missing customization options with random values.
--
-- This function takes in a data table that may have some customization options missing in `data.custom`.
--
-- It generates random values for any missing options and returns a new data table with complete customization.
--
---@param data table A table containing at least a `model` field, and possibly a `custom` table with customization options.
--
---@return generatedTable table A new table containing `model` and `custom` with all customization options filled.
--
---@usage
-- ```lua
-- local pedData = GenerateRandomPedData({ model = `MP_M_Freemode_01`, custom = {} })
-- ```
function GenerateRandomPedData(data)
    local newTable = {
        model = data.model,
        custom = {},
    }
    local isMale = data.model == `MP_M_Freemode_01`
    local randomTable = {
        -- Inheritance
        faceFather = math.random(0, 45), faceMother = math.random(0, 45), faceMix = (math.random(0, 9) / 10),
        skinFather = math.random(0, 45), skinMother = math.random(0, 45), skinMix = (math.random(0, 9) / 10),
        raceShape = math.random(0, 45), raceSkin = math.random(0, 45), raceMix = (math.random(0, 9) / 10),

        -- Face Features
        noseWidth = (math.random(0, 9) / 10),
        noseHeight = (math.random(0, 9) / 10),
        noseSize = (math.random(0, 9) / 10),
        noseBoneHeight = (math.random(0, 9) / 10),
        nosePeakHeight = (math.random(0, 9) / 10),
        noseBoneTwist = (math.random(0, 9) / 10),

        eyebrowHeight = (math.random(0, 9) / 10),
        eyebrowDepth = (math.random(0, 9) / 10),

        cheekBoneHeight = (math.random(0, 9) / 10),
        cheekBoneWidth = (math.random(0, 9) / 10),
        cheeckWidth = (math.random(0, 9) / 10),

        eyeOpening = (math.random(0, 9) / 10),
        lipThickness = (math.random(0, 9) / 10),

        jawWidth = (math.random(0, 9) / 10),
        jawSize = (math.random(0, 9) / 10),

        chinLowering = (math.random(0, 9) / 10),
        chinLength = (math.random(0, 9) / 10),
        chinSize = (math.random(0, 9) / 10),
        chinHole = (math.random(0, 9) / 10),

        neckThickness = (math.random(0, 9) / 10),

        -- Appearance
        Hair = math.random(0, isMale and 147 or 261), HairTexture = math.random(0, 63), HairHighlight = math.random(0, 63),
        Eyebrows = math.random(0, 33),
        EyebrowsOpacity = 0.9, EyebrowsColor = 0,
        Eyecolor = math.random(0, 30),
        Makeup = 0, MakeupOpacity = 0, MakeupColor = 0,
        Lipstick = 0, LipstickOpacity = 0, LipstickColor = 0,
        Beard = isMale and math.random(0, 28) or -1,
        BeardOpacity = isMale and 0.9 or 0.0, BeardColor = 0,

        -- Clothing
        Mask = math.random(0, 252), MaskVariant = 0,
        Scarf = math.random(0, isMale and 249 or 198), ScarfVariant = 0,
        Jacket = math.random(0, isMale and 634 or 713), JacketVariant = 0,
        Shirt = math.random(0, isMale and 237 or 299), ShirtVariant = 0,
        Vest = math.random(0, isMale and 81 or 91), VestVariant = 0,
        Bags = math.random(0, isMale and 138 or 148), BagsVariant = 0,
        Arms = math.random(0, isMale and 224 or 261), ArmsVariant = 0,
        Pants = math.random(0, isMale and 255 or 275), PantsVariant = 0,
        Shoes = math.random(0, isMale and 157 or 199), ShoesVariant = 0,
        Decal = math.random(0, isMale and 238 or 253), DecalVariant = 0,

        -- Accessories
        Hat = math.random(0, isMale and 232 or 229), HatVariant = 0,
        Glasses = math.random(0, isMale and 68 or 71), GlassesVariant = 0,
        Ear = math.random(0, isMale and 51 or 40), EarVariant = 0,
        Watches = math.random(0, isMale and 46 or 35), WatchesVariant = 0,
        Bracelets = math.random(0, isMale and 13 or 20), BraceletsVariant = 0,
    }
    for option in pairs(randomTable) do
        if not data.custom[option] then
            newTable.custom[option] = randomTable[option]
            debugPrint("^6Bridge^7: ^2Picking Random Ped option ^7[^5"..option.."^7]: ^6"..newTable.custom[option].."^7")
        else
            newTable.custom[option] = data.custom[option]
        end
    end
    return newTable
end

--- Cleans up all created Peds when the resource stops.
onResourceStop(function()
    for k in pairs(Peds) do
        DeletePed(Peds[k])
    end
end, true)