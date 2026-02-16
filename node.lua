-- BNO055 demo: rotating video + optional logo + optional ticker (robust)

local W, H = 1860, 960
gl.setup(W, H)

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
    print("logo load failed:", asset, img)
    return nil
end

local function safe_load_video(asset)
    local ok, v = pcall(resource.load_video, { file = asset, looped = true })
    if ok then return v end
    print("video load failed:", asset, v)
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
        if vid then print("Video:", asset) end
    else
        print("No video configured")
    end
end

util.json_watch("config.json", function(config)
    CONFIG = config or {}
    load_video()
    load_logo()
end)

local function draw_logo()
    if CONFIG.show_logo == false then return end
    if not logo then
        print("logo is nil")
        return
    end

    local margin = tonumber(CONFIG.logo_margin) or 30
    local pos = CONFIG.logo_pos or "top_right"

    local a = tonumber(CONFIG.logo_opacity)
    if a == nil then a = 1 end
    a = clamp(a, 0, 1)

    local okS, iw, ih = pcall(function() return logo:size() end)
    if not okS or not iw or not ih or ih == 0 then
        print("logo:size invalid")
        return
    end

    -- gewünschte Höhe aus Config, aber automatisch begrenzen:
    -- max 12% Bildschirmhöhe, damit es sicher ins Bild passt
    local cfg_h = tonumber(CONFIG.logo_height) or 90
    local max_h = math.floor(H * 0.12)
    local h = clamp(cfg_h, 10, max_h)

    -- Breite entsprechend Bildformat
    local w = h * (iw / ih)

    -- Zusätzlich: max 25% Bildschirmbreite
    local max_w = W * 0.25
    if w > max_w then
        local scale = max_w / w
        w = w * scale
        h = h * scale
    end

    local x, y = margin, margin
    if pos == "top_right" then
        x, y = W - w - margin, margin
    elseif pos == "bottom_left" then
        x, y = margin, H - h - margin
    elseif pos == "bottom_right" then
        x, y = W - w - margin, H - h - margin
    end

    -- Clamp: nie aus dem Bild
    x = clamp(x, margin, W - w - margin)
    y = clamp(y, margin, H - h - margin)

    -- DEBUG label
    font:write(x, y + h + 8, "LOGO DEBUG", 34, 1,0,0,1)

    gl.color(1, 1, 1, a)
    local okD, errD = pcall(function()
        logo:draw(x, y, x + w, y + h)
    end)
    if not okD then
        print("logo:draw failed:", errD)
    end
    gl.color(1, 1, 1, 1)
end

local function draw_ticker()
    if CONFIG.show_ticker == false then return end

    local text = CONFIG.ticker_text or "Ticker TEST"
    local size = tonumber(CONFIG.ticker_font_size) or 60
    local speed = tonumber(CONFIG.ticker_speed) or 160
    local gap = tonumber(CONFIG.ticker_gap) or 80

    -- Ticker auch begrenzen, damit er nicht aus dem Bild läuft
    size = clamp(size, 12, math.floor(H * 0.08))

    local y = H - size - 20
    local tw = font:width(text, size)
    local x = W - ((sys.now() * speed) % (tw + W + gap))

    font:write(x, y, text, size, 1,1,1,1)
    font:write(x + tw + gap, y, text, size, 1,1,1,1)
end

function node.render()
    gl.clear(0, 0, 0, 1)

    -- video rotated
    gl.pushMatrix()
    gl.translate(W/2, H/2)
    gl.rotate(angle, 0, 0, 1)
    gl.scale(2, 2, 1)

    if vid then
        util.draw_correct(vid, -W/2, -H/2, W/2, H/2)
    end

    gl.popMatrix()

    -- Ticker zuerst (damit Logo-Probleme ihn nicht “wegnehmen”)
    local okT, errT = pcall(draw_ticker)
    if not okT then print("draw_ticker failed:", errT) end

    local okL, errL = pcall(draw_logo)
    if not okL then print("draw_logo failed:", errL) end

    -- Debug overlay
    font:write(20, 20,  "show_logo: " .. tostring(CONFIG.show_logo), 34, 1,1,0,1)
    font:write(20, 55,  "show_ticker: " .. tostring(CONFIG.show_ticker), 34, 1,1,0,1)
    font:write(20, 90,  "W/H: " .. tostring(W) .. "x" .. tostring(H), 34, 1,1,0,1)

    local logo_asset = (type(CONFIG.logo)=="table" and CONFIG.logo.asset_name) and CONFIG.logo.asset_name or "(nil)"
    font:write(20, 125, "logo.asset: " .. tostring(logo_asset), 28, 1,1,0,1)
    font:write(20, 155, "logo obj: " .. tostring(logo ~= nil), 34, 1,1,0,1)
end
