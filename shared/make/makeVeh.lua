local Vehicles = {}

--- Creates a vehicle with the specified model and coordinates.
---
--- This function loads the vehicle model, creates the vehicle in the world at the given coordinates, sets initial properties, and returns the vehicle handle.
---
---@param model string|number The model name or hash of the vehicle to create.
---@param coords vector4 The coordinates where the vehicle will be placed, including x, y, z, and w (heading).
---
---@return number entityID The handle of the created vehicle.
---
---@usage
--- ```lua
--- local vehicle = makeVeh('adder', vector4(123.4, 567.8, 90.1, 180.0))
--- ```
function makeVeh(model, coords)
	loadModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, false)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(veh), true)
	Wait(100)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetVehicleFuelLevel(veh, 100.0)
	SetVehicleModKit(veh, 0)
	SetVehicleOnGroundProperly(veh)

	debugPrint("^6Bridge^7: ^1Veh ^2Created^7: '^6"..veh.."^7' | ^2Hash^7: ^7'^6"..model.."^7' | ^2Coord^7: "..formatCoord(coords))
	unloadModel(model)
	Vehicles[#Vehicles + 1] = veh
	return veh
end

local distanceVehicles = {}
--- Creates a vehicle that spawns when the player enters a designated polyzone area.
---
--- This function sets up a circular polyzone; when the player enters the zone, the vehicle is spawned,
--- and when the player exits, the vehicle is deleted.
---
---@param data table A table containing vehicle data.
--- - **vehicle** `string`: The model name or hash of the vehicle to spawn.
--- - **coords** `vector4`: The coordinates where the vehicle will be placed. Should include x, y, z, and w (heading).
---@param freeze boolean (optional) Whether to freeze the vehicle in place. Defaults to `false`.
---@param synced boolean (optional) Whether the vehicle should be synced across clients. Defaults to `false`.
function makeDistVehicle(data, radius, onEnter, onExit)
    local vehicle = nil
	local zoneId = keyGen() .. keyGen()
    local zone = createCirclePoly({
        name = zoneId,
        coords = vec3(data.coords.x, data.coords.y, data.coords.z),
        radius = radius,
        onEnter = function()
            vehicle = makeVeh(data.model, data.coords)
			if onEnter then
				debugPrint("makeDistVehicle onEnter running")
				onEnter(vehicle)
			end
        end,
        onExit = function()
            deleteVehicle(vehicle)
			if onExit then
				debugPrint("makeDistVehicle onExit running")
				onExit(vehicle)
			end
        end,
        debug = debugMode,
    })
	distanceVehicles[zoneId] = { zone = zone, vehicle = vehicle }
	return zoneId
end

--- Removes a specific distance-based vehicle spawning zone.
---
---@param zoneId string The unique identifier of the zone to remove.
function removeDistVehicleZone(zoneId)
    if distanceVehicles[zoneId].zone then
        removePolyZone(distanceVehicles[zoneId].zone) -- Adjust this if your polyzone library uses a different removal method.
        if distanceVehicles[zoneId].vehicle then
			deleteVehicle(distanceVehicles[zoneId].vehicle)
		end
		distanceVehicles[zoneId] = nil
        print("Removed polyzone for zoneId: " .. zoneId)
    else
        print("No zone found with zoneId: " .. zoneId)
    end
end

--- Attempts to gain network control of a vehicle and set it as a mission entity.
---
--- This function forces synchronization of a vehicle with other players by requesting network control and setting the vehicle as a mission entity.
---
---@param entity number The handle of the vehicle entity to push.
---
---@usage
--- ```lua
--- pushVehicle(vehicle)
--- ```
function pushVehicle(entity)
	SetVehicleModKit(entity, 0)
	if entity ~= 0 and DoesEntityExist(entity) then
		if not NetworkHasControlOfEntity(entity) then
			debugPrint("^6Bridge^7: ^3pushVehicle^7: ^2Requesting network control of vehicle^7.")
			NetworkRequestControlOfEntity(entity)
			local timeout = 2000
			while timeout > 0 and not NetworkHasControlOfEntity(entity) do
				Wait(100)
				timeout -= 100
			end
			if NetworkHasControlOfEntity(entity) then debugPrint("^6Bridge^7: ^3pushVehicle^7: ^2Network has control of entity^7.") end
		end
		if not IsEntityAMissionEntity(entity) then
			debugPrint("^6Bridge^7: ^3pushVehicle^7: ^2Setting vehicle as a ^7'^2mission^7' ^2entity^7.")
			SetEntityAsMissionEntity(entity, true, true)
			local timeout = 2000
			while timeout > 0 and not IsEntityAMissionEntity(entity) do
				Wait(100)
				timeout -= 100
			end
			if IsEntityAMissionEntity(entity) then debugPrint("^6Bridge^7: ^3pushVehicle^7: ^2Vehicle is a ^7'^2mission^7'^2 entity^7.") end
		end
	end
end

--- Deletes a spawned vehicle.
---
---@param vehicle number The handle of the vehicle entity to delete.
function deleteVehicle(vehicle)
    if vehicle then
        debugPrint("^6Bridge^7: ^2Destroying Vehicle^7: '^6" .. vehicle .. "^7'")
        if IsEntityAttachedToEntity(vehicle, PlayerPedId()) then
            SetEntityAsMissionEntity(vehicle)
            DetachEntity(vehicle, true, true)
        end
        DeleteVehicle(vehicle)
    end
end

--- Cleans up all created vehicles when the resource stops.
onResourceStop(function(r)
	for i = 1, #Vehicles do DeleteVehicle(Vehicles[i]) end
end)