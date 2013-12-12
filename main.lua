
Timer = love.timer
Event = love.event
Gfx = love.graphics
Sfx = love.audio
Phys = love.physics

HID = {
	Mouse = love.mouse,
	Keyboard = love.keyboard
}

require("src/Core")

function love.load(argv)
	Core.init(argv)
end

function love.update(elapsed)
	Core.update(elapsed)
end

function love.draw()
	love.graphics.clear()
	Core.render()
	love.graphics.present()
end

function love.quit()
	return not Core.exit()
end

function love.focus(f)
	Core.focus_changed(f)
end

-- Replace love.run() to use fixed timestep
function love.run()
	-- Seed RNG
	math.randomseed(os.time())
	math.random()
	math.random()

	love.load(love.arg)

	local base_time = Timer.getTime()
	local sim_time = 0
    local frame_hertz = 1.0 / 60.0

	while true do
		local update_screen = false
	    local current_time = Timer.getTime() - base_time

		while sim_time <= current_time do
			update_screen = true

			Event.pump()
			for event, a, b, c, d in Event.poll() do
				if "quit" == event then
					if not love.quit() then
						if Sfx then
							Sfx.stop()
						end
						return
					end
				end
				love.handlers[event](a, b, c, d)
			end
			Event.clear()

			love.update(frame_hertz)
			sim_time = current_time + frame_hertz
		end

		if update_screen then
			love.draw()
			Timer.sleep(0.001)
		end
	end
end
