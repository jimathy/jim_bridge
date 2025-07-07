--[[
    Player Metadata Utilities Module
    ----------------------------------
    This module provides functions for retrieving and setting metadata for players
    across different frameworks (QB, ESX, OXCore). It also registers server callbacks
    for getting and setting metadata.
]]

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
    if isStarted(QBExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() QBExport")
        return exports[QBExport]:GetCoreObject().Functions.GetPlayer(source)

    elseif isStarted(QBXExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() QBOXExport")
        return exports[QBXExport]:GetCoreObject().Functions.GetPlayer(source)

    elseif isStarted(ESXExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() ESXExport")
        return ESX.GetPlayerFromId(source)

    elseif isStarted(OXCoreExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() OXCoreExport")
        return exports[OXCoreExport]:GetPlayer(source)

    elseif isStarted(RSGExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() RSGExport")
        return exports[RSGExport]:GetCoreObject().Functions.GetPlayer(source)

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
    if not player then
        debugPrint("^6Bridge^7: ^3GetMetadata^7() calling server: "..key)
        return triggerCallback(getScript()..":server:GetMetadata", key)
    else
        if isStarted(QBExport) or isStarted(QBXExport) then
            debugPrint("^6Bridge^7: ^3GetMetadata^7() QBExport/QBXExport", key)
            return player.PlayerData.metadata[key]

        elseif isStarted(ESXExport) then
            debugPrint("^6Bridge^7: ^3GetMetadata^7() ESXExport", key)
            return player.getMeta(key)

        elseif isStarted(OXCoreExport) then
            debugPrint("^6Bridge^7: ^3GetMetadata^7() OXCoreExport", key)
            return player.get(key)

        elseif isStarted(RSGExport) then
            debugPrint("^6Bridge^7: ^3GetMetadata^7() RSGExport", key)
            return player.PlayerData.metadata[key]

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
    debugPrint("^6Bridge^7: ^3SetMetadata^7() setting metadata for key: "..key)
    if isStarted(QBExport) or isStarted(QBXExport) then
        debugPrint("^6Bridge^7: ^3SetMetadata^7() using QBExport/QBXExport")
        player.Functions.SetMetaData(key, value)

    elseif isStarted(ESXExport) then
        debugPrint("^6Bridge^7: ^3SetMetadata^7() using ESXExport")
        player.setMeta(key, value)

    elseif isStarted(OXCoreExport) then
        debugPrint("^6Bridge^7: ^3SetMetadata^7() using OXCoreExport")
        player.set(key, value)

    elseif isStarted(RSGExport) then
        debugPrint("^6Bridge^7: ^3SetMetadata^7() using RSGExport")
        player.Functions.SetMetaData(key, value)

    end
end

-- Register a server callback for setting metadata.
createCallback(getScript()..":server:setPlayerMetadata", function(source, key, value)
    debugPrint("SetMetadata callback triggered for source:", source, "key:", key, "value:", value)
    local player = GetPlayer(source)
    --[[if not player then
        print("Error setting metadata: player not found for source "..tostring(source))
        return false
    end]]
    setPlayerMetadata(player, key, value)
    print("Metadata set successfully.", key)
    return true
end)