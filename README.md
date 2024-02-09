# Jim_Bridge

This script is intended to be used with my all my scripts (soon)

It was started due to wanting to bring the same features from some scripts into others with minimal work and multiple updates
- Having certain functions in one place(this script) makes it easier to update, enchance and fix things
- This brings the possibility of branching to mutliple frameworks as I've added some already:
    - `"qb-core"`
    - `"qbx-core"`
    - `"ox_core"`
    - `"es_extended"` (requires ox_lib and ox_inventory)

All the next updates of my scripts will use this script and be added as a dependancy

------

It was a tough decision to put it up on github instead of tebex and encrypted

But I want this script to grow with help of others who know more about other cores

---

The installation of this script is simple
- REMOVE `-main` from the folder name, like any other github hosted script
- it just needs to start before any script that requires it
- it can start before core scripts if you want
- for `qb-core` I personally place this script in `resources > [standalone]`


---

### Support for different exports and scripts

In exports.lua is the list of script folder names

This is for people who have customised/renamed scripts

eg. for people who use `ps-inventory`, this is mainly based on qb-inventory
so you need to rename
```lua
    QBInv = "qb-inventory",
```
to
```lua
    QBInv = "ps-inventory",
```

This will now use events from `ps-inventory` and use it through out the scripts.

# WIP
## Documentation

This script brings alot of features to simplify making scripts with preset functions and automations.

It attempts to make use of configs from the scripts its loaded into. For example:

### `Config`
```lua
Config = {
	System = {
		Debug = true,		-- This enables Debug mode
							-- Revealing debug prints and debug boxes on targets

		Menu = "qb", 		-- This specifies what menu script will be loaded
							-- "qb" = `qb-menu` and edited versions of it
							-- "ox" = `ox_lib`'s context menu system
							-- "gta" = `WarMenu' a free script for a gta style menu

		Notify = "gta",		-- This allows you to choose the notification system for scripts
							-- "qb" = `qb-core`'s built in notifications
							-- "ox" = `ox_lib`'s built in notifications
							-- "esx" = `esx_notify` esx's default notifications
							-- "okok" = `okok-notify` okok's notifications
							-- "gta" = Native GTA style popups

		drawText = "gta",	-- The style of drawText you want to use
							-- "qb" = `qb-core`'s drawText system
							-- "ox" = `ox_lib`'s drawTextUI system
							-- "gta" = Native GTA style popups


		progressBar = "gta" -- The style of progressBar you want to use
							-- "qb" = `qb-core`'s style progressBar
							-- "ox" = `ox_lib`'s default progressBar
							-- "gta" = Native GTA style "spinner"
	},
}
```

### `openMenu(Menu, data)`

This handles creation of menus using `OX_Lib`, `qb-menu` or `WarMenu`

It uses mixed/new functions to bring more compatability to one another

`Menu` is your button entries and works like qb-menu or ox_lib, for example:

```lua
local Menu = {}
Menu[#Menu + 1] = {
	isMenuHeader = true, 			-- This makes the current button unclickable
	icon = invImg("lockpick")		-- Supports fontawesome or custom images
									-- This example use the custom function `invImg()` to retreive an nui:// link to the given item's image
	arrow = true,					-- Adds a arrow icon to the button (in qb-menu overrides the icon)
	header = "Header Test",			-- The header/title for the button
	txt = "Text test",				-- The txt/description for the button

	onSelect = function()			-- This brings the onSelect function to qb-menu
		TriggerEvent("lolhi", { lol = hi }),
	end,
									-- Enter what happens when you click the button
}
```

As you can see above, it mixes variables but makes it possible to switch between menus just by changing the config option

After you have created the info above, you need to then trigger opening of this menu with:
```lua
openMenu(Menu, 						-- Menu here is your table name you created above
{									-- Next entry in openMenu is a table
	header = "Menu Header",			-- What your menu title will be shown as
	headertxt = "Header info",		-- Info to be displayed under the title

	onExit = function()				-- Will create a "Close button"
		TriggerEvent("lolhi", { lol = hi }),
	end,							-- When clicked it will trigger the onExit event

	onBack = function()				-- Will create a "Back button"
		TriggerEvent("lolhi", { lol = hi }),
	end,							-- When clicked it will trigger the onBack event
})
```

### Support for multiple target events
These automatically detect what target script you are using

They are also automatically removed when the script is stopped (for helping optimization)
### `createEntityTarget(entity, opts, dist)`
Create an entity based target
```lua
createEntityTarget(
	entity,							-- The entity ID of what you want to target
	{
		{ 							-- Your target options here
			icon = "icon",			-- Your icon, only supports font awesome icons
			label = "Test Label",	-- The label of your target
			item = "lockpick"		-- The required it em
			job = "mechanic",		-- The required job
			gang = "lostmc",		-- The required gang
			action = function()		-- What happens when the target is selected
				TriggerEvent("lolhi", { lol = hi }),
			end,
		},
	}
, dist)								-- How close you ned to be to see the target
```

### `createBoxTarget(data, opts, dist)`
Create an entity based target
```lua
createBoxTarget(
	{
		"TargetName",				-- The name/id of your target here
		vec3(0, 0, 0),				-- The coordinates of your target
		2.0,						-- The width of your target box
		2.0,						-- The depth of your target box
		{
			name = "TargetName",	-- The name/id of your target here
			heading = 200.0,		-- The direction your target will be placed
			debugPoly = true,		-- Wether to show debug boxes to help place targets
			minZ = 190.0,			-- The bottom of your box
			maxZ = 210.0,			-- The top of your box
		},
	},
	{
		{ 							-- Your target options here
			icon = "icon",			-- Your icon, only supports font awesome icons
			label = "Test Label",	-- The label of your target
			item = "lockpick"		-- The required it em
			job = "mechanic",		-- The required job
			gang = "lostmc",		-- The required gang
			action = function()		-- What happens when the target is selected
				TriggerEvent("lolhi", { lol = hi }),
			end,
		},
	},
dist)								-- How close you ned to be to see the target
```

### `createCircleTarget(data, opts, dist)`
Create an entity based target
```lua
createCircleTarget(
	{
		"TargetName",				-- The name/id of your target here
		vec3(0, 0, 0),				-- The coordinates of your target
		2.0,						-- The radius of your target circle
		{
			name = "TargetName",	-- The name/id of your target here
			heading = 200.0,		-- The direction your target will be placed
			debugPoly = true,		-- Wether to show debug boxes to help place targets
			minZ = 190.0,			-- The bottom of your box
			maxZ = 210.0,			-- The top of your box
		},
	},
	{
		{ 							-- Your target options here
			icon = "icon",			-- Your icon, only supports font awesome icons
			label = "Test Label",	-- The label of your target
			item = "lockpick"		-- The required it em
			job = "mechanic",		-- The required job
			gang = "lostmc",		-- The required gang
			action = function()		-- What happens when the target is selected
				TriggerEvent("lolhi", { lol = hi }),
			end,
		},
	},
dist)								-- How close you ned to be to see the target
```

### `removeEntityTarget(entity)`
Triggers removal of the target entity, by checking the entity name

### `removeZoneTarget(target)`
Triggers removal of a zone(Box/Circle) target by calling the target's name/id

### `triggerNotify(title, message, type, src)`
Handles notifications for the script called from either the server or client

Supports:
- `okok`
- `qb`
- `ox`
- `gta`
- `esx`

```lua
triggerNotify(
	title = "Notification Title",		-- Usually 'nil' in my scripts, supports notifications with titles
	message = "Notification Message",	-- The notification's message
	type = "success"					-- The type of notification, depends on the supporting script
	src = 1,							-- If in the server, this is required to send to player
)
```

### `drawText(image, input, style)`
This handles calling drawText functions

Supports:
- `gta`
- `qb`
- `ox`
- `esx`

```lua
drawText(
	187,								-- Very specific for adding blip images to drawtexts, usually nil
	{
		"Line 1",						-- Supports multiple lines, helpful for displaying button prompts
		"Line 2",
	},
	"g"									-- Sets colour of text after a ":" when using GTA drawtext
)
```

### `hideText()`
Simply used to hide drawText prompts when not needed anymore

### `createCallback(callbackName, funct)`
This is my attempt at making multiframework server callbacks by using their provided events

(Only works server side)

```lua
createCallback(
	"jimsCallback", 					-- Callback event name, needs to be something that isn't already set
	function()

	end)
end
```

### `triggerCallback(callBackName, value)`
This is an attempt at a mutliframework callback

### `onPlayerLoaded(func)`
This is a multiframework event that is triggered when a player has fully loaded their character in

```lua
onPlayerLoaded(
	function()
		print("Player Loaded In!")
	end
)
```

### `createInput(title, opts)`

### `searchCar(vehicle)`

This function was made for `jim-mechanic` but can be used in other instances

I searches the model name of a currently spawned vehicle and retrieves info about it

It is smart, in terms of, if you use this multiple times it reteives the previously found info instead of searching again

It retrieves data from your vehicles.lua/database:
- `name` for example: "Zentorno Pegassi"
- `price` for example: 100000
- `class` this converts the class number to a String, for example: if the class is 10 it converts this to "Off-road"

### `getVehicleProperties(vehicle)`
Gets the current properties of the vehicle in a table

### `setVehicleProperties(vehicle, props)`
Set's the vehicles properites using the `props` table provided

### `checkDifferences(vehicle, newProps)`
This function is used by `setVehicleProperties`

It determine's what differences there are between the current vehicle and the new set of properites

If there are differences, return `true`

### `RegisterNetEvent(GetCurrentResourceName()..":server:ChargePlayer", function(cost, type, newsrc)`
This event is made to REMOVE money from a player

It can be called from client with `TriggerServerEvent`

Also can be called from server with `TriggerEvent` and a source id in `newsrc`

The name of the event uses `GetCurrentResourceName()` so it doesn't double up results with other scripts
```lua
cost = 100 -- The amount of money to be removed
type = "cash" or "card" -- The type of money that should be removed
newsrc = 1			-- The source of the player, must be nil if calling from client
```

## `RegisterNetEvent(GetCurrentResourceName()..":server:FundPlayer", function(fund, type, newsrc)`
This event is made to ADD money from a player

It can be called from client with `TriggerServerEvent`

Also can be called from server with `TriggerEvent` and a source id in `newsrc`

The name of the event uses `GetCurrentResourceName()` so it doesn't double up results with other scripts
```lua
fund = 100 -- The amount of money to be added
type = "cash" or "card" -- The type of money that should be added
newsrc = 1			-- The source of the player, must be `nil` if calling from client
```

### `createUseableItem(item, funct)`
This is a server side event to make an item usable

Note: If using ox-inv and the item info has event info, this will be ignored

```lua
createUseableItem(
	"lockpick",			-- The item you want to make usable
	function(source, item)
		TriggerClientEvent("lolhi", source, { lol = item.name }),
	end
)
```

### `hasJob(job, source, grade)`
This is an event that makes checking if the player has the requested job simple

It works both client side and server side

returns `true` or `false` and if they are on duty or not
```lua
local hasjob, duty =
	hasJob(
		"mechanic",			-- the job role
		1,					-- the source id of the player, set to nil if on client
		3,					-- the required grade of the player, can be nil to check job
	)
```

### `getPlayer(source)`
This retrieves basic info of the player

works client side and server side
Retrieves:
- Players Name
- Players Current Cash
- Players Current Bank Balance

```lua
local PlayerInfo =
	getPlayer(
		1				-- The
	)
print(json.encode(PlayerInfo, { indent = true })
```

### `registerCommand(command, options)`
This is a server side event that uses
- `ox_lib`'s - `lib.addCommand`
- `qb-core`'s - `QBCore.Commands.Add`

Example:
```lua
registerCommand(
	"hello",			-- /hello the command to be used
	"Print 'hello world'",			-- text to show in chat
	{ name = "lol", help = "hi }, 	-- Help text for the command
	false,
	function()						-- Function to be ran when the command is triggered
		print("Hello World")
	end,
	"admin",						-- the restriction, can be nil
)
```

### `invImg(item)`
This is used mainly for menu's to retrieve the item images

It detects what inventory you are using and automatically generates an `nui://` link

```lua
local imgLink = invImg("lockpick")
print(imgLink)
```

### `registerStash(name, label, slots, weight)`
This is a serverside function used to register a new stash in `ox_inventory` and `qs-inventory`

```lua
registerStash(
	"newStash",				-- The stash name/ID, this is used to open it later
	"New created Stash",	-- The name of the stash that shows in inventories
	50,						-- The amount of slots in the inventory
	4000000,				-- The max weight in the inventory
)
```

### `loadModel(model)`
This loads the requested model into the memory cache to help spawning of props
- Checks if the model exists in the server
- Attempts to load the model with a timeout, if not loaded, sends warning

### `unloadModel(model)`
This unloads a model to help clear the memory cache and help optimization
- Recommended to run after spawning a prop

### `loadAnimDict(animDict)`
This loads the requested animDict into the memory cache to help loading anims
- Checks if the dict exists in the server

### `unloadAnimDict(animDict)`
This unloads the animDict to help clear the memory cache and help optimization
- Recommended to run after running an animation

### `loadPtfxDict(ptFxName)`
This loads the requested ptFx dict into the memory cache to help loading particle effects
- Skips if the effect is alredy loaded

### `unloadPtfxDict(dict)`
This unloads a particle effect to help clear the memory cache and help optimization
- Recommended to run after running an ptfx

### `loadTextureDict(dict)`
This loads the requested texture dictionary into memory

### `countTable(table)`
This is a simple function to count how many entires are in a table, for if your table keys aren't numbered
```lua
local table = {
	["tableentry"] = true,
	["anotherentry"] = true,
}
print("countTable", countTable(table))
```

### `pairsByKeys(t)`
Searches through a table alphabetically instead of randomly

This is an optional function made to replace:
```lua
for k, v in pairs(table) do end
```
with:
```lua
for k, v in pairsByKeys(table) do end
```

### `playAnim(animDict, animName, duration, flag, ped)`
A simplified version of `TaskPlayAnim()`

Has some settings already set and basic ones ready to change

Loads the animDict automatically with `loadAnimDict()`
```lua
playAnim(
	animDict,	-- The animation dictionary
	animName, 	-- The animation's name
	duration,	-- How far into the animation it should stop
	flag, 		-- The animation flag
	ped,		-- Optional, for if you want any one other than the player to do the animation
)
```

### `stopAnim(animDict, animName, ped)`
Similar to `StopAnimTask()`

Made to stop the given animation with being able to choose which ped
```lua
stopAnim(
	animDict,	-- The animation dictionary
	animName, 	-- The animation's name
	ped,		-- Optional, for if you want any one other than the player to do the animation
)
```
### `makeVeh(model, coords)`

### `makePed(model, coords, freeze, collision, scenario, anim, synced)`

### `makeProp(data, freeze, synced)`

### `instantLookEnt(ent, ent2)`
This function forcibly changes `ent`'s heading to face `ent2`
Helpful for animations

### `lookEnt(entity)`
This function attempts to slowly turn the player to the given entity/coords

Accepts either a `entity ID` or `vector3`

### `destroyProp(entity)`
Attempts to remove a spawned prop

If its attached to a player it attempts to to detatch it first

### `pushVehicle(entity)`
This attempts to make the current entity(vehicle) network controlled

This helps with syncing it with other players (used in jim-mechanic alot)

### `ensureNetToVeh(vehNetId)`
This was created to get around fivem's warnings of failing to get network objects

Although these warnings mean't nothing, it is annoying

This is made to replace the native `NetToVeh()` but checking first if it exists


---








