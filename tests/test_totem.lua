require 'totem'

local tester = totem.Tester()

local subtester = totem.Tester()
subtester._success = function(self, message) return true, message end
subtester._failure = function(self, message) return false, message end

local tests = totem.TestSuite()

local MESSAGE = "a really useful informative error message"

local function meta_assert_success(success, message)
  tester:assert(success==true, "assert wasn't successful")
  tester:assert(string.find(message, MESSAGE) ~= nil, "message doesn't match")
end
local function meta_assert_failure(success, message)
  tester:assert(success==false, "assert didn't fail")
  tester:assert(string.find(message, MESSAGE) ~= nil, "message doesn't match")
end

function tests.really_test_assert()
  assert((subtester:assert(true, MESSAGE)),
         "subtester:assert doesn't actually work!")
  assert(not (subtester:assert(false, MESSAGE)),
         "subtester:assert doesn't actually work!")
end

function tests.test_assert()
  meta_assert_success(subtester:assert(true, MESSAGE))
  meta_assert_failure(subtester:assert(false, MESSAGE))
end

function tests.test_assertTensorEq_alltypes()
  local allTypes = {
      torch.ByteTensor,
      torch.CharTensor,
      torch.ShortTensor,
      torch.IntTensor,
      torch.LongTensor,
      torch.FloatTensor,
      torch.DoubleTensor,
  }
  for _, tensor in ipairs(allTypes) do
    local t1 = tensor():ones(10)
    local t2 = tensor():ones(10)
    meta_assert_success(subtester:assertTensorEq(t1, t2, 1e-6, MESSAGE))
  end
end

function tests.test_assertTensorSizes()
  local t1 = torch.ones(2)
  local t2 = torch.ones(3)
  local t3 = torch.ones(1,2)
  meta_assert_failure(subtester:assertTensorEq(t1, t2, 1e-6, MESSAGE))
  meta_assert_failure(subtester:assertTensorNe(t1, t2, 1e-6, MESSAGE))
  meta_assert_failure(subtester:assertTensorEq(t1, t3, 1e-6, MESSAGE))
  meta_assert_failure(subtester:assertTensorNe(t1, t3, 1e-6, MESSAGE))
end

function tests.test_assertTensorEq()
  local t1 = torch.randn(100,100)
  local t2 = t1:clone()
  local t3 = torch.randn(100,100)
  meta_assert_success(subtester:assertTensorEq(t1, t2, 1e-6, MESSAGE))
  meta_assert_failure(subtester:assertTensorEq(t1, t3, 1e-6, MESSAGE))
end

function tests.test_assertTensorNe()
  local t1 = torch.randn(100,100)
  local t2 = t1:clone()
  local t3 = torch.randn(100,100)
  meta_assert_success(subtester:assertTensorNe(t1, t3, 1e-6, MESSAGE))
  meta_assert_failure(subtester:assertTensorNe(t1, t2, 1e-6, MESSAGE))
  end

function tests.test_assertTensor_epsilon()
  local t1 = torch.rand(100,100)
  local t2 = torch.rand(100,100)*1e-5
  local t3 = t1 + t2
  meta_assert_success(subtester:assertTensorEq(t1, t3, 1e-4, MESSAGE))
  meta_assert_failure(subtester:assertTensorEq(t1, t3, 1e-6, MESSAGE))
  meta_assert_success(subtester:assertTensorNe(t1, t3, 1e-6, MESSAGE))
  meta_assert_failure(subtester:assertTensorNe(t1, t3, 1e-4, MESSAGE))
end

function tests.test_assertTable()
  local tensor = torch.rand(100,100)
  local t1 = {1, "a", key = "value", tensor = tensor, subtable = {"nested"}}
  local t2 = {1, "a", key = "value", tensor = tensor, subtable = {"nested"}}
  meta_assert_success(subtester:assertTableEq(t1, t2, MESSAGE))
  meta_assert_failure(subtester:assertTableNe(t1, t2, MESSAGE))
  for k,v in pairs(t1) do
    local x = "something else"
    t2[k] = nil
    t2[x] = v
    meta_assert_success(subtester:assertTableNe(t1, t2, MESSAGE))
    meta_assert_failure(subtester:assertTableEq(t1, t2, MESSAGE))
    t2[x] = nil
    t2[k] = x
    meta_assert_success(subtester:assertTableNe(t1, t2, MESSAGE))
    meta_assert_failure(subtester:assertTableEq(t1, t2, MESSAGE))
    t2[k] = v
    meta_assert_success(subtester:assertTableEq(t1, t2, MESSAGE))
    meta_assert_failure(subtester:assertTableNe(t1, t2, MESSAGE))
  end
end


local function good_fn() end
local function bad_fn() error("muahaha!") end

function tests.test_assertError()
  meta_assert_success(subtester:assertError(bad_fn, MESSAGE))
  meta_assert_failure(subtester:assertError(good_fn, MESSAGE))
end

function tests.test_assertNoError()
  meta_assert_success(subtester:assertNoError(good_fn, MESSAGE))
  meta_assert_failure(subtester:assertNoError(bad_fn, MESSAGE))
end

function tests.test_assertErrorPattern()
  meta_assert_success(subtester:assertErrorPattern(bad_fn, "haha", MESSAGE))
  meta_assert_failure(subtester:assertErrorPattern(bad_fn, "hehe", MESSAGE))
end

function tests.test_TensorEqChecks()
  local t1 = torch.randn(100,100)
  local t2 = t1:clone()
  local t3 = torch.randn(100,100)

  local success, msg = totem.areTensorsEq(t1, t2, 1e-5)
  tester:assert(success, "areTensorsEq should return true")
  tester:asserteq(msg, nil, "areTensorsEq erroneously gives msg on success")

  local success, msg = totem.areTensorsEq(t1, t3, 1e-5)
  tester:assert(not success, "areTensorsEq should return false")
  tester:asserteq(type(msg), 'string', "areTensorsEq should return a message")

  tester:assertNoError(function() totem.assertTensorEq(t1, t2, 1e-5) end,
                       "assertTensorEq not raising an error")
  tester:assertError(function() totem.assertTensorEq(t1, t3, 1e-5) end,
                     "assertTensorEq not raising an error")
end

function tests.test_TensorNeChecks()
  local t1 = torch.randn(100,100)
  local t2 = t1:clone()
  local t3 = torch.randn(100,100)

  local success, msg = totem.areTensorsNe(t1, t3, 1e-5)
  tester:assert(success, "areTensorsNe should return true")
  tester:asserteq(msg, nil, "areTensorsNe erroneously gives msg on success")

  local success, msg = totem.areTensorsNe(t1, t2, 1e-5)
  tester:assert(not success, "areTensorsNe should return false")
  tester:asserteq(type(msg), 'string', "areTensorsNe should return a message")

  tester:assertNoError(function() totem.assertTensorNe(t1, t3, 1e-5) end,
                       "assertTensorNe not raising an error")
  tester:assertError(function() totem.assertTensorNe(t1, t2, 1e-5) end,
                     "assertTensorNe not raising an error")
end

function tests.test_TensorArgumentErrorMessages()
  local t = torch.ones(1)
  local funcs = {
      totem.areTensorsEq,
      totem.areTensorsNe,
      totem.assertTensorEq,
      totem.assertTensorNe,
  }

  for _, fn in ipairs(funcs) do
    tester:assertErrorPattern(function() fn(nil, t, 0) end, "First argument")
    tester:assertErrorPattern(function() fn(t, nil, 0) end, "Second argument")
    tester:assertErrorPattern(function() fn(t, t, "nan") end, "Third argument")
  end
end

function tests.testSuite_duplicateTests()
    function createDuplicateTests()
        local tests = totem.TestSuite()
        function tests.testThis()
        end
        function tests.testThis()
        end
    end
    tester:assertErrorPattern(createDuplicateTests, "Test testThis is already defined.")
end

tester:add(tests):run()
