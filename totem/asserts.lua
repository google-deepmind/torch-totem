-- Functions for checking Tensor and Table equality.

--[[ Test for tensor equality

Tests whether the maximum element-wise difference between `a` and `b` is less
than or equal to `tolerance`.

Arguments:

* `ta` (tensor)
* `tb` (tensor)
* `tolerance` (optional, number) maximum elementwise difference between `a`
     and `b`. Defaults to `0`.

Returns:

1. success, boolean that indicates success
2. failure_message, string or nil
]]
function totem.areTensorsEq(ta, tb, tolerance, _negate)
  -- If _negate is true, we invert success and failure
  if _negate == nil then
    _negate = false
  end
  tolerance = tolerance or 0
  assert(torch.isTensor(ta), "First argument should be a Tensor")
  assert(torch.isTensor(tb), "Second argument should be a Tensor")
  assert(type(tolerance) == 'number',
         "Third argument should be a number describing a tolerance on"
         .. " equality for a single element")

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

  local function ensureHasAbs(t)
  -- Byte, Char and Short Tensors don't have abs
    if not t.abs then
      return t:double()
    else
      return t
    end
  end

  ta = ensureHasAbs(ta)
  tb = ensureHasAbs(tb)

  local diff = ta:clone():add(-1, tb)
  local err = diff:abs():max()
  local violation = _negate and 'TensorNE(==)' or ' TensorEQ(==)'
  local errMessage = string.format('%s violation: val=%s, tolerance=%s',
                                   violation,
                                   tostring(err),
                                   tostring(tolerance))

  local success = err <= tolerance
  if _negate then
    success = not success
  end
  return success, (not success) and errMessage or nil
end

--[[ Asserts tensor equality.

Asserts that the maximum elementwise difference between `a` and `b` is less than
or equal to `tolerance`.

Arguments:

* `ta` (tensor)
* `tb` (tensor)
* `tolerance` (optional, number) maximum elementwise difference between `a` and
    `b`. Defaults to `0`.
]]
function totem.assertTensorEq(ta, tb, tolerance)
  return assert(totem.areTensorsEq(ta, tb, tolerance))
end


--[[ Test for tensor inequality

The tensors are considered unequal if the maximum elementwise difference >=
`tolerance`.

Arguments:

* `ta` (tensor)
* `tb` (tensor)
* `tolerance` (optional, number). Defaults to `0`.

Returns:
1. success, a boolean indicating success
2. failure_message, string or nil

]]
function totem.areTensorsNe(ta, tb, tolerance)
  return totem.areTensorsEq(ta, tb, tolerance, true)
end

--[[ Asserts tensor inequality.

The tensors are considered unequal if the maximum elementwise difference >=
`tolerance`.

Arguments:

* `ta` (tensor)
* `tb` (tensor)
* `tolerance` (optional, number). Defaults to `0`.
]]
function totem.assertTensorNe(ta, tb, tolerance)
  assert(totem.areTensorsNe(ta, tb, tolerance))
end

local function isIncludedIn(ta, tb)
  if type(ta) ~= 'table' or type(tb) ~= 'table' then
    return ta == tb, '--> (Table 1) value: '.. tostring(ta) ..
                     ', (Table 2) value: ' .. tostring(tb)
  end
  for k, v in pairs(tb) do
    local equal, errMsg = totem.assertTableEq(ta[k], v)
    if not equal then return false, '['.. k .. ']' .. errMsg end
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
