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
function makeVeh(model, coords, synced, fade)
	loadModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, synced ~= false, false)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
	if gameName ~= "rdr3" then
        SetEntityAlpha(veh, 0, false)
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(veh), true)
		Wait(100)
		SetVehicleNeedsToBeHotwired(veh, false)
		SetVehRadioStation(veh, 'OFF')
		SetVehicleFuelLevel(veh, 100.0)
		SetVehicleModKit(veh, 0)

	end
	SetVehicleOnGroundProperly(veh)
	debugPrint("^6Bridge^7: ^1Veh ^2Created^7: '^6"..veh.."^7' | ^2Hash^7: ^7'^6"..model.."^7' | ^2Coord^7: "..formatCoord(coords))
	unloadModel(model)
	Vehicles[#Vehicles + 1] = veh
    if fade ~= false then
        CreateThread(function()
            fadeInEnt(veh)
        end)
    end
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
            vehicle = makeVeh(data.model, data.coords, false)
			if onEnter then
				debugPrint("^6Bridge^7: ^4makeDistVehicle ^3onEnter^7() ^2running^7")
				onEnter(vehicle)
			end
        end,
        onExit = function()
            deleteVehicle(vehicle)
			if onExit then
				debugPrint("^6Bridge^7: ^4makeDistVehicle ^3onExit^7() ^2running^7")
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