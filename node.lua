-- BNO055 demo: rotating video + optional logo + optional ticker (robust)

gl.setup(1920, 1080)

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
        -- optional fallback (nur wenn du example.mp4 wirklich im Package hast)
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
    local h = tonumber(CONFIG.logo_height) or 90
    local pos = CONFIG.logo_pos or "top_right"

    local a = tonumber(CONFIG.logo_opacity)
    if a == nil then a = 1 end
    if a < 0 then a = 0 end
    if a > 1 then a = 1 end

    -- size() kann auf manchen Builds/Objekten anders sein → absichern
    local okS, iw, ih = pcall(function() return logo:size() end)
    if not okS then
        print("logo:size failed:", iw) -- iw enthält dann die Fehlermeldung
        return
    end
    if not iw or not ih or ih == 0 then
        print("logo:size returned invalid:", tostring(iw), tostring(ih))
        return
    end

    local w = h * (iw / ih)

    local x, y = margin, margin
    if pos == "top_right" then
        x, y = WIDTH - w - margin, margin
    elseif pos == "bottom_left" then
        x, y = margin, HEIGHT - h - margin
    elseif pos == "bottom_right" then
        x, y = WIDTH - w - margin, HEIGHT - h - margin
    end

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

    local y = HEIGHT - size - 30
    local tw = font:width(text, size)
    local x = WIDTH - ((sys.now() * speed) % (tw + WIDTH + gap))

    font:write(x, y, text, size, 1,1,1,1)
    font:write(x + tw + gap, y, text, size, 1,1,1,1)
end

function node.render()
    gl.clear(0, 0, 0, 1)

    -- video rotated
    gl.pushMatrix()
    gl.translate(WIDTH/2, HEIGHT/2)
    gl.rotate(angle, 0, 0, 1)
    gl.scale(2, 2, 1)

    if vid then
        util.draw_correct(vid, -WIDTH/2, -HEIGHT/2, WIDTH/2, HEIGHT/2)
    end

    gl.popMatrix()

    -- overlays not rotated
    local okL, errL = pcall(draw_logo)
    if not okL then
        print("draw_logo failed:", errL)
    end

    local okT, errT = pcall(draw_ticker)
    if not okT then
        print("draw_ticker failed:", errT)
    end
