-- MIT License
--
-- Copyright (c) 2017 Mikael Lind
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--
-- See: https://github.com/elemel/empower

local empower = {}

local function cross2(x1, y1, x2, y2)
    return x1 * y2 - x2 * y1
end

local function normalize2(x, y)
    local length = math.sqrt(x * x + y * y)

    if length == 0 then
        return 1, 0, 0
    end

    return x / length, y / length, length
end

local Circle = {}
Circle.__index = Circle

function empower.newCircle(x, y, radius)
    local circle = setmetatable({}, Circle)
    circle.x = x or 0
    circle.y = y or 0
    circle.radius = radius or 1
    assert(circle.radius >= 0)
    return circle
end

function Circle:clone()
    return empower.newCircle(self.x, self.y, self.radius)
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
    local directionX, directionY, distance = normalize2(other.x - self.x, other.y - self.y)
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

local Diagram = {}
Diagram.__index = Diagram

function empower.newDiagram(polygon)
    local diagram = setmetatable({}, Diagram)
    diagram.polygon = assert(polygon)
    diagram.circles = {}
    diagram.circlePolygons = {}
    diagram.nextIndex = 1
    return diagram
end

function Diagram:addCircle(circle)
    circle = circle:clone()
    local polygon = self.polygon:clone()
    local emptyIndices = {}

    for i, circle2 in pairs(self.circles) do
        local polygon2 = assert(self.circlePolygons[i])
        local x1, y1, x2, y2 = circle:getRadicalAxis(circle2)
        polygon:clip(x1, y1, x2, y2)
        polygon2:clip(x2, y2, x1, y1)

        if #polygon2.vertices < 6 then
            table.insert(emptyIndices, i)
        end
    end

    while true do
        local emptyIndex = table.remove(emptyIndices)

        if not emptyIndex then
            break
        end

        self.circles[emptyIndex] = nil
        self.circlePolygons[emptyIndex] = nil
    end

    if #polygon.vertices < 6 then
        return nil
    end

    local index = self.nextIndex
    self.nextIndex = self.nextIndex + 1
    self.circles[index] = circle
    self.circlePolygons[index] = polygon
    return index
end

local Polygon = {}
Polygon.__index = Polygon

function empower.newPolygon(...)
    local polygon = setmetatable({}, Polygon)
    polygon.vertices = {...}
    assert(#polygon.vertices % 2 == 0)
    assert(#polygon.vertices >= 6)
    return polygon
end

function Polygon:clone()
    return empower.newPolygon(unpack(self.vertices))
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

-- See: https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
function Polygon:intersectLines(x1, y1, x2, y2, x3, y3, x4, y4)
    local divisor = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    local x = (x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)
    local y = (x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)
    return x / divisor, y / divisor
end

-- See: https://en.wikipedia.org/wiki/Centroid#Centroid_of_a_polygon
function Polygon:getArea()
    local area = 0
    local x1 = self.vertices[#self.vertices - 1]
    local y1 = self.vertices[#self.vertices]

    for i = 1, #self.vertices, 2 do
        local x2 = self.vertices[i]
        local y2 = self.vertices[i + 1]
        area = area + (x1 * y2 - x2 * y1)
        x1 = x2
        y1 = y2
    end

    return 0.5 * area
end

-- See: https://en.wikipedia.org/wiki/Centroid#Centroid_of_a_polygon
function Polygon:getCentroid()
    local centroidX = 0
    local centroidY = 0
    local area = 0
    local x1 = self.vertices[#self.vertices - 1]
    local y1 = self.vertices[#self.vertices]

    for i = 1, #self.vertices, 2 do
        local x2 = self.vertices[i]
        local y2 = self.vertices[i + 1]
        local z = (x1 * y2 - x2 * y1)
        centroidX = centroidX + (x1 + x2) * z
        centroidY = centroidY + (y1 + y2) * z
        area = area + z
        x1 = x2
        y1 = y2
    end

    local scale = 1 / (3 * area)
    return scale * centroidX, scale * centroidY, 0.5 * area
end

function Polygon:containsPoint(x, y)
    local x1 = self.vertices[#self.vertices - 1]
    local y1 = self.vertices[#self.vertices]

    for i = 1, #self.vertices, 2 do
        local x2 = self.vertices[i]
        local y2 = self.vertices[i + 1]

        if cross2(x - x1, y - y1, x2 - x1, y2 - y1) > 0 then
            return false
        end

        x1 = x2
        y1 = y2
    end

    return true
end

return empower
