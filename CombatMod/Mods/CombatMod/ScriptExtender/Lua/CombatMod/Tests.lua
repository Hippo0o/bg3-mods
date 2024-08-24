Test = async(function()
    local time = 0
    local interval = async.interval(1000, function()
        time = time + 1
        assert(time <= 5, "Time out")
    end)

    local x = await(async.defer(3000):After(async(function()
        local a = 0

        local b = await(async.defer(1000, function()
            return 123
        end))

        assert(b == 123, "b is not 123")

        return a + b
    end)):After(function(v)
        assert(v == 123, "v is not 123")

        return v + 222
    end))

    assert(x == 345, "x is not 345")

    local y = await(async.defer(1000, function()
        return 456
    end))

    assert(y == 456, "y is not 456")

    interval:Clear()

    assert(x + y == 801, "x+y is not 801")

    assert(interval.Cleared, "Interval not cleared")
end)

Test2 = async(function()
    local time = 0
    local interval = async.interval(1000, function()
        time = time + 1
        assert(time <= 4, "Time out")
    end)

    local x, y = await(
        async.defer(3000):After(async(function()
            local a = 0

            local b = await(async.defer(1000, function()
                return 123
            end))

            assert(b == 123, "b is not 123")

            return a + b
        end)):After(function(v)
            assert(v == 123, "v is not 123")

            return v + 222
        end),
        async.defer(1000, function()
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
end)
