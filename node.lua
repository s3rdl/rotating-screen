-- BNO055 demo: rotating video + optional logo + optional ticker (production)

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local NW, NH = NATIVE_WIDTH, NATIVE_HEIGHT

-- Safe area (adjust scale if needed)
local SAFE_SCALE_W = 0.80
local SAFE_SCALE_H = 0.80
local SAFE_W = math.floor(NW * SAFE_SCALE_W)
local SAFE_H = math.floor(NH * SAFE_SCALE_H)

local OX = math.floor((NW - SAFE_W) / 2)
local OY = math.floor((NH - SAFE_H) / 2)

local angle = 0
local vid = nil
local font = resource.load_font "OpenSans-Bold.ttf"

local CONFIG = {}
local logo = nil
local last_logo_asset = nil
local last_video_asset = nil

util.data_mapper{
    rotate = function(new_angle)
        angle = tonumber(new_angle) or 0
    end
}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function safe_load_image(asset)
    local ok, img = pcall(resource.load_image, asset)
    if ok then return img end
    return nil
end

local function safe_load_video(asset)
    local ok, v = pcall(resource.load_video, { file = asset, looped = true })
    if ok then return v end
    return nil
end

local function load_logo()
    local asset
    if type(CONFIG.logo) == "table" and CONFIG.logo.asset_name then
        asset = CONFIG.logo.asset_name
    else
        asset = CONFIG.logo_file or "logo.png"
    end

    if asset == last_logo_asset and logo then return end
    last_logo_asset = asset
    logo = asset and safe_load_image(asset) or nil
end

local function load_video()
    local asset
    if type(CONFIG.video) == "table" and CONFIG.video.asset_name then
        asset = CONFIG.video.asset_name
    else
        asset = nil
    end

    if asset == last_video_asset and vid then return end
    last_video_asset = asset

    if vid then
        vid:dispose()
        vid = nil
    end

    if asset then
        vid = safe_load_video(asset)
    end
end

util.json_watch("config.json", function(config)
    CONFIG = config or {}
    load_video()
    load_logo()
end)

local function draw_logo()
    if CONFIG.show_logo == false then return end
    if not logo then return end

    local margin = tonumber(CONFIG.logo_margin) or 30
    local pos = CONFIG.logo_pos or "top_right"

    local a = tonumber(CONFIG.logo_opacity)
    if a == nil then a = 1 end
    a = clamp(a, 0, 1)

    local okS, iw, ih = pcall(function() return logo:size() end)
    if not okS or not iw or not ih or ih == 0 then return end

    -- config height, but auto-limit inside safe area
    local cfg_h = tonumber(CONFIG.logo_height) or 90
    local h = tonumber(CONFIG.logo_height) or 90

    local w = h * (iw / ih)

    local x, y = margin, margin
    if pos == "top_right" then
        x, y = SAFE_W - w - margin, margin
    elseif pos == "bottom_left" then
        x, y = margin, SAFE_H - h - margin
    elseif pos == "bottom_right" then
        x, y = SAFE_W - w - margin, SAFE_H - h - margin
    end

    x = clamp(x, margin, SAFE_W - w - margin)
    y = clamp(y, margin, SAFE_H - h - margin)

    x = x + OX
    y = y + OY

    gl.color(1, 1, 1, a)
    logo:draw(x, y, x + w, y + h)
    gl.color(1, 1, 1, 1)
end

local function draw_ticker()
    if CONFIG.show_ticker == false then return end

    local text = CONFIG.ticker_text or ""
    if text == "" then return end

    local size = tonumber(CONFIG.ticker_font_size) or 60
    local speed = tonumber(CONFIG.ticker_speed) or 160
    local gap = tonumber(CONFIG.ticker_gap) or 80

    size = clamp(size, 12, math.floor(SAFE_H * 0.08))

    local y = (SAFE_H - size - 20) + OY
    local tw = font:width(text, size)
    local x = SAFE_W - ((sys.now() * speed) % (tw + SAFE_W + gap))
    x = x + OX

    font:write(x, y, text, size, 1,1,1,1)
    font:write(x + tw + gap, y, text, size, 1,1,1,1)
end

function node.render()
    gl.clear(0, 0, 0, 1)

    gl.pushMatrix()
    gl.translate(OX + SAFE_W/2, OY + SAFE_H/2)
    gl.rotate(angle, 0, 0, 1)
    gl.scale(2, 2, 1)

    if vid then
        util.draw_correct(vid, -SAFE_W/2, -SAFE_H/2, SAFE_W/2, SAFE_H/2)
    end

    gl.popMatrix()

    draw_ticker()
    draw_logo()
end
