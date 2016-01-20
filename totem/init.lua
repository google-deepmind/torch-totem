require 'torch'

totem = {}
totem.debugMode = false


local paths = require 'paths'
local file = require 'learning.lua.file'
local flags = require 'learning.lua.flags'
local logging = require 'learning.lua.logging'

--[[ Helper function to get Google blaze test test_srcdir ]]
function totem.getTestDataPath(filename)
  local path = os.getenv("TEST_SRCDIR")
  if not filename then
    return path
  end
  return paths.concat(path, filename)
end

--[[ Helper function to get Google blaze test test_tmpdir ]]
local testTmp
local testTmpPath = os.getenv("TEST_TMPDIR")
function totem.getTestTmpPath(filename)
  if not testTmpPath then
    testTmp = file.TempPath()
    testTmpPath = testTmp:Path()
    logging.info('Created local temporary directory ' .. testTmpPath)
  end
  if not filename then
    return testTmpPath
  end
  return paths.concat(testTmpPath, filename)
end

--[[ The debug command-line flag sets debugMode to true.
This means that if the --debug flag is used on the command-line to enable
debugging on exception, then any test errors will break in the debugger.
]]
flags.init('')
if flags.FLAGS['debug'] then
  totem.debugMode = flags.FLAGS['debug']:getValue()
end

-- Local google3 modification: mute logging when running assertError* to
-- avoid cluttered stderr output.
totem._muteLogging = true
function totem.muteLogging(mute)
  totem._muteLogging = mute
end
-- End of local modification.

local ondemand = {nn = true}
local mt = {}

--[[ Extends the totem package on-demand.

A sub-package that has not been loaded when totem was initially required can be
added on demand by defining the __index function of totem's metatable. Then
the associated file is being included and the functions defined in it are added
to the totem package.

Arguments:

* `table`, the first argument to the __index function should be self.
* `key`, the name of the sub-package to be included

Returns:

1. a reference to the newly included sub-package.
]]
function mt.__index(table, key)
    if ondemand[key] then
        torch.include('totem', key .. '.lua')
        return totem[key]
    end
end

setmetatable(totem, mt)

torch.include('totem', 'asserts.lua')
torch.include('totem', 'Tester.lua')
torch.include('totem', 'TestSuite.lua')

return totem
