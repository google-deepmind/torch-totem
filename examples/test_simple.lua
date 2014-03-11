#!/usr/bin/env th

require 'totem'

test = {}
 
tester = totem.Tester()
 
function test.A()
    local a = 10
    local b = 10
    tester:asserteq(a, b, 'a == b')
    tester:assertne(a,b,'a ~= b')
end
 
function test.B()
    local a = 10
    local b = 9
    tester:assertgt(a, b, 'a > b')
end

function test.C()
    error('Errors are treated differently than failures')
end
 
tester:add(test):run()
