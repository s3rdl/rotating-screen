-- BNO055 demo: rotating video + rotating ticker (no logo)

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

local function safe_load_video(asset)
    local ok, v = pcall(resource.load_video, { file = asset, looped = true })
    if ok then return v end
    print("video load failed:", tostring(asset), tostring(v))
    return nil
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
end)

local function draw_ticker()
    if CONFIG.show_ticker == false then return end

    local text = CONFIG.ticker_text or ""
    if text == "" then return end

    local size  = tonumber(CONFIG.ticker_font_size) or 60
    local speed = tonumber(CONFIG.ticker_speed) or 160
    local gap   = tonumber(CONFIG.ticker_gap) or 80

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

    -- 1) VIDEO: rotates + scales (as before)
    gl.pushMatrix()
    gl.translate(OX + SAFE_W/2, OY + SAFE_H/2)
    gl.rotate(angle, 0, 0, 1)
    gl.scale(2, 2, 1)

    if vid then
        util.draw_correct(vid, -SAFE_W/2, -SAFE_H/2, SAFE_W/2, SAFE_H/2)
    end
    gl.popMatrix()

    -- 2) TICKER: rotate with video, BUT DO NOT scale (keeps it visible/readable)
    gl.pushMatrix()
    gl.translate(OX + SAFE_W/2, OY + SAFE_H/2)
    gl.rotate(angle, 0, 0, 1)
    gl.translate(-(OX + SAFE_W/2), -(OY + SAFE_H/2))

    pcall(draw_ticker)

    gl.popMatrix()
end
