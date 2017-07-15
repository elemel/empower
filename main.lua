local Circle = require("Circle")
local Diagram = require("Diagram")
local Polygon = require("Polygon")
local utils = require("utils")

function love.load()
    love.window.setMode(800, 600, {
        fullscreentype = "desktop",
        highdpi = true,
        msaa = 8,
        resizable = true,
    })

    local polygon = Polygon.new(-1, -1, 1, -1, 1, 1, -1, 1)
    diagram = Diagram.new(polygon)
    maxTimeout = 0
    timeout = 0
    colors = {}
    hueSeed = 1024 * love.math.random()
    hueMean = love.math.random()
    hueAmplitude = 1 / 4
    hueFrequency = 2
    saturationSeed = 1024 * love.math.random()
    saturationMean = 1 / 2
    saturationAmplitude = 1 / 4
    saturationFrequency = 4
    lightnessSeed = 1024 * love.math.random()
    lightnessMean = 1 / 2
    lightnessAmplitude = 1 / 4
    lightnessFrequency = 8
end

function love.update(dt)
    timeout = timeout - dt

    if timeout < 0 then
        timeout = maxTimeout
        local x = 2 * love.math.random() - 1
        local y = 2 * love.math.random() - 1
        local radius = 1 / 16 / (1 + 8 * love.math.random())
        local circle = Circle.new(x, y, radius)
        local index = diagram:addCircle(circle)

        if index then
            local h = 255 * (hueMean + hueAmplitude * (2 * utils.fbm3(hueFrequency * x, hueFrequency * y, hueSeed) - 1))
            local s = 255 * (saturationMean + saturationAmplitude * (2 * utils.fbm3(saturationFrequency * x, saturationFrequency * y, saturationSeed) - 1))
            local l = 255 * (lightnessMean + lightnessAmplitude * (2 * utils.fbm3(lightnessFrequency * x, lightnessFrequency * y, lightnessSeed) - 1))
            local a = 255
            local color = {utils.toRgbaFromHsla(h, s, l, a)}
            colors[index] = color
        end
    end
end

function love.draw()
    local width, height = love.graphics.getDimensions()
    love.graphics.translate(0.5 * width, 0.5 * height)
    local x1, y1, x2, y2 = diagram.polygon:getBounds()
    local scale = math.min(width / (x2 - x1), height / (y2 - y1))
    love.graphics.scale(scale)
    love.graphics.setLineWidth(1 / scale)
    love.graphics.translate(0.5 * (x1 + x2), 0.5 * (y1 + y2))
    -- love.graphics.polygon("line", diagram.polygon.vertices)
    local polygonCount = 0

    for i, polygon in pairs(diagram.circlePolygons) do
        polygonCount = polygonCount + 1
        local color = assert(colors[i])
        -- love.graphics.circle("line", circle.x, circle.y, circle.radius, 256)
        love.graphics.setColor(color)
        love.graphics.polygon("fill", polygon.vertices)
    end
end
