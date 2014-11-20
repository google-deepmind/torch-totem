require 'torch'

totem = {}

function totem._isTensor(obj)
    return torch.typename(obj) and obj.nDimension ~= nil
end

local ondemand = {nn = true}
local mt = {}

function mt.__index(table, key)
    if ondemand[key] then
        torch.include('totem', key .. '.lua')
        return totem[key]
    end
end

setmetatable(totem, mt)

torch.include('totem', 'asserts.lua')
torch.include('totem', 'Tester.lua')

return totem
