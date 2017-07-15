local utils = require("utils")

local Circle = utils.newClass()

function Circle:init(x, y, radius)
    self.x = x or 0
    self.y = y or 0
    self.radius = radius or 1
    assert(self.radius >= 0)
end

function Circle:clone()
    return Circle.new(self.x, self.y, self.radius)
end

-- We have [1]:
--
--   d == d1 + d2 => d2 == d - d1
--
-- And [2]:
--
--   d1 ^ 2 - r1 ^ 2 == d2 ^ 2 - r2 ^ 2
--
-- Insert [1] into [2]:
--
--   d1 ^ 2 - r1 ^ 2 == (d - d1) ^ 2 - r2 ^ 2 =>
--   d1 ^ 2 - r1 ^ 2 == d ^ 2 - 2 * d * d1 + d1 ^ 2 - r2 ^ 2 =>
--   2 * d * d1 - r1 ^ 2 == d ^ 2 - r2 ^ 2 =>
--   2 * d * d1 == d ^ 2 + r1 ^ 2 - r2 ^ 2 =>
--   d1 == (d ^ 2 + r1 ^ 2 - r2 ^ 2) / (2 * d)
function Circle:getRadicalAxis(other)
    local directionX, directionY, distance = utils.normalize2(other.x - self.x, other.y - self.y)
    local distance1

    if self.radius == other.radius then
        distance1 = distance / 2
    else
        distance1 = (distance ^ 2 + self.radius ^ 2 - other.radius ^ 2) / (2 * distance)
    end

    local x1 = self.x + directionX * distance1
    local y1 = self.y + directionY * distance1
    local x2 = x1 - directionY
    local y2 = y1 + directionX
    return x1, y1, x2, y2
end

return Circle
