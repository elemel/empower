local empower = require("empower")

local function fbm3(
    x, y, z, noise, octave, lacunarityX, lacunarityY, lacunarityZ, gain)

    noise = noise or love.math.noise
    octave = octave or 3
    lacunarityX = lacunarityX or 2
    lacunarityY = lacunarityY or 2
    lacunarityZ = lacunarityZ or 2
    gain = gain or 3 / (lacunarityX + lacunarityY + lacunarityZ)

    local integralOctave, fractionalOctave = math.modf(octave)
    local amplitude = 1

    local totalNoise = 0
    local totalAmplitude = 0

    for i = 1, integralOctave do
        totalNoise = totalNoise + amplitude * noise(x, y, z)
        totalAmplitude = totalAmplitude + amplitude

        x = x * lacunarityX
        y = y * lacunarityY
        z = z * lacunarityZ
        amplitude = amplitude * gain
    end

    if fractionalOctave > 0 then
        totalNoise = totalNoise + fractionalOctave * amplitude * noise(x, y, z)
        totalAmplitude = totalAmplitude + fractionalOctave * amplitude
    end

    return totalNoise / totalAmplitude
end

-- See: http://love2d.org/wiki/HSL_color
local function toRgbaFromHsla(h, s, l, a)
    if s <= 0 then
        return l, l, l, a
    end

    h, s, l = h * 6, s, l
    local c = (1 - math.abs(2 * l - 1)) * s
    local x = (1 - math.abs(h % 2 - 1)) * c
    local m, r, g, b = (l - 0.5 * c), 0, 0, 0

    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return r + m, g + m, b + m, a
end

function love.load()
    love.window.setMode(800, 600, {
        fullscreentype = "desktop",
        highdpi = true,
        msaa = 8,
        resizable = true,
    })

    local polygon = empower.newPolygon(-1, -1, 1, -1, 1, 1, -1, 1)
    diagram = empower.newDiagram(polygon)
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
        local circle = empower.newCircle(x, y, radius)
        local index = diagram:addCircle(circle)

        if index then
            local h = hueMean + hueAmplitude * (2 * fbm3(hueFrequency * x, hueFrequency * y, hueSeed) - 1)
            local s = saturationMean + saturationAmplitude * (2 * fbm3(saturationFrequency * x, saturationFrequency * y, saturationSeed) - 1)
            local l = lightnessMean + lightnessAmplitude * (2 * fbm3(lightnessFrequency * x, lightnessFrequency * y, lightnessSeed) - 1)
            local a = 1
            local color = {toRgbaFromHsla(h, s, l, a)}
            colors[index] = color
        end
    end
end

function love.draw()
    local width, height = love.graphics.getDimensions()
    love.graphics.translate(0.5 * width, 0.5 * height)
    local x1, y1, x2, y2 = diagram.polygon:getBounds()
    local scale = math.max(width / (x2 - x1), height / (y2 - y1))
    love.graphics.scale(scale)
    love.graphics.setLineWidth(1 / scale)
    love.graphics.translate(0.5 * (x1 + x2), 0.5 * (y1 + y2))
    local polygonCount = 0

    for i, polygon in pairs(diagram.circlePolygons) do
        polygonCount = polygonCount + 1
        local color = assert(colors[i])
        love.graphics.setColor(color)
        love.graphics.polygon("fill", polygon.vertices)
    end
end
