for i = 1, 200 do
    local tier = { amount = i }

    local weight = (tier.amount - 25) / (100 - 25) * 0.7 + 0.1

    print(tier.amount, weight)
end
