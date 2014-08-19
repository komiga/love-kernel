
Timer = love.timer
Event = love.event
Gfx = love.graphics
Sfx = love.audio
Phys = love.physics

HID = {
	Mouse = love.mouse,
	Keyboard = love.keyboard
}

require("src/State")
require("src/Math")
require("src/Core")

HID.Mouse.pos = Vec2()

local lurker = nil

local function module_reload(path)
	local modname = lurker.modname(path)
	local mod = require(modname)
	if "table" == type(mod) and mod.module_reload then
		mod.module_reload()
	end
end

if State.auto_reload then
	lurker = require("dep/lurker/lurker")
	lurker.interval = 1.0
	lurker.postswap = module_reload
end

function love.load(argv)
	Core.init(argv)
end

function love.update(dt)
	if State.auto_reload then
		lurker.update()
	end
	Core.update(dt)
end

function love.draw()
	Gfx.clear()
	Gfx.origin()
	Core.render()
	Gfx.present()
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
    local frame_time = 1.0 / 60.0

	while true do
		local update_screen = false
	    local current_time = Timer.getTime() - base_time

		while sim_time <= current_time do
			update_screen = true
			HID.Mouse.pos:set(HID.Mouse.getX(), HID.Mouse.getY())

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

			love.update(frame_time)
			sim_time = current_time + frame_time
		end

		if update_screen then
			love.draw()
		end
		Timer.sleep(0.001)
	end
end
