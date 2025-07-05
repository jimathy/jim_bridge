# Jim_Bridge

This script is intended to be used with my all my scripts (soon)

It was started due to wanting to bring the same features from some scripts into others with minimal work and without multiple updates fer script

It BRIDGES frameworks and cores together through this script and does it best to detect what is being used to automate the process
- Having certain functions in one place makes it easier to update, enchance and fix things already in place
- This brings the possibility of branching to mutliple frameworks as I've added some already:
    - `"qb-core"`
    - `"qbx-core"`
    - `"ox_core"`
    - `"es_extended"` - requires ox_lib and ox_inventory
    - `"rsg-core"` - basic support for RedM's RSG Core

All of my scripts will use this script and be added as a dependancy

This was originally designed to be used for my scripts but has grown into a whole framework of unified functions that anyone can use for their own, I encourage it

------

## I want this script to grow with help of others who know more about other cores, I'm not a book of framework knowledge
This script was designed by me through over a year of research and testing.
Some of it of it hasn't been personally tested but the information has been gathered through documentation on other scripts
I hope it works as well I intend, but feel free to do pull requests if you know how to fix an issue

(Please also keep it to a similar format to prevent breakages in other scripts)

------

## Installation

The installation of this script is simple
- REMOVE `-main` from the folder name, like any other github hosted script
- It just needs to start before any script that requires it
- It can start before core scripts if you want
- For example with `qb-core` I personally place this script in `resources > [standalone]`

### Optional

I've added the ability to add override server convars to your server.cfg
- This can be used to ensure you don't have silly mistakes like forgetting to change what inventory system you use
- Also it can force debug mode off, to ensure your live server doesn't accidently get polyzones and debug information showing
- This isn't required but helpful if you are like me

```
# Jim Config Settings
# These optional but forces settings for all jim scripts
#-------
# Add this to your live server.cfg and set to true to force debug mode off
# Set to false if to dev server to allow debug mode
setr jim_DisableDebug true
setr jim_DisableEventDebug true

# Force the default setting for what framework scripts should be used
setr jim_menuScript qb              # qb, ox, gta, lation
setr jim_notifyScript gta           # qb, ox, gta, esx, okok, red, lation
setr jim_drawTextScript qb          # qb, ox, gta, esx, lation
setr jim_progressBarScript qb       # qb, ox, gta, esx, lation
setr jim_skillCheckScript qb        # qb, ox, gta, lation
setr jim_dontUseTarget false         # Set to true to disable target systems and use draw text 3d
```

-----

## Support for different frameworks and scripts

In `starter.lua` is the list of script folder names, this is already setup but this is for people who have customised/renamed their cores or scripts

# WIP
## Documentation

For organised documentation please see the new `documentation` folder within this resource

## Usage

In your own resource, simply call the desired function exported from `jim_bridge`. Each function is built to work across multiple frameworks, offering compatibility and consistency.

```lua
-- Example usage:
createCallback("myCallback", function(data)
    print("Callback received:", data)
end)

triggerCallback("myCallback", "Hello World")
```

---