if _G.__bridge_cache_loaded then return end
_G.__bridge_cache_loaded = true

_G.BridgeCache = {
    hasCache = false,
    data = nil,
    queue = {},
}

RegisterNetEvent("jim_bridge:receiveCache", function(data)
    if _G.BridgeCache.hasCache then return end
    _G.BridgeCache.data = data
    _G.BridgeCache.hasCache = true

    for _, cb in ipairs(_G.BridgeCache.queue) do
        cb(data)
    end
    _G.BridgeCache.queue = nil
end)

-- Only send the request ONCE per client session
TriggerServerEvent("jim_bridge:requestCache")

-- Exported async function
function GetBridgeCache(callback)
    if _G.BridgeCache.hasCache then
        callback(_G.BridgeCache.data)
    else
        table.insert(_G.BridgeCache.queue, callback)
    end
end
exports("GetBridgeCache", GetBridgeCache)