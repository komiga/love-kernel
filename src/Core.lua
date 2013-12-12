
module("Core", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Camera")
require("src/AudioManager")
require("src/FieldAnimator")
require("src/Hooker")
require("src/Animator")
require("src/AssetLoader")
require("src/Asset")

Binds = {
-- System
	["escape"] = {
		on_release = true,
		handler = function(_, _, _, _)
			Event.quit()
		end
	},
	["pause"] = {
		on_release = true,
		passthrough = true,
		handler = function(_, _, _, _)
			State.pause_lock = not State.pause_lock
			State.paused = State.pause_lock
			if State.paused then
				AudioManager.pause()
			else
				AudioManager.resume()
			end
		end
	},

-- Blah
	["mouse1"] = {
		on_active = true,
		handler = function(_, _, _, _)
			Camera.target(
				HID.Mouse.getX(),
				HID.Mouse.getY()
			)
		end
	},
	[{"up", "down", "left", "right"}] = {
		on_active = true,
		handler = function(ident, _, _, _)
			local xm, ym = 5.0, 5.0
			if "up" == ident then
				Camera.move(0.0, -ym)
			elseif "down" == ident then
				Camera.move(0.0,  ym)
			elseif "left" == ident then
				Camera.move(-xm, 0.0)
			elseif "right" == ident then
				Camera.move( xm, 0.0)
			end
		end
	},
	[{" ", "mouse2"}] = {
		on_release = true,
		handler = function(_, _, _, _)
			local rx = Camera.rel_x(HID.Mouse.getX() - Core.display_width_half)
			local ry = Camera.rel_y(HID.Mouse.getY() - Core.display_height_half)
			Util.debug("rx=" .. rx .. "  ry=" .. ry)
			AudioManager.spawn(Asset.sound.waaauu)
			Hooker.spawn(
				Asset.hooklets.KUMQUAT,
				rx,ry
			)
		end
	},
	["f1"] = {
		on_release = true,
		handler = function(_, _, _, _)
			Hooker.clear()
		end
	}
}

function bind_trigger_gate(_, _, _, _)
	return false == State.paused
end

function init(_)
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
		Core.Binds["f1"] = {
			on_release = true,
			handler = function(_, _, _, _)
				State.gen_debug = not State.gen_debug
				if State.gen_debug then
					print("debug mode enabled")
				else
					print("debug mode disabled")
				end
			end
		}
		Core.Binds["f2"] = {
			on_release = true,
			handler = function(_, _, _, _)
				State.gfx_debug = not State.gfx_debug
				if State.gfx_debug then
					print("graphics debug mode enabled")
				else
					print("graphics debug mode disabled")
				end
			end
		}
		Core.Binds["f3"] = {
			on_release = true,
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
	Bind.init(Core.Binds, Core.bind_trigger_gate)

	-- assets
	AssetLoader.load("asset/", Asset.desc_root, Asset)
	AudioManager.init(Asset.sound)

	-- more systems
	Camera.init(
		Core.display_width_half, Core.display_height_half,
		Core.display_width_half, Core.display_height_half,
		60.0, 60.0
	)

	Hooker.init(Asset.hooklets, Asset.font.main)
	Animator.init(Asset.anim)

	-- default rendering state
	Gfx.setFont(Asset.font.main)
	Gfx.setColor(255,255,255, 255)
	Gfx.setBackgroundColor(0,0,0, 255)

	--Gfx.setLineWidth(2.0)
	--Gfx.setLineStyle("smooth")

	local anim_data = Asset.anim.moving_square
	Core.batcher = Animator.batcher(
		anim_data, 4, Animator.BatchMode.Dynamic
	)
	Core.moving_square = {
		Animator.instance(anim_data, 1, Animator.Mode.Loop),
		Animator.instance(anim_data, 2, Animator.Mode.Loop),
		Animator.instance(anim_data, 1, Animator.Mode.Loop),
		Animator.instance(anim_data, 2, Animator.Mode.Loop),
		data = anim_data,
		i1 = 1, i2 = 2,
		i3 = 3, i4 = 4
	}

	-- Ensure debug is disabled after initialization
	if debug_mode_temp then
		State.gen_debug = false
	end
end

function deinit()
	Core.moving_square = nil
	Core.batcher = nil
end

function exit()
	Core.deinit()
	return true
end

function focus_changed(focused)
	if not State.pause_lock then
		State.paused = not focused
	end
end

function update(dt)
	if true == State.paused then
		Bind.update(0.0)
	else
		Camera.update(dt)
		Bind.update(dt)
		Hooker.update(dt)
		AudioManager:update(dt)

		Core.moving_square[1]:update(dt)
		Core.moving_square[2]:update(dt)
		Core.moving_square[3]:update(dt)
		if not Core.moving_square[4]:update(dt) then
			Core.moving_square.i1,
			Core.moving_square.i2=
			Core.moving_square.i2,
			Core.moving_square.i1
			Core.moving_square.i3,
			Core.moving_square.i4=
			Core.moving_square.i4,
			Core.moving_square.i3
		end
	end
end

function render()
	Gfx.setColor(255,255,255, 255)

	Gfx.rectangle("line",
		0.0,0.0, Core.display_width, Core.display_height
	)

	Camera.lock()
	local b, a, t

	Gfx.point(
		Camera.rel_x(0),
		Camera.rel_y(0)
	)

	a = Asset.atlas.sprites
	t = a.__tex
	Gfx.draw(t, 128,128)
	Gfx.drawq(t, a.a, 160,192)
	Gfx.drawq(t, a.b, 128,160)

	a = Core.moving_square
	b = Core.batcher

	Gfx.push()
	--Gfx.translate(-32.0, 0.0)
	b:batch_begin()
		b:add(a[a.i1], 32, 32)
		b:add(a[a.i2], 32, 64)
		b:add(a[a.i3], 64, 64)
		b:add(a[a.i4], 64, 32)
	b:batch_end()
	b:render()
	Gfx.pop()

	Hooker.render()
	Camera.unlock()

	if State.gfx_debug then
		Gfx.setColor(255,255,255, 255)
		Gfx.rectangle("line",
			0.0,0.0, Core.display_width, Core.display_height
		)
	end
end
