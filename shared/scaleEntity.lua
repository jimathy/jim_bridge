local cacheOrigScale = {}
local initialOffset = {}

--- Sets the scale of an entity.
---
--- This function scales an entity by adjusting its forward, right, and up vectors.
--- It also applies an initial offset to maintain the entity's position relative to the ground.
---
---@param entity number The entity ID to scale.
---@param scale number The scale factor to apply to the entity.
---
---@usage
--- ```lua
--- -- Scale an entity to twice its original size
--- SetEntityScale(entityId, 2.0)
--- ```
function SetEntityScale(entity, scale)
    local forward, right, up = GetEntityMatrix(entity)
    if not cacheOrigScale[entity] then
        cacheOrigScale[entity] = {
            forward = forward,
            right = right,
            up = up
        }
    end
    local minDim, maxDim = GetModelDimensions(GetEntityModel(entity))
    local originalHeight = maxDim.z - minDim.z
    local newHeight = originalHeight * scale
    initialOffset[entity] = (newHeight - originalHeight) / 3

    local forwardTemp = cacheOrigScale[entity].forward * scale
    local rightTemp = cacheOrigScale[entity].right * scale
    local upTemp = cacheOrigScale[entity].up * scale

    -- Apply the initial offset to the current position
    local currentPosition = GetEntityCoords(entity)
    local newPosition = vector3(currentPosition.x, currentPosition.y, currentPosition.z + initialOffset[entity])

    SetEntityMatrix(entity, forwardTemp, rightTemp, upTemp, currentPosition)
end

--- Resets the scale of an entity to its original values.
---
--- This function restores an entity's original forward, right, and up vectors,
--- effectively undoing any scaling applied by `SetEntityScale`.
---
---@param entity number The entity ID to reset.
---
---@usage
--- ```lua
--- -- Reset the scale of an entity
--- resetScale(entityId)
--- ```
function resetScale(entity)
    if cacheOrigScale[entity] then
        SetEntityMatrix(entity, cacheOrigScale[entity].forward, cacheOrigScale[entity].right, cacheOrigScale[entity].up, GetEntityCoords(entity))
        cacheOrigScale[entity] = nil
    end
end

--[[
CreateThread(function()
    -- Example usage:
    -- local prop = makeProp({prop = "v_res_r_figcat", coords = vec4(-1025.88, -1417.58, 5.43, 76.30)}, false, false)
    -- local ped = makePed(`a_c_cat_01`, vec4(-1022.42, -1429.97, 13.79, 68.36), true, false, nil)
    -- SetEntityCollision(prop, false, true)

    SetEntityScale(prop, 12)
    --[[CreateThread(function()
        while true do
            Wait(1000)
            resetScale(prop)
            Wait(1000)
        end
    end)
end)
]]