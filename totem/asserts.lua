-- Functions for checking Tensor, Storage and Table equality.

--[[ Test for tensor equality between two tensors of matching sizes and types

Tests whether the maximum element-wise difference between `a` and `b` is less
than or equal to `tolerance`.

Arguments:

* `ta` (tensor)
* `tb` (tensor)
* `tolerance` (optional number, default 0) maximum elementwise difference
    between `a` and `b`.
* `negate` (optional boolean, default false) if `negate` is true, we invert
    success and failure.
* `storage` (optional boolean, default false) if `storage` is true, we print an
    error message referring to Storages rather than Tensors.

Returns:

1. success, boolean that indicates success
2. failure_message, string or nil
]]
local function areSameFormatTensorsEq(ta, tb, tolerance, negate, storage)

  -- If we are comparing two empty tensors, return true.
  -- This is needed because some functions below cannot be applied to tensors
  -- of dimension 0. 
  if ta:dim() == 0 then
    return not negate
  end

  local function ensureHasAbs(t)
    -- Byte, Char and Short Tensors don't have abs
    return t.abs and t or t:double()
  end

  ta = ensureHasAbs(ta)
  tb = ensureHasAbs(tb)

  local diff = ta:clone():add(-1, tb):abs()
  local err = diff:max()
  local prefix = storage and 'Storage' or 'Tensor'
  local violation = negate and 'NE(==)' or 'EQ(==)'
  local errMessage = string.format('%s%s violation: val=%s, tolerance=%s',
                                   prefix,
                                   violation,
                                   tostring(err),
                                   tostring(tolerance))

  local success = err <= tolerance
  if negate then
    success = not success
  end
  return success, (not success) and errMessage or nil
end

--[[ Test for tensor equality

Tests whether the maximum element-wise difference between `a` and `b` is less
than or equal to `tolerance`.

Arguments:

* `ta` (tensor)
* `tb` (tensor)
* `tolerance` (optional number, default 0) maximum elementwise difference
    between `a` and `b`.
* `negate` (optional boolean, default false) if negate is true, we invert
    success and failure.

Returns:

1. success, boolean that indicates success
2. failure_message, string or nil
]]
function totem.areTensorsEq(ta, tb, tolerance, negate)
  if negate == nil then
    negate = false
  end
  tolerance = tolerance or 0
  assert(torch.isTensor(ta), "First argument should be a Tensor")
  assert(torch.isTensor(tb), "Second argument should be a Tensor")
  assert(type(tolerance) == 'number',
         "Third argument should be a number describing a tolerance on"
         .. " equality for a single element")

  if ta:dim() ~= tb:dim() then
    return negate, 'The tensors have different dimensions'
  end

  if ta:type() ~= tb:type() then
    return negate, 'The tensors have different types'
  end

  local sizea = torch.DoubleTensor(ta:size():totable())
  local sizeb = torch.DoubleTensor(tb:size():totable())
  local sizediff = sizea:clone():add(-1, sizeb)
  local sizeerr = sizediff:abs():max()
  if sizeerr ~= 0 then
    return negate, 'The tensors have different sizes'
  end

  return areSameFormatTensorsEq(ta, tb, tolerance, negate, false)

end

--[[ Asserts tensor equality.

Asserts that the maximum elementwise difference between `a` and `b` is less than
or equal to `tolerance`.

Arguments:

* `ta` (tensor)
* `tb` (tensor)
* `tolerance` (optional number, default 0) maximum elementwise difference
    between `a` and `b`.
]]
function totem.assertTensorEq(ta, tb, tolerance)
  return assert(totem.areTensorsEq(ta, tb, tolerance))
end


--[[ Test for tensor inequality

The tensors are considered unequal if the maximum elementwise difference >
`tolerance`.

Arguments:

* `ta` (tensor)
* `tb` (tensor)
* `tolerance` (optional number, default 0).

Returns:
1. success, a boolean indicating success
2. failure_message, string or nil

]]
function totem.areTensorsNe(ta, tb, tolerance)
  return totem.areTensorsEq(ta, tb, tolerance, true)
end

--[[ Asserts tensor inequality.

The tensors are considered unequal if the maximum elementwise difference >
`tolerance`.

Arguments:

* `ta` (tensor)
* `tb` (tensor)
* `tolerance` (optional number, default 0).
]]
function totem.assertTensorNe(ta, tb, tolerance)
  assert(totem.areTensorsNe(ta, tb, tolerance))
end


local typesMatching = {
    ['torch.ByteStorage'] = torch.ByteTensor,
    ['torch.CharStorage'] = torch.CharTensor,
    ['torch.ShortStorage'] = torch.ShortTensor,
    ['torch.IntStorage'] = torch.IntTensor,
    ['torch.LongStorage'] = torch.LongTensor,
    ['torch.FloatStorage'] = torch.FloatTensor,
    ['torch.DoubleStorage'] = torch.DoubleTensor,
}

--[[ Test for storage equality

Tests whether the maximum element-wise difference between `a` and `b` is less
than or equal to `tolerance`.

Arguments:

* `sa` (storage)
* `sb` (storage)
* `tolerance` (optional number, default 0) maximum elementwise difference
    between `a` and `b`.
* `negate` (optional boolean, dfeault false) if negate is true, we invert succes
    and failure.

Returns:

1. success, boolean that indicates success
2. failure_message, string or nil
]]
function totem.areStoragesEq(sa, sb, tolerance, negate)
  -- If negate is true, we invert success and failure
  if negate == nil then
    negate = false
  end
  tolerance = tolerance or 0
  assert(torch.isStorage(sa), "First argument should be a Storage")
  assert(torch.isStorage(sb), "Second argument should be a Storage")
  assert(type(tolerance) == 'number',
         "Third argument should be a number describing a tolerance on"
         .. " equality for a single element")

  if sa:size() ~= sb:size() then
    return negate, 'The storages have different sizes'
  end


  local typeOfsa = torch.type(sa)
  local typeOfsb = torch.type(sb)

  if typeOfsa ~= typeOfsb then
    return negate, 'The storages have different types'
  end

  local ta = typesMatching[typeOfsa](sa)
  local tb = typesMatching[typeOfsb](sb)

  return areSameFormatTensorsEq(ta, tb, tolerance, negate, true)
end

--[[ Asserts storage equality.

Asserts that the maximum elementwise difference between `a` and `b` is less than
or equal to `tolerance`.

Arguments:

* `sa` (storage)
* `sb` (storage)
* `tolerance` (optional number, default 0) maximum elementwise difference
    between `a` and `b`.
]]
function totem.assertStorageEq(sa, sb, tolerance)
  return assert(totem.areStoragesEq(sa, sb, tolerance))
end


--[[ Test for storage inequality

The storages are considered unequal if the maximum elementwise difference >
`tolerance`.

Arguments:

* `sa` (storage)
* `sb` (storage)
* `tolerance` (optional number, default 0).

Returns:
1. success, a boolean indicating success
2. failure_message, string or nil

]]
function totem.areStoragesNe(sa, sb, tolerance)
  return totem.areStoragesEq(sa, sb, tolerance, true)
end

--[[ Asserts storage inequality.

The storages are considered unequal if the maximum elementwise difference >
`tolerance`.

Arguments:

* `sa` (storage)
* `sb` (storage)
* `tolerance` (optional number, default 0).
]]
function totem.assertStorageNe(sa, sb, tolerance)
  assert(totem.areStoragesNe(sa, sb, tolerance))
end

local function isIncludedIn(ta, tb)
  if type(ta) ~= 'table' or type(tb) ~= 'table' then
    return ta == tb, '--> (Table 1) value: ' .. tostring(ta) ..
                     ', (Table 2) value: ' .. tostring(tb)
  end
  for k, v in pairs(tb) do
    local equal, errMsg = totem.assertTableEq(ta[k], v)
    if not equal then return false, '[' .. k .. ']' .. errMsg end
  end
  return true, nil
end

--[[ Asserts that two tables are equal (comparing values, recursively).

Arguments:

* `actual` (table)
* `expected` (table)

Returns:
1. success, a boolean indicating equality
2. failure_message, string or nil (if not equal) where string starts with
   the hierarchical location (e.g. [ind1][ind2]) of the first difference
   between the two tables followed by the values in those locations for
   both tables.
]]
function totem.assertTableEq(ta, tb)
    local bIncAB, mesAB = isIncludedIn(ta, tb)
    if not bIncAB then return bIncAB, mesAB end
    local bIncBA, mesBA = isIncludedIn(tb, ta)
    if not bIncBA then return bIncBA, mesBA end
    return true, nil
end

--[[ Asserts that two tables are *not* equal (comparing values, recursively).

Arguments:

* `actual` (table)
* `expected` (table)

]]
function totem.assertTableNe(ta, tb)
    return not totem.assertTableEq(ta, tb)
end
