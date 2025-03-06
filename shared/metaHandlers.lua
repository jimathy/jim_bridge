
function GetPlayer(source)
    if isStarted(QBExport) then
        debugPrint("^6Debug^7: ^3GetPlayer^7() QBExport")
        return exports[QBExport]:GetCoreObject().Functions.GetPlayer(source)
    elseif isStarted(QBXExport) then
        debugPrint("^6Debug^7: ^3GetPlayer^7() QBOXExport")
        return exports[QBXExport]:GetCoreObject().Functions.GetPlayer(source)
    elseif isStarted(ESXExport) then
        debugPrint("^6Debug^7: ^3GetPlayer^7() ESXExport")
        return exports[ESXExport]:GetPlayerFromId(source)
    elseif isStarted(OXCoreExport) then
        debugPrint("^6Debug^7: ^3GetPlayer^7() OXCoreExport")
        return exports[OXCoreExport]:GetPlayer(source)
    end
    return nil
end

-- Get Metadata
function GetMetadata(player, key)
    if not player then -- This would be called client side
        debugPrint("^6Debug^7: ^3GetMetadata^7() calling server")
        return triggerCallback(getScript()..":server:GetMetadata", key)
    else
        if isStarted(QBExport) or isStarted(QBXExport) then
            debugPrint("^6Debug^7: ^3GetMetadata^7() QBExport or QBXExport")
            return player.PlayerData.metadata[key]
        elseif isStarted(ESXExport) then
            debugPrint("^6Debug^7: ^3GetMetadata^7() ESXExport")
            return player.getMeta(key)
        elseif isStarted(OXCoreExport) then
            debugPrint("^6Debug^7: ^3GetMetadata^7() OXCoreExport")
            return player.get(key)
        end
    end
    return nil
end

createCallback(getScript()..":server:GetMetadata", function(source, key)
    debugPrint("^6Debug^7: ^3GetMetadata^7() Callback", source)
    local player = GetPlayer(source)
    local Metadata = {}
    if not player then
        print("Error getting metadata")
        return
    end
    if type(key) == "table" then
        for _, k in ipairs(key) do
            Metadata[k] = GetMetadata(player, k).k
        end
    elseif type(key) == "string" then
        return GetMetadata(player, key)
    end
    jsonPrint(Metadata)
    return Metadata
end)

-- Set Metadata
function SetMetadata(player, key, value)
    --if player == nil then -- This would be called client side
    --    debugPrint("^6Debug^7: ^3SetMetadata^7() calling server")
    --    triggerCallback(getScript()..":server:SetMetadata", { key, value })
    -- else
        debugPrint("^6Debug^7: ^3SetMetadata^7() setting metadata")
        if isStarted(QBExport) or isStarted(QBXExport) then
            debugPrint("^6Debug^7: ^3SetMetadata^7() QBExport or QBXExport")
            player.Functions.SetMetaData(key, value)
        elseif isStarted(ESXExport) then
            debugPrint("^6Debug^7: ^3SetMetadata^7() ESXExport")
            player.setMeta(key, value)
        elseif isStarted(OXCoreExport) then
            debugPrint("^6Debug^7: ^3SetMetadata^7() OXCoreExport")
            player.set(key, value)
        end
    --end
end


createCallback(getScript()..":server:SetMetadata", function(source, key, value)
    print(source, key, value)
    local player = GetPlayer(source)
    --jsonPrint(player)
    --[[if not player then
        print("Error getting metadata")
        return false
    end]]
    print("i did it")
    SetMetadata(player, key, value)
    return true
end)