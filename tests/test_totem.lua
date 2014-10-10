require 'totem'

local tester = totem.Tester()

local asserts = totem.asserts

local tests = {}

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
  assert((asserts:assert(true, MESSAGE)), "asserts:assert doesn't actually work!")
  assert(not (asserts:assert(false, MESSAGE)), "asserts:assert doesn't actually work!")
end

function tests.test_assert()
  meta_assert_success(asserts:assert(true, MESSAGE))
  meta_assert_failure(asserts:assert(false, MESSAGE))
end

function tests.test_assertTensorEq()
  local t1 = torch.randn(100,100)
  local t2 = t1:clone()
  local t3 = torch.randn(100,100)
  meta_assert_success(asserts:assertTensorEq(t1, t2, 1e-6, MESSAGE))
  meta_assert_failure(asserts:assertTensorEq(t1, t3, 1e-6, MESSAGE))
end

function tests.test_assertTensorNe()
  local t1 = torch.randn(100,100)
  local t2 = t1:clone()
  local t3 = torch.randn(100,100)
  meta_assert_success(asserts:assertTensorNe(t1, t3, 1e-6, MESSAGE))
  meta_assert_failure(asserts:assertTensorNe(t1, t2, 1e-6, MESSAGE))
  end

function tests.test_assertTensor_epsilon()
  local t1 = torch.rand(100,100)
  local t2 = torch.rand(100,100)*1e-5
  local t3 = t1 + t2
  meta_assert_success(asserts:assertTensorEq(t1, t3, 1e-4, MESSAGE))
  meta_assert_failure(asserts:assertTensorEq(t1, t3, 1e-6, MESSAGE))
  meta_assert_success(asserts:assertTensorNe(t1, t3, 1e-6, MESSAGE))
  meta_assert_failure(asserts:assertTensorNe(t1, t3, 1e-4, MESSAGE))
end

function tests.test_assertTable()
  local tensor = torch.rand(100,100)
  local t1 = {1, "a", key = "value", tensor = tensor}
  local t2 = {1, "a", key = "value", tensor = tensor}
  meta_assert_success(asserts:assertTableEq(t1, t2, MESSAGE))
  meta_assert_failure(asserts:assertTableNe(t1, t2, MESSAGE))
  for k,v in pairs(t1) do
    local x = "something else"
    t2[k] = nil
    t2[x] = v
    meta_assert_success(asserts:assertTableNe(t1, t2, MESSAGE))
    meta_assert_failure(asserts:assertTableEq(t1, t2, MESSAGE))
    t2[x] = nil
    t2[k] = x
    meta_assert_success(asserts:assertTableNe(t1, t2, MESSAGE))
    meta_assert_failure(asserts:assertTableEq(t1, t2, MESSAGE))
    t2[k] = v
    meta_assert_success(asserts:assertTableEq(t1, t2, MESSAGE))
    meta_assert_failure(asserts:assertTableNe(t1, t2, MESSAGE))
  end
end


local function good_fn() end
local function bad_fn() error("muahaha!") end

function tests.test_assertError()
  meta_assert_success(asserts:assertError(bad_fn, MESSAGE))
  meta_assert_failure(asserts:assertError(good_fn, MESSAGE))
end

function tests.test_assertNoError()
  meta_assert_success(asserts:assertNoError(good_fn, MESSAGE))
  meta_assert_failure(asserts:assertNoError(bad_fn, MESSAGE))
end

function tests.test_assertErrorPattern()
  meta_assert_success(asserts:assertErrorPattern(bad_fn, "haha", MESSAGE))
  meta_assert_failure(asserts:assertErrorPattern(bad_fn, "hehe", MESSAGE))
end

tester:add(tests):run()
