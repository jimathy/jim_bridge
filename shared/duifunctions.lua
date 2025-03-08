--[[
    DUI Module (Experimental)
    --------------------------
    This module handles the creation, modification, and removal of custom DUI (Display UI)
    elements using runtime textures. It supports both client and server functionality to update DUI
    images dynamically.
]]

-- Create a runtime texture dictionary on the client if not running on the server.
scriptTxd = not isServer() and CreateRuntimeTxd(getScript()..'scriptTxd') or nil
customDUIList = {}

-------------------------------------------------------------
-- DUI Client Functions
-------------------------------------------------------------

--- Creates or updates a DUI element.
---
--- @param name string The unique name for the DUI element.
--- @param http string The URL to load into the DUI.
--- @param size table A table with .x and .y fields specifying the DUI dimensions.
--- @param txd table The runtime texture dictionary where the DUI texture will be created.
--- @usage
--- ```lua
--- createDui("logo", "https://example.com/logo.png", { x = 512, y = 256 }, scriptTxd)
--- ```
function createDui(name, http, size, txd)
    if not customDUIList[name] then
        local newDui = CreateDui(http, math.floor(size.x), math.floor(size.y))
        while not GetDuiHandle(newDui) do Wait(0) end
        CreateRuntimeTextureFromDuiHandle(txd, name, GetDuiHandle(newDui))
        customDUIList[name] = newDui
        SetDuiUrl(customDUIList[name], http)
    else
        SetDuiUrl(customDUIList[name], http)
    end
end

--- Opens a DUI selection input allowing the user to change the DUI image URL.
---
--- @param data table A table containing DUI data:
---   - name: The key name in the DUI list.
---   - texn: The texture name.
---   - texd: The texture dictionary.
---   - size: A table with .x and .y dimensions.
---
--- @usage
--- ```lua
--- DuiSelect({ name = "logo", texn = "logoTex", texd = "someTxd", size = { x = 512, y = 256 } })
--- ```
function DuiSelect(data)
    local imagePreview = ""
    for k, v in pairs(duiList[data.name]) do
        if v.tex.texn == data.texn and duiList[data.name][k] then
            imagePreview = "<center>- Current Image -<br>" ..
                           "<img src="..duiList[data.name][k].url.." width=150px><br>" ..
                           "Size: ["..math.floor(data.size.x)..", "..math.floor(data.size.y).."]<br><br>"
        end
    end
    local dialog = exports['qb-input']:ShowInput({
        header = imagePreview..Loc[Config.Lan].menu["dui_new"],
        submitText = Loc[Config.Lan].menu["dui_change"],
        inputs = { { type = 'text', isRequired = true, name = 'url', text = Loc[Config.Lan].menu["dui_url"] } }
    })
    if dialog and dialog.url then
        data.url = dialog.url
        -- Scan URL for valid image extension and banned words.
        local searchList = { "png", "jpg", "jpeg", "gif", "webp", "bmp" }
        local banList = { "porn" }
        local searchFound = false
        for _, ext in pairs(searchList) do
            if string.find(tostring(data.url), ext) then
                searchFound = true
                break
            end
        end
        for _, banned in pairs(banList) do
            if string.find(tostring(data.url), banned) then
                searchFound = false
                print("BANNED WORD: "..banned)
                break
            end
        end
        if searchFound then
            TriggerServerEvent(getScript()..":Server:ChangeDUI", data)
        end
    end
end

--- Client event handler to update DUI elements.
RegisterNetEvent(getScript()..":Client:ChangeDUI", function(data)
    debugPrint("^6Bridge^7: ^2Receiving new DUI ^7- ^6"..data.url.."^7")
    if tostring(data.url) ~= "-" then
        createDui(data.texn, tostring(data.url), data.size, scriptTxd)
        AddReplaceTexture(tostring(data.texd), tostring(data.texn), getScript().."scriptTxd", tostring(data.texn))
    end
end)

--- Client event handler to clear DUI elements.
RegisterNetEvent(getScript()..":Client:ClearDUI", function(data)
    if customDUIList[tostring(data.texn)] then
        RemoveReplaceTexture(tostring(data.texd), tostring(data.texn))
        if IsDuiAvailable(customDUIList[tostring(data.texn)]) then
            SetDuiUrl(customDUIList[data.name], nil)
        end
    end
end)

-------------------------------------------------------------
-- DUI Server Functions
-------------------------------------------------------------

--- Server event handler to change DUI settings.
--- If no URL is provided, resets to the preset value.
RegisterNetEvent(getScript()..":Server:ChangeDUI", function(data)
    if not data.url then
        for k, v in pairs(duiList[data.name]) do
            if v.tex.texn == data.texn then
                debugPrint("^6Bridge^7: ^2Preset: ^6"..tostring(duiList[data.name][k].preset).."^7")
                data.url = duiList[data.name][k].preset
            end
        end
    end
    for k, v in pairs(duiList[data.name]) do
        if v.tex.texn == data.texn then
            duiList[data.name][k].url = data.url
        end
    end
	debugPrint("^6Bridge^7: ^3DUI^2 Sending new DUI to all players^7 - ^6"..data.url.."^7")
    TriggerClientEvent(getScript()..":Client:ChangeDUI", -1, data)
end)

--- Server event handler to clear DUI settings.
RegisterNetEvent(getScript()..":Server:ClearDUI", function(data)
    if data.url == "-" then
        for k, v in pairs(duiList[data.name]) do
            if v.tex.texn == data.texn then
                duiList[data.name][k].url = "-"
            end
        end
    end
    TriggerClientEvent(getScript()..":Client:ClearDUI", -1, data)
end)

-------------------------------------------------------------
-- Resource Cleanup
-------------------------------------------------------------

onResourceStop(function()
    for k, v in pairs(duiList or {}) do
        for i = 1, #v do
            RemoveReplaceTexture(tostring(v[i].tex.texd), tostring(v[i].tex.texn))
        end
    end
end, true)

-------------------------------------------------------------
-- DUI List Callback (Server)
-------------------------------------------------------------

if isServer() then
    createCallback(getScript()..":Server:duiList", function(source)
        return duiList
    end)
end