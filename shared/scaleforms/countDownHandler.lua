--[[
    CountdownHandler Module
    -------------------------
    This module provides a countdown HUD using a Scaleform movie ("COUNTDOWN").
    It handles loading, updating, and disposing of the scaleform, as well as
    playing sounds and displaying messages for each countdown tick.

    TriggerNetEvent(getScript()..":startCountdown", 5, 25)
]]

CountdownHandler = {}
CountdownHandler.__index = CountdownHandler

--- Creates a new CountdownHandler instance.
--- @return table table A new CountdownHandler object.
function CountdownHandler:new()
    local self = setmetatable({}, CountdownHandler)
    self.scaleform = nil
    self.renderCountdown = false
    self.colour = { r = 255, g = 255, b = 255, a = 255 }
    return self
end

--- Loads the "COUNTDOWN" scaleform movie.
function CountdownHandler:Load()
    if self.scaleform then
        return
    end
    self.scaleform = RequestScaleformMovie("COUNTDOWN")
    while not HasScaleformMovieLoaded(self.scaleform) do
        Wait(0)
    end
end

--- Disposes of the currently loaded scaleform movie.
function CountdownHandler:Dispose()
    if self.scaleform then
        SetScaleformMovieAsNoLongerNeeded(self.scaleform)
        self.scaleform = nil
    end
end

--- Updates the HUD by drawing the scaleform movie fullscreen.
function CountdownHandler:Update()
    if self.scaleform then
        DrawScaleformMovieFullscreen(self.scaleform, 255, 255, 255, 255, 0)
    end
end

--- Displays a message on the countdown HUD.
--- @param message string The message to display.
function CountdownHandler:ShowMessage(message)
    local r, g, b, a = self.colour.r, self.colour.g, self.colour.b, self.colour.a

    -- Set the message in the scaleform.
    BeginScaleformMovieMethod(self.scaleform, "SET_MESSAGE")
    ScaleformMovieMethodAddParamPlayerNameString(message)
    ScaleformMovieMethodAddParamInt(r)
    ScaleformMovieMethodAddParamInt(g)
    ScaleformMovieMethodAddParamInt(b)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()

    -- Trigger a fade effect (optional).
    BeginScaleformMovieMethod(self.scaleform, "FADE_MP")
    ScaleformMovieMethodAddParamPlayerNameString(message)
    ScaleformMovieMethodAddParamInt(r)
    ScaleformMovieMethodAddParamInt(g)
    ScaleformMovieMethodAddParamInt(b)
    EndScaleformMovieMethod()
end

--- Starts the countdown HUD.
--- @param number number|nil The starting number for the countdown (default: 3).
--- @param hudColour number|nil The HUD colour index (default: 18).
--- @return boolean boolean True when the countdown has finished.
--- @usage
--- ```lua
--- if CountdownHandler:Start(5, 25) then
---     -- When run in an if statement, the script will wait until its finished to continue
---     print("Countdown Complete")
--- end
--- ```
function CountdownHandler:Start(number, hudColour)
    local finished = false
    number = number or 3
    hudColour = hudColour or 18

    -- Get HUD colour using framework function; alternatives could be added here.
    local r, g, b, a = GetHudColour(hudColour)
    self.colour = { r = r, g = g, b = b, a = a }

    self:Load()

    self.renderCountdown = true
    CreateThread(function()
        while self.renderCountdown do
            Wait(0)
            self:Update()
        end
    end)

    -- Countdown logic
    CreateThread(function()
        local currentNumber = number
        while currentNumber > 0 do
            playSound("Count")
            self:ShowMessage(tostring(currentNumber))
            Wait(1000)
            currentNumber = currentNumber - 1
        end

        playSound("Go")
        self:ShowMessage("GO")
        finished = true

        Wait(1000)
        self.renderCountdown = false
        self:Dispose()
        finished = true
    end)

    while not finished do Wait(10) end
    return true
end

-- Create a singleton instance of CountdownHandler.
CountdownHandler = CountdownHandler:new()

-- Register an event to start the countdown.
RegisterNetEvent(getScript()..":startCountdown", function(number, hudColour)
    CountdownHandler:Start(number, hudColour)
end)

return CountdownHandler