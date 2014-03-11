#!/usr/bin/env th

require 'totem'

test = {}

tester = totem.Tester()
 
function test.Dimension()
    local a = torch.Tensor(1,2)
    local b = torch.Tensor(2)
    tester:assertTensorEq(a, b, 1e-16, 'a == b')
    tester:assertTensorNe(a, b, 1e-16, 'a ~= b')
end

function test.Size()
    local a = torch.Tensor(1,2)
    local b = torch.Tensor(2,2)
    tester:assertTensorEq(a, b, 1e-16, 'a == b')
    tester:assertTensorNe(a, b, 1e-16, 'a ~= b')
end

function test.DifferentValues()
    local a = torch.zeros(1,2)
    local b = torch.ones(1,2)
    tester:assertTensorEq(a, b, 1e-16, 'a == b')
    tester:assertTensorNe(a, b, 1e-16, 'a ~= b')
end

function test.SameValues()
    local a = torch.zeros(1,2)
    local b = torch.zeros(1,2)
    tester:assertTensorEq(a, b, 1e-16, 'a == b')
    tester:assertTensorNe(a, b, 1e-16, 'a ~= b')
end

tester:add(test):run()
