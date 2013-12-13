
module("Core", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Screen")
require("src/Camera")
require("src/AudioManager")
require("src/Animator")
require("src/AssetLoader")

require("src/Screens/Main")
require("src/Screens/Intro")

local data = {
	bind_table = nil
}

Core.display_width = nil
Core.display_width_half = nil
Core.display_height = nil
Core.display_height_half = nil

data.bind_table = {
-- System
	["pause"] = {
		on_release = true,
		system = true,
		handler = function(_, _, _, _)
			local paused = not State.pause_lock
			State.pause_lock = false
			Core.pause(paused)
			State.pause_lock = paused
		end
	}
}

function bind_gate(bind, ident, dt, kind)
	if State.paused then
		return false
	end
	return Screen.bind_gate(bind, ident, dt, kind)
end

function init(args)
	-- Ensure debug is enabled for initialization
	local debug_mode_temp = false
	if not State.gen_debug then
		debug_mode_temp = true
		State.gen_debug = true
	end

	Core.display_width = Gfx.getWidth()
	Core.display_width_half = 0.5 * Core.display_width
	Core.display_height = Gfx.getHeight()
	Core.display_height_half = 0.5 * Core.display_height

	if not debug_mode_temp then
		data.bind_table["f1"] = {
			on_release = true,
			system = true,
			handler = function(_, _, _, _)
				State.gen_debug = not State.gen_debug
				if State.gen_debug then
					print("debug mode enabled")
				else
					print("debug mode disabled")
				end
			end
		}
		data.bind_table["f2"] = {
			on_release = true,
			system = true,
			handler = function(_, _, _, _)
				State.gfx_debug = not State.gfx_debug
				if State.gfx_debug then
					print("graphics debug mode enabled")
				else
					print("graphics debug mode disabled")
				end
			end
		}
		data.bind_table["f3"] = {
			on_release = true,
			system = true,
			handler = function(_, _, _, _)
				State.sfx_debug = not State.sfx_debug
				if State.sfx_debug then
					print("sound debug mode enabled")
				else
					print("sound debug mode disabled")
				end
			end
		}
	end

	-- system initialization
	Util.init()
	Bind.init(data.bind_table, bind_gate, true)

	-- assets
	AssetLoader.load("asset/", Asset.desc_root, Asset)
	AudioManager.init(Asset.sound)

	-- more systems
	Animator.init(Asset.anim)
	Screen.init()

	-- default rendering state
	Gfx.setFont(Asset.font.main)
	Gfx.setColor(255,255,255, 255)
	Gfx.setBackgroundColor(0,0,0, 255)

	Screen.push(MainScreen.init(args))

	-- Ensure debug is disabled after initialization
	if debug_mode_temp then
		State.gen_debug = false
	end
end

function deinit()
	Screen.clear()
end

function exit()
	Core.deinit()
	return true
end

function pause(paused)
	if not State.pause_lock then
		State.paused = paused
		if State.paused then
			AudioManager.pause()
		else
			AudioManager.resume()
		end
	end
end

function focus_changed(focused)
	if not State.pause_lock then
		pause(not focused)
	end
end

function update(dt)
	if true == State.paused then
		Bind.update(0.0)
	else
		Bind.update(dt)
		AudioManager.update(dt)
	end
	Screen.update(dt)
end

function render()
	Gfx.setColor(255,255,255, 255)
	Screen.render()

	if State.gfx_debug then
		Gfx.setColor(192,192,192, 200)
		-- Full quad
		--[[Gfx.rectangle("line",
			0.0,0.0,
			Core.display_width, Core.display_height
		)--]]

		-- Top left
		Gfx.rectangle("line",
			0.0,0.0,
			Core.display_width_half, Core.display_height_half
		)
		-- Top Right
		Gfx.rectangle("line",
			Core.display_width_half, 0.0,
			Core.display_width_half, Core.display_height_half
		)
		-- Bottom left
		Gfx.rectangle("line",
			0.0, Core.display_height_half,
			Core.display_width_half, Core.display_height_half
		)
		-- Bottom Right
		Gfx.rectangle("line",
			Core.display_width_half, Core.display_height_half,
			Core.display_width_half, Core.display_height_half
		)
	end
end
