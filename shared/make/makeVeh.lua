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

--- Cleans up all created vehicles when the resource stops.
onResourceStop(function(r)
	for i = 1, #Vehicles do DeleteVehicle(Vehicles[i]) end
end)