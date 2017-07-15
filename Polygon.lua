local utils = require("utils")

local Polygon = utils.newClass()

function Polygon:init(...)
    self.vertices = {...}
    assert(#self.vertices % 2 == 0)
    assert(#self.vertices >= 6)
end

function Polygon:clone()
    return Polygon.new(unpack(self.vertices))
end

function Polygon:getBounds()
    local x1 = math.huge
    local y1 = math.huge
    local x2 = -math.huge
    local y2 = -math.huge

    for i = 1, #self.vertices, 2 do
        local x = self.vertices[i]
        x1 = math.min(x1, x)
        x2 = math.max(x2, x)
    end

    for i = 2, #self.vertices, 2 do
        local y = self.vertices[i]
        y1 = math.min(y1, y)
        y2 = math.max(y2, y)
    end

    return x1, y1, x2, y2
end

function Polygon:clip(x1, y1, x2, y2)
    local vertices = self.vertices
    self.vertices = {}
    local x3 = vertices[#vertices - 1]
    local y3 = vertices[#vertices]

    for i = 1, #vertices, 2 do
        local x4 = vertices[i]
        local y4 = vertices[i + 1]

        if self:isPointInside(x4, y4, x1, y1, x2, y2) then
            if not self:isPointInside(x3, y3, x1, y1, x2, y2) then
                local x, y = self:intersectLines(x3, y3, x4, y4, x1, y1, x2, y2)
                table.insert(self.vertices, x)
                table.insert(self.vertices, y)
            end

            table.insert(self.vertices, x4)
            table.insert(self.vertices, y4)
        else
            if self:isPointInside(x3, y3, x1, y1, x2, y2) then
                local x, y = self:intersectLines(x3, y3, x4, y4, x1, y1, x2, y2)
                table.insert(self.vertices, x)
                table.insert(self.vertices, y)
            end
        end

        x3 = x4
        y3 = y4
    end
end

function Polygon:isPointInside(x, y, x1, y1, x2, y2)
    return (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1) < 0
end

-- https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
function Polygon:intersectLines(x1, y1, x2, y2, x3, y3, x4, y4)
    local divisor = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    local x = (x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)
    local y = (x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)
    return x / divisor, y / divisor
end

return Polygon
