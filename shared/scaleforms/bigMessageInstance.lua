--[[
    BigMessage Module
    -----------------
    This module provides a flexible way to display large, attention-grabbing messages
    on screen using a Scaleform movie ("MP_BIG_MESSAGE_FREEMODE"). It supports multiple
    message types (mission passed, colored shard, old-style, simple shard, rank-up, weapon purchased,
    and large multiplayer messages), including customizable transitions and durations.
]]

BigMessage = {}
BigMessage.__index = BigMessage

--- Creates a new BigMessage instance.
--- @return table table A new BigMessage object.
function BigMessage:new()
    local self = setmetatable({}, BigMessage)
    self.scaleform = nil
    self.startTime = 0
    self.duration = 0
    self.transition = "TRANSITION_OUT"
    self.transitionDuration = 0.15
    self.transitionPreventAutoExpansion = false
    self.transitionExecuted = false
    self.manualDispose = false
    self.isDisplaying = false
    return self
end

--- Loads the Scaleform movie if it has not been loaded yet.
function BigMessage:Load()
    if self.scaleform then return end
    self.scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")
    while not HasScaleformMovieLoaded(self.scaleform) do
        Wait(0)
    end
end

--- Disposes of the Scaleform movie.
--- If manualDispose is true, executes a transition before disposing.
function BigMessage:Dispose()
    if not self.scaleform then return end

    if self.manualDispose then
        BeginScaleformMovieMethod(self.scaleform, self.transition)
        ScaleformMovieMethodAddParamBool(false)
        ScaleformMovieMethodAddParamFloat(self.transitionDuration)
        ScaleformMovieMethodAddParamBool(self.transitionPreventAutoExpansion)
        EndScaleformMovieMethod()

        -- Wait a fraction of the transition duration (in milliseconds)
        Wait((self.transitionDuration * 0.5) * 1000)
        self.manualDispose = false
    end

    self.startTime = 0
    self.transitionExecuted = false
    SetScaleformMovieAsNoLongerNeeded(self.scaleform)
    self.scaleform = nil
    self.isDisplaying = false
end

--- Updates the display by drawing the Scaleform movie fullscreen.
function BigMessage:Update()
    if not self.scaleform then return end

    DrawScaleformMovieFullscreen(self.scaleform, 255, 255, 255, 255, 0)

    if self.manualDispose then return end

    if self.startTime ~= 0 and (GetGameTimer() - self.startTime) > self.duration then
        if not self.transitionExecuted then
            BeginScaleformMovieMethod(self.scaleform, self.transition)
            ScaleformMovieMethodAddParamBool(false)
            ScaleformMovieMethodAddParamFloat(self.transitionDuration)
            ScaleformMovieMethodAddParamBool(self.transitionPreventAutoExpansion)
            EndScaleformMovieMethod()
            self.transitionExecuted = true
            -- Extend duration slightly for smooth transition
            self.duration = self.duration + ((self.transitionDuration * 0.5) * 1000)
        else
            self:Dispose()
        end
    end
end

--- Sets the transition properties for disposing the message.
--- @param transition string The transition function name (default: "TRANSITION_OUT").
--- @param duration number The duration for the transition (default: 0.4).
--- @param preventAutoExpansion boolean Whether to prevent auto-expansion (default: true).
function BigMessage:SetTransition(transition, duration, preventAutoExpansion)
    self.transition = transition or "TRANSITION_OUT"
    self.transitionDuration = duration or 0.4
    self.transitionPreventAutoExpansion = preventAutoExpansion or true
end

--- Starts a thread to continuously update the HUD until the message is done.
function BigMessage:StartUpdate()
    if self.isDisplaying then return end

    self.isDisplaying = true
    CreateThread(function()
        while self.isDisplaying do
            Wait(0)
            self:Update()
        end
    end)
end

--- Displays a mission passed message.
--- @param msg string The message to display.
--- @param duration number|nil The duration (in milliseconds) to display the message (default: 5000).
--- @param manualDispose boolean|nil Whether to manually dispose the Scaleform after display (default: false).
--- @usage
--- ```lua
--- BigMessage:ShowMissionPassedMessage("MISSION PASSED", 5000)
--- ```
function BigMessage:ShowMissionPassedMessage(msg, duration, manualDispose)
    duration = duration or 5000
    self:Load()
    self.startTime = GetGameTimer()
    self.manualDispose = manualDispose or false

    BeginScaleformMovieMethod(self.scaleform, "SHOW_MISSION_PASSED_MESSAGE")
    ScaleformMovieMethodAddParamPlayerNameString(msg)
    ScaleformMovieMethodAddParamPlayerNameString("")
    ScaleformMovieMethodAddParamInt(100)
    ScaleformMovieMethodAddParamBool(true)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()

    self.duration = duration
    self:StartUpdate()
end

--- Displays a colored shard message.
--- @param msg string The main message.
--- @param desc string The description text.
--- @param textColor number The text color index.
--- @param bgColor number The background color index.
--- @param duration number|nil Duration in milliseconds (default: 5000).
--- @param manualDispose boolean|nil Whether to manually dispose the Scaleform (default: false).
function BigMessage:ShowColoredShard(msg, desc, textColor, bgColor, duration, manualDispose)
    duration = duration or 5000
    self:Load()
    self.startTime = GetGameTimer()
    self.manualDispose = manualDispose or false

    BeginScaleformMovieMethod(self.scaleform, "SHOW_SHARD_CENTERED_MP_MESSAGE")
    ScaleformMovieMethodAddParamPlayerNameString(msg)
    ScaleformMovieMethodAddParamPlayerNameString(desc)
    ScaleformMovieMethodAddParamInt(bgColor)
    ScaleformMovieMethodAddParamInt(textColor)
    EndScaleformMovieMethod()

    self.duration = duration
    self:StartUpdate()
end

--- Displays an old-style mission passed message.
--- @param msg string The message.
--- @param duration number|nil Duration in milliseconds (default: 5000).
--- @param manualDispose boolean|nil Whether to manually dispose (default: false).
function BigMessage:ShowOldMessage(msg, duration, manualDispose)
    duration = duration or 5000
    self:Load()
    self.startTime = GetGameTimer()
    self.manualDispose = manualDispose or false

    BeginScaleformMovieMethod(self.scaleform, "SHOW_MISSION_PASSED_MESSAGE")
    ScaleformMovieMethodAddParamPlayerNameString(msg)
    EndScaleformMovieMethod()

    self.duration = duration
    self:StartUpdate()
end

--- Displays a simple shard message.
--- @param msg string The main message.
--- @param subtitle string The subtitle text.
--- @param duration number|nil Duration in milliseconds (default: 5000).
--- @param manualDispose boolean|nil Whether to manually dispose (default: false).
function BigMessage:ShowSimpleShard(msg, subtitle, duration, manualDispose)
    duration = duration or 5000
    self:Load()
    self.startTime = GetGameTimer()
    self.manualDispose = manualDispose or false

    BeginScaleformMovieMethod(self.scaleform, "SHOW_SHARD_CREW_RANKUP_MP_MESSAGE")
    ScaleformMovieMethodAddParamPlayerNameString(msg)
    ScaleformMovieMethodAddParamPlayerNameString(subtitle)
    EndScaleformMovieMethod()

    self.duration = duration
    self:StartUpdate()
end

--- Displays a rank-up message.
--- @param msg string The main message.
--- @param subtitle string The subtitle text.
--- @param rank number The rank level achieved.
--- @param duration number|nil Duration in milliseconds (default: 5000).
--- @param manualDispose boolean|nil Whether to manually dispose (default: false).
function BigMessage:ShowRankupMessage(msg, subtitle, rank, duration, manualDispose)
    duration = duration or 5000
    self:Load()
    self.startTime = GetGameTimer()
    self.manualDispose = manualDispose or false

    BeginScaleformMovieMethod(self.scaleform, "SHOW_BIG_MP_MESSAGE")
    ScaleformMovieMethodAddParamPlayerNameString(msg)
    ScaleformMovieMethodAddParamPlayerNameString(subtitle)
    ScaleformMovieMethodAddParamInt(rank)
    ScaleformMovieMethodAddParamPlayerNameString("")
    ScaleformMovieMethodAddParamPlayerNameString("")
    EndScaleformMovieMethod()

    self.duration = duration
    self:StartUpdate()
end

--- Displays a weapon purchased message.
--- @param bigMessage string The main message.
--- @param weaponName string The name of the weapon purchased.
--- @param weaponHash number The weapon hash.
--- @param duration number|nil Duration in milliseconds (default: 5000).
--- @param manualDispose boolean|nil Whether to manually dispose (default: false).
function BigMessage:ShowWeaponPurchasedMessage(bigMessage, weaponName, weaponHash, duration, manualDispose)
    duration = duration or 5000
    self:Load()
    self.startTime = GetGameTimer()
    self.manualDispose = manualDispose or false

    BeginScaleformMovieMethod(self.scaleform, "SHOW_WEAPON_PURCHASED")
    ScaleformMovieMethodAddParamPlayerNameString(bigMessage)
    ScaleformMovieMethodAddParamPlayerNameString(weaponName)
    ScaleformMovieMethodAddParamInt(weaponHash)
    ScaleformMovieMethodAddParamPlayerNameString("")
    ScaleformMovieMethodAddParamInt(100)
    EndScaleformMovieMethod()

    self.duration = duration
    self:StartUpdate()
end

--- Displays a large multiplayer message.
--- @param msg string The main message.
--- @param duration number|nil Duration in milliseconds (default: 5000).
--- @param manualDispose boolean|nil Whether to manually dispose (default: false).
function BigMessage:ShowMpMessageLarge(msg, duration, manualDispose)
    duration = duration or 5000
    self:Load()
    self.startTime = GetGameTimer()
    self.manualDispose = manualDispose or false

    BeginScaleformMovieMethod(self.scaleform, "SHOW_CENTERED_MP_MESSAGE_LARGE")
    ScaleformMovieMethodAddParamPlayerNameString(msg)
    ScaleformMovieMethodAddParamPlayerNameString("")
    ScaleformMovieMethodAddParamInt(100)
    ScaleformMovieMethodAddParamBool(true)
    ScaleformMovieMethodAddParamInt(100)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(self.scaleform, "TRANSITION_IN")
    EndScaleformMovieMethod()

    self.duration = duration
    self:StartUpdate()
end

--- Displays a "Wasted" multiplayer message.
--- @param msg string The main message.
--- @param subtitle string The subtitle text.
--- @param duration number|nil Duration in milliseconds (default: 5000).
--- @param manualDispose boolean|nil Whether to manually dispose (default: false).
function BigMessage:ShowMpWastedMessage(msg, subtitle, duration, manualDispose)
    duration = duration or 5000
    self:Load()
    self.startTime = GetGameTimer()
    self.manualDispose = manualDispose or false

    BeginScaleformMovieMethod(self.scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
    ScaleformMovieMethodAddParamPlayerNameString(msg)
    ScaleformMovieMethodAddParamPlayerNameString(subtitle)
    EndScaleformMovieMethod()

    self.duration = duration
    self:StartUpdate()
end

--- Starts the update loop for displaying the message.
function BigMessage:StartUpdate()
    if self.isDisplaying then return end
    self.isDisplaying = true
    CreateThread(function()
        while self.isDisplaying do
            Wait(0)
            self:Update()
        end
    end)
end

-- Create an instance of BigMessage and return it.
BigMessage = BigMessage:new()

return BigMessage