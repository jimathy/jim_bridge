(# Jim_Bridge

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

### `openMenu(Menu, data)`

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
They are also automatically removed when the script is stopped (for helping 
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

## `triggerNotify(title, message, type, src)`
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

## `drawText(image, input, style)`
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

## `hideText()`
Simply used to hide drawText prompts when not needed anymore

## `createCallback(callbackName, funct)`
This is my attempt at making multiframework server callbacks by using their provided events
(Only works server side)

```lua
createCallback(
	"jimsCallback", 					-- Callback event name, needs to be something that isn't already set
	function()

	end)
end
```

## `triggerCallback(callBackName, value)`
This is an attempt at a mutliframework callback

## `onPlayerLoaded(func)`
This is a multiframework event that is triggered when a player has fully loaded their character in

```lua
onPlayerLoaded(
	function()
		print("Player Loaded In!")
	end
)
```

---








