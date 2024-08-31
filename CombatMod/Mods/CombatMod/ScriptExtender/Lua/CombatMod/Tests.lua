Require("Hlib/StandardLib")
local Log = Require("Hlib/Log")

local tests = {
    async(function()
        local time = 0
        local interval = async.interval(1000, function()
            time = time + 1
            assert(time <= 5, "Time out")
        end)

        local x = await(async
            .defer(3000)
            :After(async(function()
                local a = 0

                Log.Warn("A")
                local b = await(async.defer(1000, function()
                    Log.Warn("B")
                    return 123
                end))

                assert(b == 123, "b is not 123")

                return a + b
            end))
            :After(function(v)
                assert(v == 123, "v is not 123")
                Log.Warn("C")

                return v + 222
            end))

        assert(x == 345, "x is not 345")

        local y = await(async.defer(1000, function()
            Log.Warn("D")
            return 456
        end))

        assert(y == 456, "y is not 456")

        interval:Clear()

        assert(x + y == 801, "x+y is not 801")

        assert(interval.Cleared, "Interval not cleared")
        Log.Warn("E")

        return true
    end),
    async(function()
        local time = 0
        local interval = async.interval(1000, function()
            time = time + 1
            assert(time <= 5, "Time out")
        end)

        local x = await(async
            .defer(3000)
            :After(async(function()
                local a = 0

                Log.Warn("A")
                local b = await(async.defer(1000, function()
                    Log.Warn("B")
                    return 123
                end))

                assert(b == 123, "b is not 123")

                return a + b
            end))
            :After(function(v)
                assert(v == 123, "v is not 123")
                Log.Warn("C")

                return v + 222
            end))

        assert(x == 345, "x is not 345")

        local y = await(async.defer(1000, function()
            Log.Warn("D")
            return 456
        end))

        assert(y == 456, "y is not 456")

        interval:Clear()

        assert(x + y == 801, "x+y is not 801")

        assert(interval.Cleared, "Interval not cleared")
        Log.Warn("E")
    end),
    async(function()
        local time = 0
        local interval = async.interval(1000, function()
            time = time + 1
            assert(time <= 4, "Time out")
        end)

        local x, y = await(
            async
                .defer(3000)
                :After(async(function()
                    local a = 0

                    Log.Warn("B")
                    local b = await(async.defer(1000, function()
                        Log.Warn("C")
                        return 123
                    end))

                    assert(b == 123, "b is not 123")

                    return a + b
                end))
                :After(function(v)
                    assert(v == 123, "v is not 123")

                    Log.Warn("D")
                    return v + 222
                end),
            async.defer(1000, function()
                Log.Warn("A")
                return 456
            end)
        )

        assert(#x == 1, "x is not 1 length table")
        assert(#y == 1, "y is not 1 length table")

        assert(x[1] == 345, "x is not 345")

        assert(y[1] == 456, "y is not 456")

        interval:Clear()

        assert(x[1] + y[1] == 801, "x+y is not 801")

        assert(interval.Cleared, "Interval not cleared")
        Log.Warn("E")
    end),
    async(function()
        local time = 0
        local x = await(async.waituntil(function(self)
            if time >= 4 then
                Log.Warn("A")
                return true
            end

            time = time + 1

            return false
        end, function()
            Log.Warn("B")
            return 123
        end))

        Log.Warn("C")
        assert(x == 123, "x is not 123")

        local time = 0
        local x = await(async.waituntil(function(self)
            if time >= 4 then
                Log.Warn("D")
                self:Clear()
                return
            end

            time = time + 1

            return false
        end, function()
            return 123
        end))

        assert(x == nil, "x is not nil")
        Log.Warn("E")
    end),
    async(function()
        local ok, err = pcall(
            await,
            async
                .defer(1000, function()
                    Log.Warn("A")
                    return async.defer(100)
                end)
                :After(function()
                    Log.Warn("A2")
                    error("Error")
                    return 456
                end)
        )

        assert(not ok, "Error not thrown")
        assert(type(err) == "string", "Error is not 'Error'")
        Log.Error("B", err)

        local x = await(async
            .defer(1000, function()
                Log.Warn("C")
                error("Error")
                return 123
            end)
            :Catch(function(err)
                Log.Error("D", err)
                assert(type(err) == "string", "Error is not 'Error'")
                return 456
            end))

        Log.Warn("E")
        assert(x == 456, "x is not 456")

        await(async.defer(1000, function()
            Log.Warn("F", "Throwing error")
            error("Error")
            return 123
        end))

        assert(false, "Error not thrown")
        Log.Warn("-D")
    end),
}

return async(function(j)
    for i, test in pairs(tests) do
        if j and i ~= j then
            goto continue
        end

        Log.Warn("Running test", i)
        xpcall(function()
            local x = { await(test()) }
            Log.Info("Test Success", i, table.unpack(x))
        end, function(err)
            Log.Error("Test failed", i, err)
        end)

        ::continue::
    end
end)
