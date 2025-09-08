--[[
    Player Metadata Utilities Module
    ----------------------------------
    This module provides functions for retrieving and setting metadata for players
    across different frameworks (QB, ESX, OXCore). It also registers server callbacks
    for getting and setting metadata.
]]

local metaDataFunc = {
    {   framework = QBXExport,
        GetPlayer =
            function(src)
                if src then
                    return exports[QBXExport]:GetPlayer(src)
                end
                return exports[QBXExport]:GetPlayerData()
            end,
        GetPlayerMetadata =
            function(Player, dataToCheck)
                return Player.PlayerData.metadata[dataToCheck]
            end,
        SetPlayerMetadata =
            function(Player, key, value)
                return Player.Functions.SetMetaData(key, value)
            end,
    },

    {   framework = QBExport,
        GetPlayer =
            function(src)
                if src then
                    return exports[QBExport]:GetCoreObject().Functions.GetPlayer(src)
                end
                local info = nil
                Core.Functions.GetPlayerData(function(PlayerData) info = PlayerData end)
                return info
            end,
        GetPlayerMetadata =
            function(Player, dataToCheck)
                return Player.PlayerData.metadata[dataToCheck]
            end,
        SetPlayerMetadata =
            function(Player, key, value)
                return Player.Functions.SetMetaData(key, value)
            end,
    },

    {   framework = ESXExport,
        GetPlayer =
            function(src)
                if src then
                    return ESX.GetPlayerFromId(src)
                end
                return ESX.GetPlayerData()
            end,
        GetPlayerMetadata =
            function(Player, dataToCheck)
                return Player.getMeta(dataToCheck)
            end,
        SetPlayerMetadata =
            function(Player, key, value)
                return Player.set(key, value)
            end,
    },

    {   framework = OXCoreExport,
        GetPlayer =
            function(src)
                if src then
                    return exports[OXCoreExport]:GetPlayer(src)
                end
                return {}
            end,
        GetPlayerMetadata =
            function(Player, dataToCheck)
                return Player.get(dataToCheck)
            end,
        SetPlayerMetadata =
            function(Player, key, value)
                return Player.set(key, value)
            end,
    },

    {   framework = RSGExport,
        GetPlayer =
            function(src)
                if src then
                    return exports[RSGExport]:GetCoreObject().Functions.GetPlayer(src)
                end
                local info = nil
                Core.Functions.GetPlayerData(function(PlayerData) info = PlayerData end)
                return info
            end,
        GetPlayerMetadata = function(Player, dataToCheck)
            return Player.PlayerData.metadata[dataToCheck]
        end,
        SetPlayerMetadata = function(Player, key, value)
            return Player.Functions.SetMetaData(key, value)
        end,
    },

}


-------------------------------------------------------------
-- Player Retrieval
-------------------------------------------------------------

--- Retrieves the player object using the active core export.
---
--- @param source number The server ID of the player.
--- @return table|nil table The player object, or nil if no supported core is detected.
---
--- @usage
--- ```lua
--- local player = GetPlayer(playerId)
--- ```
function GetPlayer(source)
    for i = 1, #metaDataFunc do
        local framework = metaDataFunc[i]
        if isStarted(framework.framework) then
            return framework.GetPlayer(source)
        end
    end
    return nil
end

-------------------------------------------------------------
-- Metadata Retrieval
-------------------------------------------------------------

--- Retrieves metadata from a player object.
---
--- If called client-side (player is nil), it triggers a server callback to retrieve metadata.
---
--- @param player table|nil The player object; if nil, metadata is retrieved via a server callback.
--- @param key string The metadata key to retrieve.
--- @return any The value of the requested metadata, or nil if not found.
---
--- @usage
--- ```lua
--- local myMeta = getPlayerMetadata(player, "myKey")
--- ```
function getPlayerMetadata(player, key)
    -- Assume this is client side and callback to server to get the data
    if not player then
        debugPrint("^6Bridge^7: ^3GetMetadata^7() calling server: "..key)
        return triggerCallback(getScript()..":server:GetMetadata", key)
    else
        -- else grab server metadata about the player
        for i = 1, #metaDataFunc do
            local framework = metaDataFunc[i]
            if isStarted(framework.framework) then

                debugPrint("^6Bridge^7: ^3GetMetadata^7() ^3"..framework.framework.."^7", key)
                return framework.GetPlayerMetadata(player, key)
            end
        end
    end
    return nil
end

-- Register a server callback for retrieving metadata.
createCallback(getScript()..":server:GetMetadata", function(source, key)
    debugPrint("^6Bridge^7: ^3GetMetadata Callback^7 from source: "..tostring(source)..", key: "..tostring(key))
    local player = GetPlayer(source)
    if not player then
        print("Error getting metadata: player not found for source "..tostring(source))
        return
    end

    if type(key) == "table" then
        local Metadata = {}
        for _, k in ipairs(key) do
            Metadata[k] = getPlayerMetadata(player, k)
        end
        return Metadata
    elseif type(key) == "string" then
        return getPlayerMetadata(player, key)
    end
end)

-------------------------------------------------------------
-- Metadata Setting
-------------------------------------------------------------

--- Sets metadata on a player object.
---
--- The function updates the player's metadata using the active core export.
---
--- @param player table The player object.
--- @param key string The metadata key to set.
--- @param value any The new value for the metadata key.
---
--- @usage
--- ```lua
--- setPlayerMetadata(player, "myKey", "newValue")
--- ```
function setPlayerMetadata(player, key, value)
    debugPrint("^6Bridge^7: ^3SetMetadata^7() setting metadata^7...")
    for i = 1, #metaDataFunc do
        local framework = metaDataFunc[i]
        if isStarted(framework.framework) then
            debugPrint("^6Bridge^7: ^3SetMetadata^7() ^3"..framework.framework.."^7", key, value)
            return framework.GetPlayerMetadata(player, key)
        end
    end
    debugPrint("^6Bridge^7: ^1Error setting metadata^7, ^1framework not supported^7?")
end

-- Register a server callback for setting metadata.
createCallback(getScript()..":server:setPlayerMetadata", function(source, key, value)
    local src = source
    debugPrint("SetMetadata callback triggered for source:", src, "key:", key, "value:", value)
    local player = GetPlayer(src)
    setPlayerMetadata(player, key, value)
    print("Metadata set successfully.", key)
    return true
end)