local Circle = require("Circle")
local Polygon = require("Polygon")
local utils = require("utils")

local Diagram = utils.newClass()

function Diagram:init(polygon)
    self.polygon = assert(polygon)
    self.circles = {}
    self.circlePolygons = {}
    self.nextIndex = 1
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

return Diagram
