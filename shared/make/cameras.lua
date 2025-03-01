--- Creates a temporary camera at a specified position, pointing towards given coordinates.
--
-- This function creates a camera at a position relative to an entity or at a specified position and orients it to look at the target coordinates.
-- The camera is only created if `Config.Crafting.craftCam` is enabled in the configuration.
--
---@param ent entityId|coords The base position for the camera. Can be an entity handle or a `vector3` position.
-- If `ent` is an entity, the camera position is calculated as an offset from the entity's position using `GetOffsetFromEntityInWorldCoords`.
-- If `ent` is a `vector3`, it is used directly as the camera's position.
--
---@param coords vector3 The target `vector3` coordinates that the camera will point at.
--
---@return cam camID The handle of the created camera, or `nil` if the camera was not created (e.g., if `Config.Crafting.craftCam` is `false`).
--
---@usage
-- ```lua
-- local cam = createTempCam(entity, targetCoords)
-- ```
function createTempCam(ent, coords)
	local cam = nil
	if Config.Crafting.craftCam then
		if debugMode then
			triggerNotify(nil, "ModCam Created", "success")
		end
		local camCoords = nil
		if type(ent) ~= "vector3" then
			camCoords = GetOffsetFromEntityInWorldCoords(ent, 1.0, -0.3, 0.8)
		else
			camCoords = ent
		end
		-- Create the camera with specified parameters
		cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camCoords.x, camCoords.y, camCoords.z + 0.5, 1.0, 0.0, 0.0, 60.00, false, 0)
		-- Point the camera at the target coordinates
		PointCamAtCoord(cam, coords)
	end
	return cam
end

--- Activates and starts rendering the temporary camera.
--
-- This function sets the specified camera as active and begins rendering it with a smooth transition.
-- The camera is only activated if `Config.Crafting.craftCam` is enabled in the configuration.
--
---@param cam camID The handle of the camera to activate and render.
--
---@usage
-- ```lua
-- startTempCam(cam)
-- ```
function startTempCam(cam)
	if Config.Crafting.craftCam then
		SetCamActive(cam, true)
		RenderScriptCams(true, true, 1000, true, true)
	end
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
function stopTempCam()
	if Config.Crafting.craftCam then
		CreateThread(function()
			Wait(1000)
			RenderScriptCams(false, true, 500, true, true)
			DestroyAllCams()
		end)
	end
end