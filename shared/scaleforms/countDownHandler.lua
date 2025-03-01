CountdownHandler = {}
CountdownHandler.__index = CountdownHandler

function CountdownHandler:new()
    local self = setmetatable({}, CountdownHandler)
    self.scaleform = nil
    self.renderCountdown = false
    self.colour = { r = 255, g = 255, b = 255, a = 255 }
    return self
end

function CountdownHandler:Load()
    if self.scaleform then return end
    self.scaleform = RequestScaleformMovie("COUNTDOWN")
    while not HasScaleformMovieLoaded(self.scaleform) do
        Wait(0)
    end
end

function CountdownHandler:Dispose()
    if self.scaleform then
        SetScaleformMovieAsNoLongerNeeded(self.scaleform)
        self.scaleform = nil
    end
end

function CountdownHandler:Update()
    if self.scaleform then
        DrawScaleformMovieFullscreen(self.scaleform, 255, 255, 255, 255, 0)
    end
end

function CountdownHandler:ShowMessage(message)
    local r, g, b, a = self.colour.r, self.colour.g, self.colour.b, self.colour.a

    BeginScaleformMovieMethod(self.scaleform, "SET_MESSAGE")
    ScaleformMovieMethodAddParamPlayerNameString(message)
    ScaleformMovieMethodAddParamInt(r)
    ScaleformMovieMethodAddParamInt(g)
    ScaleformMovieMethodAddParamInt(b)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(self.scaleform, "FADE_MP")
    ScaleformMovieMethodAddParamPlayerNameString(message)
    ScaleformMovieMethodAddParamInt(r)
    ScaleformMovieMethodAddParamInt(g)
    ScaleformMovieMethodAddParamInt(b)
    EndScaleformMovieMethod()
end

--- Starts the countdown with the specified number and HUD color.
---
--- @param number number|nil The starting number for the countdown. Defaults to 3.
--- @param hudColour number|nil The HUD color index. Defaults to 18.
---
--- @return boolean `true` when the countdown has finished.
---
--- @usage
--- ```lua
--- -- Start a countdown of 5 seconds with HUD color 25
--- if CountdownHandler:Start(5, 25) then
---     print("Countdown Complete")
--- end
--- ```
function CountdownHandler:Start(number, hudColour)
    local finished = false
    number = number or 3
    hudColour = hudColour or 18

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

    -- Begin the countdown
    CreateThread(function()
        local currentNumber = number
        while currentNumber > 0 do
            -- Play countdown sound
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

-- Create an instance of CountdownHandler
CountdownHandler = CountdownHandler:new()

-- Optional: Register an event to start the countdown
RegisterNetEvent(getScript()..":startCountdown", function(number, hudColour)
    CountdownHandler:Start(number, hudColour)
end)

return CountdownHandler