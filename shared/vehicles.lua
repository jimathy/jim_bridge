--[[
    Vehicle Info & Properties Module
    ----------------------------------
    This module provides utilities for:
      - Retrieving vehicle information from a Vehicles table.
      - Getting and setting vehicle properties using the active framework.
      - Comparing vehicle property differences.
      - Synchronizing vehicle properties across clients.
      - Managing network control of vehicles.
      - Finding the closest vehicle to a given position.
]]

-- Cached vehicle info to avoid unnecessary re-searches.
local lastCar, carInfo = nil, {}

--- Searches the 'Vehicles' table for a specific vehicle's details.
--- If the vehicle differs from the last searched, it retrieves its model and updates the carInfo table.
--- The table includes the vehicle's name, price, and class information.
---
--- @param vehicle number The entity ID of the vehicle to search for.
--- @return table|nil table A table containing the vehicle's details or nil if the vehicle is invalid.
---
--- @usage
--- ```lua
--- local info = searchCar(vehicleEntity)
--- print(info.name, info.price, info.class.name, info.class.index)
--- ```
function searchCar(vehicle)
    if lastCar ~= vehicle then -- If same car, use previous info
        lastCar = vehicle
        carInfo = {}
        local model = GetEntityModel(vehicle)
        local classlist = {
            "Compacts",          --1
            "Sedans",            --2
            "SUVs",              --3
            "Coupes",            --4
            "Muscle",            --5
            "Sports Classics",   --6
            "Sports",            --7
            "Super",             --8
            "Motorcycles",       --9
            "Off-road",          --10
            "Industrial",        --11
            "Utility",           --12
            "Vans",              --13
            "Cycles",            --14
            "Boats",             --15
            "Helicopters",       --16
            "Planes",            --17
            "Service",           --18
            "Emergency",         --19
            "Military",          --20
            "Commercial",        --21
            "Trains",            --22
            "Open Wheel",        --23
        }
        if Vehicles then
            for k, v in pairs(Vehicles) do
                if tonumber(v.hash) == model or joaat(v.hash) == model or joaat(v.model) == model then
                    debugPrint("^6Bridge^7: ^2Vehicle info found in^7 ^4Vehicles^7 ^2table^7: ^6"..(v.hash and v.hash or v.model).. " ^7(^6"..Vehicles[k].name.."^7)")
                    carInfo.name = Vehicles[k].name.." "..Vehicles[k].brand
                    carInfo.price = Vehicles[k].price
                    carInfo.class = classlist[GetVehicleClass(vehicle) + 1], GetVehicleClass(vehicle)
                    break
                end
            end

            if not carInfo.name then
                debugPrint("^6Bridge^7: ^2Vehicle ^1not ^2found in ^4vehicles^7 ^2table^7: ^6"..model.." ^7(^6"..GetDisplayNameFromVehicleModel(model):lower().."^7)")
                carInfo.name = string.upper(GetMakeNameFromVehicleModel(model).." "..GetDisplayNameFromVehicleModel(model))
                carInfo.price = 0
                carInfo.class = classlist[GetVehicleClass(vehicle) + 1], GetVehicleClass(vehicle)
            end
            return carInfo
        else
            if not carInfo.name then
                debugPrint("^6Bridge^7: ^2Vehicle ^1not ^2found in ^4vehicles^7 ^2table^7: ^6"..model.." ^7(^6"..GetDisplayNameFromVehicleModel(model):lower().."^7)")
                carInfo.name = string.upper(GetMakeNameFromVehicleModel(model).." "..GetDisplayNameFromVehicleModel(model))
                carInfo.price = 0
                carInfo.class = classlist[GetVehicleClass(vehicle) + 1], GetVehicleClass(vehicle)
            end
        end
    else
        return carInfo
    end
end

-------------------------------------------------------------
-- Vehicle Properties Functions
-------------------------------------------------------------

--- Retrieves the properties of a given vehicle using the active framework.
---
--- @param vehicle number The entity ID of the vehicle.
--- @return table|nil table A table containing the vehicle's properties or nil if invalid.
---
--- @usage
--- ```lua
--- local props = getVehicleProperties(vehicleEntity)
--- if props then
---     -- Use vehicle properties
--- end
--- ```
function getVehicleProperties(vehicle)
    if not vehicle then return nil end

    local propertyFunc = {
        { framework = OXLibExport,
            func = function(vehicle)
                return lib.getVehicleProperties(vehicle)
            end,
        },
        { framework = QBExport,
            func = function(vehicle)
                return Core.Functions.GetVehicleProperties(vehicle)
            end,
        },
    }
    for i = 1, #propertyFunc do
        local prop = propertyFunc[i]
        if isStarted(prop.framework) then
            local properties = prop.func(vehicle)
            debugPrint("^6Bridge^7: ^2Getting Vehicle Properties ^7[^6"..prop.framework.."^7] - [^3"..vehicle.."^7] - [^3"..GetEntityModel(vehicle).."^7/^3"..properties.model.."^7] - [^3"..properties.plate.."^7]")
            return properties
        end
    end

    return nil
end

--- Sets the properties of a given vehicle if changes are detected.
--- It compares the current properties with the new ones and applies the update using the active framework.
---
--- @param vehicle number The entity ID of the vehicle.
--- @param props table The new properties to apply.
---
--- @usage
--- ```lua
--- setVehicleProperties(vehicleEntity, newProperties)
--- ```
function setVehicleProperties(vehicle, props)
    if checkDifferences(vehicle, props) then
        if not DoesEntityExist(vehicle) then
            print("Unable to set vehicle properties for '"..vehicle.."' (^1entity does not exist^7)")
        end

        if isStarted(QBExport) and not isStarted(QBXExport) then
            Core.Functions.SetVehicleProperties(vehicle, props)
            debugPrint("^6Bridge^7: ^2Setting Vehicle Properties ^7[^6"..QBExport.."^7] - [^3"..vehicle.."^7] - [^3"..GetEntityModel(vehicle).."^7/^3"..props.model.."^7] - [^3"..props.plate.."^7]")

        elseif isStarted(OXLibExport) then
            lib.setVehicleProperties(vehicle, props, false)
            debugPrint("^6Bridge^7: ^2Setting Vehicle Properties ^7[^6"..OXLibExport.."^7] - [^3"..vehicle.."^7] - [^3"..GetEntityModel(vehicle).."^7/^3"..props.model.."^7] - [^3"..props.plate.."^7]")
        end
    else
        debugPrint("^6Bridge^7: ^2No Changes Found ^7 [^3"..vehicle.."^7] - [^3"..GetEntityModel(vehicle).."^7/^3"..props.model.."^7] - [^3"..props.plate.."^7]")
    end
end

--- Checks for differences between the current and new vehicle properties.
--- Compares properties using JSON encoding for deep comparison and logs differences.
---
--- @param vehicle number The entity ID of the vehicle.
--- @param newProps table The new properties to compare.
--- @return boolean `true` if differences are found; `false` otherwise.
---
--- @usage
--- ```lua
--- if checkDifferences(vehicleEntity, newProperties) then
---     setVehicleProperties(vehicleEntity, newProperties)
--- end
--- ```
function checkDifferences(vehicle, newProps)
    local oldProps = getVehicleProperties(vehicle)
    debugPrint("^6Bridge^7: ^2Finding differences in ^3Vehicle Properties^7")
    local differencesFound = true

    for k in pairs(oldProps) do
        if json.encode(oldProps[k]) ~= json.encode(newProps[k]) then
            differencesFound = true
            debugPrint("^6Bridge^7: ^5Old ^7[^3"..k.."^7] - "..json.encode(oldProps[k], { indent = true }))
            debugPrint("^6Bridge^7: ^5New ^7[^3"..k.."^7] - "..json.encode(newProps[k], { indent = true }))
        end
    end

    return differencesFound
end

-------------------------------------------------------------
-- Vehicle Properties Synchronization
-------------------------------------------------------------

--- Event handler for setting vehicle properties received from the server.
--- Listens for the `ox:setVehicleProperties` event and applies the properties.
---
--- @event `getScript()..ox:setVehicleProperties`
--- @param netId number The network ID of the vehicle.
--- @param props table The new vehicle properties.
RegisterNetEvent(getScript()..":ox:setVehicleProperties", function(netId, props)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local value = props
    Entity(vehicle).state[getScript()..':setVehicleProperties'] = value
end)

--- Handles state bag changes for updating vehicle properties.
--- When the state bag changes, the new properties are applied to the vehicle.
---
--- @param bagName string The state bag's name.
--- @param key string The key that changed.
--- @param value table The new state value.
AddStateBagChangeHandler(getScript()..':setVehicleProperties', '', function(bagName, _, value)
    if not value or not GetEntityFromStateBagName then return end
    local entity = GetEntityFromStateBagName(bagName)
    local networked = not bagName:find('localEntity')
    debugPrint("^6Bridge^7: ^2Setting Vehicle Properties ^7[^6"..OXLibExport.."^7] - [^3"..entity.."^7] - [^3"..GetEntityModel(entity).."^7] - [^3"..value.plate.."^7]")

    if networked then return end

    if lib.setVehicleProperties(entity, value) then
        Entity(entity).state:set('setVehicleProperties', nil, true)
    end
end)

-------------------------------------------------------------
-- Vehicle Control Functions
-------------------------------------------------------------

--- This function ensures that the vehicle is controlled by the current player and is set as a mission entity.
--- It requests network control and sets the vehicle accordingly to synchronize changes across clients.
---
---@param entity number The entity ID of the vehicle to push.
---
---@usage
--- ```lua
--- pushVehicle(vehicleEntity)
--- ```
function pushVehicle(entity)
    SetVehicleModKit(entity, 0)
    if entity ~= 0 and DoesEntityExist(entity) then
        -- Request network control if not already controlled.
        if not NetworkHasControlOfEntity(entity) then
            debugPrint("^6Bridge^7: ^3pushEnt^7: ^2Requesting network control of vehicle^7.")
            NetworkRequestControlOfEntity(entity)
            local timeout = 2000
            while timeout > 0 and not NetworkHasControlOfEntity(entity) do
                Wait(100)
                timeout = timeout - 100
            end
            if NetworkHasControlOfEntity(entity) then
                debugPrint("^6Bridge^7: ^3pushEnt^7: ^2Network now has control of the entity^7.")
            end
        end

        -- Set as mission entity if not already set.
        if not IsEntityAMissionEntity(entity) then
            debugPrint("^6Bridge^7: ^3pushEnt^7: ^2Setting vehicle as a ^7'^2mission^7' ^2entity^7.")
            SetEntityAsMissionEntity(entity, true, true)
            local timeout = 2000
            while timeout > 0 and not IsEntityAMissionEntity(entity) do
                Wait(100)
                timeout = timeout - 100
            end
            if IsEntityAMissionEntity(entity) then
                debugPrint("^6Bridge^7: ^3pushEnt^7: ^2Vehicle is a ^7'^2mission^7'^2 entity^7.")
            end
        end
    end
end

-- add entitty named version
function pushEnt(...) pushVehicle(...) end


--- Finds the closest vehicle to the specified coordinates.
--- The function uses different APIs based on whether a source is provided.
---
--- @param coords table|vector3 (Optional) The reference coordinates. If nil, uses the player's position.
--- @param src boolean (Optional) If true, uses GetPlayerPed(source) and GetAllVehicles.
--- @return number closestVehicle The closest vehicle entity and its distance.
--- @return number closestDistance The distance of the closest vehicle.
---
--- @usage
--- ```lua
--- local closestVeh, distance = getClosestVehicle({ x = 100, y = 200, z = 30 }, src)
--- ```
function getClosestVehicle(coords, src)
    local ped, vehicles, closestDistance, closestVehicle

    if src then
        -- if checking server side cache src's ped and use server native
        ped = GetPlayerPed(src)
        vehicles = GetAllVehicles()
    else
        -- if checking client side cache local ped and use client native
        ped = PlayerPedId()
        vehicles = GetGamePool('CVehicle')
    end

    local closestDistance, closestVehicle = -1, -1

    if coords then
        if type(coords) == 'table' then
            coords = vec3(coords.x, coords.y, coords.z)
        end
    else
        coords = GetEntityCoords(ped)
    end

    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords.xyz)

        if closestDistance == -1 or distance < closestDistance then
            closestDistance = distance
            closestVehicle = vehicles[i]
        end
    end

    return closestVehicle, closestDistance
end

--- Checks whether a vehicle is owned or not using the plate as reference
---
--- @param plate string The plate of the vehicle to check
--- @return boolean whether vehicle is owned
---
--- @usage
--- ```lua
--- local plate = "ABCD1234"
--- local isVehicleOwned = isVehicleOwned(plate)
--- ```

local vehiclesOwned = {}

function isVehicleOwned(plate)
    -- If already checked, cache it to reduce database calls
    if vehiclesOwned[plate] == true then
        return true
    else
        -- Find frameworks vehicle table and search sql for if vehicle plate is owned
        local sqlTable = "player_vehicles"
        local vehDatabase = {

            {   framework = ESXExport,
                sqlTable = "owned_vehicles"
            },

            {   framework = QBExport,
                sqlTable = "player_vehicles"
            },

            {   framework = QBXExport,
                sqlTable = "player_vehicles"
            },

            {   framework = OXCoreExport,
                sqlTable = "owned_vehicles"
            },

        }

        for i = 1, #vehDatabase do
            local framework = vehDatabase[i]
            if isStarted(framework.framework) then
                sqlTable = framework.sqlTable
            end
        end

        local result = MySQL.query.await("SELECT 1 from "..sqlTable.." WHERE plate = ?", { plate })
        if json.encode(result) ~= "[]" then
            vehiclesOwned[plate] = true     -- Cache ownership for later checks
            return true
        else
            return false
        end
    end
end