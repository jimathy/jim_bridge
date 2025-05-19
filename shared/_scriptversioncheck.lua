function parseVersion(version)
    local parts = {}
    for num in version:gmatch("%d+") do
        table.insert(parts, tonumber(num))
    end
    return parts
end

function compareVersions(current, newest)
    local currentParts = parseVersion(current)
    local newestParts = parseVersion(newest)
    for i = 1, math.max(#currentParts, #newestParts) do
        local c = currentParts[i] or 0
        local n = newestParts[i] or 0
        if c < n then return -1
        elseif c > n then return 1 end
    end
    return 0
end

function capitalize(str)
    return (str:gsub("^%l", string.upper):gsub("%-%l", function(letter) return "-" .. string.upper(letter:sub(2)) end))
end

local scriptName = ("^2"..capitalize(getScript()):gsub("%-", "^7-^2"):gsub("%_", "^7_^2")) or ""
local scriptVersion = ("^5"..GetResourceMetadata(getScript(), 'version', nil):gsub("%.", "^7.^5")) or ""
local scriptDescription = ("^2"..GetResourceMetadata(getScript(), 'description', nil)) or ""
local scriptAuthor = ("^2by ^4"..GetResourceMetadata(getScript(), 'author', nil):gsub("%and", "^7and^4")) or ""

print(scriptName.." ^7v"..scriptVersion.."^7 - "..scriptDescription.." "..scriptAuthor.."^7")

function CheckVersion()
    if isServer() and GetResourceMetadata(getScript(), 'author', nil) == "Jimathy" then
        CreateThread(function()
            Wait(4000)
            local script = getScript()
            local currentVersionRaw = GetResourceMetadata(script, 'version')

            PerformHttpRequest('https://raw.githubusercontent.com/jimathy/UpdateVersions/master/'..script..'.txt', function(err, newestVersionRaw, headers)
                if not newestVersionRaw then
                    -- fallback
                    PerformHttpRequest('https://raw.githubusercontent.com/jimathy/'..script..'/master/version.txt', function(err, fallbackVersionRaw, headers)
                        if not fallbackVersionRaw then
                            print("^1Currently unable to run a version check for ^7'^3"..script.."^7' (^3"..currentVersionRaw.."^7)")
                            return
                        end

                        local lines = {}
                        for line in fallbackVersionRaw:gmatch("[^\r\n]+") do table.insert(lines, line) end
                        local fallbackVersion = (lines[1] or "0.0.0"):gsub("v", "")
                        local changelog = {}
                        for i = 2, #lines do table.insert(changelog, lines[i]) end

                        local compareResult = compareVersions(currentVersionRaw, fallbackVersion)
                        if compareResult == 0 then
                            print("^7'^3"..script.."^7' - ^2You are running the latest version^7. (^3"..currentVersionRaw.."^7)")
                        elseif compareResult < 0 then
                            print("^1----------------------------------------------------------------------^7")
                            print("^7'^3"..script.."^7' - ^1You are currently running an outdated version^7! (^3"..currentVersionRaw.."^7 → ^3"..fallbackVersion.."^7)")
                            if #changelog > 0 then
                                for _, line in ipairs(changelog) do
                                    print((line:find("http") and "^7" or "^5")..line)
                                end
                            end
                            print("^1----------------------------------------------------------------------^7")
                            SetTimeout(1200000, function() CheckVersion() end)
                        else
                            print("^7'^3"..script.."^7' - ^5You are running a newer version ^7(^3"..currentVersionRaw.."^7 ← ^3"..fallbackVersion.."^7)")
                        end
                    end)
                else
                    local lines = {}
                    for line in newestVersionRaw:gmatch("[^\r\n]+") do table.insert(lines, line) end
                    local newestVersion = (lines[1] or "0.0.0"):gsub("v", "")
                    local changelog = {}
                    for i = 2, #lines do table.insert(changelog, lines[i]) end

                    local compareResult = compareVersions(currentVersionRaw, newestVersion)
                    if compareResult == 0 then
                        print("^7'^3"..script.."^7' - ^2You are running the latest version^7. (^3"..currentVersionRaw.."^7)")
                    elseif compareResult < 0 then
                        print("^1----------------------------------------------------------------------^7")
                        print("^7'^3"..script.."^7' - ^1You are currently running an outdated version^7! (^3"..currentVersionRaw.."^7 → ^3"..newestVersion.."^7)")
                        if #changelog > 0 then
                            for _, line in ipairs(changelog) do
                                print((line:find("http") and "^7" or "^5")..line)
                            end
                        end
                        print("^1----------------------------------------------------------------------^7")
                        SetTimeout(1200000, function() CheckVersion() end)
                    else
                        print("^7'^3"..script.."^7' - ^5You are running a newer version ^7(^3"..currentVersionRaw.."^7 ← ^3"..newestVersion.."^7)")
                    end
                end
            end)
        end)
    end
end

CheckVersion()
