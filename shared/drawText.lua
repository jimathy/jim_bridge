local radarTable = {}

--- Displays text on the screen using the configured draw text system.
---
--- This function handles displaying text with optional images or icons using different frameworks like 'qb', 'ox', 'gta', and 'esx'.
---
---@param image string|nil An optional image or icon to display with the text. Can be a URL, path, or a reference to an icon.
---@param input table A table of strings, each representing a line of text to display.
---@param style string|nil An optional style code for default GTA popups (e.g., '~g~' for green text).
---@param oxStyleTable table|nil An optional table specifying style parameters for the 'ox' draw text system.
---
---@usage
--- ```lua
--- drawText("img_link", { "Test line 1", "Test Line 2" }, "~g~")
--- ```
function drawText(image, input, style, oxStyleTable) local text = ""
	if Config.System.drawText == "qb" then
		for i = 1, #input do
			text = text..input[i].."</span>"..(input[i+1] ~= nil and "<br>" or "") end
		local text = text:gsub("%:", ":<span style='color:yellow'>")
		if image then
			text = '<img src="'..(radarTable[image] or nil)..'" style="width:12px;height:12px">'..text
		end
		exports[QBExport]:DrawText(text, 'left')

	elseif Config.System.drawText == "ox" then
		for k, v in pairs(input) do
			input[k] = v.."   \n"
		end
		lib.showTextUI(table.concat(input), { icon = (image and radarTable[image] or image) or nil, position = 'left-center', style = oxStyleTable})

	elseif Config.System.drawText == "gta" then
		for i = 1, #input do if input[i] ~= "" then text = text..input[i].."\n~s~" end end
		if image then text = "~BLIP_"..image.."~ "..text end

		DisplayHelpMsg(text:gsub("%:", ":~"..(style or "g").."~"))
    elseif Config.System.drawText == "esx" then
        for i = 1, #input do
			text = text..input[i].."</span>"..(input[i+1] ~= nil and "<br>" or "") end
		local text = text:gsub("%:", ":<span style='color:yellow'>")
		if image then
			text = '<img src="'..radarTable[image]..'" style="width:12px;height:12px">'..text
		end
		ESX.TextUI(text, nil)
	end
end

--- Hides any text currently being displayed on the screen.
---
--- This function clears the text displayed by the `drawText` function, using the appropriate method based on the configured draw text system.
function hideText()
    if Config.System.drawText == "qb" then
        exports[QBExport]:HideText()
    elseif Config.System.drawText == "ox" then
        lib.hideTextUI()
    elseif Config.System.drawText == "gta" then
        ClearAllHelpMessages()
    elseif Config.System.drawText == "esx" then
        ESX.HideUI()
    end
end