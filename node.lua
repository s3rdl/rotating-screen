-- BNO055 demo: rotating video + optional logo + optional ticker (robust)

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT * 0.95)

local angle = 0
local vid = nil
local font = resource.load_font "OpenSans-Bold.ttf"

local CONFIG = {}
local logo = nil
local last_logo_asset = nil

util.data_mapper{
    rotate = function(new_angle)
        angle = tonumber(new_angle) or 0
    end
}

local function load_logo()
    local asset = nil
    if type(CONFIG.logo) == "table" and CONFIG.logo.asset_name then
        asset = CONFIG.logo.asset_name
    else
        asset = CONFIG.logo_file or "logo.png"
    end

    if asset == last_logo_asset and logo then
        return
    end
    last_logo_asset = asset

    if asset and resource.exists(asset) then
        logo = resource.load_image(asset)
    else
        logo = nil
    end
end

local function load_video()
    local video_asset = nil
    if type(CONFIG.video) == "table" and CONFIG.video.asset_name then
        video_asset = CONFIG.video.asset_name
    else
        -- Fallback, wenn Setup (noch) nicht konfiguriert ist
        video_asset = "example.mp4"
    end

    if vid then
        vid:dispose()
        vid = nil
    end

    if video_asset and resource.exists(video_asset) then
        vid = resource.load_video{
            file = video_asset,
            looped = true,
        }
        print("Video asset:", video_asset)
    else
        vid = nil
        print("Video missing:", tostring(video_asset))
    end
end

util.json_watch("config.json", function(config)
    CONFIG = config or {}
    load_video()
    load_logo()
end)

local function draw_logo()
    -- nil => an, nur false => aus
    if CONFIG.show_logo == false then return end
    if not logo then load_logo() end
    if not logo then return end

    local margin = tonumber(CONFIG.logo_margin) or 30
    local h = tonumber(CONFIG.logo_height) or 90
    local pos = CONFIG.logo_pos or "top_right"

    local a = tonumber(CONFIG.logo_opacity)
    if a == nil then a = 1 end
    if a < 0 then a = 0 end
    if a > 1 then a = 1 end

    local iw, ih = logo:size()
    if not iw or not ih or ih == 0 then return end
    local w = h * (iw / ih)

    local x, y = margin, margin
    if pos == "top_left" then
        x, y = margin, margin
    elseif pos == "top_right" then
        x, y = WIDTH - w - margin, margin
    elseif pos == "bottom_left" then
        x, y = margin, HEIGHT - h - margin
    elseif pos == "bottom_right" then
        x, y = WIDTH - w - margin, HEIGHT - h - margin
    end

    gl.color(1, 1, 1, a)
    logo:draw(x, y, x + w, y + h)
    gl.color(1, 1, 1, 1)
end

local function draw_ticker()
    -- nil => an, nur false => aus
    if CONFIG.show_ticker == false then return end

    local text = CONFIG.ticker_text or ""
    if text == "" then
        text = "Ticker aktiv (setze ticker_text im Setup)"
    end

    local size = tonumber(CONFIG.ticker_font_size) or 44
    local pad  = tonumber(CONFIG.ticker_padding) or 18
    local speed = tonumber(CONFIG.ticker_speed) or 120
    local gap = tonumber(CONFIG.ticker_gap) or 60

    local bar_h = size + pad * 2
    local y = HEIGHT - bar_h + pad

    -- Hintergrund nur, wenn verfügbar (manche Builds haben kein gl.rect)
    if gl.rect then
        gl.color(0, 0, 0, 0.55)
        gl.rect(0, HEIGHT - bar_h, WIDTH, HEIGHT)
        gl.color(1, 1, 1, 1)
    end

    local tw = font:width(text, size)
    local t = sys.now()
    local cycle = tw + WIDTH + gap
    local x = WIDTH - ((t * speed) % cycle)

    font:write(x, y, text, size, 1, 1, 1, 1)
    font:write(x + tw + gap, y, text, size, 1, 1, 1, 1)
end

function node.render()
    gl.clear(0, 0, 0, 1)

    -- Rotiertes Video
    gl.pushMatrix()
    gl.translate(WIDTH/2, HEIGHT/2)
    gl.rotate(angle, 0, 0, 1)
    gl.scale(2, 2, 1)

    if vid then
        util.draw_correct(vid, -WIDTH/2, -HEIGHT/2, WIDTH/2, HEIGHT/2)
    else
        -- Debug, falls Video fehlt
        font:write(-WIDTH/2 + 20, -HEIGHT/2 + 20, "NO VIDEO", 60, 1, 0, 0, 1)
    end

    gl.popMatrix()

    -- Debug-Version, damit du Updates sicher erkennst
    font:write(20, 20, "VERSION 9", 40, 1,1,1,1)

    -- Overlays (nicht rotiert)
    draw_logo()
    draw_ticker()
end
