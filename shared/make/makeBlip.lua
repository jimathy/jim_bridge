local blipTable = {}

--- Creates a blip at specified coordinates with given properties.
--
-- This function adds a map blip at the provided coordinates and sets various display properties such as sprite, color, scale, and more.
-- It also handles attaching a preview image to the blip if certain resources are running and a preview is provided.
--
---@param data A table containing blip data and properties.
-- - **coords**: A `vector3` containing x, y, z coordinates where the blip will be placed.
-- - **sprite** (optional): The blip sprite/icon ID. Default is `106`.
-- - **col** (optional): The color ID of the blip. Default is `5`.
-- - **scale** (optional): The scale of the blip. Default is `0.7`.
-- - **disp** (optional): The display option of the blip. Default is `6`.
-- - **category** (optional): The category ID for the blip.
-- - **name**: The name of the blip, used for display on the map.
-- - **preview** (optional): A URL or image path for a preview image to display with the blip.
--
---@return blip blipID The handle of the created blip.
--
---@usage
-- ```lua
-- local blipData = {
--     coords = vector3(123.4, 567.8, 90.1),
--     sprite = 1,
--     col = 2,
--     scale = 0.8,
--     disp = 4,
--     category = 7,
--     name = "My Blip",
--     preview = "http://example.com/preview.png"
-- }
-- local blip = makeBlip(blipData)
-- ```
function makeBlip(data)
    local blip = nil
    if gameName == "rdr3" then
        blip = BlipAddForCoords(1664425300, data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, data.sprite or `blip_shop_market_stall`)
        SetBlipScale(blip, data.scale or 0.2)
        SetBlipName(blip, data.name)
        --BlipSetStyle(blip, data.col or `BLIP_STYLE_CREATOR_DEFAULT`)
    else
        blip = AddBlipForCoord(vec3(data.coords.x, data.coords.y, data.coords.z))
        SetBlipCoords(blip, data.coords.x, data.coords.y, data.coords.z) -- Manually set blip coordinates again as sometimes it just refuses
        SetBlipAsShortRange(blip, true)
        SetBlipSprite(blip, data.sprite or 106)
        SetBlipColour(blip, data.col or 5)
        SetBlipScale(blip, data.scale or 0.7)
        SetBlipDisplay(blip, data.disp or 6)
        if data.category then
            SetBlipCategory(blip, data.category)
        end
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(tostring(data.name))
        EndTextCommandSetBlipName(blip)
        -- Handle preview image if certain resources are running
        if isStarted("jim-blipcontroller") then
            if data.preview then
                local txname = string.gsub(tostring(data.name..'preview'..string.gsub(data.coords.z, "%.", "")), "[ ()~]", "")
                if data.preview:find("http") or data.preview:find("nui") then
                    createDui(txname, data.preview, vec2(512, 256), scriptTxd)
                else
                    CreateRuntimeTextureFromImage(scriptTxd, txname, data.preview)
                end
                exports["jim-blipcontroller"]:ShowBlipInfo(blip, {
                    title = data.name,
                    dict = getScript()..'scriptTxd',
                    tex = txname,
                })
            end
        end
    end
    blipTable[blip] = blip

    if DoesBlipExist(blip) then
        debugPrint("^6Bridge^7: ^6Blip ^2created^7: '^6"..data.name.."^7' - '"..formatCoord(data.coords).."'")
    else
        print("Error making blip")
    end
    return blip
end

--- Creates a blip attached to a specified entity with given properties.
--
-- This function adds a map blip attached to the provided entity and sets various display properties such as sprite, color, scale, and more.
-- It also handles attaching a preview image to the blip if certain resources are running and a preview is provided.
--
---@param data table A table containing blip data and properties.
-- - **entity**: The entity to which the blip will be attached.
-- - **sprite** (optional): The blip sprite/icon ID. Default is `106`.
-- - **col** (optional): The color ID of the blip. Default is `5`.
-- - **scale** (optional): The scale of the blip. Default is `0.7`.
-- - **disp** (optional): The display option of the blip. Default is `6`.
-- - **category** (optional): The category ID for the blip.
-- - **name**: The name of the blip, used for display on the map.
-- - **preview** (optional): A URL or image path for a preview image to display with the blip.
--
--
---@return number blipID The handle of the created blip.
---@usage
-- ```lua
-- local blipData = {
--     entity = myEntity,
--     sprite = 1,
--     col = 2,
--     scale = 0.8,
--     disp = 4,
--     category = 7,
--     name = "Entity Blip",
--     preview = "http://example.com/preview.png"
-- }
-- local blip = makeEntityBlip(blipData)
-- ```
function makeEntityBlip(data)
    local blip = nil
    if gameName == "rdr3" then
        blip = BlipAddForEntity(1664425300, data.entity)
        SetBlipSprite(blip, data.sprite or `blip_ambient_coach`)
        SetBlipScale(blip, data.scale or 0.2)
        SetBlipName(blip, data.name)

    else
        AddBlipForEntity(data.entity)
        blip = GetBlipFromEntity(data.entity)
        blipTable[blip] = blip
        SetBlipAsShortRange(blip, true)
        SetBlipSprite(blip, data.sprite or 106)
        SetBlipColour(blip, data.col or 5)
        SetBlipScale(blip, data.scale or 0.7)
        SetBlipDisplay(blip, data.disp or 6)
        if data.category then SetBlipCategory(blip, data.category) end
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(tostring(data.name))
        EndTextCommandSetBlipName(blip)
        -- Handle preview image if certain resources are running
        if isStarted("fs_smallresources") or isStarted("blip-info") or isStarted("blipinfo") then
            if data.preview then
                local txname = string.gsub(tostring(data.name..'preview'), "[ ()~]", "")
                if data.preview:find("http") or data.preview:find("nui") then
                    createDui(txname, data.preview, vec2(512, 256), scriptTxd)
                else
                    CreateRuntimeTextureFromImage(scriptTxd, txname, data.preview)
                end
                exports["fs_smallresources"]:SetBlipInfoImage(blip, getScript()..'previewTxd', txname)
                exports["fs_smallresources"]:SetBlipInfoTitle(blip, data.name, false)
            end
        end
    end
    blipTable[blip] = blip

    if DoesBlipExist(blip) then
        debugPrint("^6Bridge^7: ^6Blip ^2created for Entity^7: '^6"..data.name.."^7'")
    else
        print("Error making blip")
    end
    return blip
end

if gameName == "rdr3" then
    onResourceStop(function()
        for k in pairs(blipTable) do
            RemoveBlip(k)
        end
    end, true)
end