WarMenu = { }
WarMenu.__index = WarMenu

if not isServer() then

-- Deprecated
WarMenu.debug = false
function WarMenu.SetDebugEnabled(enabled)
end
function WarMenu.IsDebugEnabled()
	return false
end
---

local menus = { }
local keys = { down = 187, scrollDown = 242, up = 188, scrollUp = 241, left = 189, right = 190, select = 191, accept = 237, back = 194, cancel = 238 }

local skipInputNextFrame = true
local optionCount = 0

local currentKey = nil
local currentMenu = nil

local toolTipWidth = 0.153

local spriteWidth = 0.027
local spriteHeight = spriteWidth * GetAspectRatio()

local titleHeight = 0.101
local titleYOffset = 0.021
local titleFont = 1
local titleScale = 1.0

local buttonHeight = 0.038
local buttonFont = 0
local buttonScale = 0.365
local buttonTextXOffset = 0.005
local buttonTextYOffset = 0.005
local buttonSpriteXOffset = 0.002
local buttonSpriteYOffset = 0.005

local defaultStyle = {
	x = 0.0175,
	y = 0.025,
	width = 0.23,
	maxOptionCountOnScreen = 10,
	titleVisible = true,
	titleColor = { 0, 0, 0, 255 },
	titleBackgroundColor = { 245, 127, 23, 255 },
	titleBackgroundSprite = nil,
	subTitleColor = { 245, 127, 23, 255 },
	textColor = { 254, 254, 254, 255 },
	subTextColor = { 189, 189, 189, 255 },
	focusTextColor = { 0, 0, 0, 255 },
	focusColor = { 245, 245, 245, 255 },
	backgroundColor = { 0, 0, 0, 160 },
	subTitleBackgroundColor = { 0, 0, 0, 255 },
	buttonPressedSound = { name = 'SELECT', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' }, --https://pastebin.com/0neZdsZ5
}

local function IsNavigatedDown()
	return IsControlJustReleased(2, keys.down) or IsControlJustReleased(2, keys.scrollDown)
end

local function IsNavigatedUp()
	return IsControlJustReleased(2, keys.up) or IsControlJustReleased(2, keys.scrollUp)
end

local function IsSelectedPressed()
	return IsControlJustReleased(2, keys.select) or IsControlJustReleased(2, keys.accept)
end

local function IsBackPressed()
	return IsControlJustReleased(2, keys.back) or IsControlJustReleased(2, keys.cancel)
end

local function setMenuProperty(id, property, value)
	if not id then
		return
	end

	local menu = menus[id]
	if menu then
		menu[property] = value
	end
end

local function setStyleProperty(id, property, value)
	if not id then
		return
	end

	local menu = menus[id]

	if menu then
		if not menu.overrideStyle then
			menu.overrideStyle = { }
		end

		menu.overrideStyle[property] = value
	end
end

local function getStyleProperty(property, menu)
	menu = menu or currentMenu

	if menu.overrideStyle then
		local value = menu.overrideStyle[property]
		if value ~= nil then
			return value
		end
	end

	return menu.style and menu.style[property] or defaultStyle[property]
end

local function getTitleHeight()
	return getStyleProperty('titleVisible') and titleHeight or 0
end

local function copyTable(t)
	if type(t) ~= 'table' then
		return t
	end

	local result = { }
	for k, v in pairs(t) do
		result[k] = copyTable(v)
	end

	return result
end

local function setMenuVisible(id, visible, holdCurrentOption)
	if currentMenu then
		if visible then
			if currentMenu.id == id then
				return
			end
		else
			if currentMenu.id ~= id then
				return
			end
		end
	end

	if visible then
		local menu = menus[id]

		if not currentMenu then
			menu.currentOption = 1
		else
			if not holdCurrentOption then
				menus[currentMenu.id].currentOption = 1
			end
		end

		currentMenu = menu
		skipInputNextFrame = true

		SetUserRadioControlEnabled(false)
		HudWeaponWheelIgnoreControlInput(true)
	else
		HudWeaponWheelIgnoreControlInput(false)
		SetUserRadioControlEnabled(true)

		currentMenu = nil
	end
end

local function setTextParams(font, color, scale, center, shadow, alignRight, wrapFrom, wrapTo)
	SetTextFont(font)
	SetTextColour(color[1], color[2], color[3], color[4] or 255)
	SetTextScale(scale, scale)

	if shadow then
		SetTextDropShadow()
	end

	if center then
		SetTextCentre(true)
	elseif alignRight then
		SetTextRightJustify(true)
	end

	if not wrapFrom or not wrapTo then
		wrapFrom = wrapFrom or getStyleProperty('x')
		wrapTo = wrapTo or getStyleProperty('x') + getStyleProperty('width') - buttonTextXOffset
	end

	SetTextWrap(wrapFrom, wrapTo)
end

local function getLinesCount(text, x, y)
	BeginTextCommandLineCount('TWOSTRINGS')
	AddTextComponentString(tostring(text))
	return EndTextCommandGetLineCount(x, y)
end

local function drawText(text, x, y)
	BeginTextCommandDisplayText('TWOSTRINGS')
	AddTextComponentString(tostring(text))
	EndTextCommandDisplayText(x, y)
end

local function drawRect(x, y, width, height, color)
	DrawRect(x, y, width, height, color[1], color[2], color[3], color[4] or 255)
end

local function getCurrentIndex()
	if currentMenu.currentOption <= getStyleProperty('maxOptionCountOnScreen') and optionCount <= getStyleProperty('maxOptionCountOnScreen') then
		return optionCount
	elseif optionCount > currentMenu.currentOption - getStyleProperty('maxOptionCountOnScreen') and optionCount <= currentMenu.currentOption then
		return optionCount - (currentMenu.currentOption - getStyleProperty('maxOptionCountOnScreen'))
	end

	return nil
end

local function drawTitle()
	if not getStyleProperty('titleVisible') then
		return
	end

	local x = getStyleProperty('x') + getStyleProperty('width') / 2
	local y = getStyleProperty('y') + titleHeight / 2

	if getStyleProperty('titleBackgroundSprite') then
		DrawSprite(getStyleProperty('titleBackgroundSprite').dict, getStyleProperty('titleBackgroundSprite').name, x, y, getStyleProperty('width'), titleHeight, 0., 255, 255, 255, 255)
	else
		drawRect(x, y, getStyleProperty('width'), titleHeight, getStyleProperty('titleBackgroundColor'))
	end

	if currentMenu.title then
		setTextParams(titleFont, getStyleProperty('titleColor'), titleScale, true)
		drawText(currentMenu.title, x, y - titleHeight / 2 + titleYOffset)
	end
end

local function drawSubTitle()
	local x = getStyleProperty('x') + getStyleProperty('width') / 2
	local y = getStyleProperty('y') + getTitleHeight() + buttonHeight / 2

	drawRect(x, y, getStyleProperty('width'), buttonHeight, getStyleProperty('subTitleBackgroundColor'))

	setTextParams(buttonFont, getStyleProperty('subTitleColor'), buttonScale, false)
	drawText(currentMenu.subTitle, getStyleProperty('x') + buttonTextXOffset, y - buttonHeight / 2 + buttonTextYOffset)

	if optionCount > getStyleProperty('maxOptionCountOnScreen') then
		setTextParams(buttonFont, getStyleProperty('subTitleColor'), buttonScale, false, false, true)
		drawText(tostring(currentMenu.currentOption)..' / '..tostring(optionCount), getStyleProperty('x') + getStyleProperty('width'), y - buttonHeight / 2 + buttonTextYOffset)
	end
end

local function drawButton(text, subText)
	local currentIndex = getCurrentIndex()
	if not currentIndex then
		return
	end

	local backgroundColor = nil
	local textColor = nil
	local subTextColor = nil
	local shadow = false

	if currentMenu.currentOption == optionCount then
		backgroundColor = getStyleProperty('focusColor')
		textColor = getStyleProperty('focusTextColor')
		subTextColor = getStyleProperty('focusTextColor')
	else
		backgroundColor = getStyleProperty('backgroundColor')
		textColor = getStyleProperty('textColor')
		subTextColor = getStyleProperty('subTextColor')
		shadow = true
	end

	local x = getStyleProperty('x') + getStyleProperty('width') / 2
	local y = getStyleProperty('y') + getTitleHeight() + buttonHeight + (buttonHeight * currentIndex) - buttonHeight / 2

	drawRect(x, y, getStyleProperty('width'), buttonHeight, backgroundColor)

	setTextParams(buttonFont, textColor, buttonScale, false, shadow)
	drawText(text, getStyleProperty('x') + buttonTextXOffset, y - (buttonHeight / 2) + buttonTextYOffset)

	if subText then
		setTextParams(buttonFont, subTextColor, buttonScale, false, shadow, true)
		drawText(subText, getStyleProperty('x') + buttonTextXOffset, y - buttonHeight / 2 + buttonTextYOffset)
	end
end

function WarMenu.CreateMenu(id, title, subTitle, style)
	-- Default settings
	local menu = { }

	-- Members
	menu.id = id
	menu.previousMenu = nil
	menu.currentOption = 1
	menu.title = title
	menu.subTitle = subTitle and string.upper(subTitle) or 'INTERACTION MENU'

	-- Style
	if style then
		menu.style = style
	end

	menus[id] = menu
end

function WarMenu.CreateSubMenu(id, parent, subTitle, style)
	local parentMenu = menus[parent]
	if not parentMenu then
		return
	end

	WarMenu.CreateMenu(id, parentMenu.title, subTitle and string.upper(subTitle) or parentMenu.subTitle)

	local menu = menus[id]

	menu.previousMenu = parent

	if parentMenu.overrideStyle then
		menu.overrideStyle = copyTable(parentMenu.overrideStyle)
	end

	if style then
		menu.style = style
	elseif parentMenu.style then
		menu.style = copyTable(parentMenu.style)
	end
end

function WarMenu.CurrentMenu()
	return currentMenu and currentMenu.id or nil
end

function WarMenu.OpenMenu(id)
	if id and menus[id] then
		PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
		setMenuVisible(id, true, true)
	end
end

function WarMenu.IsMenuOpened(id)
	return currentMenu and currentMenu.id == id
end
WarMenu.Begin = WarMenu.IsMenuOpened

function WarMenu.IsAnyMenuOpened()
	return currentMenu ~= nil
end

function WarMenu.IsMenuAboutToBeClosed()
	return false
end

function WarMenu.CloseMenu()
	if currentMenu then
		setMenuVisible(currentMenu.id, false)
		optionCount = 0
		currentKey = nil
		PlaySoundFrontend(-1, 'QUIT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
	end
end

function WarMenu.ToolTip(text, width, flipHorizontal)
	if not currentMenu then
		return
	end

	local currentIndex = getCurrentIndex()
	if not currentIndex then
		return
	end

	width = width or toolTipWidth

	local x = nil
	if not flipHorizontal then
		x = getStyleProperty('x') + getStyleProperty('width') + width / 2 + buttonTextXOffset
	else
		x = getStyleProperty('x') - width / 2 - buttonTextXOffset
	end

	local textX = x - (width / 2) + buttonTextXOffset
	setTextParams(buttonFont, getStyleProperty('textColor'), buttonScale, false, true, false, textX, textX + width - (buttonTextYOffset * 2))
	local linesCount = getLinesCount(text, textX, getStyleProperty('y'))

	local height = GetTextScaleHeight(buttonScale, buttonFont) * (linesCount + 1) + buttonTextYOffset
	local y = getStyleProperty('y') + getTitleHeight() + (buttonHeight * currentIndex) + height / 2

	drawRect(x, y, width, height, getStyleProperty('backgroundColor'))

	y = y - (height / 2) + buttonTextYOffset
	drawText(text, textX, y)
end

function WarMenu.Button(text, subText)
	if not currentMenu then
		return
	end

	optionCount = optionCount + 1

	drawButton(text, subText)

	local pressed = false

	if currentMenu.currentOption == optionCount then
		if currentKey == keys.select then
			pressed = true
			PlaySoundFrontend(-1, getStyleProperty('buttonPressedSound').name, getStyleProperty('buttonPressedSound').set, true)
		elseif currentKey == keys.left or currentKey == keys.right then
			PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
		end
	end

	return pressed
end

function WarMenu.SpriteButton(text, dict, name, r, g, b, a)
	if not currentMenu then
		return
	end

	local pressed = WarMenu.Button(text)

	local currentIndex = getCurrentIndex()
	if not currentIndex then
		return
	end

	if not HasStreamedTextureDictLoaded(dict) then
		RequestStreamedTextureDict(dict)
	end
	DrawSprite(dict, name, getStyleProperty('x') + getStyleProperty('width') - spriteWidth / 2 - buttonSpriteXOffset, getStyleProperty('y') + getTitleHeight() + buttonHeight + (buttonHeight * currentIndex) - spriteHeight / 2 + buttonSpriteYOffset, spriteWidth, spriteHeight, 0., r or 255, g or 255, b or 255, a or 255)

	return pressed
end

function WarMenu.InputButton(text, windowTitleEntry, defaultText, maxLength, subText)
	if not currentMenu then
		return
	end

	local pressed = WarMenu.Button(text, subText)
	local inputText = nil

	if pressed then
		DisplayOnscreenKeyboard(1, windowTitleEntry or 'FMMC_MPM_NA', '', defaultText or '', '', '', '', maxLength or 255)

		while true do
			DisableAllControlActions(0)

			local status = UpdateOnscreenKeyboard()
			if status == 2 then
				break
			elseif status == 1 then
				inputText = GetOnscreenKeyboardResult()
				break
			end

			Citizen.Wait(0)
		end
	end

	return pressed, inputText
end

function WarMenu.MenuButton(text, id, subText)
	if not currentMenu then
		return
	end

	local pressed = WarMenu.Button(text, subText)

	if pressed then
		currentMenu.currentOption = optionCount
		setMenuVisible(currentMenu.id, false)
		setMenuVisible(id, true, true)
	end

	return pressed
end

function WarMenu.CheckBox(text, checked, callback)
	if not currentMenu then
		return
	end

	local name = nil
	if currentMenu.currentOption == optionCount + 1 then
		name = checked and 'shop_box_tickb' or 'shop_box_blankb'
	else
		name = checked and 'shop_box_tick' or 'shop_box_blank'
	end

	local pressed = WarMenu.SpriteButton(text, 'commonmenu', name)

	if pressed then
		checked = not checked
		if callback then callback(checked) end
	end

	return pressed
end

function WarMenu.ComboBox(text, items, currentIndex, selectedIndex, callback)
	if not currentMenu then
		return
	end

	local itemsCount = #items
	local selectedItem = items[currentIndex]
	local isCurrent = currentMenu.currentOption == optionCount + 1
	selectedIndex = selectedIndex or currentIndex

	if itemsCount > 1 and isCurrent then
		selectedItem = '← '..tostring(selectedItem)..' →'
	end

	local pressed = WarMenu.Button(text, selectedItem)

	if pressed then
		selectedIndex = currentIndex
	elseif isCurrent then
		if currentKey == keys.left then
			if currentIndex > 1 then currentIndex = currentIndex - 1 else currentIndex = itemsCount end
		elseif currentKey == keys.right then
			if currentIndex < itemsCount then currentIndex = currentIndex + 1 else currentIndex = 1 end
		end
	end

	if callback then callback(currentIndex, selectedIndex) end
	return pressed, currentIndex
end

function WarMenu.Display()
	if currentMenu then
		if not IsPauseMenuActive() then
			ClearAllHelpMessages()
			HudWeaponWheelIgnoreSelection()
			DisablePlayerFiring(PlayerId(), true)
			DisableControlAction(0, 25, true)

			drawTitle()
			drawSubTitle()

			currentKey = nil

			if skipInputNextFrame then
				skipInputNextFrame = false
			else
				if IsNavigatedDown() then
					PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

					if currentMenu.currentOption < optionCount then
						currentMenu.currentOption = currentMenu.currentOption + 1
					else
						currentMenu.currentOption = 1
					end
				elseif IsNavigatedUp() then
					PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

					if currentMenu.currentOption > 1 then
						currentMenu.currentOption = currentMenu.currentOption - 1
					else
						currentMenu.currentOption = optionCount
					end
				elseif IsControlJustReleased(2, keys.left) then
					currentKey = keys.left
				elseif IsControlJustReleased(2, keys.right) then
					currentKey = keys.right
				elseif IsSelectedPressed() then
					currentKey = keys.select
				elseif IsBackPressed() then
					if menus[currentMenu.previousMenu] then
						setMenuVisible(currentMenu.previousMenu, true)
						PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
					else
						WarMenu.CloseMenu()
					end
				end
			end
		end

		optionCount = 0
	end
end
WarMenu.End = WarMenu.Display

function WarMenu.CurrentOption()
	if currentMenu and optionCount ~= 0 then
		return currentMenu.currentOption
	end

	return nil
end

function WarMenu.IsItemHovered()
	if not currentMenu or optionCount == 0 then
		return false
	end

	return currentMenu.currentOption == optionCount
end

function WarMenu.IsItemSelected()
	return currentKey == keys.select and WarMenu.IsItemHovered()
end

function WarMenu.SetTitle(id, title)
	setMenuProperty(id, 'title', title)
end
WarMenu.SetMenuTitle = WarMenu.SetTitle

function WarMenu.SetSubTitle(id, text)
	setMenuProperty(id, 'subTitle', string.upper(text))
end
WarMenu.SetMenuSubTitle = WarMenu.SetSubTitle

function WarMenu.SetMenuStyle(id, style)
	setMenuProperty(id, 'style', style)
end

function WarMenu.SetMenuTitleVisible(id, visible)
	setStyleProperty(id, 'titleVisible', visible)
end

function WarMenu.SetMenuX(id, x)
	setStyleProperty(id, 'x', x)
end

function WarMenu.SetMenuY(id, y)
	setStyleProperty(id, 'y', y)
end

function WarMenu.SetMenuWidth(id, width)
	setStyleProperty(id, 'width', width)
end

function WarMenu.SetMenuMaxOptionCountOnScreen(id, count)
	setStyleProperty(id, 'maxOptionCountOnScreen', count)
end

function WarMenu.SetTitleColor(id, r, g, b, a)
	setStyleProperty(id, 'titleColor', { r, g, b, a })
end
WarMenu.SetMenuTitleColor = WarMenu.SetTitleColor

function WarMenu.SetMenuSubTitleColor(id, r, g, b, a)
	setStyleProperty(id, 'subTitleColor', { r, g, b, a })
end

function WarMenu.SetMenuSubTitleBackgroundColor(id, r, g, b, a)
	setStyleProperty(id, 'subTitleBackgroundColor', { r, g, b, a })
end

function WarMenu.SetTitleBackgroundColor(id, r, g, b, a)
	setStyleProperty(id, 'titleBackgroundColor', { r, g, b, a })
end
WarMenu.SetMenuTitleBackgroundColor = WarMenu.SetTitleBackgroundColor

function WarMenu.SetTitleBackgroundSprite(id, dict, name)
	RequestStreamedTextureDict(dict)
	setStyleProperty(id, 'titleBackgroundSprite', { dict = dict, name = name })
end
WarMenu.SetMenuTitleBackgroundSprite = WarMenu.SetTitleBackgroundSprite

function WarMenu.SetMenuBackgroundColor(id, r, g, b, a)
	setStyleProperty(id, 'backgroundColor', { r, g, b, a })
end

function WarMenu.SetMenuTextColor(id, r, g, b, a)
	setStyleProperty(id, 'textColor', { r, g, b, a })
end

function WarMenu.SetMenuSubTextColor(id, r, g, b, a)
	setStyleProperty(id, 'subTextColor', { r, g, b, a })
end

function WarMenu.SetMenuFocusColor(id, r, g, b, a)
	setStyleProperty(id, 'focusColor', { r, g, b, a })
end

function WarMenu.SetMenuFocusTextColor(id, r, g, b, a)
	setStyleProperty(id, 'focusTextColor', { r, g, b, a })
end

function WarMenu.SetMenuButtonPressedSound(id, name, set)
	setStyleProperty(id, 'buttonPressedSound', { name = name, set = set })
end

end