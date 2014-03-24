local lapp = require 'pl.lapp'
require 'sys'
local c = sys.COLORS

local NCOLS = 80


local isTensor = totem._isTensor


local Tester = torch.class('totem.Tester')

function Tester:__init()
    self.errors = {}
    self.tests = {}
    self.curtestname = ''
end


-- Add a success to the test
function Tester:_success (message)
    self.countasserts = self.countasserts + 1
    local name = self.curtestname
    self.assertionPass[name] = self.assertionPass[name] + 1
end

-- Add a failure to the test
function Tester:_failure (message)
    self.countasserts = self.countasserts + 1
    local name = self.curtestname
    self.assertionFail[name] = self.assertionFail[name] + 1
    local ss = debug.traceback('tester',2)
    ss = ss:match('[^\n]+\n[^\n]+\n([^\n]+\n[^\n]+)\n')
    if type(message) == 'function' then
        message = message()
    end
    self.errors[#self.errors+1] = self.curtestname .. '\n' .. message .. '\n' .. ss .. '\n'
end

--[[

Parameters:

- `condition` (boolean)
- `message` (string or function : nil → string)

]]
function Tester:_assert_sub (condition, message)
    if condition then
        self:_success(message)
    else
        self:_failure(message)
    end
end


-- Assert that a condition is true
function Tester:assert(condition, message)
    self:_assert_sub(condition,
            string.format('%s\n%s  condition=%s', message, ' BOOL violation ',
                tostring(condition)))
end


-- Assert that `val` < `condition`
function Tester:assertlt(val, condition, message)
    self:_assert_sub(val < condition,
            string.format('%s\n%s  val=%s, condition=%s', message, ' LT(<) violation ',
                tostring(val), tostring(condition)))
end


-- Assert that `val` > `condition`
function Tester:assertgt(val, condition, message)
   self:_assert_sub(val > condition,
        string.format('%s\n%s  val=%s, condition=%s',message,' GT(>) violation ',
            tostring(val), tostring(condition)))
end


-- Assert that `val` <= `condition`
function Tester:assertle(val, condition, message)
    self:_assert_sub(val <= condition,
            string.format('%s\n%s  val=%s, condition=%s', message, ' LE(<=) violation ',
                tostring(val), tostring(condition)))
end


-- Assert that `val` >= `condition`
function Tester:assertge(val, condition, message)
    self:_assert_sub(val >= condition,
            string.format('%s\n%s  val=%s, condition=%s', message, ' GE(>=) violation ',
                tostring(val), tostring(condition)))
end


-- Assert that `val` == `condition`
function Tester:asserteq(val, condition, message)
    self:_assert_sub(val == condition,
            string.format('%s\n%s  val=%s, condition=%s', message, ' EQ(==) violation ',
                tostring(val), tostring(condition)))
end


-- Assert that `a` - `b` < `condition`
function Tester:assertalmosteq(a, b, condition, message)
    condition = condition or 1e-16
    local err = math.abs(a-b)
    self:_assert_sub(err < condition,
            string.format('%s\n%s  val=%s, condition=%s', message, ' ALMOST_EQ(==) violation ',
                tostring(err), tostring(condition)))
end


-- Assert that `val` ~= `condition`
function Tester:assertne (val, condition, message)
    self:_assert_sub(val ~= condition,
            function ()
                return string.format('%s\n%s  val=%s, condition=%s', message, ' NE(~=) violation ',
                    tostring(val), tostring(condition))
            end)
end


--[[ Assert tensor equality

Parameters:

- `ta` (tensor)
- `tb` (tensor)
- `condition` (number) maximum pointwise difference between `a` and `b`
- `message` (string)
- `neg` (boolean) allows to invert the output. If this argument is true, then
        failures become successes and viceversa. See Tester:assertTensorNe.

Asserts that the maximum pointwise difference between `a` and `b` is less than
or equal to `condition`.

]]
function Tester:assertTensorEq(ta, tb, condition, message, neg)
    local success = self._success
    local failure = self._failure
    -- If neg is true, we invert the success and failure functions
    -- This allows to easily implement Tester:assertTensorNe
    if neg then
        local temp = success
        success = failure
        failure = temp
    end

    if ta:dim() ~= tb:dim() then
        failure(self, string.format('%s\n%s', message, 'The tensors have different dimensions'))
        return
    end
    local sizea = torch.DoubleTensor(ta:size():totable())
    local sizeb = torch.DoubleTensor(tb:size():totable())
    local sizediff = sizea:clone():add(-1, sizeb)
    local sizeerr = sizediff:abs():max()
    if sizeerr ~= 0 then
        failure(self, string.format('%s\n%s', message, 'The tensors have different sizes'))
        return
    end

    local diff = ta:clone():add(-1, tb)
    local err = diff:abs():max()
    local errMessage = string.format('%s\n%s  val=%s, condition=%s',
                                     message, ' TensorEQ(==) violation ',
                                     tostring(err),
                                     tostring(condition))
    if err <= condition then
        success(self, errMessage)
    else
        failure(self, errMessage)
    end
end


--[[ Assert tensor inequality

Parameters:

- `ta` (tensor)
- `tb` (tensor)
- `condition` (number)
- `message` (string)

The tensors are considered unequal if the maximum pointwise difference >= condition.

]]
function Tester:assertTensorNe(ta, tb, condition, message)
    return self:assertTensorEq(ta, tb, condition, message, true)
end


local function areTablesEqual(ta, tb)

    local function isIncludedIn(ta, tb)
        if type(ta) ~= 'table' or type(tb) ~= 'table' then 
            return ta == tb 
        end
        for k, v in pairs(tb) do
            if not areTablesEqual(ta[k], v) then return false end
        end
        return true
    end

    return isIncludedIn(ta, tb) and isIncludedIn(tb, ta)
end


--[[ Assert that two tables are equal (comparing values, recursively)

Parameters:

- `ta` (table)
- `tb` (table)
- `message` (string)

--]]
function Tester:assertTableEq(ta, tb, message)
    self:_assert_sub(areTablesEqual(ta, tb),
            string.format('%s\n%s val=%s, condition=%s', message, ' TableEQ(==) violation ',
                tostring(err), tostring(condition)))
end


--[[ Assert that two tables are *not* equal (comparing values, recursively)

Parameters:

- `ta` (table)
- `tb` (table)
- `message` (string)

--]]
function Tester:assertTableNe(ta, tb, message)
    self:_assert_sub(not areTablesEqual(ta, tb),
            string.format('%s\n%s val=%s, condition=%s', message, ' TableEQ(==) violation ',
                tostring(err), tostring(condition)))
end


--[[ Assert that an error is raised by `f`

Parameters:

- `f` (function) function to be tested
- `message` (string) message to print on assertion failure

]]
function Tester:assertError(f, message)
    return self:assertErrorObj(f, function(err) return true end, message)
end


--[[ Assert that an error is not raised by `f`

Parameters:

- `f` (function) function to be tested
- `message` (string) message to print on assertion failure

]]
function Tester:assertNoError(f, message)
    return self:assertErrorObj(f, function(err) return true end, message, true)
end


--[[ Assert that an error is raised by `f` with a specific message

Parameters:

- `f` (function) function to be tested
- `errmsg` (string) error message that should be generated by `f`
- `message` (string) message to print on assertion failure

]]
function Tester:assertErrorMsg(f, errmsg, message)
    return self:assertErrorObj(f, function(err) return err == errmsg end, message)
end


--[[ Assert that an error is raised by `f` containing a specific pattern

Parameters:

- `f` (function) function to be tested
- `errPattern` (string) pattern that should be present in the error object
- `message` (string) message to print on assertion failure

]]
function Tester:assertErrorPattern(f, errPattern, message)
    return self:assertErrorObj(f, function(err) return string.find(err, errPattern) ~= nil end, message)
end


--[[ Assert that an error is raised by `f` which satisfies some condition

Parameters:

- `f` (function) function to be tested
- `errcomp` (function : obj → bool) function that compares the error object to its expected value
- `message` (string) message to print on assertion failure
- `condition` (boolean) assert condition on status of pcall (defaults to false)

]]
function Tester:assertErrorObj(f, errcomp, message, condition)
    local status, err = pcall(f)
    self:_assert_sub(status == (condition or false) and errcomp(err),
            string.format('%s\n%s  err=%s', message,' ERROR violation ', tostring(err)))
end



--[[ Legacy assert on equality with a supplied precision (number, table, or user data)

Parameters:

- `got` (number, table, userData) the value computed during the test execution
- `expected` (number, table, userData) the expected value
- `label` (string) used for output labelling
- `precision` (number) the maximum allowed precision required to pass

]]
function Tester:eq(got, expected, label, precision)
    label = label or "eq"
    precision = precision or 0

    local ok
    local diff = 0
    if type(expected) == "table" then
        self:_eqTable(got, expected, label, precision)
        return
    elseif type(expected) == "userdata" then
        if got.nDimension then
            self:_eqSize(got, expected, label)
            diff = got:clone():add(-1, expected):abs():max()
            ok = diff <= precision
        else
            self:_eqStorage(got, expected, label, precision)
            return
        end
    else
        if precision == 0 then
            ok = (got == expected)
        else
            diff = math.abs(got - expected)
            ok = (diff <= precision)
        end
    end

    self:_assert_sub(ok, 
        function ()
            return string.format("%s violation at precision %f (max diff=%f): %s != %s",
                    tostring(label), precision, diff, tostring(got), tostring(expected))
        end)
end


function Tester:_eqSize(ta, tb, label)
    local ok = true
    if ta:nDimension() ~= tb:nDimension() then
        ok = false
    else
        for i = 1, ta:nDimension() do
            if ta:size(i) ~= tb:size(i) then
                ok = false
                break
            end
        end
    end

    self:_assert_sub(ok,
        function ()
            return string.format("%s inconsistent size: %s != %s", tostring(label), tostring(ta), tostring(tb))
        end)
end


function Tester:_eqStorage(got, expected, label, precision)
    self:_assert_sub(#got == #expected, 
        string.format("%s inconsistent storage size: %s != %s", label, #got, #expected))
    for i = 1, #expected do
        self:eq(got[i], expected[i], label, precision)
    end
end


function Tester:_eqTable(got, expected, label, precision)
    self:_assert_sub(#got == #expected,
        string.format("%s inconsistent table size: %s != %s", label, #got, #expected))

    for k, v in pairs(expected) do
        self:eq(got[k], v, label, precision)
    end

    for k, v in pairs(got) do
        self:eq(v, expected[k], label, precision)
    end
end


function Tester:_pcall(f)
    local nerr = #self.errors
    local stat, result = xpcall(f, debug.traceback)
    if not stat then
        self.errors[#self.errors+1] = self.curtestname .. '\n Function call failed \n' .. result .. '\n'
    end
    return stat, result, stat and (nerr == #self.errors)
end


local function unwords(...)
    return table.concat({...}, ' ')
end


local function pluralize(num, str)
    local stem = num .. ' ' .. str
    if num == 1 then
        return stem
    else
        return stem .. 's'
    end
end


local function coloured(str, colour)
    return colour .. str .. c.none
end


local function bracket(str)
    return '[' .. str .. ']'
end


function Tester:_nfailures(tests)
    local nfailures = 0
    for name,_ in pairs(tests) do
        if self.assertionFail[name] > 0 then
            nfailures = nfailures + 1
        end
    end
    return nfailures
end


function Tester:_nerrors(tests)
    local nerrors = 0
    for name,_ in pairs(tests) do
        if self.testError[name] > 0 then
            nerrors = nerrors + 1
        end
    end
    return nerrors
end


function Tester:_report(tests, ntests, nfailures, nerrors, summary)
    io.write('Completed ' .. pluralize(self.countasserts, 'assert'))
    io.write(' in ' .. pluralize(ntests, 'test') .. ' with ')

    io.write(coloured(pluralize(nfailures, 'failure'), nfailures == 0 and c.green or c.red))
    io.write(' and ')
    io.write(coloured(pluralize(nerrors, 'error'), nerrors == 0 and c.green or c.magenta))
    io.write('\n')

    if #self.errors ~= 0 and not summary then
        io.write(string.rep('-', NCOLS))
        io.write('\n')
        for i,v in ipairs(self.errors) do
            io.write(v)
            io.write('\n')
            io.write(string.rep('-', NCOLS))
            io.write('\n')
        end
    end
end


function Tester:_logOutput(f, tests)
    local npasses, nfails, nerrors = 0, 0, 0
    for name,_ in pairs(tests) do
        npasses = npasses + self.assertionPass[name]
        nfails = nfails + self.assertionFail[name]
        nerrors = nerrors + self.testError[name]
        f:write(unwords(name, self.assertionPass[name], self.assertionFail[name], self.testError[name]))
        f:write('\n')
    end
    f:write(unwords('[total]', npasses, nfails, nerrors))
    f:write('\n')
    f:close()
end


function Tester:_listTests(tests)
    for name,_ in pairs(tests) do
        print(name)
    end
end


function Tester:_runCL(candidates)

    local args = lapp([[Run tests

Usage:

  ]] .. arg[0] .. [[ [options] [test1 [test2...] ]

Options:

  --list print the names of the available tests instead of running them.
  --log-output (optional file-out) redirect compact test results to file.
        This contains one line per test in the following format:
        name #passed-assertions #failed-assertions #exceptions
  --no-colour suppress colour output
  --summary print only pass/fail status rather than full error messages.
  --full-tensors when printing tensors, always print in full even if large.
        Otherwise just print a summary for large tensors.
  --early-abort (optional boolean) abort execution on first error.
 
If any test names are specified only the named tests are run. Otherwise
all the tests are run.

]])
    if #args > 0 then
        candidates = args
    end

    if args.no_colour then
        coloured = function(str) return str end
    end

    if not args.full_tensors then
        local _tostring = tostring
        tostring = function(x)
            if isTensor(x) and x:nElement() > 256 then
                local sz = _tostring(x:size(1))
                for i = 2,x:nDimension() do
                    sz = sz .. 'x' .. _tostring(x:size(i))
                end
                return string.format('Tensor of size %s, min=%f, max=%f', sz, x:min(), x:max())
            else
                return _tostring(x)
            end
        end
    end

    local tests = self:_getTests(candidates)
    if args.list then
        self:_listTests(tests)
        return 0
    else
        local status = self:_run(tests, args.summary, args.early_abort)
        if args.log_output then
            self:_logOutput(args.log_output, tests)
        end
        return status
    end
end


--[[ Run tests

Parameters:

- `tests` (optional string or table of strings) names of tests to run (if not
   running from the command-line).

]]
function Tester:run(tests)
    local status = 0
    if arg then
        status = self:_runCL()
    else
        status = self:_run(self:_getTests(tests))
    end
    os.exit(status)
end


function Tester:_getTests(candidates)
    local tests = self.tests

    local function getMatchingNames(pattern)
        local matchingNames = {}
        for name,_ in pairs(self.tests) do
            if string.match(name, pattern) then table.insert(matchingNames, name) end
        end
        if next(matchingNames) == nil then
            lapp.error(string.format("Invalid test case '%s'", pattern), true)
        end
        return matchingNames
    end

    if type(candidates) == 'string' then
        candidates = getMatchingNames(candidates)
    end

    if type(candidates) == 'table' then
        tests = {}
        for _,name in ipairs(candidates) do
            local curNames = getMatchingNames(name)
            for _,name in pairs(curNames) do
                tests[name] = self.tests[name]
            end
        end
    end

    return tests
end


local function countFormat(n)
    local total = string.format('%u', n)
    return string.format('%%%uu/%u ', total:len(), total), total:len() * 2 + 2
end


function Tester:_run(tests, summary, earlyAbort)

    self.countasserts = 0

    self.assertionPass = {}
    self.assertionFail = {}
    self.testError = {}
    local ntests = 0
    for name,_ in pairs(tests) do
        self.assertionPass[name] = 0
        self.assertionFail[name] = 0
        self.testError[name] = 0
        ntests = ntests + 1
    end

    local cfmt, cfmtlen = countFormat(ntests)

    io.write('Running ' .. pluralize(ntests, 'test') .. '\n')
    local i = 1
    for name,fn in pairs(tests) do
        self.curtestname = name

        -- TODO: compute max length of name and cut it down to size if needed 
        local strinit = coloured(string.format(cfmt,i), c.cyan)
                      .. self.curtestname .. ' ' 
                      .. string.rep('.', NCOLS-6-2-cfmtlen-self.curtestname:len()) .. ' '
        io.write(strinit .. bracket(coloured('WAIT', c.cyan)))
        io.flush()

        local stat, message, pass = self:_pcall(fn)
        io.write('\r')
        io.write(strinit)
      
        if not stat then
            self.testError[name] = 1
            io.write(bracket(coloured('ERROR', c.magenta)))
        elseif pass then
            io.write(bracket(coloured('PASS', c.green)))
        else
            io.write(bracket(coloured('FAIL', c.red)))
        end
        io.write('\n')
        io.flush()

        if earlyAbort and (i<ntests) and (not stat or not pass) then
            io.write('Aborting on first error, not all tests have been executed\n')
            break
        end

        i = i + 1

        collectgarbage()
    end
    local nfailures = self:_nfailures(tests)
    local nerrors = self:_nerrors(tests)
    self:_report(tests, ntests, nfailures, nerrors, summary)
    return nfailures + nerrors == 0 and 0 or 1
end


--[[ Add one or more test cases to tester

Parameters:

- `f` (function or table) add the function or every function in the table to
   the test set. 
- `name` (optional string) name of test

Return:

- `self`

]]
function Tester:add(f, name)
    name = name or 'unknown'
    if type(f) == "table" then
        for i,v in pairs(f) do
            self:add(v,i)
        end
    elseif type(f) == "function" then
        self.tests[name] = f
    else
        error('Tester:add(f) expects a function or a table of functions')
    end
    return self
end
