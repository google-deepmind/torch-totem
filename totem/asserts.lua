
local asserts = {}
totem.asserts = asserts

--[[ Assert tensor equality

Parameters:

- `ta` (tensor)
- `tb` (tensor)
- `condition` (number) maximum pointwise difference between `a` and `b`

Asserts that the maximum pointwise difference between `a` and `b` is less than
or equal to `condition`.

]]
function asserts.assertTensorEq(ta, tb, condition, neg)
    -- If neg is true, we invert success and failure
    -- This allows to easily implement Tester:assertTensorNe
    local invert = false
    if neg == nil then
      invert = false
    else
      invert = true
    end

    if ta:dim() ~= tb:dim() then
        return false, 'The tensors have different dimensions'
    end
    local sizea = torch.DoubleTensor(ta:size():totable())
    local sizeb = torch.DoubleTensor(tb:size():totable())
    local sizediff = sizea:clone():add(-1, sizeb)
    local sizeerr = sizediff:abs():max()
    if sizeerr ~= 0 then
        return false, 'The tensors have different sizes'
    end

    local function ensureNotByte(t)
      -- Ensure tensor is not a byte tensor (convert to double in this case).
        if t:type() == 'torch.ByteTensor' then
            return t:double()
        else
            return t
        end
    end

    ta = ensureNotByte(ta)
    tb = ensureNotByte(tb)

    local diff = ta:clone():add(-1, tb)
    local err = diff:abs():max()
    local violation = invert and 'TensorNE(==)' or ' TensorEQ(==)'
    local errMessage = string.format('%s violation: val=%s, condition=%s',
                                     violation,
                                     tostring(err),
                                     tostring(condition))

    if invert then
        return not (err <= condition), errMessage
    else
        return err <= condition , errMessage
    end
end

--[[ Assert tensor inequality

Parameters:

- `ta` (tensor)
- `tb` (tensor)
- `condition` (number)

The tensors are considered unequal if the maximum pointwise difference >= condition.

]]
function asserts.assertTensorNe(ta, tb, condition)
  return asserts.assertTensorEq(ta, tb, condition, true)
end


local function isIncludedIn(ta, tb)
    if type(ta) ~= 'table' or type(tb) ~= 'table' then
        return ta == tb
    end
    for k, v in pairs(tb) do
        if not asserts.assertTableEq(ta[k], v) then return false end
    end
    return true
end

--[[ Assert that two tables are equal (comparing values, recursively)

Parameters:

- `actual` (table)
- `expected` (table)

]]
function asserts.assertTableEq(ta, tb)
    return isIncludedIn(ta, tb) and isIncludedIn(tb, ta)
end

--[[ Assert that two tables are *not* equal (comparing values, recursively)

Parameters:

- `actual` (table)
- `expected` (table)

]]
function asserts.assertTableNe(ta, tb)
    return not asserts.assertTableEq(ta, tb)
end
