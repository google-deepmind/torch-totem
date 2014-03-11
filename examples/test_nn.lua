#!/usr/bin/env th

require 'totem'
require 'nn'

test = {}

tester = totem.Tester()


local function net()
    local net = nn.Linear(10, 10)
    local input = torch.randn(5, 10)
    return net, input
end


function test.gradients()
    totem.nn.checkGradients(tester, net())
end


function test.minibatch()
    totem.nn.checkMinibatch(tester, net())
end


tester:add(test):run()
