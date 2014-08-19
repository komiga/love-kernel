
require("src/State")
require("src/Util")
require("src/Bind")
require("src/Scene")
require("src/AudioManager")
require("src/Animator")
require("src/AssetLoader")

require("src/Scene/Main")

local M = def_module("Core", {
	bind_table = nil,
	focus_fn = nil
})

M.data.bind_table = Bind.redefine_group(M.data.bind_table, {
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
})

function M.bind_gate(bind, ident, dt, kind)
	if State.paused then
		return false
	end
	return Scene.bind_gate(bind, ident, dt, kind)
end

function M.init(args)
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
		M.data.bind_table["f1"] = {
			on_release = true,
			system = true,
			handler = function(_, _, _, _)
				State.gen_debug = not State.gen_debug
				if State.gen_debug then
					log("debug mode enabled")
				else
					log("debug mode disabled")
				end
			end
		}
		M.data.bind_table["f2"] = {
			on_release = true,
			system = true,
			handler = function(_, _, _, _)
				State.gfx_debug = not State.gfx_debug
				if State.gfx_debug then
					log("graphics debug mode enabled")
				else
					log("graphics debug mode disabled")
				end
			end
		}
		M.data.bind_table["f3"] = {
			on_release = true,
			system = true,
			handler = function(_, _, _, _)
				State.sfx_debug = not State.sfx_debug
				if State.sfx_debug then
					log("sound debug mode enabled")
				else
					log("sound debug mode disabled")
				end
			end
		}
		M.data.bind_table["f6"] = {
			on_release = true,
			system = true,
			handler = function(_, _, _, _)
				State.gfx_debug_cross = not State.gfx_debug_cross
				if State.gfx_debug_cross then
					log("graphics crosshair debug mode enabled")
				else
					log("graphics crosshair debug mode disabled")
				end
			end
		}
	end

	-- system initialization
	Util.init()
	Bind.init(M.data.bind_table, Core.bind_gate, true)

	-- assets
	AssetLoader.load("asset/", Asset.desc_root, Asset)
	AudioManager.init(Asset.sound)

	-- more systems
	Animator.init(Asset.anim)
	Scene.init()

	-- default rendering state
	Gfx.setFont(Asset.font.main)
	Gfx.setLineWidth(2.0)
	Gfx.setColor(255,255,255, 255)
	Gfx.setBackgroundColor(0,0,0, 255)

	Scene.push(MainScene.init(args))

	-- Ensure debug is disabled after initialization
	if debug_mode_temp then
		State.gen_debug = false
	end
end

function M.deinit()
	Scene.clear()
end

function M.exit()
	Core.deinit()
	return true
end

function M.pause(paused)
	if not State.pause_lock then
		State.paused = paused
		if State.paused then
			AudioManager.pause()
		else
			AudioManager.resume()
		end
	end
end

function M.set_focus_fn(fn)
	M.data.focus_fn = fn
end

function M.focus_changed(focused)
	if nil ~= M.data.focus_fn then
		M.data.focus_fn(focused)
	end
end

function M.update(dt)
	if true == State.paused then
		Bind.update(0.0)
	else
		Bind.update(dt)
		AudioManager.update(dt)
	end
	Scene.update(dt)
end

function M.render()
	Gfx.setColor(255,255,255, 255)
	Scene.render()

	if State.gfx_debug then
		Gfx.setColor(192,192,192, 200)
		-- Full quad
		Gfx.rectangle("line",
			0.0,0.0,
			Core.display_width, Core.display_height
		)
	end

	if State.gfx_debug_cross then
		Gfx.setColor(192,192,192, 200)
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

return M
