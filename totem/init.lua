totem = {}

function totem._isTensor(obj)
    return torch.typename(obj) and obj.nDimension ~= nil
end

torch.include('totem', 'Tester.lua')
torch.include('totem', 'nn.lua')

return totem
