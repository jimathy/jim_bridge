local camCache = {}

--- Creates a temporary camera at a specified position, pointing towards given coordinates.
--
-- This function creates a camera at a position relative to an entity or at a specified position and orients it to look at the target coordinates.
-- The camera is only created if `Config.Crafting.craftCam` is enabled in the configuration.
--
---@param ent entityId|coords The base position for the camera. Can be an entity handle or a `vector3` position.
-- If `ent` is an entity, the camera position is calculated as an offset from the entity's position using `GetOffsetFromEntityInWorldCoords`.
-- If `ent` is a `vector3`, it is used directly as the camera's position.
--
---@param coords vector3|entityId The target `vector3` coordinates that the camera will point at.
--
---@return camID number The handle of the created camera, or `nil` if the camera was not created (e.g., if `Config.Crafting.craftCam` is `false`).
--
---@usage
-- ```lua
-- local cam = createTempCam(entity, targetCoords)
-- ```
function createTempCam(ent, coords)
	local camID = nil
	if Config.Crafting?.craftCam or Config.System.enableCam then

		-- if not ent or coords are provided, make a basic camera to control later
		if not ent and not coords then
			camID = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
			camCache[#camCache+1] = camID
			return camID
		end

		-- if received a vector3 or vector4 use those coords for origin point, otherwrise get offset from entity
		local camCoords = type(ent) ~= "number" and ent or GetOffsetFromEntityInWorldCoords(ent, 1.0, -0.3, 0.8)

		-- Create the camera
		camID = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camCoords.x, camCoords.y, camCoords.z + 0.5, 1.0, 0.0, 0.0, 60.00, false, 0)
		camCache[#camCache+1] = camID

		debugPrint("^6Bridge^7: ^2Custom Camera Created", camID)

		--if type(coords) == "number" then
		--	SetCamCoord(camID, GetCamCoord(camID) + vec3(0, 0, 1.0))
		--end
		if coords then
			camLookAt(camID, coords)
		end

	end
	return camID
end


local cacheCameraEffect = {}
local cachePrevCam = nil
--- Activates and starts rendering the temporary camera.
--
-- This function sets the specified camera as active and begins rendering it with a smooth transition.
-- The camera is only activated if `Config.Crafting.craftCam` is enabled in the configuration.
--
---@param cam number The handle of the camera to activate and render.
---@param renderTime number The handle of the camera to activate and render.
---@param loadScene boolean The handle of the camera to activate and render.
---@param filter table The filter or postFx to render when starting the camera.
--
---@usage
-- ```lua
-- startTempCam(camID, 1000, true, { postFx = "HeistCelebEnd" })
-- ```
function startTempCam(cam, renderTime, loadScene, filter, switchCam)
	if cam and DoesCamExist(cam) then
		debugPrint("Starting camera")
		-- if moving from a cached previous cam, or you've sent a camre id for it to switch from, interpolate to it
		if switchCam or cachePrevCam then
			SetCamActiveWithInterp(cam, cachePrevCam, renderTime or 1000, 0, 0)
			SetCamActive(cachePrevCam, false) -- Set previous cam inactive (shouldn't be needed but just in case)
		else
			SetCamActive(cam, true)
		end
		cachePrevCam = cam

		-- Clear previous filters
		if cacheCameraEffect.postFx then
            AnimpostfxStop(cacheCameraEffect.postFx)
            cacheCameraEffect.postFx = nil
        end
        if cacheCameraEffect.timecycle then
            ClearTimecycleModifier()
            cacheCameraEffect.timecycle = nil
        end

		-- Apply filters (timecycle) here as requested
		if filter and filter.modifier then
			SetTimecycleModifier(filter.modifier)
			SetTimecycleModifierStrength((filter.strength or 1.0) + 0.0)
			cacheCameraEffect.timecycle = true
		end

		if filter and filter.postFx then
			AnimpostfxPlay(filter.postFx, 0, filter.loop and true or false)
			cacheCameraEffect.postFx = filter.postFx
		end

		if loadScene then
			loadLocation(cam, nil, 100.0)
		end

		RenderScriptCams(true, true, renderTime or 1000, true, true)
	end
end

-- Follow cam or coords
function camLookAt(cam, entCoords)
	if cam and DoesCamExist(cam) and entCoords then
		if type(entCoords) ~= "number" then
			PointCamAtCoord(cam, entCoords.xyz)
		else
			PointCamAtEntity(cam, entCoords)
		end
	end
end

function loadLocation(cam, pos, radius)
	local pos = pos or GetCamCoord(cam)

	SetFocusPosAndVel(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
	RequestCollisionAtCoord(pos.x, pos.y, pos.z)
	NewLoadSceneStart(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, radius or 100.0, 0)

	local t0 = GetGameTimer()
	while not IsNewLoadSceneLoaded() and (GetGameTimer() - t0) < 2000 do
		RequestCollisionAtCoord(pos.x, pos.y, pos.z)
		Wait(0)
	end

	NewLoadSceneStop()
end

function clearLoadLocation()
	ClearFocus()
	NewLoadSceneStop()
end


--- Deactivates the temporary camera and stops rendering.
--
-- This function waits for one second, then stops rendering script cameras and destroys all cameras.
-- The delay allows for any transitions or animations to complete.
--
-- The camera is only deactivated if `Config.Crafting.craftCam` is enabled in the configuration.
--
---@usage
-- ```lua
-- stopTempCam()
-- ```
function stopTempCam(renderTime)
	CreateThread(function()
		Wait(1000)

		cachePrevCam = nil

		-- Clear previous filters
		if cacheCameraEffect.postFx then
            AnimpostfxStop(cacheCameraEffect.postFx)
            cacheCameraEffect.postFx = nil
        end
        if cacheCameraEffect.timecycle then
            ClearTimecycleModifier()
            cacheCameraEffect.timecycle = nil
        end

		RenderScriptCams(false, true, renderTime or 500, true, true)

		clearLoadLocation()

		Wait(renderTime or 0)
		for i = 1, #camCache do
			DestroyCam(camCache[i], true)
		end
		camCache = {}
	end)
end

function createCam(...) return createTempCam(...) end
function startCam(...) return startTempCam(...) end
function stopCam(...) return stopTempCam(...) end