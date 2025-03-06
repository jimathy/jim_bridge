-- Get Vehicle Info --
local lastCar = nil
local carInfo = {}

--- Searches the 'Vehicles' table for a specific vehicle's 'name', 'price', and 'class'.
---
--- This function checks if the provided vehicle is different from the last searched vehicle.
--- If it's a new vehicle, it retrieves its model and searches the 'Vehicles' table for matching entries.
--- It populates the `carInfo` table with the vehicle's name, price, and class.
--- If the vehicle is not found in the table, it defaults to using the vehicle's display name and sets the price to 0.
---
---@param vehicle number The entity ID of the vehicle to search for.
---
---@return table|nil table containing the vehicle's `name`, `price`, and `class`, or `nil` if the vehicle is invalid.
---
---@usage
--- ```lua
--- local info = searchCar(vehicleEntity)
--- print(info.name, info.price, info.class)
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
        }
        if Vehicles then
            for k, v in pairs(Vehicles) do
                if tonumber(v.hash) == model or GetHashKey(v.hash) == model or GetHashKey(v.model) == model then
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

-- Vehicle Properties --

--- Retrieves the properties of a given vehicle.
---
--- This function fetches the vehicle's properties based on the active framework (QBCore or ox).
--- It utilizes the framework's native functions or events to obtain the vehicle's mod list and other details.
---
--- @param vehicle number The entity ID of the vehicle.
---
--- @return table|nil table containing the vehicle's properties, or `nil` if the vehicle is invalid or the framework is not detected.
---
--- @usage
--- ```lua
--- local props = getVehicleProperties(vehicleEntity)
--- if props then
---     -- Manipulate vehicle properties
--- end
--- ```
function getVehicleProperties(vehicle)
    local properties = {}
    if vehicle == nil then return nil end
    if isStarted(QBExport) and not isStarted(QBXExport) then
        properties = Core.Functions.GetVehicleProperties(vehicle)
        debugPrint("^6Bridge^7: ^2Getting Vehicle Properties ^7[^6"..QBExport.."^7] - [^3"..vehicle.."^7] - [^3"..GetEntityModel(vehicle).."^7/^3"..properties.model.."^7] - [^3"..properties.plate.."^7]")
    elseif isStarted(OXLibExport) then
        properties = lib.getVehicleProperties(vehicle)
        debugPrint("^6Bridge^7: ^2Getting Vehicle Properties ^7[^6"..OXLibExport.."^7] - [^3"..vehicle.."^7] - [^3"..GetEntityModel(vehicle).."^7/^3"..properties.model.."^7] - [^3"..properties.plate.."^7]")
    end
    return properties
end

--- Sets the properties of a given vehicle.
---
--- This function applies the provided properties to the vehicle using the active framework's functions or events.
--- It first retrieves the current properties and checks for differences before applying the new ones.
---
---@param vehicle number The entity ID of the vehicle.
---@param props table The properties to set on the vehicle.
---
---@usage
--- ```lua
--- setVehicleProperties(vehicleEntity, newProperties)
--- ```
function setVehicleProperties(vehicle, props)
    local oldProps = getVehicleProperties(vehicle)
    if checkDifferences(vehicle, props) then
        --if debugMode then debugDifferences(vehicle, props) end
        if not DoesEntityExist(vehicle) then
            print(("Unable to set vehicle properties for '%s' (entity does not exist)"):format(vehicle))
        end
        if isStarted(QBExport) and not isStarted(QBXExport) then
            Core.Functions.SetVehicleProperties(vehicle, props)
            debugPrint("^6Bridge^7: ^2Setting Vehicle Properties ^7[^6"..QBExport.."^7] - [^3"..vehicle.."^7] - [^3"..GetEntityModel(vehicle).."^7/^3"..props.model.."^7] - [^3"..props.plate.."^7]")
        else
            TriggerServerEvent(getScript()..":ox:setVehicleProperties", VehToNet(vehicle), props)
        end
    else
        debugPrint("^6Bridge^7: ^2No Changes Found ^7 [^3"..vehicle.."^7] - [^3"..GetEntityModel(vehicle).."^7/^3"..props.model.."^7] - [^3"..props.plate.."^7]")
    end
end

--- Checks for differences between the current and new vehicle properties.
---
--- This function compares each property of the vehicle to determine if any changes have been made.
--- It logs the differences for debugging purposes.
---
---@param vehicle number The entity ID of the vehicle.
---@param newProps table The new properties to compare against the current ones.
---
---@return boolean `true` if differences are found, `false` otherwise.
---
---@usage
--- ```lua
--- if checkDifferences(vehicleEntity, newProperties) then
---     setVehicleProperties(vehicleEntity, newProperties)
--- end
--- ```
function checkDifferences(vehicle, newProps)
    local oldProps = getVehicleProperties(vehicle)
    debugPrint("^6Bridge^7: ^2Finding differences in ^3Vehicle Properties^7")
    local allow = false
    for k in pairs(oldProps) do
        if json.encode(oldProps[k]) ~= json.encode(newProps[k]) then
            allow = true
            debugPrint("^6Bridge^7: ^5Old ^7[^3"..k.."^7] - "..json.encode(oldProps[k], { indent = true }))
            debugPrint("^6Bridge^7: ^5New ^7[^3"..k.."^7] - "..json.encode(newProps[k], { indent = true }))
        end
    end
    return allow
end

--- Handles setting vehicle properties received from the server.
---
--- This event listens for the `ox:setVehicleProperties` event and applies the received properties to the vehicle.
---
---@event
---@param netId number The network ID of the vehicle.
---@param props table The properties to set on the vehicle.
---
---@usage
--- -- Server-side: TriggerClientEvent(getScript()..":ox:setVehicleProperties", netId, properties)
RegisterNetEvent(getScript()..":ox:setVehicleProperties", function(netId, props)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local value = props
    Entity(vehicle).state[getScript()..':setVehicleProperties'] = value
end)

--- Handles state bag changes for setting vehicle properties.
---
--- This handler listens for changes to the vehicle's state bag and applies the new properties accordingly.
---
---@param bagName string The name of the state bag.
---@param key string The key that changed.
---@param value table The new value of the state.
---
---@usage
--- -- Automatically handled when the state bag changes
AddStateBagChangeHandler(getScript()..':setVehicleProperties', '', function(bagName, _, value)
    if not value or not GetEntityFromStateBagName then return end
    local entity = GetEntityFromStateBagName(bagName)
    local networked = not bagName:find('localEntity')
    debugPrint("^6Bridge^7: ^2Setting Vehicle Properties ^7[^6"..OXLibExport.."^7] - [^3"..entity.."^7] - [^3"..GetEntityModel(entity).."^7] - [^3"..value.plate.."^7]")

    if networked and NetworkGetEntityOwner(entity) ~= cache.playerId then return end

    if lib.setVehicleProperties(entity, value) then
        Entity(entity).state:set('setVehicleProperties', nil, true)
    end
end)

--- Pushes a vehicle to other players by syncing it.
---
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
        if not NetworkHasControlOfEntity(entity) then
            debugPrint("^6Bridge^7: ^3pushVehicle^7: ^2Requesting network control of vehicle^7.")
            NetworkRequestControlOfEntity(entity)
            local timeout = 2000
            while timeout > 0 and not NetworkHasControlOfEntity(entity) do
                Wait(100)
                timeout = timeout - 100
            end
            if NetworkHasControlOfEntity(entity) then
                debugPrint("^6Bridge^7: ^3pushVehicle^7: ^2Network has control of entity^7.")
            end
        end
        if not IsEntityAMissionEntity(entity) then
            debugPrint("^6Bridge^7: ^3pushVehicle^7: ^2Setting vehicle as a ^7'^2mission^7' &2entity^7.")
            SetEntityAsMissionEntity(entity, true, true)
            local timeout = 2000
            while timeout > 0 and not IsEntityAMissionEntity(entity) do
                Wait(100)
                timeout = timeout - 100
            end
            if IsEntityAMissionEntity(entity) then
                debugPrint("^6Bridge^7: ^3pushVehicle^7: ^2Vehicle is a ^7'^2mission^7'^2 entity^7.")
            end
        end
    end
end

function getClosestVehicle(coords, src)
    if src then
        local ped = GetPlayerPed(source)
        local vehicles = GetAllVehicles()
        local closestDistance, closestVehicle = -1, -1
        if coords then coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords end
        if not coords then coords = GetEntityCoords(ped) end
        for i = 1, #vehicles do
            local vehicleCoords = GetEntityCoords(vehicles[i])
            local distance = #(vehicleCoords - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestVehicle = vehicles[i]
                closestDistance = distance
            end
        end
        return closestVehicle, closestDistance
    else
        local ped = PlayerPedId()
        local vehicles = GetGamePool('CVehicle')
        local closestDistance = -1
        local closestVehicle = -1
        if coords then
            coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
        else
            coords = GetEntityCoords(ped)
        end
        for i = 1, #vehicles, 1 do
            local vehicleCoords = GetEntityCoords(vehicles[i])
            local distance = #(vehicleCoords - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestVehicle = vehicles[i]
                closestDistance = distance
            end
        end
        return closestVehicle, closestDistance
    end
end