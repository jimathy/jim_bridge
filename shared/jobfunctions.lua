-- Global variable to track duty status
onDuty = false

--- Scans the 'Jobs' and 'Gangs' tables to identify roles classified as Bosses.
---
--- This function iterates through the specified role's grades within the `Jobs` or `Gangs` tables.
--- It identifies which grades are marked as bosses (`isboss`) or have bank authorization (`bankAuth`).
--- The function returns a table where each role maps to the lowest grade number that qualifies as a boss.
---
---@param role string The name of the job or gang role to check for boss grades.
---
---@return table table A table containing roles mapped to their respective boss grade numbers.
---
---@usage
--- ```lua
--- local bosses = makeBossRoles("police")
--- if bosses["police"] then
---     print("Police role has a boss grade.")
--- end
--- ```
function makeBossRoles(role)
    local boss = {}
    local data = (Jobs and Jobs[role]) or (Gangs and Gangs[role])
    if data then
        for grade, info in pairs(data.grades) do
            if info.isboss or info.bankAuth then
                boss[role] = boss[role] and math.min(boss[role], tonumber(grade)) or tonumber(grade)
            end
        end
    end
    return boss
end

--- Checks if the player has a specific job and is on duty.
---
--- This function verifies whether the player possesses the specified job and, if applicable,
--- whether they are currently on duty. It provides a notification if the player fails these checks.
---
---@param job string The name of the job or gang to check.
---
---@return boolean Returns `true` if the player has the job (and is on duty if required), otherwise `false`.
---
---@usage
--- ```lua
--- if jobCheck("mechanic") then
---     -- Allow access to mechanic-related features
--- else
---     -- Deny access or notify the player
--- end
--- ```
function jobCheck(job)
    canDo = true
    if Jobs[job] then
        if not hasJob(job) or not onDuty then
            triggerNotify(nil, Loc[Config.Lan].error["not_clockedin"])
            canDo = false
        end
    end
    if Gangs[job] then
        if not hasJob(job) then
            canDo = false
        end
    end
    return canDo
end

--- Toggles the player's duty status.
---
--- This function switches the player's duty state between on-duty and off-duty.
--- It integrates with QBcore's duty system if available; otherwise, it manually toggles the `onDuty` variable
--- and sends a notification to the player about their new duty status.
---
---@usage
--- ```lua
--- toggleDuty()
--- -- Player will receive a notification indicating their new duty status
--- ```
function toggleDuty()
    if isStarted(QBExport) or isStarted(QBXExport) then
        TriggerServerEvent("QBCore:ToggleDuty")
    else
        onDuty = not onDuty
        if onDuty then
            triggerNotify(nil, "Now on duty", "success")
        else
            triggerNotify(nil, "Now off duty", "success")
        end
    end
end

--- Initiates the hand-washing action for the player.
---
--- This function triggers an animation and a progress bar to simulate the player washing their hands.
--- Upon completion, it sends a success notification. If the action is canceled, it notifies the player of the cancellation.
---
---@param data table A table containing the coordinates where the hand-washing action takes place.
--- - **coords** (`vector3`): The position where the hand-washing animation and camera are focused.
---
---@return void
---
---@usage
--- ```lua
--- washHands({ coords = vector3(200.0, 300.0, 40.0) })
--- -- Player will perform the hand-washing animation at the specified location
--- ```
function washHands(data) local ped = PlayerPedId()
    lookEnt(data.coords)
    local cam = createTempCam(ped, data.coords)
    if progressBar({
        label = Loc[Config.Lan].progressbar["progress_washing"],
        time = 5000,
        cancel = true,
        dict = "mp_arresting",
        anim = "a_uncuff",
        flag = 32,
        icon = "fas fa-hand-holding-droplet",
        cam = cam
    }) then
        triggerNotify(nil, Loc[Config.Lan].success["washed_hands"], "success")
    else
        triggerNotify(nil, Loc[Config.Lan].error["cancel"], 'error')
    end
    ClearPedTasks(ped)
end

--- Handles the player's interaction with a toilet or urinal.
---
--- This function manages the animations and progress bars associated with using a toilet or urinal.
--- Depending on whether the interaction is with a urinal (`data.urinal`), it plays the appropriate animation
--- and triggers server events upon successful completion. If the action is canceled, it notifies the player.
---
---@param data table A table containing data about the toilet interaction.
--- - **urinal** (`boolean`): Indicates whether the interaction is with a urinal (`true`) or a toilet (`false`).
--- - **sitcoords** (`vector4`): The coordinates and heading for the seating animation when using a toilet.
---
---@usage
--- ```lua
--- useToilet({ urinal = true })
--- -- Player uses a urinal with corresponding animations and notifications
---
--- useToilet({ urinal = false, sitcoords = vector4(215.76, -810.12, 29.73, 90.0) })
--- -- Player sits down to use a toilet with corresponding animations and notifications
--- ```
function useToilet(data)
    if data.urinal then
        if progressBar({
            label = "Using Urinal",
            time = 5000,
            cancel = true,
            dict = "misscarsteal2peeing",
            anim = "peeing_loop",
            flag = 32
        }) then
            TriggerServerEvent(getScript().."server:Urinal")
        else
            lockInv(false)
            triggerNotify(nil, Loc[Config.Lan].error["cancelled"], 'error')
        end
    else
        TaskStartScenarioAtPosition(PlayerPedId(), "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", data.sitcoords.x, data.sitcoords.y, data.sitcoords.z, data.sitcoords[4], 0, 1, true)
        if progressBar({
            label = "Using Toilet",
            time = 10000,
            cancel = true
        }) then
            TriggerServerEvent(getScript().."server:Urinal")
            ClearPedTasks(PlayerPedId())
        else
            lockInv(false)
            triggerNotify(nil, Loc[Config.Lan].error["cancelled"], 'error')
        end
    end
end

--- Teleports the player to specified coordinates with a fade effect.
---
--- This function fades the screen out, moves the player to the target coordinates (`data.telecoords`),
--- sets the player's heading, and then fades the screen back in. It's commonly used for door interactions
--- or teleportation points within the game.
---
---@param data table A table containing teleportation data.
--- - **telecoords** (`vector4`): The target coordinates and heading for the teleportation.
---
---@usage
--- ```lua
--- useDoor({ telecoords = vector4(215.76, -810.12, 29.73, 90.0) })
--- -- Player is teleported to the specified coordinates with a fade effect
--- ```
function useDoor(data)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    SetEntityCoords(PlayerPedId(), data.telecoords.xyz, 0, 0, 0, false)
    SetEntityHeading(PlayerPedId(), data.telecoords.w)
    DoScreenFadeIn(1000)
    Wait(100)
end
