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
			--PerformHttpRequest('https://raw.githubusercontent.com/jimathy/UpdateVersions/master/test.txt', function(err, body, headers)
			PerformHttpRequest('https://raw.githubusercontent.com/jimathy/jim_bridge/master/version.txt', function(err, body, headers)
                if not body then
                    print("^1Unable to run version check for ^7'^3jim_bridge^7' (^3"..currentVersionRaw.."^7)")
                    return
                end

                local lines = {}
                for line in body:gmatch("[^\r\n]+") do
                    table.insert(lines, line)
                end

                local newestVersionRaw = lines[1] or "0.0.0"
                local changelog = {}
                for i = 2, #lines do
                    table.insert(changelog, lines[i])
                end

                local compareResult = compareVersions(currentVersionRaw, newestVersionRaw)

                if compareResult == 0 then
                    print("^7'^3jim_bridge^7' - ^2You are running the latest version^7. ^7(^3"..currentVersionRaw.."^7)")
                elseif compareResult < 0 then
                    print("^1----------------------------------------------------------------------^7")
                    print("^7'^3jim_bridge^7' - ^1You are running an outdated version^7! ^7(^3"..currentVersionRaw.."^7 → ^3"..newestVersionRaw.."^7)")
                    for _, line in ipairs(changelog) do
                        print((line:find("http") and "^7" or "^5")..line)
                    end
                    print("^1----------------------------------------------------------------------^7")
                    SetTimeout(1200000, function()
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