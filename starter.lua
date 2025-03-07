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
    OXTargetExport = "ox_target"
}

-- Required variables
debugMode = Config.System.Debug

QBInvNew = true

InventoryWeight = 120000

-- Load files here into the invoking script
for _, v in pairs({ -- This is a specific load order
    'helpers.lua',  -- needs to be first
    '_loaders.lua',

    '_eventDebug.lua',
    'coreloader.lua',   -- needs to be second to load all core related stuff before everything else
    'callback.lua',

    'duifunctions.lua',

    -- Native Scaleforms
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
    'itemcontrol.lua',
    'playerfunctions.lua',
    'metaHandlers.lua',
    'jobfunctions.lua',
    'banking.lua',

    -- Interactions
    'targets.lua',
    'contextmenus.lua',
    'input.lua',
    'notify.lua',
    'drawText.lua',

    -- Crafting / Shops / Stashes
    'crafting.lua',
    'stashcontrol.lua',

    -- Kind of "other"
    'isAnimal.lua',
    'scaleEntity.lua',
    'vehicles.lua',
    'effects.lua',
    'versioncheck.lua'
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