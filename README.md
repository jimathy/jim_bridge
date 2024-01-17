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