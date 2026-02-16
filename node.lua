gl.setup(1920, 1080)

local angle = 0
local vid = nil

local font = resource.load_font "OpenSans-Bold.ttf"
local ticker = "Ticker TEST"
local tsize = 60
local speed = 160
local gap = 80

util.data_mapper{
    rotate = function(new_angle)
        angle = tonumber(new_angle) or 0
    end
}

util.json_watch("config.json", function(config)
    if vid then
        vid:dispose()
        vid = nil
    end

    if config and config.video and config.video.asset_name then
        vid = resource.load_video{
            file = config.video.asset_name,
            looped = true,
        }
        print("Video:", config.video.asset_name)
    else
        print("No video configured")
    end
end)

function node.render()
    gl.clear(0, 0, 0, 1)

    gl.pushMatrix()
    local tw = font:width(ticker, tsize)
    local x = WIDTH - ((sys.now() * speed) % (tw + WIDTH + gap))
    font:write(x, HEIGHT - tsize - 30, ticker, tsize, 1,1,1,1)
    font:write(x + tw + gap, HEIGHT - tsize - 30, ticker, tsize, 1,1,1,1)
    gl.translate(WIDTH/2, HEIGHT/2)
    gl.rotate(angle, 0, 0, 1)
    gl.scale(2, 2, 1)

    if vid then
        util.draw_correct(vid, -WIDTH/2, -HEIGHT/2, WIDTH/2, HEIGHT/2)
    end

    gl.popMatrix()
end
