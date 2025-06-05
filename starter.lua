gameName = not IsDuplicityVersion() and GetCurrentGameName()

Exports = {
    QBExport = "qb-core",
    QBXExport = "qbx_core",
    ESXExport = "es_extended",
    OXCoreExport = "ox_core",

    OXInv = "ox_inventory",
    QBInv = "qb-inventory",
    PSInv = "ps-inventory",
    QSInv = "qs-inventory",
    CoreInv = "core_inventory",
    CodeMInv = "codem-inventory",
    OrigenInv = "origen_inventory",
    TgiannInv = "tgiann-inventory",

    OXLibExport = "ox_lib",

    QBMenuExport = "qb-menu",

    QBTargetExport = "qb-target",
    OXTargetExport = "ox_target",

    -- REDM
    RSGExport = "rsg-core",
    RSGInv = "rsg-inventory"
}

-- Required variables
debugMode = Config.System.Debug

QBInvNew = true

InventoryWeight = 120000

-- [[ Server.Cfg Convar Check ]]--
-- Check server convars for hard set defaults, otherwise it uses per script configurations
if Config and Config.System then
    if Config.System.Debug then
        if GetConvar("jim_DisableDebug", "false") == "true" then
            debugMode = false
        end
        if GetConvar("jim_DisableEventDebug", "false") == "true" then
            Config.System.EventDebug = false
        end
    end

    Config.System.Menu = GetConvar("jim_menuScript", Config.System.Menu)
    Config.System.Notify = GetConvar("jim_notifyScript", Config.System.Notify or "gta")
    Config.System.ProgressBar = GetConvar("jim_progressBarScript", Config.System.ProgressBar or "gta")
    Config.System.drawText = GetConvar("jim_drawTextScript", Config.System.drawText or "gta")
    Config.System.skillCheck = GetConvar("jim_skillCheckScript", Config.System.skillCheck or "gta")

    if GetConvar("jim_dontUseTarget", "false") == "true" then
        Config.System.DontUseTarget = true
    end
end

-- Load the core files here instead of in fxmanifests
-- Forcefully loads the files and quietly, compared to fxmanifest complaining if they don't exist when you don't need them all
local filesToLoad = {
    Shared = {
        [Exports.OXLibExport] = { "init.lua" },
        [Exports.OXCoreExport] = { "lib/init.lua" },
        [Exports.ESXExport] = { "imports.lua" },
        [Exports.QBXExport] = { "modules/playerdata.lua" },
    },
    Client = {
        ["PolyZone"] = { "client.lua", "BoxZone.lua", "EntityZone.lua", "CircleZone.lua", "ComboZone.lua" },
        ["warmenu"] = { "warmenu.lua", },
    },
}

-- Shared framework file loader
for Type, ScriptTable in pairs(filesToLoad) do
    if Type == "Client" and IsDuplicityVersion() then
        goto continue
    else
        for scriptName, files in pairs(ScriptTable) do
            local state = GetResourceState(scriptName)
            -- if the resource is started, load the file
            if state == "started" then
                if scriptName == Exports.OXLibExport and GetResourceState(Exports.OXCoreExport):find("start") then
                    if debugMode then print("OX_Core found, skipping OX_Lib loading") end
                    goto skip
                end
                -- Force items into a table if they are not
                if type(files) == "string" then
                    files = { files }
                end
                for _, file in pairs(files) do
                    --print("^5CoreLoader^7: '"..scriptName.."/"..file.."' ^2into ^7'"..GetCurrentResourceName().."' ...")
                    local fileLoader = assert(load(LoadResourceFile(scriptName, (file)), ('@@'..scriptName..'/'..file)))
                    fileLoader()
                    if debugMode then
                        print("^5CoreLoader^7: ^2loaded ^1Core ^2file^7: ^3"..scriptName.."^7/^3"..(file):gsub("/", "^7/^3"):gsub("%.lua", "^7.lua").." ^2into ^7'"..GetCurrentResourceName().."'")
                    end
                end
                ::skip::
            end

            -- if script is in server, but not started warn the user
            if state == "uninitialized" or state == "stopped" then
                print("^5CoreLoader^7: ^3"..scriptName.." ^1 found but it wasn't started^7.")
                print("^1Check your ^3server^7.^3cfg ^1load order^7")
            end

            -- debugging only, if the script is missing, warn the user
            if state == "missing" then
                if debugMode then
                    print("^5CoreLoader^7: ^3"..scriptName.." ^2not found^7, ^2skipping")
                end
            end
        end
    end
    ::continue::
end

-- Load files here into the invoking script
for _, v in pairs({ -- This is a specific load order

    'helpers.lua',  -- needs to be first
    '_loaders.lua',

    '_eventDebug.lua',
    'callback.lua',
    'coreloader.lua',

    'duifunctions.lua',

    -- Native Scaleforms
    'scaleforms/scaleform_basic.lua',
    'scaleforms/bigMessageInstance.lua',
    'scaleforms/countDownHandler.lua',
    'scaleforms/debugScaleform.lua',
    'scaleforms/instructionalButtons.lua',
    'scaleforms/timerBars.lua',

    -- Required functions
    'make/loaders.lua',
    'make/makeBlip.lua',
    'make/makePed.lua',
    'make/makeProp.lua',
    'make/makeVeh.lua',
    'make/cameras.lua',
    'make/progressBars.lua',

    'wrapperfunctions.lua',
    'polyZone.lua',
    'inventories.lua',
    'itemcontrol.lua',
    'playerfunctions.lua',
    'metaHandlers.lua',
    'jobfunctions.lua',
    'societybank.lua',
    'phones.lua',

    -- Interactions
    'targets.lua',
    'contextmenus.lua',
    'input.lua',
    'notify.lua',
    'drawText.lua',
    'skillcheck.lua',

    -- Crafting / Shops / Stashes
    'crafting.lua',
    'shops.lua',
    'stashcontrol.lua',

    -- Kind of "other"
    'isAnimal.lua',
    'scaleEntity.lua',
    'vehicles.lua',
    'effects.lua',

    --'warmenu.lua',

    -- Do version check last
    '_scriptversioncheck.lua'
}) do
    if debugMode then
        --print("^5Loading^7: 'jim_bridge/shared/"..v.."' ^2into ^7'"..GetCurrentResourceName().."' ...")
    end
    local fileLoader = assert(load(LoadResourceFile('jim_bridge', ('shared/'..v)), ('@@jim_bridge/shared/'..v)))
    fileLoader()
    if debugMode then
        print("^5CoreLoader^7: ^2loaded file^7: ^3"..(v):gsub("/", "^7/^3"):gsub("%.lua", "^7.lua").."^7")
    end
end