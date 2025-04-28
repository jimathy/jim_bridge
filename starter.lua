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

-- Check server convars for hard set defaults
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
    Config.System.Notify = GetConvar("jim_notifyScript", Config.System.Notify)
    Config.System.ProgressBar = GetConvar("jim_progressBarScript", Config.System.ProgressBar)
    Config.System.drawText = GetConvar("jim_drawTextScript", Config.System.drawText)
    Config.System.skillCheck = GetConvar("jim_skillCheckScript", Config.System.skillCheck)

    if GetConvar("jim_dontUseTarget", "false") == "true" then
        Config.System.DontUseTarget = true
    end
end

QBInvNew = true

InventoryWeight = 120000

-- Load files here into the invoking script
for _, v in pairs({ -- This is a specific load order
    --'convarCheck.lua',
    'helpers.lua',  -- needs to be first
    '_loaders.lua',

    '_eventDebug.lua',
    'callback.lua',
    'coreloader.lua',   -- needs to be second to load all core related stuff before everything else

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

    -- Do version check last
    '_scriptversioncheck.lua'
}) do
    if debugMode then
        --print("^5Loading^7: 'jim_bridge/shared/"..v.."' ^2into ^7'"..GetCurrentResourceName().."' ...")
    end
    local fileLoader = assert(load(LoadResourceFile('jim_bridge', ('shared/'..v)), ('@@jim_bridge/shared/'..v)))
    fileLoader()
    if debugMode then
        print("^5Success^7: ^2loaded file^7: ^3"..(v):gsub("/", "^7/^3"):gsub("%.lua", "^7.lua").."^7")
    end
end
