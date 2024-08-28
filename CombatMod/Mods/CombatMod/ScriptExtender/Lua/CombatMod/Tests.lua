return {
    Test = async(function()
        local time = 0
        local interval = async.interval(1000, function()
            time = time + 1
            assert(time <= 5, "Time out")
        end)

        local x = await(async
            .defer(3000)
            :After(async(function()
                local a = 0

                L.Debug("A")
                local b = await(async.defer(1000, function()
                    L.Debug("B")
                    return 123
                end))

                assert(b == 123, "b is not 123")

                return a + b
            end))
            :After(function(v)
                assert(v == 123, "v is not 123")
                L.Debug("C")

                return v + 222
            end))

        assert(x == 345, "x is not 345")

        local y = await(async.defer(1000, function()
            L.Debug("D")
            return 456
        end))

        assert(y == 456, "y is not 456")

        interval:Clear()

        assert(x + y == 801, "x+y is not 801")

        assert(interval.Cleared, "Interval not cleared")
        L.Debug("E")
    end),
    Test2 = async(function()
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

                    L.Debug("B")
                    local b = await(async.defer(1000, function()
                        L.Debug("C")
                        return 123
                    end))

                    assert(b == 123, "b is not 123")

                    return a + b
                end))
                :After(function(v)
                    assert(v == 123, "v is not 123")

                    L.Debug("D")
                    return v + 222
                end),
            async.defer(1000, function()
                L.Debug("A")
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
        L.Debug("E")
    end),
    Test3 = async(function()
        local time = 0
        local x = await(async.waituntil(function(self)
            if time >= 4 then
                return true
            end

            time = time + 1

            return false
        end, function()
            return 123
        end))

        assert(x == 123, "x is not 123")

        local time = 0
        local x = await(async.waituntil(function(self)
            if time >= 4 then
                self:Clear()
                return
            end

            time = time + 1

            return false
        end, function()
            return 123
        end))

        assert(x == nil, "x is not nil")
    end),
    Test4 = async(function()
        local ok, err = pcall(
            await,
            async.defer(1000, function()
                error("Error")
                return 123
            end)
        )

        assert(not ok, "Error not thrown")

        await(async.defer(1000, function()
            error("Error")
            return 123
        end))
    end),
}
