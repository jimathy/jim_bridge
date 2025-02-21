-- IN NO WAY PERFECT -- ** Experimental debugging
function toggleDebug()
    Config.System.Debug = not Config.System.Debug
    print("Debug Prints = "..tostring(Config.System.Debug))
end
exports("toggleDebug", toggleDebug)

function getDebug() return Config.System.Debug end
exports("getDebug", getDebug)

local origRegisterNetEvent = RegisterNetEvent
local origTriggerEvent = TriggerEvent
local origTriggerServerEvent = TriggerServerEvent
local origTriggerClientEvent = TriggerClientEvent
local origExecuteCommand = ExecuteCommand
local origRegisterCommand = RegisterCommand
local origPairs = pairs
local origiPairs = ipairs

function getDebugInfo(info)
    local info = info
    local level = 2
    if info and info.short_src:match("scheduler.lua") then
        repeat
            info = debug.getinfo(level, "nSl")
            level += 1
            local found = false
            for _, v in pairs({
                "deffered.lua",
                "scheduler.lua",
                "_eventDebug.lua",
                "targets.lua",
                "init.lua",
                "MySQL.lua",
                "helpers.lua",
            }) do
                if info and info.short_src:match(v) then
                    found = true
                end
            end
        until not info or (info.short_src and found == false)
    end

    return " ^7[^3"..(info and info.short_src:match("^.+/(.+)$") or "unknown").."^7:^3"..(info and info.currentline or "unknown").."^7]"
end

--This is just a for debugging, not important, just announces which events are being registered triggered when these functions are used
function RegisterNetEvent(name, funct)
    if Config.System.EventDebug then
        if name:find("__ox_cb_") then
            print("^6Bridge^7: ^2Registered ^3"..(isServer() and "Server" or "Client").." ^2Callback^7: ^6"..name:gsub("__ox_cb_", ""):gsub("%:", "^7:^4").."^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        else
            print("^6Bridge^7: ^2Registering ^3"..(isServer() and "Server" or "Client").." ^2Net event^7: ^6"..name:gsub("%:", "^7:^4").."^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        end
    end
    origRegisterNetEvent(name, funct)
end

function TriggerEvent(name, ...)
    local data = {...}
    if Config.System.EventDebug then
        if name:find("__cfx_export") then
            print("^6Bridge^7: "..GetPrintTime().." ^2Triggering ^3"..(isServer() and "Server" or "Client").." ^2Export^7: ^6"..name:gsub("__cfx_export_", ""):gsub("%:", "^7:^4").."^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        else
            print("^6Bridge^7: "..GetPrintTime().." ^2Triggering ^3"..(isServer() and "Server" or "Client").." ^2Net event^7: ^6"..name:gsub("%:", "^7:^4").."^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        end
        for i, value in ipairs(data) do
            if value then
                local valueStr = (type(value) == "table" and json.encode(value) or tostring(value))
                print(string.format("^6Bridge^7: ^7[^3%d^7]: ^7(^5%s^7): %s".."^7", i, type(value), valueStr))
            end
        end    end
    origTriggerEvent(name, ...)
end

function TriggerServerEvent(name, ...) -- Client side, trigger a server event
    local data = {...}
    if Config.System.EventDebug then
        if name:find("__ox_cb") then
            print("^6Bridge^7: "..GetPrintTime().." ^2Triggered ^3Server ^2Callback: ^6"..name:gsub("__ox_cb_", "").."^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        else
            print("^6Bridge^7: "..GetPrintTime().." ^2Triggering ^3Server ^2Net event^7: ^6"..name:gsub("%:", "^7:^4").."^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        end
        for i, value in ipairs(data) do
            if value then
                local valueStr = (type(value) == "table" and json.encode(value) or tostring(value))
                print(string.format("^6Bridge^7: ^7[^3%d^7]: ^7(^5%s^7): %s".."^7", i, type(value), valueStr))
            end
        end    end
    origTriggerServerEvent(name, ...)
end

function TriggerClientEvent(name, ...) -- Server side, trigger a client event
    local data = {...}
    if Config.System.EventDebug then
        if name:find("__ox_cb") then
            print("^6Bridge^7: "..GetPrintTime().." ^2Triggered ^3Client ^2Callback: ^6"..name:gsub("__ox_cb_", "").."^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        else
            print("^6Bridge^7: "..GetPrintTime().." ^2Triggering ^3Client ^2Net event^7: ^6"..name:gsub("%:", "^7:^4").."^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        end
        for i, value in ipairs(data) do
            if value then
                local valueStr = (type(value) == "table" and json.encode(value) or tostring(value))
                print(string.format("^6Bridge^7: ^7[^3%d^7]: ^7(^5%s^7): %s".."^7", i, type(value), valueStr))
            end
        end    end
    origTriggerClientEvent(name, ...)
end

function RegisterCommand(command, funct, restrict)
    if Config.System.EventDebug then
        print("^6Bridge^7: ^2Registering ^2Command^7: /"..command.." ^7| ^4Funct^7: "..tostring(funct):gsub("function: ", "").." ^7| ^4Admin^7: "..(restict and "true" or "false")..getDebugInfo(debug.getinfo(2, "nSl")))
    end
    origRegisterCommand(command, funct, restrict)
end

function ExecuteCommand(comm) -- Client side, execute /command
    if Config.System.EventDebug then
        print("^6Bridge^7: "..GetPrintTime().." ^2Triggering ^3ExecuteCommand^7: /"..comm..getDebugInfo(debug.getinfo(2, "nSl")))
    end
    origExecuteCommand(comm)
end

function pairs(tbl)
    if not tbl then
        print("^1Error^7: ^1nil ^2for ^3pairs^7(), ^2setting to ^7{} ^2to prevent break^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        return origPairs({})
    end
    return origPairs(tbl)
end

function ipairs(tbl)
    local tbl = tbl
    if not tbl then
        if Config.System.EventDebug then
            print("^1Error^7: ^3iPairs^7() ^1nil ^2recieved^7, ^2setting to ^7{} ^2to prevent break^7"..getDebugInfo(debug.getinfo(2, "nSl")))
        end
        tbl = {}
    end
    return pairsByKeys(tbl) -- change to pairsByKeys for less errors
end

--[[
local origPrint = print
function print(...)
    origPrint(getDebugInfo(debug.getinfo(2, "nSl"))..":")
    origPrint(...)
end
]]