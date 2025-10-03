if not isServer() then
    local RopeCache = {
        nextId = 1,
        byId = {},
        byHandle = {},
    }

    function loadRopeTextures()
        RopeLoadTextures()
        local tries = 0
        while not RopeAreTexturesLoaded() and tries < 200 do
            Wait(0)
            tries += 1
        end
        return RopeAreTexturesLoaded()
    end

    function maybeUnloadTextures()
        local anyLeft = false
        local all = GetAllRopes()
        if all and type(all) == "table" then
            for _, _ in ipairs(all) do anyLeft = true break end
        end
        if not anyLeft then
            RopeUnloadTextures()
        end
    end

    function registerRope(ropeHandle, startCoords, endCoords, opts)
        if not ropeHandle or ropeHandle == 0 then return nil end
        local id = RopeCache.nextId
        RopeCache.nextId = id + 1

        local rec = {
            handle = ropeHandle,
            startCoords = startCoords,
            endCoords = endCoords,
            type = opts.ropeType,
            rate = opts.lengthChangeRate,
            breakable = opts.breakable,
            createdAt = GetGameTimer()
        }
        RopeCache.byId[id] = rec
        RopeCache.byHandle[ropeHandle] = id
        debugPrint("^5Debug^7: 2Registered Rope^7'^3"..id.."^7' - '^3"..ropeHandle.."^7'")
        return id
    end

    function resolve(id)
        if type(id) ~= "number" then return nil, "rope id must be a number" end
        local rec = RopeCache.byId[id]
        if not rec then return nil, "rope id not found" end
        if not DoesRopeExist(rec.handle) then
            -- stale; clean mapping
            RopeCache.byHandle[rec.handle] = nil
            RopeCache.byId[id] = nil
            return nil, "rope no longer exists"
        end
        return rec
    end

    --- Create a rope pinned between two coordinates.
    --- @param startCoords vector3|table  start coord
    --- @param endCoords vector3|table  end coord
    --- @param opts table|nil   { ropeType=0..7, breakable=false, collision=true, lockFromFront=false, lengthChangeRate=1.0, timeMultiplier=1.0, slack=0.0, preset=nil }
    --- @return integer ropeId
    function ropeCreateLine(startCoords, endCoords, opts)

        startCoords = type(startCoords) == "number" and GetEntityCoords(startCoords) or startCoords
        endCoords = type(endCoords) == "number" and GetEntityCoords(endCoords) or endCoords

        opts = opts or {}

        local length = #(startCoords - endCoords)
        local mid = (startCoords + endCoords) * 0.5

        local ropeType         = opts.ropeType or 1   -- 0..7 (see ropedata.xml types)
        local initLength       = length + (opts.slack or 0.0)
        local maxLength        = initLength           -- allow droop equal to init
        local minLength        = 0.0
        local lengthChangeRate = opts.lengthChangeRate or 1.0
        local collisionOn      = (opts.collision ~= false)
        local lockFromFront    = (opts.lockFromFront == true)
        local timeMultiplier   = opts.timeMultiplier or 1.0
        local breakable        = (opts.breakable == true)

        local rope = AddRope(mid.x, mid.y, mid.z, 0.0, 0.0, 0.0, maxLength, ropeType, initLength, minLength, lengthChangeRate, false, collisionOn, lockFromFront, timeMultiplier, breakable, 0)

        if not rope or rope == 0 or not DoesRopeExist(rope) then
            debugPrint("^1AddRope failed")
            return nil
        end

        -- Optional preset (e.g., "ropeFamily3") if provided.
        if opts.preset then
            -- Best-effort; if invalid it just won't change.
            pcall(function() LoadRopeData(rope, tostring(opts.preset)) end)
        end

        ActivatePhysics(rope)

        -- Pin both ends to the given coords.
        local count = GetRopeVertexCount(rope)
        if count and count >= 2 then
            PinRopeVertex(rope, 0, startCoords.x, startCoords.y, startCoords.z)
            PinRopeVertex(rope, count - 1, endCoords.x, endCoords.y, endCoords.z)
        end

        local id = registerRope(rope, startCoords, endCoords, {
            ropeType = ropeType,
            lengthChangeRate = lengthChangeRate,
            breakable = breakable
        })

        return id
    end

    --- Delete and unregister a rope.
    --- @param id integer
    function ropeDelete(id)
        local rec, err = resolve(id)
        if not rec then return false, err end
        local rope = rec.handle
        if DoesRopeExist(rope) then
            DeleteRope(rope)
        end
        RopeCache.byHandle[rope] = nil
        RopeCache.byId[id] = nil
        debugPrint(("deleted rope id=%s"):format(id))
        maybeUnloadTextures()
        return true
    end

    --- Force rope to a specific length (instant snap).
    --- @param id integer
    --- @param newLength number
    function ropeSetLength(id, newLength)
        local rec, err = resolve(id)
        if not rec then return false, err end
        RopeForceLength(rec.handle, newLength)
        return true
    end

    --- Smoothly wind the rope (shorten over time).
    --- @param id integer
    function ropeStartWinding(id)
        local rec, err = resolve(id)
        if not rec then return false, err end
        StartRopeWinding(rec.handle)
        return true
    end

    --- Stop winding (if winding).
    function ropeStopWinding(id)
        local rec, err = resolve(id)
        if not rec then return false, err end
        StopRopeWinding(rec.handle)
        return true
    end

    --- Smoothly unwind the rope from the front (lengthen over time).
    function ropeStartUnwinding(id)
        local rec, err = resolve(id)
        if not rec then return false, err end
        StartRopeUnwindingFront(rec.handle)
        return true
    end

    --- Stop unwinding (if unwinding).
    function ropeStopUnwinding(id)
        local rec, err = resolve(id)
        if not rec then return false, err end
        StopRopeUnwindingFront(rec.handle)
        return true
    end

    --- Change the wind speed (length change rate).
    --- @param id integer
    --- @param rate number  (units per sec; try 0.5..5.0)
    function ropeSetRate(id, rate)
        local rec, err = resolve(id)
        if not rec then return false, err end
        SetRopeLengthChangeRate(rec.handle, rate)
        rec.rate = rate
        return true
    end

    --- Move end endpoint to a new coordinate (re-pins the vertex).
    --- @param id integer
    --- @param pos vector3|table
    function ropeMoveEnd(id, pos)
        local rec, err = resolve(id)
        if not rec then return false, err end
        pos = type(pos) == "number" and GetEntityCoords(pos) or pos
        local rope = rec.handle
        local count = GetRopeVertexCount(rope)
        if not count or count < 2 then return false, "invalid vertex count" end
        PinRopeVertex(rope, count - 1, pos.x, pos.y, pos.z)
        rec.endCoord = pos
        return true
    end

    --- Move start endpoint to a new coordinate (re-pins the vertex).
    --- @param id integer
    --- @param pos vector3|table
    function ropeMoveStart(id, pos)
        local rec, err = resolve(id)
        if not rec then return false, err end
        pos = type(pos) == "number" and GetEntityCoords(pos) or pos
        local rope = rec.handle
        local count = GetRopeVertexCount(rope)
        if not count or count < 2 then return false, "invalid vertex count" end
        PinRopeVertex(rope, 0, pos.x, pos.y, pos.z)
        rec.startCoord = pos
        return true
    end

    --- Re-pin both endpoints in one call.
    function ropeSetEnds(ropeId, startCoord, endCoord)
        startCoord = type(startCoord) == "number" and GetEntityCoords(startCoord) or startCoord
        endCoord = type(endCoord) == "number" and GetEntityCoords(endCoord) or endCoord
        local rec, err = resolve(ropeId)
        if not rec then return false, err end
        local rope = rec.handle
        local count = GetRopeVertexCount(rope)
        if not count or count < 2 then
            return false, "invalid vertex count"
        end
        PinRopeVertex(rope, 0, startCoord.x, startCoord.y, startCoord.z)
        PinRopeVertex(rope, count - 1, endCoord.x, endCoord.y, endCoord.z)
        rec.startCoord = startCoord
        rec.endCoord = endCoord
        return true
    end

    function ropeExists(id)
        local rec = RopeCache.byId[id]
        return rec and DoesRopeExist(rec.handle) or false
    end

    onResourceStart(function()
        loadRopeTextures()
    end)

    onResourceStop(function()
        for id, rec in pairs(RopeCache.byId) do
            if rec.handle and DoesRopeExist(rec.handle) then
                DeleteRope(rec.handle)
            end
            RopeCache.byHandle[rec.handle] = nil
            RopeCache.byId[id] = nil
        end
        maybeUnloadTextures()
    end)
end