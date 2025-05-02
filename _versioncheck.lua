local function parseVersion(version)
    local parts = {}
    for num in version:gmatch("%d+") do
        table.insert(parts, tonumber(num))
    end
    return parts
end

local function compareVersions(current, newest)
    local currentParts = parseVersion(current)
    local newestParts = parseVersion(newest)
    for i = 1, math.max(#currentParts, #newestParts) do
        local c = currentParts[i] or 0
        local n = newestParts[i] or 0
        if c < n then return -1
        elseif c > n then return 1 end
    end
    return 0 -- equal
end

function CheckBridgeVersion()
    if IsDuplicityVersion() then
		CreateThread(function()
			Wait(4000)
			local currentVersionRaw = GetResourceMetadata("jim_bridge", 'version')
			PerformHttpRequest('https://raw.githubusercontent.com/jimathy/jim_bridge/master/version.txt', function(err, newestVersionRaw, headers)
				if not newestVersionRaw then
					print("^1Unable to run version check for ^7'^3jim_bridge^7' (^3"..currentVersionRaw.."^7)")
					return
				end

				newestVersionRaw = newestVersionRaw:match("[^\r\n]+")
				local compareResult = compareVersions(currentVersionRaw, newestVersionRaw)

				if compareResult == 0 then
					print("^7'^3jim_bridge^7' - ^2You are running the latest version^7. ^7(^3"..currentVersionRaw.."^7)")
				elseif compareResult < 0 then
					-- Made the check a bit more obvious
					print("^1----------------------------------------------------------------------^7")
					print("^7'^3jim_bridge^7' - ^1You are running an outdated version^7! ^7(^3"..currentVersionRaw.."^7 → ^3"..newestVersionRaw.."^7)")
					print("^1----------------------------------------------------------------------^7")
					SetTimeout(1200000, function()
						-- Do a naughty repeat message every 20 minutes until the the script is updated
						CheckBridgeVersion()
					end)
				else
					print("^7'^3jim_bridge^7' - ^5You are running a newer version ^7(^3"..currentVersionRaw.."^7 ← ^3"..newestVersionRaw.."^7)")
				end
			end)
		end)
	end
end

CheckBridgeVersion()