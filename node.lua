-- BNO055 demo: rotating video + rotating ticker (no logo)

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local NW, NH = NATIVE_WIDTH, NATIVE_HEIGHT

-- Safe area (keep if your display overscans)
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
    local asset = nil
    if type(CONFIG.video) == "table" and CONFIG.video.asset_name then
        asset = CONFIG.video.asset_name
    end

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

local function draw_ticker_rotated()
    if CONFIG.show_ticker == false then return end

    local text = CONFIG.ticker_text or ""
    if text == "" then return end

    local size  = tonumber(CONFIG.ticker_font_size) or 60
    local speed = tonumber(CONFIG.ticker_speed) or 160
    local gap   = tonumber(CONFIG.ticker_gap) or 80
    local pad   = tonumber(CONFIG.ticker_padding) or 18

    -- keep readable inside safe area
    size = clamp(size, 12, math.floor(SAFE_H * 0.10))
    pad  = clamp(pad, 0, 200)
    gap  = clamp(gap, 0, 2000)

    -- We are inside rotated coordinate system centered at (0,0)
    -- Draw ticker near bottom of safe area:
    local base_y = SAFE_H/2 - (size + pad * 2) - 20

    -- Optional background bar (only if supported)
    local bg = CONFIG.ticker_bg
    if bg == nil then bg = true end
    if bg and gl.rect then
        local a = tonumber(CONFIG.ticker_bg_opacity)
        if a == nil then a = 0.55 end
        a = clamp(a, 0, 1)
        gl.color(0, 0, 0, a)
        gl.rect(-SAFE_W/2, base_y - pad, SAFE_W/2, base_y + size + pad)
        gl.color(1, 1, 1, 1)
    end

    local tw = font:width(text, size)
    local t = sys.now()
    local cycle = tw + SAFE_W + gap
    local x = SAFE_W/2 - ((t * speed) % cycle)

    -- left padding: move text slightly away from left edge of bar
    local y = base_y

    font:write(x - SAFE_W/2 + pad, y, text, size, 1,1,1,1)
    font:write(x - SAFE_W/2 + pad + tw + gap, y, text, size, 1,1,1,1)
end

function node.render()
    gl.clear(0, 0, 0, 1)

    -- Everything in this block rotates (video + ticker)
    gl.pushMatrix()
    gl.translate(OX + SAFE_W/2, OY + SAFE_H/2)
    gl.rotate(angle, 0, 0, 1)
    gl.scale(2, 2, 1)

    if vid then
        util.draw_correct(vid, -SAFE_W/2, -SAFE_H/2, SAFE_W/2, SAFE_H/2)
    end

    -- rotating ticker
    pcall(draw_ticker_rotated)

    gl.popMatrix()
end
