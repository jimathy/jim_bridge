--[[
    Duty & Interaction Utilities Module
    --------------------------------------
    This module provides functions related to:
      • Determining boss roles from Jobs and Gangs tables.
      • Checking a player's job and duty status.
      • Toggling duty state.
      • Simulating player interactions such as hand washing, using toilets/urinals,
        and teleporting via doors.
]]

-------------------------------------------------------------
-- Global Duty Status
-------------------------------------------------------------
-- This attempts to sync up with the players framework onDuty variable
-- This stops the script getting confused when one is false and one is true
onDuty = false

if not isServer() then
    onPlayerLoaded(function()
        onDuty = getPlayer().onDuty
    end, true)
end

-------------------------------------------------------------
-- Boss Role Detection
-------------------------------------------------------------

--- Scans the 'Jobs' and 'Gangs' tables to identify roles classified as bosses.
---
--- Iterates through the specified role's grades in the Jobs or Gangs table and returns
--- a table mapping the role to the lowest grade number that qualifies as a boss (isboss or bankAuth).
---
--- @param role string The job or gang role to check.
--- @return table table A table with the role mapped to its boss grade number.
---
--- @usage
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
            if info.isboss or info.bankAuth or info.isBoss then
                boss[role] = boss[role] and math.min(boss[role], tonumber(grade)) or tonumber(grade)
            end
        end
    end
    return boss
end

-------------------------------------------------------------
-- Job & Duty Checks
-------------------------------------------------------------

--- Checks if the player has a specific job (or gang) and is on duty.
---
--- Verifies whether the player possesses the specified role. If the role is defined in the Jobs table,
--- it also checks that the player is clocked in (onDuty). If the check fails, a notification is sent.
---
--- @param job string The job or gang to check.
--- @return boolean Returns true if the player meets the criteria; false otherwise.
---
--- @usage
--- ```lua
--- if jobCheck("mechanic") then
---     -- Allow mechanic features.
--- else
---     -- Deny access.
--- end
--- ```
function jobCheck(job)
    local canDo = true
    if Jobs[job] then
        if not hasJob(job) or not getPlayer().onDuty then
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
--- Switches the player's duty state between on-duty and off-duty. If using QBcore,
--- it triggers the appropriate server event. Otherwise, it manually toggles the onDuty variable and notifies the player.
---
--- @usage
--- ```lua
--- toggleDuty()  -- Player receives a notification of their new duty status.
--- ```
function toggleDuty()
    if isStarted(QBExport) or isStarted(QBXExport) then
        TriggerServerEvent("QBCore:ToggleDuty")
        Wait(100)
        onDuty = getPlayer().onDuty
    elseif isStarted(RSGExport) then
        TriggerServerEvent("RSGCore:ToggleDuty")
        Wait(100)
        onDuty = getPlayer().onDuty
    else
        if onDuty then
            triggerNotify(nil, "Now on duty", "success")
        else
            triggerNotify(nil, "Now off duty", "success")
        end
    end
end

-- Framework specific functions to keep duty status synced
RegisterNetEvent("QBCore:Client:OnJobUpdate", function(JobInfo) onDuty = JobInfo.onduty end)
RegisterNetEvent("QBCore:Client:SetDuty", function(duty) onDuty = duty end)

RegisterNetEvent("qbx_core:client:onJobUpdate", function(JobInfo) onDuty = JobInfo.onduty end)

RegisterNetEvent("RSGCore:Client:OnJobUpdate", function(JobInfo) onDuty = JobInfo.onduty end)
RegisterNetEvent("RSGCore:Client:SetDuty", function(duty) onDuty = duty end)

-------------------------------------------------------------
-- Interaction Functions
-------------------------------------------------------------

--- Initiates the hand-washing action for the player.
---
--- Triggers an animation and a progress bar to simulate hand washing at the specified coordinates.
--- On success, it notifies the player; if cancelled, it sends an error notification.
---
--- @param data table A table containing:
---     - coords (vector3): The location where the hand-washing action occurs.
---
--- @usage
--- ```lua
--- washHands({ coords = vector3(200.0, 300.0, 40.0) })
--- ```
function washHands(data)
    local ped = PlayerPedId()
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
        triggerNotify(nil, Loc[Config.Lan].error["cancel"], "error")
    end
    ClearPedTasks(ped)
end

--- Handles the player's interaction with a toilet or urinal.
---
--- Manages animations and progress bars for using a urinal or a toilet. If the action is successful,
--- it triggers the appropriate server event (urinal usage) or notifies the player if cancelled.
---
--- @param data table A table containing:
---     - urinal (boolean): `true if using a urinal; false for a toilet.`
---     - sitcoords (vector4): `Coordinates and heading for seating when using a toilet.`
---
--- @usage
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
            triggerNotify(nil, Loc[Config.Lan].error["cancelled"], "error")
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
            triggerNotify(nil, Loc[Config.Lan].error["cancelled"], "error")
        end
    end
end

--- Teleports the player to specified coordinates with a fade effect.
---
--- Fades the screen out, moves the player to the target coordinates, sets the player's heading,
--- then fades the screen back in. Commonly used for door interactions or teleportation points.
---
--- @param data table A table containing:
---   - telecoords (vector4): The target coordinates and heading.
---
--- @usage
--- ```lua
--- useDoor({ telecoords = vector4(215.76, -810.12, 29.73, 90.0) })
--- ```
function useDoor(data)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    SetEntityCoords(PlayerPedId(), data.telecoords.xyz, 0, 0, 0, false)
    SetEntityHeading(PlayerPedId(), data.telecoords.w)
    DoScreenFadeIn(1000)
    Wait(100)
end


function openBossMenu(isGang, group)
    if isStarted("qb-management") then
        if isGang then
            TriggerEvent("qb-gangmenu:client:OpenMenu")
        else
            TriggerEvent("qb-bossmenu:client:OpenMenu")
        end
    elseif isStarted("qbx_management") then
        exports["qbx_management"]:OpenBossMenu(isGang and "gang" or "job")

    elseif isStarted("esx_society") then
        TriggerEvent('esx_society:openBossMenu', group, function() end, { wash = false })
    end
end