function totem.TestSuite()
    local obj = {
        __tests = {},
        __isTotemTestSuite = true
    }

    local metatable = {}

    function metatable:__index(key)
        return self.__tests[key]
    end

    function metatable:__newindex(key, value)
        if self.__tests[key] ~= nil then
            error("Test " .. tostring(key) .. " is already defined.")
        end
        self.__tests[key] = value
    end

    setmetatable(obj, metatable)

    return obj
end

