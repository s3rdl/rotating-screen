gl.setup(1920, 1080)

local angle = 0
local vid = nil

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
    gl.translate(WIDTH/2, HEIGHT/2)
    gl.rotate(angle, 0, 0, 1)
    gl.scale(2, 2, 1)

    if vid then
        util.draw_correct(vid, -WIDTH/2, -HEIGHT/2, WIDTH/2, HEIGHT/2)
    end

    gl.popMatrix()
end
