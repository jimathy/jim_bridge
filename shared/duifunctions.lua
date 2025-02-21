-- DUI STUFF -- * Experimental * --

scriptTxd = not isServer() and CreateRuntimeTxd(getScript()..'scriptTxd') or nil
customDUIList = {}

-- DUI CLIENT
function createDui(name, http, size, txd)
	--print(name, http, size, txd)
	if not customDUIList[name] then
		local newTxt = CreateDui(http, math.floor(size.x), math.floor(size.y))
		while not GetDuiHandle(newTxt) do Wait(0) end
		CreateRuntimeTextureFromDuiHandle(txd, name, GetDuiHandle(newTxt))
		customDUIList[name] = newTxt
		SetDuiUrl(customDUIList[name], http)
	else
		SetDuiUrl(customDUIList[name], http)
	end
end

function DuiSelect(data)
    local image = ""
	for k, v in pairs(duiList[data.name]) do
		if v.tex.texn == data.texn then
			if duiList[data.name][k] then
				image = "<center>- Current Image -<br>"..
						"<img src="..duiList[data.name][k].url.." width=150px><br>"..
						"Size: ["..math.floor(data.size.x)..", "..math.floor(data.size.y).."]<br><br>"
			end
		end
	end
    local dialog = exports['qb-input']:ShowInput({
        header = image..Loc[Config.Lan].menu["dui_new"],
        submitText = Loc[Config.Lan].menu["dui_change"],
        inputs = { { type = 'text', isRequired = true, name = 'url', text = Loc[Config.Lan].menu["dui_url"] } } })
    if dialog then
        if not dialog.url then return end
        data.url = dialog.url
        --Scan the link to see if it has an image extention otherwise, stop here.
        local searchList = { "png", "jpg", "jpeg", "gif", "webp", "bmp" }
        --Scan the link for certain terms that will flag it and refuse to show it
        local banList = { "porn" } -- I dunno, let me know what links people manage to find
        local searchFound = false
        for k, v in pairs(searchList) do
			if string.find(tostring(data.url), tostring(v))then
				searchFound = true
			end
		end
        for k, v in pairs(banList) do
			if string.find(tostring(data.url), tostring(v)) then
				searchFound = false print("BANNED WORD: "..v)
			end
		end
        if searchFound then
			TriggerServerEvent(getScript()..":Server:ChangeDUI", data)
		end
    end
end

RegisterNetEvent(getScript()..":Client:ChangeDUI", function(data)
    debugPrint("^6Bridge^7: ^2Recieving new DUI ^7- ^6"..data.url.."^7")
    if tostring(data.url) ~= "-" then
		createDui(data.texn, tostring(data.url), data.size, scriptTxd)
        AddReplaceTexture(tostring(data.texd), tostring(data.texn), getScript()..'scriptTxd', tostring(data.texn))
    end
end)

RegisterNetEvent(getScript()..":Client:ClearDUI", function(data)
    if customDUIList[tostring(data.texn)] then
        RemoveReplaceTexture(tostring(data.texd), tostring(data.texn))
        if IsDuiAvailable(customDUIList[tostring(data.texn)]) then
			SetDuiUrl(customDUIList[data.name], nil)
		end
    end
end)

-- DUI SERVER
RegisterNetEvent(getScript()..":Server:ChangeDUI", function(data)
    -- if no url given, "reset" it back to preset
    if not data.url then
		for k, v in pairs(duiList[data.name]) do
			if v.tex.texn == data.texn then
				debugPrint("^6Bridge^7: ^2Preset^7: ^6"..tostring(duiList[data.name][k].preset).."^7")
				data.url = duiList[data.name][k].preset
			end
		end
    end
    -- if it has a url, update server DUI list and send to players
	for k, v in pairs(duiList[data.name]) do
		if v.tex.texn == data.texn then
			duiList[data.name][k].url = data.url
		end
	end
	debugPrint("^6Bridge^7: ^3DUI^2 Sending new DUI to all players^7 - ^6"..data.url.."^7")
	TriggerClientEvent(getScript()..":Client:ChangeDUI", -1, data)
end)

RegisterNetEvent(getScript()..":Server:ClearDUI", function(data)
    if data.url == "-" then
		for k, v in pairs(duiList[data.name]) do
			if v.tex.texn == data.texn then
				duiList[data.name][k].url = "-"
			end
		end
	end
    -- Clear the DUI from loading
    TriggerClientEvent(getScript()..":Client:ClearDUI", -1, data)
    --duiList[tostring(data.tex)].url = ""
end)

AddEventHandler('onResourceStop', function(r) if r ~= getScript() then return end
    for k, v in pairs(duiList or {}) do
		for i = 1, #v do
			RemoveReplaceTexture(tostring(v[i].tex.texd), tostring(v[i].tex.texn))
		end
    end
end)

if isServer() then
    createCallback(getScript()..":Server:duiList", function(source)
            return duiList
    end)
end