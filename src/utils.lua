local utilities = {}

function utilities.distance(first, second)
    local firstCenterX
    local firstCenterY
    local secondCenterX
    local secondCenterY

    if not first.width or not first.height or not second.width or not second.height then
        firstCenterX = first.x + first.collider.width / 2
        firstCenterY = first.y + first.collider.height / 2
        secondCenterX = second.x + second.collider.width / 2
        secondCenterY = second.y + second.collider.height / 2
    else
        firstCenterX = first.x + first.width / 2
        firstCenterY = first.y + first.height / 2
        secondCenterX = second.x + second.width / 2
        secondCenterY = second.y + second.height / 2
    end

    local dx = secondCenterX - firstCenterX
    local dy = secondCenterY - firstCenterY

    return math.sqrt(dx * dx + dy * dy)
end

function utilities.clamp(value, min, max)
    if value > max then
        value = max
    elseif value < min then
        value = min
    end
    return value
end

function utilities.splitname(name)
    local basename, number = name:match("^(.-)_(%d+)$")

    if basename then
        return basename, tonumber(number)
    end

    return name, nil
end

function utilities.lerp(a, b, t)
    return a + (b - a) * t
end

return utilities