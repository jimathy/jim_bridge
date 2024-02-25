onDuty = false
function jobCheck(job)
	canDo = true
	if not hasJob(job) or not onDuty then
		triggerNotify(nil, Loc[Config.Lan].error["not_clockedin"])
		canDo = false
	end
	return canDo
end

local time = 500
function loadModel(model)
	if not IsModelValid(model) then print("^6Bridge^7: ^1ERROR^7: ^2Model^7 - '^6"..model.."^7' ^2does not exist in server") return
	else
		if not HasModelLoaded(model) then
			if Config.System.Debug then print("^6Bridge^7: ^2Loading Model^7: '^6"..model.."^7'") end
			while not HasModelLoaded(model) and time > 0 do time -= 1 RequestModel(model) Wait(0) end
			if not HasModelLoaded(model) then print("^6Bridge^7: ^3LoadModel^7: ^2Timed out loading model ^7'^6"..model.."^7'") end
		end
		time = 500
	end
end
function unloadModel(model) if Config.System.Debug then print("^6Bridge^7: ^2Removing Model from memory cache^7: '^6"..model.."^7'") end SetModelAsNoLongerNeeded(model) end

function loadAnimDict(animDict)
	if not DoesAnimDictExist(animDict) then print("^6Bridge^7: ^1ERROR^7: ^2Anim Dictionary^7 - '^6"..animDict.."^7' ^2does not exist in server") return
	else
		if Config.System.Debug then print("^6Bridge^7: ^2Loading Anim Dictionary^7: '^6"..animDict.."^7'") end
		while not HasAnimDictLoaded(animDict) do RequestAnimDict(animDict) Wait(5) end
	end
end
function unloadAnimDict(animDict) if Config.System.Debug then print("^6Bridge^7: ^2Removing Anim Dictionary from memory cache^7: '^6"..animDict.."^7'") end RemoveAnimDict(animDict) end

function loadPtfxDict(ptFxName)
	if not HasNamedPtfxAssetLoaded(ptFxName) then
		if Config.System.Debug then
			print("^6Bridge^7: ^2Loading Ptfx Dictionary^7: '^6"..ptFxName.."^7'")
		end
		while not HasNamedPtfxAssetLoaded(ptFxName) do RequestNamedPtfxAsset(ptFxName) Wait(5) end
	end
end
function unloadPtfxDict(dict) if Config.System.Debug then print("^6Bridge^7: ^2Removing Ptfx Dictionary^7: '^6"..dict.."^7'") end RemoveNamedPtfxAsset(dict) end

function loadTextureDict(dict)
	if not HasStreamedTextureDictLoaded(dict) then
		if Config.System.Debug then
			print("^6Bridge^7: ^2Loading Texture Dictionary^7: '^6"..dict.."^7'")
		end
		while not HasStreamedTextureDictLoaded(dict) do RequestStreamedTextureDict(dict) Wait(5) end
	end
end

function countTable(table) local i = 0 for keys in pairs(table) do i += 1 end return i end

function pairsByKeys(t) local a = {} for n in pairs(t) do a[#a+1] = n end table.sort(a) local i = 0 local iter = function() i += 1 if a[i] == nil then return nil else return a[i], t[a[i]] end end return iter end

function playAnim(animDict, animName, duration, flag, ped)
	loadAnimDict(animDict)
	TaskPlayAnim(ped and ped or PlayerPedId(), animDict, animName, 8.0, -8.0, duration or 30000, flag or 50, 1, false, false, false)
end

function stopAnim(animDict, animName, ped)
	StopAnimTask(ped or PlayerPedId(), animDict, animName, 0.5)
	StopAnimTask(ped or PlayerPedId(), animName, animDict, 0.5)
	unloadAnimDict(animDict)
end

function makeVeh(model, coords)
	loadModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, false)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(veh), true)
	Wait(100)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetVehicleFuelLevel(veh, 100.0)
	SetVehicleModKit(veh, 0)
	SetVehicleOnGroundProperly(veh)
	if Config.System.Debug then
		local coords = { string.format("%.2f", coords.x), string.format("%.2f", coords.y), string.format("%.2f", coords.z), (string.format("%.2f", coords.w or 0.0)) }
		print("^6Bridge^7: ^1Veh ^2Created^7: '^6"..veh.."^7' | ^2Hash^7: ^7'^6"..(model).."^7' | ^2Coord^7: ^5vec4^7(^6"..(coords[1]).."^7, ^6"..(coords[2]).."^7, ^6"..(coords[3]).."^7, ^6"..(coords[4]).."^7)")
	end
	unloadModel(model)
    return veh
end

local Peds = {}
local Props = {}
function makePed(model, coords, freeze, collision, scenario, anim, synced)
	loadModel(model)
	local ped = CreatePed(0, model, coords.x, coords.y, coords.z-1.03, coords.w, synced and synced or false, false)
	SetEntityInvincible(ped, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	FreezeEntityPosition(ped, freeze and freeze or true)

    if collision then SetEntityNoCollisionEntity(ped, PlayerPedId(), false) end
    if scenario then TaskStartScenarioInPlace(ped, scenario, 0, true) end
    if anim then
        loadAnimDict(anim[1])
        TaskPlayAnim(ped, anim[1], anim[2], 0.5, 1.0, -1, 1, 0.2, 0, 0, 0)
    end
	if Config.System.Debug then
		local coords = { string.format("%.2f", coords.x), string.format("%.2f", coords.y), string.format("%.2f", coords.z), (string.format("%.2f", coords.w or 0.0)) }
		print("^6Bridge^7: ^1Ped ^2Created^7: '^6"..ped.."^7' | ^2Hash^7: ^7'^6"..(model).."^7' | ^2Coord^7: ^5vec4^7(^6"..(coords[1]).."^7, ^6"..(coords[2]).."^7, ^6"..(coords[3]).."^7, ^6"..(coords[4]).."^7)")
	end
    unloadModel(model)
	Peds[#Peds+1] = ped
    return ped
end

function makeProp(data, freeze, synced)
    loadModel(data.prop)
    local prop = CreateObject(data.prop, data.coords.x, data.coords.y, data.coords.z-1.03, synced and synced or false, synced and synced or false, false)
    SetEntityHeading(prop, data.coords.w + 180.0)
    FreezeEntityPosition(prop, freeze and freeze or 0)
    if Config.System.Debug then
		local coords = { string.format("%.2f", data.coords.x), string.format("%.2f", data.coords.y), string.format("%.2f", data.coords.z), (string.format("%.2f", data.coords.w or 0.0)) }
		print("^6Bridge^7: ^1Prop ^2Created^7: '^6"..prop.."^7' | ^2Hash^7: ^7'^6"..(data.prop).."^7' | ^2Coord^7: ^5vec4^7(^6"..(coords[1]).."^7, ^6"..(coords[2]).."^7, ^6"..(coords[3]).."^7, ^6"..(coords[4]).."^7)")
	end
	unloadModel(data.prop)
	Props[#Props+1] = prop
	return prop
end

function cv(amount)
    local formatted = amount or "0"
    while true do formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2') if (k==0) then break end Wait(0) end
    return formatted
end

function DrawText3D(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x,y,z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function instantLookEnt(ent, ent2)
    local p1 = GetEntityCoords(ent, true)
    local p2 = GetEntityCoords(ent2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading( ent, heading )
end

function lookEnt(entity) local ped = PlayerPedId()
	if entity then
		if type(entity) == "vector3" or type(entity) == "vector4" then
			if not IsPedHeadingTowardsPosition(ped, entity.xyz, 30.0) then
				TaskTurnPedToFaceCoord(ped, entity.xyz, 1500)
				if Config.System.Debug then print("^6Bridge^7: ^2Turning Player to^7: '^6"..json.encode(entity).."^7'") end
				Wait(1500)
			end
		else
			if DoesEntityExist(entity) then
				if not IsPedHeadingTowardsPosition(ped, GetEntityCoords(entity), 30.0) then
					TaskTurnPedToFaceCoord(ped, GetEntityCoords(entity), 1500)
					if Config.System.Debug then print("^6Bridge^7: ^2Turning Player to^7: '^6"..entity.."^7'") end
					Wait(1500)
				end
			end
		end
	end
end

function destroyProp(entity)
	if entity then
		if Config.System.Debug then print("^6Bridge^7: ^2Destroying Prop^7: '^6"..entity.."^7'") end
		if IsEntityAttachedToEntity(entity, PlayerPedId()) then
			SetEntityAsMissionEntity(entity)
			DetachEntity(entity, true, true)
		end
		DeleteObject(entity)
	end
end

function pushVehicle(entity)
	SetVehicleModKit(entity, 0)
	if entity ~= 0 and DoesEntityExist(entity) then
		if not NetworkHasControlOfEntity(entity) then
			if Config.System.Debug then print("^6Bridge^7: ^3pushVehicle^7: ^2Requesting network control of vehicle^7.") end
			NetworkRequestControlOfEntity(entity)
			local timeout = 2000
			while timeout > 0 and not NetworkHasControlOfEntity(entity) do
				Wait(100)
				timeout = timeout - 100
			end
			if NetworkHasControlOfEntity(entity) and Config.System.Debug then print("^6Bridge^7: ^3pushVehicle^7: ^2Network has control of entity^7.") end
		end
		if not IsEntityAMissionEntity(entity) then
			if Config.System.Debug then print("^6Bridge^7: ^3pushVehicle^7: ^2Setting vehicle as a ^7'^2mission^7' &2entity^7.") end
			SetEntityAsMissionEntity(entity, true, true)
			local timeout = 2000
			while timeout > 0 and not IsEntityAMissionEntity(entity) do
				Wait(100)
				timeout = timeout - 100
			end
			if IsEntityAMissionEntity(entity) and Config.System.Debug then print("^6Bridge^7: ^3pushVehicle^7: ^2Vehicle is a ^7'^2mission^7'^2 entity^7.") end
		end
	end
end

function ensureNetToVeh(vehNetID)
	if Config.System.Debug then print("^6Bridge^7: ^3ensureNetToVeh^7: ^2Requesting NetworkDoesNetworkIdExist^7(^6"..vehNetID.."^7)") end
	local timeout = 100
	while not NetworkDoesNetworkIdExist(vehNetID) and timeout > 0 do timeout -= 1 Wait(10) end
	if not NetworkDoesNetworkIdExist(vehNetID) then return 0 end
	timeout = 100
	local vehicle = NetToVeh(vehNetID)
	while not DoesEntityExist(vehicle) and vehicle ~= 0 and timeout > 0 do timeout -= 1 Wait(10) end
	if not DoesEntityExist(vehicle) then return 0 end
	return vehicle
end

local scriptTxd = not IsDuplicityVersion() and CreateRuntimeTxd(GetCurrentResourceName()..'scriptTxd') or nil

local customDUIList = {}
function makeBlip(data)
	local blip = AddBlipForCoord(vec3(data.coords.x, data.coords.y, data.coords.z))
	SetBlipAsShortRange(blip, true)
	SetBlipSprite(blip, data.sprite or 106)
	SetBlipColour(blip, data.col or 5)
	SetBlipScale(blip, data.scale or 0.7)
	SetBlipDisplay(blip, (data.disp or 6))
    if data.category then SetBlipCategory(blip, data.category) end
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(tostring(data.name))
	EndTextCommandSetBlipName(blip)
	if GetResourceState("blip_info"):find("start") or GetResourceState("blip-info"):find("start") or GetResourceState("blipinfo"):find("start") then
		if data.preview then
			local txname = tostring(data.name..'preview'..string.gsub(data.coords.z, "%.", ""))
			if data.preview:find("http") then
				createDui(txname, data.preview, vec2(512, 256), scriptTxd)
			else
				CreateRuntimeTextureFromImage(scriptTxd, txname, data.preview)
			end
			exports["blip_info"]:SetBlipInfoImage(blip, GetCurrentResourceName()..'scriptTxd', txname)
			exports["blip_info"]:SetBlipInfoTitle(blip, data.name, false)
		end
	end
	if Config.System.Debug then print("^6Bridge^7: ^6Blip ^2created for location^7: '^6"..data.name.."^7'") end
	return blip
end

function makeEntityBlip(data)
	AddBlipForEntity(data.entity)
	local blip = GetBlipFromEntity(data.entity)
	SetBlipAsShortRange(blip, true)
	SetBlipSprite(blip, data.sprite or 106)
	SetBlipColour(blip, data.col or 5)
	SetBlipScale(blip, data.scale or 0.7)
	SetBlipDisplay(blip, (data.disp or 6))
    if data.category then SetBlipCategory(blip, data.category) end
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(tostring(data.name))
	EndTextCommandSetBlipName(blip)
	if GetResourceState("blip_info"):find("start") or GetResourceState("blip-info"):find("start") or GetResourceState("blipinfo"):find("start") then
		if data.preview then
			local txname = data.name..'preview'
			if data.preview:find("http") then
				createDui(txname, data.preview, vec2(512, 256), scriptTxd)
			else
				CreateRuntimeTextureFromImage(scriptTxd, txname, data.preview)
			end
			exports["blip_info"]:SetBlipInfoImage(blip, GetCurrentResourceName()..'previewTxd', txname)
			exports["blip_info"]:SetBlipInfoTitle(blip, data.name, false)
		end
	end
	if Config.System.Debug then print("^6Bridge^7: ^6Blip ^2created for Entity^7: '^6"..data.name.."^7'") end
    return blip
end

-- DUI STUFF - WIP --

-- DUI CLIENT
function createDui(name, http, size, txd)
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
			TriggerServerEvent(GetCurrentResourceName()..":Server:ChangeDUI", data)
		end
    end
end

RegisterNetEvent(GetCurrentResourceName()..":Client:ChangeDUI", function(data)
    if Config.System.Debug then print("^6Bridge^7: ^2Recieving new DUI ^7- ^6"..data.url.."^7") end
    if tostring(data.url) ~= "-" then
		createDui(data.texn, tostring(data.url), data.size, scriptTxd)
        AddReplaceTexture(tostring(data.texd), tostring(data.texn), GetCurrentResourceName()..'scriptTxd', tostring(data.texn))
    end
end)

RegisterNetEvent(GetCurrentResourceName()..":Client:ClearDUI", function(data)
    if customDUIList[tostring(data.texn)] then
        RemoveReplaceTexture(tostring(data.texd), tostring(data.texn))
        if IsDuiAvailable(customDUIList[tostring(data.texn)]) then
			SetDuiUrl(customDUIList[data.name], nil)
		end
    end
end)

-- DUI SERVER
RegisterNetEvent(GetCurrentResourceName()..":Server:ChangeDUI", function(data)
    -- if no url given, "reset" it back to preset
    if not data.url then
		for k, v in pairs(duiList[data.name]) do
			if v.tex.texn == data.texn then
				if Config.System.Debug then print("^6Bridge^7: ^2Preset^7: ^6"..tostring(duiList[data.name][k].preset).."^7") end
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
	if Config.System.Debug then print("^6Bridge^7: ^3DUI^2 Sending new DUI to all players^7 - ^6"..data.url.."^7") end
	TriggerClientEvent(GetCurrentResourceName()..":Client:ChangeDUI", -1, data)
end)

RegisterNetEvent(GetCurrentResourceName()..":Server:ClearDUI", function(data)
    if data.url == "-" then
		for k, v in pairs(duiList[data.name]) do
			if v.tex.texn == data.texn then
				duiList[data.name][k].url = "-"
			end
		end
	end
    -- Clear the DUI from loading
    TriggerClientEvent(GetCurrentResourceName()..":Client:ClearDUI", -1, data)
    --duiList[tostring(data.tex)].url = ""
end)

AddEventHandler('onResourceStop', function(r) if r ~= GetCurrentResourceName() then return end
    for k, v in pairs(duiList or {}) do
		for i = 1, #v do
			RemoveReplaceTexture(tostring(v[i].tex.texd), tostring(v[i].tex.texn))
		end
    end
end)

function lockInv(toggle)
	FreezeEntityPosition(PlayerPedId(), toggle)
	LocalPlayer.state:set("inv_busy", toggle, true)
	TriggerEvent('inventory:client:busy:status', toggle)
	TriggerEvent('canUseInventoryAndHotbar:toggle', not toggle)
end

function createTempCam(ent, coords)
	local cam = nil
	if Config.Crafting.craftCam then
		if Config.System.Debug then
			triggerNotify(nil, "ModCam Created", "success")
		end
		local camCoords = nil
		if type(ent) ~= "vector3" then
			camCoords = GetOffsetFromEntityInWorldCoords(ent, 1.2, -0.3, 0.8)
		else
			camCoords = ent
		end
		--local pedCoords = GetEntityCoords(PlayerPedId())
		cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camCoords.x, camCoords.y, camCoords.z+0.5, 1.0, 0.0, 0.0, 60.00, false, 0)
		PointCamAtCoord(cam, coords)
	end
	return cam
end

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

function startTempCam(cam)
	if Config.Crafting.craftCam then
		SetCamActive(cam, true)
		RenderScriptCams(true, true, 1000, true, true)
	end
end
function stopTempCam()
	if Config.Crafting.craftCam then
		CreateThread(function()
			Wait(1000)
			RenderScriptCams(false, true, 500, true, true)
			DestroyAllCams()
		end)
	end
end

local inProgress = false
function progressBar(data)
	local result = nil
	if data.cam then
		startTempCam(data.cam)
	end
	if Config.System.ProgressBar == "ox" then
		if exports[OXLibExport]:progressBar({
			duration = Config.System.Debug and 1000 or data.time,
			label = data.label,
			useWhileDead = data.dead and data.dead or false,
			canCancel = data.cancel and data.cancel or true,
			anim = {
				dict = data.dict,
				clip = data.anim,
				flag = (data.flag == 8 and 32 or data.flag) or nil,
				scenario = data.task
			},
			disable = {
				combat = true
			},
		}) then
			result = true
			lockInv(false)
			if data.cam then stopTempCam(data.cam) end
		else
			result = false
			lockInv(false)
			if data.cam then stopTempCam(data.cam) end
		end

	elseif Config.System.ProgressBar == "qb" then
		Core.Functions.Progressbar("mechbar",
			data.label,
			Config.System.Debug and 1000 or data.time,
			data.dead and data.dead or false,
			data.cancel or true,
			{ disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true, },
			{ animDict = data.dict, anim = data.anim, flags = data.flag and data.flag or 32, task = data.task }, {}, {},
			function()
				result = true
				lockInv(false)
				if data.cam then
					stopTempCam(data.cam)
				end
			end, function()
				result = false
				lockInv(false)
				if data.cam then
					stopTempCam(data.cam)
				end
			end, data.icon)

	elseif Config.System.ProgressBar == "esx" then
		ESX.Progressbar(data.label, Config.System.Debug and 1000 or data.time, {
			FreezePlayer = true,
			animation ={
				type =data.anim,
				dict = data.dict,
				scenario = data.task,
			},
			onFinish = function()
				result = true
				FreezeEntityPosition(PlayerPedId(), false)
				lockInv(false)
				if data.cam then
					stopTempCam(data.cam)
				end
			end, onCancel = function()
				result = false
				FreezeEntityPosition(PlayerPedId(), false)
				lockInv(false)
				if data.cam then
					stopTempCam(data.cam)
				end
			end
		})

	elseif Config.System.ProgressBar == "gta" then
		local wait, inProgress = (Config.System.Debug and 1000 or data.time), true
		--local wait = data.time
		inProgress = true
		if not (data.dead and data.dead or false) then
			lockInv(true)
			displaySpinner(data.label)
			local ped = PlayerPedId()
			if data.dict then
				playAnim(data.dict, data.anim, -1, (data.flag == 8 and 32 or data.flag) or nil)
			end
			if data.task then
				TaskStartScenarioInPlace(ped, data.task, -1, true)
			end
			while inProgress and wait > 0 do wait -= 15
				local waitTimer = 0
				DisablePlayerFiring(ped, true)
				DisableControlAction(0, 25, true)
				DisableControlAction(0, 21, true)
                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 36, true)
				if data.cam ~= nil then
					DisableControlAction(0, 1, true)
					DisableControlAction(0, 2, true)
					DisableControlAction(0, 106, true)
				end
				if data.cancel then
					if IsControlJustReleased(0, 202) or IsControlJustReleased(0, 77) then
						inProgress = false
						waitTimer = 1500
						displaySpinner(Loc[Config.Lan].error["cancel"])
					end
				end
				Wait(waitTimer)
			end
			inProgress = false
			if data.cam then stopTempCam(data.cam) end
			if data.dict then stopAnim(data.dict, data.anim, ped) end
			ClearPedTasks(ped)
		end
		lockInv(false)
		stopSpinner()
		result = (wait <= 0)
	end
	while result == nil do Wait(10) end
	return result
end

function displaySpinner(text)
	BeginTextCommandBusyspinnerOn('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandBusyspinnerOn(4)
end

function stopSpinner() if not IsDuplicityVersion() then BusyspinnerOff() end end

function stopPropgressBar()
	if Config.System.ProgressBar == "ox" then
		exports[OXLibExport]:cancelProgress()
	elseif Config.System.ProgressBar == "qb" then
		TriggerEvent("progressbar:client:cancel")
	elseif Config.System.ProgressBar == "gta" then
		inProgress = false
		BusyspinnerOff()
	end
end

-- [[ OTHER ]] --
function washHands(data)
	lookEnt(data.coords)
	local cam = createTempCam(PlayerPedId(), data.coords)
	if progressBar({
		label = Loc[Config.Lan].progressbar["progress_washing"],
		time = 5000,
		cancel = true,
		dict = "mp_arresting",
		anim = "a_uncuff",
		flag = 32,
		icon = "fas fa-hand-holding-droplet",
		cam = cam
	}) then
		triggerNotify(nil, Loc[Config.Lan].success["washed_hands"], "success")
	else
		triggerNotify(nil, Loc[Config.Lan].error["cancel"], 'error')
	end
	ClearPedTasks(PlayerPedId())
end

function useToilet(data)
	if data.urinal then
		if progressBar({
			label = "Using Urinal",
			time = 5000,
			cancel = true,
			dict = "misscarsteal2peeing",
			anim = "peeing_loop",
			flag = 32
		}) then
			TriggerServerEvent(GetCurrentResourceName().."server:Urinal")else
			lockInv(false)
			triggerNotify(nil, Loc[Config.Lan].error["cancelled"], 'error')
		end
	else
		TaskStartScenarioAtPosition(PlayerPedId(), "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", data.sitcoords.x, data.sitcoords.y, data.sitcoords.z, data.sitcoords[4], 0, 1, true)
		if progressBar({
			label = "Using Toilet",
			time = 10000,
			cancel = true
		}) then
			TriggerServerEvent(GetCurrentResourceName().."server:Urinal")
			ClearPedTasks(PlayerPedId())
		else
			lockInv(false)
			triggerNotify(nil, Loc[Config.Lan].error["cancelled"], 'error')
		end
	end
end

RegisterNetEvent(GetCurrentResourceName()..":server:Urinal", function()
	local src = source
	local Player = getPlayer(src)
	local thirstamt = math.random(10,30)
	local thirst = Player.thirst - thirstamt
	setThirst(src, getPlayer(src).thirst - thirst)
end)

RegisterNetEvent(GetCurrentResourceName()..":server:setNeed", function(type, amount) local src = source
	if type == "thirst" then
		setThirst(src, amount)
	elseif type == "hunger" then
		setHunger(src, amount)
	end
end)

function setThirst(src, thirst)
	if GetResourceState(ESXExport):find("start") then
		TriggerClientEvent('esx_status:add', src, 'thirst', thirst)
	elseif GetResourceState(QBExport):find("start") or GetResourceState(QBXExport):find("start") then
		local Player = Core.Functions.GetPlayer(src)
		Player.Functions.SetMetaData('thirst', thirst)
		TriggerClientEvent("hud:client:UpdateNeeds", src, thirst, Player.PlayerData.metadata.thirst)
	end
end

function setHunger(src, hunger)
	if GetResourceState(ESXExport):find("start") then
		TriggerClientEvent('esx_status:add', src, 'hunger', hunger)
	elseif GetResourceState(QBExport):find("start") or GetResourceState(QBXExport):find("start") then
		local Player = Core.Functions.GetPlayer(src)
		Player.Functions.SetMetaData('hunger', hunger)
		TriggerClientEvent("hud:client:UpdateNeeds", src, hunger, Player.PlayerData.metadata.hunger)
	end
end

function useDoor(data)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
	SetEntityCoords(PlayerPedId(), data.telecoords.xyz, 0, 0, 0, false)
	SetEntityHeading(PlayerPedId(), data.telecoords.w)
	DoScreenFadeIn(1000)
    Wait(100)
end

-- [[CONSUME]] --
function ConsumeSuccess(itemName, type)
	ExecuteCommand("e c")
	removeItem(itemName, 1)
	if GetResourceState(ESXExport):find("start") then
		if Items[itemName].hunger then
			TriggerServerEvent(GetCurrentResourceName()..":server:setNeed", "hunger", Items[itemName].hunger * 10000)
		end
		if Items[itemName].thirst then
			TriggerServerEvent(GetCurrentResourceName()..":server:setNeed", "thirst", Items[itemName].thirst * 10000)
		end
	else
		if Items[itemName].hunger then
			TriggerServerEvent(GetCurrentResourceName()..":server:setNeed", "hunger", Core.Functions.GetPlayerData().metadata["hunger"] + Items[itemName].hunger)
		end
		if Items[itemName].thirst then
			TriggerServerEvent(GetCurrentResourceName()..":server:setNeed", "thirst", Core.Functions.GetPlayerData().metadata["thirst"] + Items[itemName].thirst)
		end
	end
	if type == "alcohol" then alcoholCount += 1
		if alcoholCount > 1 and alcoholCount < 4 then
			TriggerEvent("evidence:client:SetStatus", "alcohol", 200)
		elseif alcoholCount >= 4 then
			TriggerEvent("evidence:client:SetStatus", "heavyalcohol", 200)
			AlienEffect()
		end
	end
	getRandomReward(itemName) -- check if a reward item should be given
end

function addItem(item, amount, info)
    TriggerServerEvent(GetCurrentResourceName()..":server:toggleItem", true, item, amount, nil, info)
end

function removeItem(item, amount)
    TriggerServerEvent(GetCurrentResourceName()..":server:toggleItem", false, item, amount, nil, info)
end

RegisterNetEvent(GetCurrentResourceName()..":server:toggleItem", function(give, item, amount, newsrc)
    local src = newsrc or source
	local addremove = (tostring(give) == "true" and "addItem" or "removeItem")
	if Config.System.Debug then
		print("^6Bridge^7: ^3toggleItem ^2triggered^7: ^6"..addremove.."^7 - '"..tostring(item).."' x"..(tostring(amount) or "1"))
	end
	local remamount = (amount and amount or 1)
	if item == nil then return end
	if give == 0 or give == false then
		if hasItem(item, amount and amount or 1, src) then -- check if you still have the item
            if GetResourceState(OXInv):find("start") then
                local success = exports[OXInv]:RemoveItem(src, item, (amount and amount or 1), nil)
				if Config.System.Debug then
					print("^6Bridge^7: ^3"..addremove.."^7[^6"..OXInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
				end

            elseif GetResourceState(QSInv):find("start") then
                local success = exports[QSInv]:RemoveItem(src, item, amount)
				if Config.System.Debug then
					print("^6Bridge^7: ^3"..addremove.."^7[^6"..QSInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
				end

			elseif GetResourceState(CoreInv):find("start") then
				if GetResourceState(QBExport):find("start") then
					Core.Functions.GetPlayer(src).Functions.RemoveItem(item, amount, nil)
				elseif GetResourceState(ESXExport):find("start") then
					ESX.GetPlayerFromId(src).removeInventoryItem(item, count)
				end
				if Config.System.Debug then
					print("^6Bridge^7: ^3"..addremove.."^7[^6"..CoreInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
				end

            elseif GetResourceState(OrigenInv):find("start") then
                local success = exports[OrigenInv]:RemoveItem(src, item, amount)
				if Config.System.Debug then
					print("^6Bridge^7: ^3"..addremove.."^7[^6"..OrigenInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
				end

			elseif GetResourceState(CodeMInv):find("start") then
                local success = exports[CodeMInv]:RemoveItem(src, item, amount)
				if Config.System.Debug then
					print("^6Bridge^7: ^3"..addremove.."^7[^6"..CodeMInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
				end

            elseif GetResourceState(QBInv):find("start") then
				while remamount > 0 do
                    if Core.Functions.GetPlayer(src).Functions.RemoveItem(item, 1) then end
                    remamount -= 1
                end
				if Config.Crafting.showItemBox then
                    TriggerClientEvent('inventory:client:ItemBox', src, Items[item], "remove", (amount and amount or 1))
                end
				if Config.System.Debug then
					print("^6Bridge^7: ^3"..addremove.."^7[^6"..QBInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
				end
			else
				print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3exports^1.^2lua^7")
			end
		else
            dupeWarn(src, item, amount) -- if not boot the player
        end
	else
        local amount = amount and amount or 1
        if GetResourceState(OXInv):find("start") then
			local success = exports[OXInv]:AddItem(src, item, amount or 1, nil)
			if Config.System.Debug then
				print("^6Bridge^7: ^3"..addremove.."^7[^6"..OXInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
            end

		elseif GetResourceState(QSInv):find("start") then
            local success = exports[QSInv]:AddItem(src, item, amount)
            if Config.System.Debug then
				print("^6Bridge^7: ^3"..addremove.."^7[^6"..QSInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
            end

		elseif GetResourceState(CoreInv):find("start") then
			if GetResourceState(QBExport):find("start") or GetResourceState(QBXExport):find("start") then
				Core.Functions.GetPlayer(src).Functions.AddItem(item, amount, nil, nil)
			elseif GetResourceState(ESXExport):find("start") then
				ESX.GetPlayerFromId(src).addInventoryItem(item, amount)
			end
			if Config.System.Debug then
				print("^6Bridge^7: ^3"..addremove.."^7[^6"..CoreInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
            end

        elseif GetResourceState(CodeMInv):find("start") then
            local success = exports[CodeMInv]:AddItem(src, item, amount)
			if Config.System.Debug then
				print("^6Bridge^7: ^3"..addremove.."^7[^6"..CodeMInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
            end

		elseif GetResourceState(OrigenInv):find("start") then
			local success = exports[OrigenInv]:AddItem(src, item, amount)
			if Config.System.Debug then
				print("^6Bridge^7: ^3"..addremove.."^7[^6"..OrigenInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
			end

		elseif GetResourceState(QBInv):find("start") then
			if Core.Functions.GetPlayer(src).Functions.AddItem(item, amount or 1) then
				--if Config.Crafting.showItemBox then
                    TriggerClientEvent("inventory:client:ItemBox", src, Items[item], "add", amount and amount or 1)
                --end
			end
			if Config.System.Debug then
				print("^6Bridge^7: ^3"..addremove.."^7[^6"..QBInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
            end

		else
			print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3exports^1.^2lua^7")
		end
	end
end)

--Item Exploit protection
function dupeWarn(src, item, amount)
    print("^5DupeWarn^7: (^1"..tostring(src).."^7) ^2Tried to remove item ^7('^3"..item.."^7')^2 but it wasn't there^7")
    if Config.System.Debug == false then
        DropPlayer(src, src.." ^1Kicked for suspected duplicating items:"..item)
    end
    print("^5DupeWarn:^7: (^1"..tostring(src).."^7) ^2Dropped from server - exploit protection detected an item not being found in players inventory^7")
end

function breakTool(data) --wip
	local durability, slot = getDurability(item)
	durability -= data.damage
	if not durability then durability = 100 end
	if durability <= 0 then
		removeItem(data.item, 1)
		local breakId = GetSoundId()
		PlaySoundFromEntity(breakId, "Drill_Pin_Break", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
	else
		TriggerServerEvent(GetCurrentResourceName()..":server:setMetaData", { item = data.item, slot = slot, metadata = { durability = durability }})
	end
end

function getDurability(item)
	local lowestSlot = 100		-- anything above your players max slots
	local durability = nil
	if GetResourceState(QBInv):find("start") then
		local itemcheck = Core.Functions.GetPlayerData().items
		for k, v in pairs(itemcheck) do
			if v.name == item then
				if v.slot <= lowestSlot then
					lowestSlot = v.slot
					durability = itemcheck[k].info.durability
				end
			end
		end
	end

	if GetResourceState(OXInv):find("start") then
		local itemcheck = exports[OXInv]:Search('slots', item)
		for k, v in pairs(itemcheck) do
			if v.slot <= lowestSlot then
				lowestSlot = v.slot
				durability = itemcheck[k].metadata.durability
			end
		end
	end

	if GetResourceState(QSInv):find("start") then
		local itemcheck = exports[QSInv]:getUserInventory()
		for k, v in pairs(itemcheck) do
			if v.name == item and v.slot <= lowestSlot then
				lowestSlot = v.slot
				durability = itemcheck[k].metadata.durability
			end
		end
	end

	if GetResourceState(OrigenInv):find("start") then
		local itemcheck = exports[OrigenInv]:getPlayerInventory()
		for k, v in pairs(itemcheck) do
			if v.name == item and v.slot <= lowestSlot then
				lowestSlot = v.slot
				durability = itemcheck[k].metadata.durability
			end
		end
	end
	return durability, lowestSlot
end

RegisterNetEvent(GetCurrentResourceName()..":server:setMetaData", function(data)
	local src = source
	if GetResourceState(QBInv):find("start") then
		local Player = Core.Functions.GetPlayer(src)
		Player.PlayerData.items[data.slot].info = data.metadata
		Player.PlayerData.items[data.slot].description = "HP : "..data.metadata.durability
		Player.Functions.SetInventory(Player.PlayerData.items)
	end

	if GetResourceState(OXInv):find("start") then
		exports[OXInv]:SetMetadata(source, data.slot, data.metadata)
	end

	if GetResourceState(QSInv):find("start") then
		exports[QSInv]:SetItemMetadata(source, data.slot, data.metadata)
	end

	if GetResourceState(OrigenInv):find("start") then
		local item = exports[OrigenInv]:GetItemBySlot(source, data.slot)
		if item then
			exports[OrigenInv]:SetItemData(source, item.name, "durability", data.metadata.durability)
		end
	end
end)

function toggleDuty()
	if GetResourceState(QBExport):find("start") or GetResourceState(QBXExport):find("start") then
		TriggerServerEvent("QBCore:ToggleDuty")
	else
		onDuty = not onDuty
		if onDuty then
			triggerNotify(nil, "Now on duty", "success")
		else
			triggerNotify(nil, "Now off duty", "success")
		end
	end
end

local function CheckVersion()
	if IsDuplicityVersion() then
		local currentVersion = "^3"..GetResourceMetadata(GetCurrentResourceName(), 'version'):gsub("%.", "^7.^3").."^7"
		PerformHttpRequest('https://raw.githubusercontent.com/jimathy/UpdateVersions/master/'..GetCurrentResourceName()..'.txt', function(err, newestVersion, headers)
			if not newestVersion then
				PerformHttpRequest('https://raw.githubusercontent.com/jimathy/'..GetCurrentResourceName()..'/master/version.txt', function(err, freeVersion, headers)
					if not freeVersion then print("^1Currently unable to run a version check for ^7'^3"..GetCurrentResourceName().."^7' ("..currentVersion.."^7)") return end
					local currentVersion = "^3"..GetResourceMetadata(GetCurrentResourceName(), 'version'):gsub("%.", "^7.^3").."^7"
					freeVersion = "^3"..freeVersion:sub(1, -2):gsub("%.", "^7.^3"):gsub("%\r", "").."^7"
					print("^6Version Check^7: ^2Running^7: "..currentVersion.." ^2Latest^7: "..freeVersion)
					print(freeVersion == currentVersion and "^7'^3"..GetCurrentResourceName().."^7' - ^6You are running the latest version.^7 ("..currentVersion..")" or "^7'^3"..GetCurrentResourceName().."^7' - ^1You are currently running an outdated version^7, ^1please update^7!")
				end)
			else
				newestVersion = "^3"..newestVersion:sub(1, -2):gsub("%.", "^7.^3"):gsub("%\r", "").."^7"
				print("^6Version Check^7: ^2Running^7: "..currentVersion.." ^2Latest^7: "..newestVersion)
				print(newestVersion == currentVersion and '^6You are running the latest version.^7 ('..currentVersion..')' or "^1You are currently running an outdated version^7, ^1please update^7!")
			end
		end)
	end
end
CheckVersion()

--Screen Effects
local alienEffect = false
function AlienEffect()
    if alienEffect then return else alienEffect = true end
    if Config.System.Debug then print("^5Debug^7: ^3AlienEffect^7() ^2activated") end
    AnimpostfxPlay("DrugsMichaelAliensFightIn", 3.0, 0)
    Wait(math.random(5000, 8000))
    local Ped = PlayerPedId()
    local animDict = "MOVE_M@DRUNK@VERYDRUNK"
    loadAnimDict(animDict)
    SetPedCanRagdoll(Ped, true)
    ShakeGameplayCam('DRUNK_SHAKE', 2.80)
    SetTimecycleModifier("Drunk")
    SetPedMovementClipset(Ped, animDict, 1)
    SetPedMotionBlur(Ped, true)
    SetPedIsDrunk(Ped, true)
    Wait(1500)
    SetPedToRagdoll(Ped, 5000, 1000, 1, 0, 0, 0)
    Wait(13500)
    SetPedToRagdoll(Ped, 5000, 1000, 1, 0, 0, 0)
    Wait(120500)
    ClearTimecycleModifier()
    ResetScenarioTypesEnabled()
    ResetPedMovementClipset(Ped, 0)
    SetPedIsDrunk(Ped, false)
    SetPedMotionBlur(Ped, false)
    AnimpostfxStopAll()
    ShakeGameplayCam('DRUNK_SHAKE', 0.0)
    AnimpostfxPlay("DrugsMichaelAliensFight", 3.0, 0)
    Wait(math.random(45000, 60000))
    AnimpostfxPlay("DrugsMichaelAliensFightOut", 3.0, 0)
    AnimpostfxStop("DrugsMichaelAliensFightIn")
    AnimpostfxStop("DrugsMichaelAliensFight")
    AnimpostfxStop("DrugsMichaelAliensFightOut")
    alienEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3AlienEffect^7() ^2stopped") end
end
local weedEffect = false
function WeedEffect()
    if weedEffect then return else weedEffect = true end
    if Config.System.Debug then print("^5Debug^7: ^3WeedEffect^7() ^2activated") end
    AnimpostfxPlay("DrugsMichaelAliensFightIn", 3.0, 0)
    Wait(math.random(3000, 20000))
    AnimpostfxPlay("DrugsMichaelAliensFight", 3.0, 0)
    Wait(math.random(15000, 20000))
    AnimpostfxPlay("DrugsMichaelAliensFightOut", 3.0, 0)
    AnimpostfxStop("DrugsMichaelAliensFightIn")
    AnimpostfxStop("DrugsMichaelAliensFight")
    AnimpostfxStop("DrugsMichaelAliensFightOut")
    weedEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3WeedEffect^7() ^2stopped") end
end
local trevorEffect = false
function TrevorEffect()
    if trevorEffect then return else trevorEffect = true end
    if Config.System.Debug then print("^5Debug^7: ^3TrevorEffect^7() ^2activated") end
    AnimpostfxPlay("DrugsTrevorClownsFightIn", 3.0, 0)
    Wait(3000)
    AnimpostfxPlay("DrugsTrevorClownsFight", 3.0, 0)
    Wait(30000)
	AnimpostfxPlay("DrugsTrevorClownsFightOut", 3.0, 0)
	AnimpostfxStop("DrugsTrevorClownsFight")
	AnimpostfxStop("DrugsTrevorClownsFightIn")
	AnimpostfxStop("DrugsTrevorClownsFightOut")
    trevorEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3TrevorEffect^7() ^2stopped") end
end
local turboEffect = false
function TurboEffect()
    if turboEffect then return else turboEffect = true end
    if Config.System.Debug then print("^5Debug^7: ^3TurboEffect^7() ^2activated") end
    AnimpostfxPlay('RaceTurbo', 0, true)
    SetTimecycleModifier('rply_motionblur')
    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.25)
    Wait(30000)
    StopGameplayCamShaking(true)
    SetTransitionTimecycleModifier('default', 0.35)
    Wait(1000)
    ClearTimecycleModifier()
    AnimpostfxStop('RaceTurbo')
    turboEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3TurboEffect^7() ^2stopped") end
end
local rampageEffect = false
function RampageEffect()
    if rampageEffect then return else rampageEffect = true end
    if Config.System.Debug then print("^5Debug^7: ^3RampageEffect^7() ^2activated") end
    AnimpostfxPlay('Rampage', 0, true)
    SetTimecycleModifier('rply_motionblur')
    ShakeGameplayCam('SKY_DIVING_SHAKE', 0.25)
    Wait(30000)
    StopGameplayCamShaking(true)
    SetTransitionTimecycleModifier('default', 0.35)
    Wait(1000)
    ClearTimecycleModifier()
    AnimpostfxStop('Rampage')
    rampageEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3RampageEffect^7() ^2stopped") end
end
local focusEffect = false
function FocusEffect()
    if focusEffect then return else focusEffect = true end
    if Config.System.Debug then print("^5Debug^7: ^3FocusEffect^7() ^2activated") end
    Wait(1000)
    AnimpostfxPlay('FocusIn', 0, true)
    Wait(30000)
    AnimpostfxStop('FocusIn')
    focusEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3FocusEffect^7() ^2stopped") end
end
local nightVisionEffect = false
function NightVisionEffect()
    if NightVisionEffect then return else nightVisionEffect = true end
    if Config.System.Debug then print("^5Debug^7: ^3NightVisionEffect^7() ^2activated") end
    SetNightvision(true)
    Wait(math.random(3000, 4000))  -- FEEL FREE TO CHANGE THIS
    SetNightvision(false)
    SetSeethrough(false)
    nightVisionEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3NightVisionEffect^7() ^2stopped") end
end
local thermalEffect = false
function ThermalEffect()
    if thermalEffect then return else thermalEffect = true end
    if Config.System.Debug then print("^5Debug^7: ^3ThermalEffect^7() ^2activated") end
    SetNightvision(true)
    SetSeethrough(true)
    Wait(math.random(2000, 3000))  -- FEEL FREE TO CHANGE THIS
    SetNightvision(false)
    SetSeethrough(false)
    thermalEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3ThermalEffect^7() ^2stopped") end
end

--Built-in Buff effects
local healEffect = false
function HealEffect(data)
    if healEffect then return end
    if Config.System.Debug then print("^5Debug^7: ^3HealEffect^7() ^2activated") end
    healEffect = true
    local count = (data[1] / 1000)
    while count > 0 do
        Wait(1000)
        count -= 1
        SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + data[2])
    end
    healEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3HealEffect^7() ^2stopped") end
end

local staminaEffect = false
function StaminaEffect(data)
    if staminaEffect then return end
    if Config.System.Debug then print("^5Debug^7: ^3StaminaEffect^7() ^2activated") end
    staminaEffect = true
    local startStamina = (data[1] / 1000)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
    while startStamina > 0 do
        Wait(1000)
        if math.random(5, 100) < 10 then RestorePlayerStamina(PlayerId(), data[2]) end
        startStamina -= 1
        if math.random(5, 100) < 51 then end
    end
    startStamina = 0
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    staminaEffect = false
    if Config.System.Debug then print("^5Debug^7: ^3StaminaEffect^7() ^2stopped") end
end

function StopEffects() -- Used to clear up any effects stuck on screen
    if Config.System.Debug then print("^5Debug^7: ^2All screen effects stopped") end
    ShakeGameplayCam('DRUNK_SHAKE', 0.0)
    SetPedToRagdoll(PlayerPedId(), 5000, 1000, 1, 0, 0, 0)
    ClearTimecycleModifier()
    ResetScenarioTypesEnabled()
    ResetPedMovementClipset(PlayerPedId(), 0)
    SetPedIsDrunk(PlayerPedId(), false)
    SetPedMotionBlur(PlayerPedId(), false)
    SetNightvision(false)
    SetSeethrough(false)
    AnimpostfxStop("DrugsMichaelAliensFightIn")
    AnimpostfxStop("DrugsMichaelAliensFight")
    AnimpostfxStop("DrugsMichaelAliensFightOut")
	AnimpostfxStop("DrugsTrevorClownsFight")
	AnimpostfxStop("DrugsTrevorClownsFightIn")
	AnimpostfxStop("DrugsTrevorClownsFightOut")
    AnimpostfxStop('RaceTurbo')
    AnimpostfxStop('FocusIn')
    AnimpostfxStop('Rampage')
end

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
	stopSpinner()
	for i = 1, #Peds do DeletePed(Peds[i]) end
    for i = 1, #Props do destroyProp(Props[i]) end
end)