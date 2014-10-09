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

torch.include('totem', 'Tester.lua')

totem.asserts = totem.Tester()
totem.asserts._success = function(self, message) return true, message end
totem.asserts._failure = function(self, message) return false, message end

return totem
