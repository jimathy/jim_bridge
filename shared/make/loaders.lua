local time = 500

--- Loads a specified model into memory.
---
--- This function checks if the model is valid and not already loaded.
--- If not loaded, it requests the model and waits until it is loaded or times out.
---
---@param model string|number The name or hash of the model to load.
---
---@usage
--- ```lua
--- loadModel('prop_chair_01a')
--- ```
function loadModel(model)
	if not IsModelValid(model) then print("^6Bridge^7: ^1ERROR^7: ^2Model^7 - '^6"..model.."^7' ^2does not exist in server") return
	else
		if not HasModelLoaded(model) then
			debugPrint("^6Bridge^7: ^2Loading Model^7: '^6"..model.."^7'")
			while not HasModelLoaded(model) and time > 0 do time -= 1 RequestModel(model) Wait(0) end
			if not HasModelLoaded(model) then print("^6Bridge^7: ^3LoadModel^7: ^2Timed out loading model ^7'^6"..model.."^7'") end
		end
		time = 500
	end
end

--- Unloads a model from memory.
---
--- This function marks a model as no longer needed, allowing the game to free up memory.
---
---@param model string|number The name or hash of the model to unload.
---
---@usage
--- ```lua
--- unloadModel('prop_chair_01a')
--- ```
function unloadModel(model)
    debugPrint("^6Bridge^7: ^2Removing Model from memory cache^7: '^6"..model.."^7'")
    SetModelAsNoLongerNeeded(model)
end

--- Loads an animation dictionary into memory.
---
--- This function checks if the animation dictionary exists and requests it.
--- It waits until the animation dictionary is loaded before proceeding.
---
---@param animDict string The name of the animation dictionary to load.
---
---@usage
--- ```lua
--- loadAnimDict('amb@world_human_hang_out_street@male_c@base')
--- ```
function loadAnimDict(animDict)
	if not DoesAnimDictExist(animDict) then
		print("^6Bridge^7: ^1ERROR^7: ^2Anim Dictionary^7 - '^6"..animDict.."^7' ^2does not exist in server") return
	else
		debugPrint("^6Bridge^7: ^2Loading Anim Dictionary^7: '^6"..animDict.."^7'")
		while not HasAnimDictLoaded(animDict) do RequestAnimDict(animDict) Wait(5) end
	end
end

--- Unloads an animation dictionary from memory.
---
--- This function removes the animation dictionary from the game's memory cache.
---
---@param animDict string The name of the animation dictionary to unload.
---
---@usage
---@
--- ```lua
--- unloadAnimDict('amb@world_human_hang_out_street@male_c@base')
--- ```
function unloadAnimDict(animDict)
    debugPrint("^6Bridge^7: ^2Removing Anim Dictionary from memory cache^7: '^6"..animDict.."^7'")
    RemoveAnimDict(animDict)
end

--- Loads a particle effects (ptfx) dictionary into memory.
---
--- This function requests the named particle effects asset and waits until it's loaded.
---
---@param ptFxName string The name of the particle effects dictionary to load.
---
---@usage
--- ```lua
--- loadPtfxDict('core')
--- ```
function loadPtfxDict(ptFxName)
	if not HasNamedPtfxAssetLoaded(ptFxName) then
		debugPrint("^6Bridge^7: ^2Loading Ptfx Dictionary^7: '^6"..ptFxName.."^7'")
		while not HasNamedPtfxAssetLoaded(ptFxName) do RequestNamedPtfxAsset(ptFxName) Wait(5) end
	end
end

--- Unloads a particle effects (ptfx) dictionary from memory.
---
--- This function removes the named particle effects asset from the game's memory cache.
---
---@param dict string The name of the particle effects dictionary to unload.
---
---@usage
--- ```lua
--- unloadPtfxDict('core')
--- ```
function unloadPtfxDict(dict)
    debugPrint("^6Bridge^7: ^2Removing Ptfx Dictionary^7: '^6"..dict.."^7'")
    RemoveNamedPtfxAsset(dict)
end

--- Loads a texture dictionary into memory.
---
--- This function requests the streamed texture dictionary and waits until it's loaded.
---
---@param dict string The name of the texture dictionary to load.
---
---@usage
--- ```lua
--- loadTextureDict('commonmenu')
--- ```
function loadTextureDict(dict)
	if not HasStreamedTextureDictLoaded(dict) then
		debugPrint("^6Bridge^7: ^2Loading Texture Dictionary^7: '^6"..dict.."^7'")
		while not HasStreamedTextureDictLoaded(dict) do RequestStreamedTextureDict(dict) Wait(5) end
	end
end

--- Loads a script audio bank into memory.
---
--- This function requests a script audio bank and waits until it's loaded or times out.
---
---@param bank string The name of the script audio bank to load.
---
---@return boolean `true` if the audio bank was successfully loaded; otherwise, `false`.
---
---@usage
--- ```lua
--- local success = loadScriptBank('DLC_HEISTS_GENERAL_FRONTEND_SOUNDS')
--- ```
function loadScriptBank(bank)
    local timeout = 2000
    debugPrint("^6Bridge^7: ^2Loading ^3Script ^2AudioBank^7...")
    while not RequestScriptAudioBank(bank, false) do Wait(10) timeout -= 10 if timeout <= 0 then break end end

    local success = RequestScriptAudioBank(bank, false)
    debugPrint("^6Bridge^7: "..(success and "^3Successfully ^2loaded^7: '^4" or "^1Failed to ^2load^7: '^4")..bank.."^7'")
    return success
end

--- Loads an ambient audio bank into memory.
---
--- This function requests an ambient audio bank and waits until it's loaded or times out.
---
---@param bank string The name of the ambient audio bank to load.
---
---@return boolean `true` if the audio bank was successfully loaded; otherwise, `false`.
---
---@usage
--- ```lua
--- local success = loadAmbientBank('AMB_REVERB_GENERIC')
--- ```
function loadAmbientBank(bank)
    local timeout = 2000
    debugPrint("^6Bridge^7: ^2Loading ^3Ambient ^2AudioBank^7...")
    while not RequestAmbientAudioBank(bank, 0) do
        Wait(10)
        timeout -= 10
        if timeout <= 0 then break end
    end
    local success = RequestAmbientAudioBank(bank, 0)
    debugPrint("^6Bridge^7: "..(success and "^3Successfully ^2loaded^7: '^4" or "^1Failed to ^2load^7: '^4")..bank.."^7'")
    return success
end

--- Plays an animation on a specified ped.
---
--- This function loads the animation dictionary and instructs the ped to play the animation.
---
---@param animDict string The name of the animation dictionary.
---@param animName string The name of the animation within the dictionary.
---@param duration number (optional) The duration to play the animation in milliseconds. Default is `30000`.
---@param flag number (optional) The animation flag controlling how the animation is played. Default is `50`.
---@param ped number (optional) The ped on which to play the animation. Defaults to the player's ped if not specified.
---@param speed number (optional) The speed multiplier for the animation. Default is `8.0`.
---
---@usage
--- ```lua
--- playAnim('amb@world_human_hang_out_street@male_c@base', 'base', 5000, 1, PlayerPedId(), 1.0)
--- ```
function playAnim(animDict, animName, duration, flag, ped, speed)
    loadAnimDict(animDict)
    debugPrint("^6Bridge^7: ^3playAnim^7() ^2Triggered^7: ", animDict, animName, flag)
	TaskPlayAnim(ped and ped or PlayerPedId(), animDict, animName, speed or 8.0, speed or -8.0, duration or 30000, flag or 50, 1, false, false, false)
end

--- Stops a specified animation on a ped.
---
--- This function stops the animation and unloads the animation dictionary from memory.
---
---@param animDict string The name of the animation dictionary.
---@param animName string The name of the animation within the dictionary.
---@param ped number (optional) The ped on which to stop the animation. Defaults to the player's ped if not specified.
---
---@usage
--- ```lua
--- stopAnim('amb@world_human_hang_out_street@male_c@base', 'base', PlayerPedId())
--- ```
function stopAnim(animDict, animName, ped)
    debugPrint("^6Bridge^7: ^3stopAnim^7() ^2Triggered^7: ", animDict, animName)
    StopAnimTask(ped or PlayerPedId(), animDict, animName, 0.5)
    StopAnimTask(ped or PlayerPedId(), animName, animDict, 0.5)
    unloadAnimDict(animDict)
end

--- Plays a game sound from a specified coordinate or entity.
---
--- This function attempts to play a sound from either a coordinate or an entity, using the specified audio bank and sound name.
---
---@param bank string The name of the audio bank containing the sound.
---@param sound string The name of the sound to play.
---@param coords vector3|number A `vector3` coordinate or an entity handle from which to play the sound.
---@param synced boolean A boolean indicating whether the sound is synced across clients.
---@param range number (optional) The maximum range at which the sound can be heard. Default is `10.0`.
---
---@usage
--- ```lua
--- playGameSound('DLC_HEIST_HACKING_SNAKE_SOUNDS', 'Beep', vector3(0, 0, 0), false, 15.0)
--- ```
function playGameSound(audioBank, soundSet, soundRef, coords, synced, range)
    debugPrint("^6Bridge^7: ^2Attempting to play: ^3"..soundRef.." ^7('^4"..audioBank.."^7')")
    loadScriptBank(audioBank)
    local range = range or 10.0
    local soundId = GetSoundId()
    while not soundId do Wait(10) end
    if type(coords) == "vector3" or type(coords) == "vector4" then
        debugPrint("^6Bridge^7: ^2Playing sound from Coord^7: "..formatCoord(coords.xyz))
        PlaySoundFromCoord(soundId, soundRef, coords.x, coords.y, coords.z, soundSet, synced, range, 0)
    else
        debugPrint("^6Bridge^7: ^2Playing sound from Entity^7: ^4"..coords.."^7")
        PlaySoundFromEntity(soundId, soundRef, coords, soundSet, synced, 1.0)
    end
    ReleaseScriptAudioBank(audioBank)
end

-- Experimental, add fade in for spawned entities
function fadeInEnt(ent, duration)
    if not DoesEntityExist(ent) then return end
    duration = duration or 500 -- in ms
    local fadeSteps = 20
    local stepTime = duration / fadeSteps

    SetEntityAlpha(ent, 0, false)
    SetEntityVisible(ent, true, false)
    SetEntityLocallyInvisible(ent) -- sometimes helps prevent "pop-in" in early frames

    for i = 1, fadeSteps do
        Wait(stepTime)
        local newAlpha = math.floor((i / fadeSteps) * 255)
        SetEntityAlpha(ent, newAlpha, false)
    end

    -- Restore full visibility
    ResetEntityAlpha(ent)
end