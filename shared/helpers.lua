--- Utility Functions for Resource Management and Debugging
---
--- This script provides a set of utility functions for managing resources, debugging, and handling various common tasks within the game environment.
--- It includes functions for checking resource states, generating unique keys, formatting numbers and coordinates, handling JSON data, and more.

--[[ Resource and Environment Checks ]]--

--- Checks if a specific resource is started.
---
---@param script string The name of the resource to check.
---@return boolean `true` if the resource state contains "start", otherwise `false`.
---
---@usage
--- ```lua
--- if isStarted("myResource") then
---     print("Resource is running")
--- end
--- ```
function isStarted(script)
    return GetResourceState(script):find("start")
end

local scriptName = nil

--- Retrieves the current resource name.
---
--- Caches the resource name after the first call for efficiency.
---
--- @return string scriptName The name of the current resource.
---
--- @usage
--- ```lua
--- local currentScript = getScript()
--- print("Current script:", currentScript)
--- ```
function getScript()
    if not scriptName then scriptName = GetCurrentResourceName() end
    return scriptName
end

--- Determines if the current execution context is the server.
---
--- Very helpful for shared files complaining about client functions running on server or vice versa
---
--- @return boolean Returns `true` if running on the server, otherwise `false`.
---
---@usage
--- ```lua
--- if isServer() then
---     -- Server-specific code
--- else
---     -- Client-specific code
--- end
--- ```
function isServer()
    return IsDuplicityVersion()
end

--[[ Debugging Functions ]]--

--- Prints debug messages if debugging mode is enabled.
---
--- Concatenates all arguments and prints them along with debug information.
---
--- @param ... any Multiple arguments to be concatenated and printed.
---
--- @usage
--- ```lua
--- debugPrint("Player has joined:", playerName)
--- ```
function debugPrint(...)
    if debugMode then
        local args = {...}
        local output = table.concat(args, " ")  -- Concatenate all arguments with a space
        print(output, getDebugInfo(debug.getinfo(2, "nSl")))
    end
end

--- Prints event-related debug messages if event debugging is enabled.
---
--- @param ... any Multiple arguments to be printed.
---
--- @usage
--- ```lua
--- eventPrint("Event triggered:", eventName)
--- ```
function eventPrint(...)
    if Config.System.EventDebug then
        print(...)
    end
end

-- Function to recursively colorize the JSON data
function getSortedKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        local numA, numB = tonumber(a), tonumber(b)
        if numA and numB then return numA < numB
        else return tostring(a) < tostring(b) end
    end)
    return keys
end

--- Recursively colorizes a table for debug printing.
---
--- @param tbl table The table to colorize.
--- @return table colourizedTable The colorized table.
---
--- @usage
--- ```lua
--- local colorizedData = colorizeTable(myTable)
--- jsonPrint(colorizedData)
--- ```
function colorizeTable(tbl)
    local newData, sortedKeys = {}, getSortedKeys(tbl)
    for _, k in ipairs(sortedKeys) do
        local v = tbl[k]
        newData["^6"..tostring(k).."^7"] = ((type(v) == "table") and colorizeTable(v)) or (type(v):find("vector") and formatCoord(v)) or "^2"..tostring(v).."^7"
    end
    return newData
end

--- Encodes a table into an ordered JSON string with indentation.
---
--- @param data table The table to encode.
--- @param indent string The string used for indentation (e.g., "  ").
--- @param level number The current indentation level.
--- @return string The formatted JSON string.
---
--- @usage
--- ```lua
--- local jsonString = encodeOrderedJSON(myTable, "  ", 0)
--- print(jsonString)
--- ```
function encodeOrderedJSON(data, indent, level)
    local jsonParts, prefix, sortedKeys = {"{"}, string.rep(indent, level), getSortedKeys(data)
    for i, k in ipairs(sortedKeys) do
        jsonParts[#jsonParts + 1] = (i > 1 and ",\n" or "\n")..prefix..indent..json.encode(k)..": "
        jsonParts[#jsonParts + 1] = (type(data[k]) == "table") and encodeOrderedJSON(data[k], indent, level + 1) or json.encode(data[k])
    end
    jsonParts[#jsonParts + 1] = "\n"..prefix.."}"
    return table.concat(jsonParts)
end

--- Prints a table as a colorized and ordered JSON string if debugging mode is enabled.
---
--- @param data table The table to print.
---
--- @usage
--- ```lua
--- jsonPrint(myTable)
--- ```
function jsonPrint(data)
    if debugMode then
        print(encodeOrderedJSON(colorizeTable(data), "  ", 0), getDebugInfo(debug.getinfo(2, "nSl")))
    end
end

--- Retrieves the current time formatted for debug prints.
---
--- @return string string The formatted time string, e.g., "^7(14:23:45)".
---
--- @usage
--- ```lua
--- local currentTime = GetPrintTime()
--- debugPrint("Current Time:", currentTime)
--- ```
function GetPrintTime()
    if isServer() then
        local hour, min, sec = os.date('%H'), os.date('%M'), os.date('%S')
        return "^7("..string.format("%02d", hour)..":"..string.format("%02d", min)..":"..string.format("%02d", sec)..")"
    else
        local _, _, _, hour, min, sec = GetLocalTime()
        return "^7("..string.format("%02d", hour)..":"..string.format("%02d", min)..":"..string.format("%02d", sec)..")"
    end
end

--- Generates a unique 3-character alphanumeric key.
---
--- @return string GeneratedString A randomly generated 3-character string.
---
--- @usage
--- ```lua
--- local uniqueKey = keyGen()
--- print("Generated Key:", uniqueKey)
--- ```
function keyGen()
    local charset = {
        "q","w","e","r","t","y","u","i","o","p","a","s","d","f","g","h","j","k","l","z","x","c","v","b","n","m",
        "Q","W","E","R","T","Y","U","I","O","P","A","S","D","F","G","H","J","K","L","Z","X","C","V","B","N","M",
        "1","2","3","4","5","6","7","8","9","0"
    }
    local GeneratedID = ""
	for i = 1, 3 do GeneratedID = GeneratedID..charset[math.random(1, #charset)] end
    return GeneratedID
end

--- Formats a number with commas as thousand separators.
---
--- @param amount number The number to format.
--- @return string commaValue The formatted number string with commas.
---
--- @usage
--- ```lua
--- local formattedNumber = cv(1000000)  -- "1,000,000"
--- print(formattedNumber)
--- ``
function cv(amount)
    local formatted = tostring(amount or "0")
    while true do formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2') if (k==0) then break end Wait(0) end
    return formatted
end

--- Formats a coordinate vector for debug printing.
---
--- @param coord table A vector3 or vector4 table with `x`, `y`, `z`, and optional `w` components.
--- @return string The formatted coordinate string with color codes.
---
--- @usage
--- ```lua
--- local formattedCoord = formatCoord(vector3(100.0, 200.0, 300.0))
--- debugPrint("Player Position:", formattedCoord)
--- ```
function formatCoord(coord)
    local vecType = type(coord):gsub("tor", "")
    local components = {
        [1] = coord.x and ("^6"..string.format("%.1f", coord.x)) or "",
        [2] = coord.y and ("^7, ^6"..string.format("%.1f", coord.y)) or "",
        [3] = coord.z and ("^7, ^6"..string.format("%.1f", coord.z)) or "",
        [4] = coord.w and ("^7, ^6"..string.format("%.1f", coord.w)) or "",
    }
    return "^5"..vecType.."^7("..components[1]..components[2]..components[3]..components[4].."^7)"
end

--- Calculates the center point of a list of zones (coordinates).
---
--- @param table table A table of vector3 coordinates.
--- @return vector3 vector3 The center coordinate.
---
--- @usage
--- ```lua
--- local center = getCenterOfZones({vector3(100, 200, 300), vector3(110, 210, 310)})
--- print("Center of Zones:", center)
--- ```
function getCenterOfZones(table)
    local totalX, totalY, totalZ = 0, 0, 0

    for _, coord in ipairs(table) do
        totalX = totalX + coord.x
        totalY = totalY + coord.y
        totalZ = totalZ + coord.z
    end

    local count = #table
    return vector3(totalX / count, totalY / count, totalZ / count)
end

--- Counts the number of keys in a table.
---
--- @param table table The table to count keys in.
--- @return number number The number of keys in the table.
---
--- @usage
--- ```lua
--- local count = countTable(myTable)
--- print("Number of keys:", count)
--- ```
function countTable(table) local i = 0 for keys in pairs(table) do i += 1 end return i end


--- Returns an iterator that iterates over a table's keys in sorted order.
---
--- @param t table The table to iterate over.
--- @return function function An iterator function.
---
--- @usage
--- ```lua
--- for k, v in pairsByKeys(myTable) do
---     print(k, v)
--- end
--- ```
function pairsByKeys(t)
    local t = t
    if not t then
        print("^1Error^7: ^3Nil ^2table recieved for ^3pairsByKeys^7(), ^2setting to ^7{} ^2to prevent break^7")
        t = {}
    end
    local a = {} for n in pairs(t) do a[#a+1] = n end table.sort(a) local i = 0 local iter = function() i += 1 if a[i] == nil then return nil else return a[i], t[a[i]] end end return iter
end

--- Creates a new table with consecutive numerical indices sorted by the `id` field.
---
--- @param originalTable table The original table with entries containing an `id` field.
--- @return table The new table with sorted entries and consecutive `id` values.
---
--- @usage
--- local sortedTable = createConsecutiveTable(originalTable)
--- for i, entry in ipairs(sortedTable) do
---     print(i, entry)
--- end
function createConsecutiveTable(originalTable)
    local sortedEntries = {}
    for _, entry in pairs(originalTable) do
        table.insert(sortedEntries, entry)
    end
    table.sort(sortedEntries, function(a, b)
        return a.id < b.id
    end)
    local newTable = {}
    for newIndex, entry in ipairs(sortedEntries) do
        entry.id = newIndex
        newTable[newIndex] = entry
    end
    return newTable
end

--[[ Drawing Functions ]]--

--- Draws 3D text at specified coordinates.
---
--- @param coord table A vector3 table with `x`, `y`, and `z` coordinates.
--- @param text string The text to display.
--- @param highlight boolean (optional) Whether to highlight certain parts of the text.
---
--- @usage
--- ```lua
--- CreateThread(function()
---     while true do
---         DrawText3D(vector3(100, 200, 300), "Hello World", true)
---         Wait(0)
---     end
--- end)
--- ```
function DrawText3D(coord, text, highlight)
    SetTextScale(0.30, 0.30)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    local totalLength = string.len(text)
    local textMaxLength = textMaxLength or 99 -- max 99
    local text = totalLength > textMaxLength and text:sub(1, totalLength - (totalLength - textMaxLength)) or text
    AddTextComponentString(highlight and text:gsub("%~w~", "~y~") or text)
    SetDrawOrigin(coord.x, coord.y, coord.z, 0)
    DrawText(0.0, 0.0)
    local count, length = GetLineCountAndMaxLength(text)

    local padding = 0.005
    local heightFactor = (count / 43) + padding
    local weightFactor = (length / 150) + padding

    local height = (heightFactor / 2) - padding / 1
    local width = (weightFactor / 2) - padding / 1

    DrawRect(0.0, height, width, heightFactor, 0, 0, 0, 150)
    ClearDrawOrigin()
end

--- Displays a help message on the screen.
---
--- @param text string The text to display as a help message.
---
--- @usage
--- DisplayHelpMsg("Press E to interact")
function DisplayHelpMsg(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandDisplayHelp(0, true, false, -1)
end

--- Displays a "Saving/Loading" spinner with a custom message.
---
--- @param text string The message to display alongside the spinner.
---
--- @usage
--- ```lua
--- displaySpinner("Saving data...")
--- ```
function displaySpinner(text)
    BeginTextCommandBusyspinnerOn('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandBusyspinnerOn(4)
end

--- Stops the "Saving/Loading" spinner.
---
--- This function is client-side only.
---
--- @usage
--- ```lua
--- stopSpinner()
--- ```
function stopSpinner()
    if not isServer() then
        BusyspinnerOff()
    end
end

--- Concatenates a table of strings into a single string separated by newlines.
---
--- @param tbl table A table containing string elements.
--- @return string string The concatenated string with newline separators.
---
--- @usage
--- ```lua
--- local combinedText = concatenateText({"Line 1", "Line 2", "Line 3"})
--- print(combinedText)
--- ```
function concatenateText(tbl)
    local result = ""
    for i = 1, #tbl do
        result = result..tbl[i]
        if i < #tbl then
            result = result.."\n"  -- Add newline only if it's not the last element
        end
    end
    return result
end

--- Converts rotation to a direction vector.
---
--- @param rot vector3 A vector3 containing rotation values
--- @return vector3 vector3 A vector3 representing the direction.
---
--- @usage
--- ```lua
--- local direction = RotationToDirection({ z = 90 })
--- print(direction)
--- ```
function RotationToDirection(rot)
    local adjust = (math.pi / 180)
    return vec3(-math.sin(adjust * rot.z) * math.abs(math.cos(adjust * rot.x)), math.cos(adjust * rot.z) * math.abs(math.cos(adjust * rot.x)), math.sin(adjust * rot.x))
end

--- Creates a simple text-based progress bar.
---
--- @param percentage number The completion percentage (0-100).
--- @return string string A string representing the progress bar, e.g., "█████░░░░░".
---
--- @usage
--- ```lua
--- local bar = basicBar(50)  -- "█████░░░░░"
--- print(bar)
--- ```
function basicBar(percentage)
    local percentage = math.ceil(percentage)
    local totalBlocks = 10
    local filledBlocks = math.floor((percentage / 100) * totalBlocks)
    local emptyBlocks = totalBlocks - filledBlocks

    local bar = string.rep("█", filledBlocks)..string.rep("░", emptyBlocks)
    return bar
end

--- Normalizes a 3D vector.
---
--- @param vec vector3 A vector3 table with `x`, `y`, and `z` components.
--- @return vector3 vector3 The normalized vector3.
---
--- @usage
--- ```lua
--- local normalizedVec = normalizeVector(vector3(1, 2, 3))
--- print(normalizedVec)
--- ```
function normalizeVector(vec)
    local length = math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
    if length ~= 0 then
        return vec3(vec.x / length, vec.y / length, vec.z / length)
    else
        return vec3(0, 0, 0)
    end
end

--- Draws a line between two coordinates for debugging purposes.
---
--- @param startCoords vector3 A vector3 table representing the start point.
--- @param endCoords vector3 A vector3 table representing the end point.
--- @param col vector4 A table with `x`, `y`, `z`, `w` representing the color and opacity.
---
--- @usage
--- ```lua
--- drawLine(vector3(100, 200, 300), vector3(150, 250, 350), vector4(255, 0, 0, 255))
--- ```
function drawLine(startCoords, endCoords, col)
    if debugMode then
        CreateThread(function()
            local showCount = 1000
            while showCount >= 0 do
                DrawLine(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y, endCoords.z, col.x, col.y, col.z, col.w)
                showCount -= 10
                Wait(0)
            end
        end)
    end
end

--- Draws a sphere at specified coordinates for debugging purposes.
---
--- @param coords vector3 A vector3 table representing the center of the sphere.
--- @param col vector4 A table with `x`, `y`, `z`, `w` representing the color and opacity.
---
--- @usage
--- ```lua
--- drawSphere(vector3(100, 200, 300), vector4(0, 255, 0, 255))
--- ```
function drawSphere(coords, col)
    if debugMode then
        CreateThread(function()
            local showCount = 1000
            while showCount >= 0 do
                DrawSphere(coords.x, coords.y, coords.z, 0.5, col.x, col.y, col.z, col.w)
                showCount -= 1
                Wait(10)
            end
        end)
    end
end

--- Performs a raycast between two coordinates and returns the result.
---
--- @param startCoords table A vector3 table representing the start point.
--- @param endCoords table A vector3 table representing the end point.
--- @param entity number|nil The entity to ignore during the raycast.
--- @param flags number|nil Raycast flags to customize the raycast behavior. Defaults to `4294967295`.
--- @return multiple multiple Returns multiple values from `GetShapeTestResultIncludingMaterial`.
---
--- @usage
--- ```lua
--- local hit, hitPos, material = PerformRaycast(startVec, endVec, playerPed, 1)
--- if hit == 1 then
---     print("Hit at position:", hitPos)
---     print("Material:", material)
--- end
--- ```
function PerformRaycast(startCoords, endCoords, entity, flags)
    drawLine(startCoords, endCoords, vec4(0, 0, 255, 255))
    local val1, val2, val3, val4, val5, val6 = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y, endCoords.z, flags or 4294967295, entity, 0))
    if val2 then
        --drawSphere(val3, vec4(255, 0, 255, 0.5))
    end
    return val1, val2, val3, val4, val5, val6
end

--- Adjusts the Z-coordinate of a position to align with the ground.
---
--- @param coords vector4 A vector3 or vector4 table with `x`, `y`, `z`, and optional `w` components.
--- @return vector3|vector4 vector  adjusted coordinate with the Z value set to the ground level.
---
--- @usage
--- ```lua
--- local groundCoords = adjustForGround(playerCoords)
--- print("Ground Position:", groundCoords)
--- ```
function adjustForGround(coords)
    local coords = coords
    local foundGround, zPos = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0)

    if foundGround then
        if coords.w then
            coords = vec4(coords.x, coords.y, zPos, coords.w)
        else
            coords = vec3(coords.x, coords.y, zPos)
        end
        --debugPrint("^6Bridge^7: Adjusting for ground pos ", coords.z, zPos)

        return coords
    else
        return coords
    end
end

--- Ensures that a network vehicle exists by verifying its network ID.
---
--- @param vehNetID number The network ID of the vehicle.
--- @return number number The vehicle entity if it exists, otherwise `0`.
---
--- @usage
--- ```lua
--- local vehicle = ensureNetToVeh(netID)
--- if vehicle ~= 0 then
---     print("Vehicle exists:", vehicle)
--- end
--- ```
function ensureNetToVeh(vehNetID)
    debugPrint("^6Bridge^7: ^3ensureNetToVeh^7: ^2Requesting NetworkDoesNetworkIdExist^7(^6"..vehNetID.."^7)")
    local timeout = 100
    while not NetworkDoesNetworkIdExist(vehNetID) and timeout > 0 do
        timeout -= 1
        Wait(10)
    end
    if not NetworkDoesNetworkIdExist(vehNetID) then return 0 end
    timeout = 100
    local vehicle = NetToVeh(vehNetID)
    while not DoesEntityExist(vehicle) and vehicle ~= 0 and timeout > 0 do
        timeout -= 1
        Wait(10)
    end
    if not DoesEntityExist(vehicle) then return 0 end
    return vehicle
end

--- Ensures that a network entity exists by verifying its network ID.
---
--- @param entNetID number The network ID of the entity.
--- @return number The entity if it exists, otherwise `0`.
---
--- @usage
--- local entity = ensureNetToEnt(netID)
--- if entity ~= 0 then
---     print("Entity exists:", entity)
--- end
function ensureNetToEnt(entNetID)
    debugPrint("^6Bridge^7: ^3ensureNetToEnt^7: ^2Requesting NetworkDoesNetworkIdExist^7(^6"..entNetID.."^7)")
    local timeout = 100
    while not NetworkDoesNetworkIdExist(entNetID) and timeout > 0 do
        timeout -= 1
        Wait(10)
    end
    if not NetworkDoesNetworkIdExist(entNetID) then return 0 end
    timeout = 100
    local entity = NetworkGetEntityFromNetworkId(entNetID)
    while not DoesEntityExist(entity) and entity ~= 0 and timeout > 0 do
        timeout -= 1
        Wait(10)
    end
    if not DoesEntityExist(entity) then return 0 end
    return entity
end

--[[ Material Definitions ]]--

--- A table mapping material names to their corresponding hash values.
---
--- Used for identifying materials based on hash codes.
local materials = {
    none = -1,
    Unknown = -1775485061,
    concrete = 1187676648,
    concrete_pothole = 359120722,
    concrete_dusty = -1084640111,
    tarmac = 282940568,
    tarmac_painted = -1301352528,
    tarmac_pothole = 1886546517,
    rumble_strip = -250168275,
    breeze_block = -954112554,
    rock = -840216541,
    rock_mossy = -124769592,
    stone = 765206029,
    cobblestone = 576169331,
    brick = 1639053622,
    marble = 1945073303,
    paving_slab = 1907048430,
    sandstone_solid = 592446772,
    sandstone_brittle = 1913209870,
    sand_loose = -1595148316,
    sand_compact = 510490462,
    sand_wet = 909950165,
    sand_track = -1907520769,
    sand_underwater = -1136057692,
    sand_dry_deep = 509508168,
    sand_wet_deep = 1288448767,
    ice = -786060715,
    ice_tarmac = -1931024423,
    snow_loose = -1937569590,
    snow_compact = -878560889,
    snow_deep = 1619704960,
    snow_tarmac = 1550304810,
    gravel_small = 951832588,
    gravel_large = 2128369009,
    gravel_deep = -356706482,
    gravel_train_track = 1925605558,
    dirt_track = -1885547121,
    mud_hard = -1942898710,
    mud_pothole = 312396330,
    mud_soft = 1635937914,
    mud_underwater = -273490167,
    mud_deep = 1109728704,
    marsh = 223086562,
    marsh_deep = 1584636462,
    soil = -700658213,
    clay_hard = 1144315879,
    clay_soft = 560985072,
    grass_long = -461750719,
    grass = 1333033863,
    grass_short = -1286696947,
    hay = -1833527165,
    bushes = 581794674,
    twigs = -913351839,
    leaves = -2041329971,
    woodchips = -309121453,
    tree_bark = -1915425863,
    metal_solid_small = -1447280105,
    metal_solid_medium = -365631240,
    metal_solid_large = 752131025,
    metal_hollow_small = 15972667,
    metal_hollow_medium = 1849540536,
    metal_hollow_large = -583213831,
    metal_chainlink_small = 762193613,
    metal_chainlink_large = 125958708,
    metal_corrugated_iron = 834144982,
    metal_grille = -426118011,
    metal_railing = 2100727187,
    metal_duct = 1761524221,
    metal_garage_door = -231260695,
    metal_manhole = -754997699,
    wood_solid_small = -399872228,
    wood_solid_medium = 555004797,
    wood_solid_large = 815762359,
    wood_solid_polished = 126470059,
    wood_floor_dusty = -749452322,
    wood_hollow_small = 1993976879,
    wood_hollow_medium = -365476163,
    wood_hollow_large = -925419289,
    wood_chipboard = 1176309403,
    wood_old_creaky = 722686013,
    wood_high_density = -1742843392,
    wood_lattice = 2011204130,
    ceramic = -1186320715,
    roof_tile = 1755188853,
    roof_felt = -1417164731,
    fibreglass = 1354180827,
    tarpaulin = -642658848,
    plastic = -2073312001,
    plastic_hollow = 627123000,
    plastic_high_density = -1625995479,
    plastic_clear = -1859721013,
    plastic_hollow_clear = 772722531,
    plastic_high_density_clear = -1338473170,
    fibreglass_hollow = -766055098,
    rubber = -145735917,
    rubber_hollow = -783934672,
    linoleum = 289630530,
    laminate = 1845676458,
    carpet_solid = 669292054,
    carpet_solid_dusty = 158576196,
    carpet_floorboard = -1396484943,
    cloth = 122789469,
    plaster_solid = -574122433,
    plaster_brittle = -251888898,
    cardboard_sheet = 236511221,
    cardboard_box = -1409054440,
    paper = 474149820,
    foam = 808719444,
    feather_pillow = 1341866303,
    polystyrene = -1756927331,
    leather = -570470900,
    tvscreen = 1429989756,
    slatted_blinds = 673696729,
    glass_shoot_through = 937503243,
    glass_bulletproof = 244521486,
    glass_opaque = 1500272081,
    perspex = -1619794068,
    car_metal = -93061983,
    car_plastic = 2137197282,
    car_softtop = -979647862,
    car_softtop_clear = 2130571536,
    car_glass_weak = 1247281098,
    car_glass_medium = 602884284,
    car_glass_strong = 1070994698,
    car_glass_bulletproof = -1721915930,
    car_glass_opaque = 513061559,
    water = 435688960,
    blood = 5236042,
    oil = -634481305,
    petrol = -1634184340,
    fresh_meat = 868733839,
    dried_meat = -1445160429,
    emissive_glass = 1501078253,
    emissive_plastic = 1059629996,
    vfx_metal_electrified = -309134265,
    vfx_metal_water_tower = 611561919,
    vfx_metal_steam = -691277294,
    vfx_metal_flame = 332778253,
    phys_no_friction = 1666473731,
    phys_golf_ball = -1693813558,
    phys_tennis_ball = -256704763,
    phys_caster = -235302683,
    phys_caster_rusty = 2016463089,
    phys_car_void = 1345867677,
    phys_ped_capsule = -291631035,
    phys_electric_fence = -1170043733,
    phys_electric_metal = -2013761145,
    phys_barbed_wire = -1543323456,
    phys_pooltable_surface = 605776921,
    phys_pooltable_cushion = 972939963,
    phys_pooltable_ball = -748341562,
    buttocks = 483400232,
    thigh_left = -460535871,
    shin_left = 652772852,
    foot_left = 1926285543,
    thigh_right = -236981255,
    shin_right = -446036155,
    foot_right = -1369136684,
    spine0 = -1922286884,
    spine1 = -1140112869,
    spine2 = 1457572381,
    spine3 = 32752644,
    clavicle_left = -1469616465,
    upper_arm_left = -510342358,
    lower_arm_left = 1045062756,
    hand_left = 113101985,
    clavicle_right = -1557288998,
    upper_arm_right = 1501153539,
    lower_arm_right = 1777921590,
    hand_right = 2000961972,
    neck = 1718294164,
    head = -735392753,
    animal_default = 286224918,
    car_engine = -1916939624,
    puddle = 999829011,
    concrete_pavement = 2015599386,
    brick_pavement = -1147361576,
    phys_dynamic_cover_bound = -2047468855,
    vfx_wood_beer_barrel = 998201806,
    wood_high_friction = -2140087047,
    rock_noinst = 127813971,
    bushes_noinst = 1441114862,
    metal_solid_road_surface = -729112334,
    stunt_ramp_surface = -2088174996,
    temp_01 = 746881105,
    temp_02 = -1977970111,
    temp_03 = 1911121241,
    temp_04 = 1923995104,
    temp_05 = -1393662448,
    temp_06 = 1061250033,
    temp_07 = -1765523682,
    temp_08 = 1343679702,
    temp_09 = 1026054937,
    temp_10 = 63305994,
    temp_11 = 47470226,
    temp_12 = 702596674,
    temp_13 = -1637485913,
    temp_14 = -645955574,
    temp_15 = -1583997931,
    temp_16 = -1512735273,
    temp_17 = 1011960114,
    temp_18 = 1354993138,
    temp_19 = -801804446,
    temp_20 = -2052880405,
    temp_21 = -1037756060,
    temp_22 = -620388353,
    temp_23 = 465002639,
    temp_24 = 1963820161,
    temp_25 = 1952288305,
    temp_26 = -1116253098,
    temp_27 = 889255498,
    temp_28 = -1179674098,
    temp_29 = 1078418101,
    temp_30 = 13626292
}

--- Retrieves the ground material at a specified position.
---
--- This function performs a raycast downwards from the given coordinates to determine the material type of the ground.
---
--- @param coords vector3 The coordinates from which to perform the raycast.
--- @return number|nil number The material hash if found; otherwise, `nil`.
--- @return string string The name of the material.
---
--- @usage
--- ```lua
--- local materialHash, materialName = GetGroundMaterialAtPosition(vector3(100, 200, 300))
--- print("Ground material:", materialName)
--- ```
function GetGroundMaterialAtPosition(coords)
    local endX, endY, endZ = coords.x, coords.y, coords.z - 1.0

    local rayHandle = StartShapeTestCapsule(coords.x, coords.y, coords.z, endX, endY, endZ, 1.0, 1, playerPed, 7)
    local _, hit, _, _, materialHash, _ = GetShapeTestResultIncludingMaterial(rayHandle)
    local materialName = "Unknown"
    for k, v in pairs(materials) do
        if v == materialHash then
            materialName = k
            break
        end
    end
    if hit then return materialHash, materialName
    else return nil, materialName end
end

--- Retrieves the dimensions of a prop/model.
---
--- This function loads the specified model and returns its width, depth, and height based on its bounding box.
---
--- @param model string The name or hash of the model.
--- @return number number The width of the prop.
--- @return number number The depth of the prop.
--- @return number number The height of the prop.
---
--- @usage
--- ```lua
--- local width, depth, height = GetPropDimensions("prop_barrel_01a")
--- print("Dimensions:", width, depth, height)
--- ```
function GetPropDimensions(model)
    loadModel(model)
    local minDim, maxDim = GetModelDimensions(model)
    local width, depth, height = maxDim.x - minDim.x, maxDim.y - minDim.y, maxDim.z - minDim.z

    return width, depth, height
end

--- Retrieves the forward direction vector of an entity based on its heading.
---
--- This function calculates the forward direction vector using the entity's heading angle.
---
--- @param entity number The entity whose forward vector is to be calculated.
--- @return vector3 vector3 The forward direction vector.
---
--- @usage
--- ```lua
--- local forwardVec = GetEntityForwardVector(playerPed)
--- print("Forward Vector:", forwardVec)
--- ```
function GetEntityForwardVector(entity)
    local heading = math.rad(GetEntityHeading(entity) + 90)
    return vec3(math.cos(heading), math.sin(heading), 0.0)
end