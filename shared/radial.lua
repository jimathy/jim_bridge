--[[
    Radial Menu Wrapper
    -------------------
    Unified radial helpers for supported UI scripts.
]]

local radialFunc = {
    tss = {
        setItems = function(items)
            return exports[TSSHudExport]:SetRadialMenuItems(items or {})
        end,
        addItem = function(item, parentId)
            return exports[TSSHudExport]:AddRadialItem(item, parentId)
        end,
        addSubItem = function(parentId, item)
            return exports[TSSHudExport]:AddRadialSubmenuItem(parentId, item)
        end,
        updateItem = function(itemId, updates)
            return exports[TSSHudExport]:UpdateRadialItem(itemId, updates)
        end,
        removeItem = function(itemId)
            return exports[TSSHudExport]:RemoveRadialItem(itemId)
        end,
        clearItems = function()
            return exports[TSSHudExport]:ClearRadialMenuItems()
        end,
        getItems = function()
            return exports[TSSHudExport]:GetRadialMenuItems()
        end,
        open = function()
            return exports[TSSHudExport]:OpenRadialMenu()
        end,
        close = function(resetPath)
            return exports[TSSHudExport]:CloseRadialMenu(resetPath)
        end,
    }
}

local function getRadialHandler()
    local system = Config and Config.System and Config.System.Radial or "tss"
    if radialFunc[system] then
        if system == "tss" and not isStarted(TSSHudExport) then
            return nil
        end
        return radialFunc[system]
    end

    if isStarted(TSSHudExport) then
        return radialFunc.tss
    end

    return nil
end

function setRadialMenuItems(items)
    local handler = getRadialHandler()
    if not handler then return false end
    return handler.setItems(items)
end

function addRadialItem(item, parentId)
    local handler = getRadialHandler()
    if not handler then return false end
    return handler.addItem(item, parentId)
end

function addRadialSubmenuItem(parentId, item)
    local handler = getRadialHandler()
    if not handler then return false end
    return handler.addSubItem(parentId, item)
end

function updateRadialItem(itemId, updates)
    local handler = getRadialHandler()
    if not handler then return false end
    return handler.updateItem(itemId, updates)
end

function removeRadialItem(itemId)
    local handler = getRadialHandler()
    if not handler then return false end
    return handler.removeItem(itemId)
end

function clearRadialMenuItems()
    local handler = getRadialHandler()
    if not handler then return false end
    return handler.clearItems()
end

function getRadialMenuItems()
    local handler = getRadialHandler()
    if not handler then return {} end
    return handler.getItems() or {}
end

function openRadialMenu()
    local handler = getRadialHandler()
    if not handler then return false end
    return handler.open()
end

function closeRadialMenu(resetPath)
    local handler = getRadialHandler()
    if not handler then return false end
    return handler.close(resetPath)
end

