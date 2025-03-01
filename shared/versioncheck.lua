-- Version check for jim_bridge --
function CheckBridgeVersion()
	if isServer() then
        local currentVersion = "^3"..GetResourceMetadata("jim_bridge", 'version'):gsub("%.", "^7.^3").."^7"
        PerformHttpRequest('https://raw.githubusercontent.com/jimathy/jim_bridge/master/version.txt', function(err, newestVersion, headers)
            if not newestVersion then print("^1Currently unable to run a version check for ^7'^3jim_bridge^7' ("..currentVersion.."^7)") return end
            newestVersion = "^3"..newestVersion:sub(1, -2):gsub("%.", "^7.^3"):gsub("%\r", "").."^7"
            print(newestVersion == currentVersion and "^7'^3jim_bridge^7' - ^6You are running the latest version.^7 ("..currentVersion..")" or "^7'^3jim_bridge^7' - ^1You are currently running an outdated version^7, ^1please update^7!")
		end)
	end
end
--CheckBridgeVersion()

-- Print Script names
function capitalize(str)
    return (str:gsub("^%l", string.upper):gsub("%-%l", function(letter) return "-" .. string.upper(letter:sub(2)) end))
end

local scriptName = ("^2"..capitalize(getScript()):gsub("%-", "^7-^2"):gsub("%_", "^7_^2")) or ""
local scriptVersion = ("^5"..GetResourceMetadata(getScript(), 'version', nil):gsub("%.", "^7.^5")) or ""
local scriptDescription = ("^2"..GetResourceMetadata(getScript(), 'description', nil)) or ""
local scriptAuthor = ("^2by ^4"..GetResourceMetadata(getScript(), 'author', nil):gsub("%and", "^7and^4")) or ""

print(scriptName.." ^7v"..scriptVersion.."^7 - "..scriptDescription.." "..scriptAuthor.."^7")

-- Loaded script Version Check, requires CheckVersion() to be placed in a server file
function CheckVersion()
	if isServer() then
		local currentVersion = "^3"..GetResourceMetadata(getScript(), 'version'):gsub("%.", "^7.^3").."^7"
		PerformHttpRequest('https://raw.githubusercontent.com/jimathy/UpdateVersions/master/'..getScript()..'.txt', function(err, newestVersion, headers)
			if not newestVersion then
				PerformHttpRequest('https://raw.githubusercontent.com/jimathy/'..getScript()..'/master/version.txt', function(err, freeVersion, headers)
					if not freeVersion then print("^1Currently unable to run a version check for ^7'^3"..getScript().."^7' ("..currentVersion.."^7)") return end
					local currentVersion = "^3"..GetResourceMetadata(getScript(), 'version'):gsub("%.", "^7.^3").."^7"
					freeVersion = "^3"..freeVersion:sub(1, -2):gsub("%.", "^7.^3"):gsub("%\r", "").."^7"
					print("^6Version Check^7: ^2Running^7: "..currentVersion.." ^2Latest^7: "..freeVersion)
					print(freeVersion == currentVersion and "^7'^3"..getScript().."^7' - ^6You are running the latest version.^7 ("..currentVersion..")" or "^7'^3"..getScript().."^7' - ^1You are currently running an outdated version^7, ^1please update^7!")
				end)
			else
				newestVersion = "^3"..newestVersion:sub(1, -2):gsub("%.", "^7.^3"):gsub("%\r", "").."^7"
				print("^6Version Check^7: ^2Running^7: "..currentVersion.." ^2Latest^7: "..newestVersion)
				print(newestVersion == currentVersion and '^6You are running the latest version.^7 ('..currentVersion..')' or "^1You are currently running an outdated version^7, ^1please update^7!")
			end
		end)
	end
end
--CheckVersion()