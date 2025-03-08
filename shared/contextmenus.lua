--[[
    Menu Opening Module
    ---------------------
    This module provides a unified function to open menus using the configured menu system.
    Supported systems include:
      • jim-nui (kinda)
      • ox (or ox_context)
      • qb (using QBMenuExport)
      • gta (using WarMenu)
      • esx (using ESX.UI.Menu)
]]

--- Opens a menu using the configured menu system.
---
--- This function translates code and creates menus in several different menu scripts, depending on the configured menu system specified in `Config.System.Menu`.
---
---@param Menu table A table containing the menu options to display.
--- Each menu item can include:
---     - header (`string`): The text to display for the menu item.
---     - txt (`string`, optional): Additional text or description.
---     - icon (`string`, optional): Icon to display with the menu item.
---     - onSelect (`function`, optional): Function to execute when the menu item is selected.
---     - arrow (`boolean`, optional): Whether to display an arrow next to the item (for certain menus).
---     - params (`table`, optional): Additional parameters, such as events and arguments.
---     - isMenuHeader (`boolean`, optional): Marks the item as a header.
---     - disabled (`boolean`, optional): Disables the menu item if `true`.
---
---@param data table A table containing configuration data for the menu.
---     - header (`string`): The header/title of the menu.
---     - headertxt (`string`, optional): Additional header text.
---     - onBack (`function`, optional): Function to call when the "Return" option is selected.
---     - onExit (`function`, optional): Function to call when the menu is exited.
---     - onSelected (`function`, optional): Function to call when a menu item is selected (for certain menu systems).
---     - canClose (`boolean`, optional): Whether the menu can be closed by the user.
---
---@usage
--- ```lua
--- openMenu({
---     { header = "Option 1", txt = "Description 1", onSelect = function() print("Option 1 selected") end },
---     { header = "Option 2", txt = "Description 2", onSelect = function() print("Option 2 selected") end },
--- }, {
---     header = "Main Menu",
---     headertxt = "Select an option",
---     onBack = function() print("Return selected") end,
---     onExit = function() print("Menu closed") end,
---     canClose = true,
--- })
--- ```
function openMenu(Menu, data)
    if Config.System.Menu == "jim" then
        -- Insert "Return" option if onBack is defined.
        if data.onBack then
            table.insert(Menu, 1, {
                icon = "fas fa-circle-arrow-left",
                title = "Return",
                onSelect = data.onBack,
            })
        end
        exports["jim-nui"]:openMenu({
            title = data.header..(data.headertxt and " -- "..data.headertxt or ""),
            canClose = data.canClose and data.canClose or nil,
            onClose = (data.onBack and data.onBack) or (data.onExit and data.onExit) or nil,
            onExit = data.onExit and data.onExit or nil,
            options = Menu,
        })

    elseif Config.System.Menu == "ox" then
        local index = nil
        if data.onBack and not data.onSelected then
            table.insert(Menu, 1, {
                icon = "fas fa-circle-arrow-left",
                title = "Return",
                onSelect = data.onBack,
                label = "Return",
            })
        end
        for k in pairs(Menu) do
            if data.onSelected and Menu[k].arrow then
                Menu[k].icon = "fas fa-angle-right"
            end
            -- If no title, use header or txt as title/label.
            if not Menu[k].title then
                if Menu[k].header ~= nil and Menu[k].header ~= "" then
                    Menu[k].title = Menu[k].header
                    Menu[k].label = Menu[k].header
                    if Menu[k].txt then Menu[k].description = Menu[k].txt else Menu[k].description = "" end
                else
                    Menu[k].title = Menu[k].txt
                    Menu[k].label = Menu[k].txt
                end
            end
            -- Copy parameters from 'params' if available.
            if Menu[k].params then
                Menu[k].event = Menu[k].params.event
                Menu[k].args = Menu[k].params.args or {}
            end
            if Menu[k].isMenuHeader then
                Menu[k].disabled = true
            end
        end
        local menuID = 'Menu'
        (data.onSelected and lib.registerMenu or lib.registerContext)({
            id = menuID,
            title = data.header..br..br..(data.headertxt and data.headertxt or ""),
            position = 'top-right',
            options = Menu,
            canClose = data.canClose and data.canClose or nil,
            onClose = (data.onBack and data.onBack) or (data.onExit and data.onExit) or nil,
            onExit = data.onExit and data.onExit or nil,
            onSelected = data.onSelected and (function(selected) index = selected end) or nil,
        }, data.onSelected and (function(x, y, args)
            if Menu[x].refresh then
                if Menu[x].onSelect then
                    Menu[x].onSelect()
                end
                lib.showMenu(menuID, index)
            else
                if Menu[x].onSelect then
                    Menu[x].onSelect()
                else
                    lib.showMenu(menuID, index)
                end
            end
        end) or nil)
        if data.onSelected then
            lib.showMenu(menuID, 1)
        else
            lib.showContext(menuID)
        end

    elseif Config.System.Menu == "qb" then
        if data.onBack then
            table.insert(Menu, 1, {
                icon = "fas fa-circle-arrow-left",
                header = " ",
                txt = "Return",
                params = {
                    isAction = true,
                    event = data.onBack,
                },
            })
        elseif data.canClose then
            table.insert(Menu, 1, {
                icon = "fas fa-circle-xmark",
                header = " ",
                txt = "Close",
                params = {
                    isAction = true,
                    event = data.onExit and data.onExit or (function() exports[QBMenuExport]:closeMenu() end),
                },
            })
        end
        if data.header ~= nil then
            local tempMenu = {}
            for k, v in pairs(Menu) do tempMenu[k + 1] = v end
            tempMenu[1] = { header = data.header, txt = data.headertxt or "", isMenuHeader = true }
            Menu = tempMenu
        end
        for k in pairs(Menu) do
            if not Menu[k].params or not Menu[k].params.event then
                Menu[k].params = {
                    isAction = true,
                    event = Menu[k].onSelect or function() end,
                }
            end
            if not Menu[k].header then Menu[k].header = " " end
            if Menu[k].arrow then Menu[k].icon = "fas fa-angle-right" end
            Menu[k].isMenuHeader = Menu[k].isMenuHeader or Menu[k].disable
        end
        exports[QBMenuExport]:openMenu(Menu)

    elseif Config.System.Menu == "gta" then
        WarMenu.CreateMenu(tostring(Menu), data.header, data.headertxt or " ", {
            titleColor = { 222, 255, 255 },
            maxOptionCountOnScreen = 15,
            width = 0.25,
            x = 0.7,
        })
        if WarMenu.IsAnyMenuOpened() then return end
        WarMenu.OpenMenu(tostring(Menu))
        CreateThread(function()
            local close = true
            while true do
                if WarMenu.Begin(tostring(Menu)) then
                    if data.onBack then
                        if WarMenu.SpriteButton("Return", 'commonmenu', "arrowleft", 127, 127, 127) then
                            WarMenu.CloseMenu()
                            Wait(10)
                            data.onBack()
                        end
                    end
                    for k in pairs(Menu) do
                        local pressed = WarMenu.Button(Menu[k].header)
                        if not Menu[k].header then
                            Menu[k].header = Menu[k].txt
                            Menu[k].txt = nil
                        end
                        if Menu[k].txt and Menu[k].txt ~= "" and WarMenu.IsItemHovered() then
                            if Menu[k].disabled or Menu[k].isMenuHeader then
                                WarMenu.ToolTip("~r~"..Menu[k].txt, 0.18, true)
                            else
                                WarMenu.ToolTip(
                                    (Menu[k].blip and "~BLIP_".."8".."~ " or "")..
                                    Menu[k].txt:gsub("%:", ":~g~"):gsub("%\n", "\n~s~"), 0.18,
                                    true)
                            end
                        end
                        if pressed and not Menu[k].isMenuHeader then
                            WarMenu.CloseMenu()
                            close = false
                            Menu[k].onSelect()
                        end
                    end
                    WarMenu.End()
                else
                    return
                end
                if not WarMenu.IsAnyMenuOpened() and close then
                    stopTempCam(cam)
                    if data.onExit then data.onExit() end
                end
                Wait(0)
            end
        end)

    elseif Config.System.Menu == "esx" then
        for k in pairs(Menu) do
            Menu[k].label = Menu[k].header
            Menu[k].name = "button"..k
        end
        if data.canClose then
            table.insert(Menu, 1, {
                icon = "fas fa-circle-xmark",
                label = "Close",
                name = "close",
                onSelect = data.onExit,
            })
        end
        if data.onBack then
            table.insert(Menu, 1, {
                icon = "fas fa-circle-arrow-left",
                label = "Return",
                name = "return",
                onSelect = data.onBack,
            })
        end
        ESX.UI.Menu.Open("default", getScript(), "Example_Menu", {
            title = data.header,
            align = 'top-right',
            elements = Menu,
        },
        function(menuData, menu)
            for k in pairs(Menu) do
                if menuData.current.name == Menu[k].name then
                    menu.close()
                    Wait(10)
                    Menu[k].onSelect()
                end
            end
        end,
        function(data, menu)
            menu.close()
        end)
    end
end

--- A line break constant used for menu header formatting.
br = (Config.System.Menu == "ox" or Config.System.Menu == "gta") and "\n" or "<br>"

--- Checks if the current menu system is 'ox' or 'gta' for formatting purposes.
--- @return boolean boolean True if using ox or gta menus, otherwise false.
--- @usage
--- ```lua
--- if isOx() then
---     -- Use specific formatting
--- end
--- ```
function isOx() return (Config.System.Menu == "ox" or Config.System.Menu == "gta") end


--- Checks if any WarMenu menu is currently open.
---
--- @return boolean boolean Returns `true` if a WarMenu menu is open; otherwise, `false`.
---
--- @usage
--- ```lua
--- if isWarMenuOpen() then
---     -- Do something
--- end
--- ```
function isWarMenuOpen() if Config.System.Menu == "gta" then return WarMenu.IsAnyMenuOpened() else return false end end