
MainScreen = MainScreen or {}
local M = MainScreen

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Screen")
require("src/Camera")
require("src/AudioManager")
require("src/Hooker")
require("src/Animator")
require("src/AssetLoader")
require("src/Asset")

M.data = M.data or {
	__initialized = false,

	bind_table = nil,
	bind_group = nil,
	impl = nil,
	instance = nil
}

M.data.bind_table = {
	["escape"] = {
		on_release = true,
		passthrough = false,
		handler = function(_, _, _, _)
			Event.quit()
		end
	},
	["mouse1"] = {
		on_active = true,
		handler = function(_, _, _, _)
			Camera.target(
				Camera.srel_x(HID.Mouse.getX()),
				Camera.srel_y(HID.Mouse.getY())
			)
		end
	},
	["mouse2"] = {
		on_release = true,
		handler = function(_, _, _, _)
			Camera.target(
				Camera.srel_x(HID.Mouse.getX()),
				Camera.srel_y(HID.Mouse.getY())
			)
		end
	},
	[{"up", "down", "left", "right"}] = {
		on_active = true,
		handler = function(ident, _, _, _)
			local xm, ym = 40.0, 40.0
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
	[{" "}] = {
		on_release = true,
		handler = function(_, _, _, _)
			local rx = Camera.srel_x(HID.Mouse.getX())
			local ry = Camera.srel_y(HID.Mouse.getY())
			--AudioManager.spawn(Asset.sound.waaauu)
			Hooker.spawn(
				Asset.hooklets.KUMQUAT,
				rx,ry
			)
		end
	},
	["c"] = {
		on_release = true,
		handler = function(_, _, _, _)
			Hooker.clear_specific(Asset.hooklets.KUMQUAT)
		end
	},
	["i"] = {
		on_release = true,
		handler = function(_, _, _, _)
			M.data.impl:push_intro()
		end
	}
}

-- class Impl

M.Impl = Util.class(M.Impl)

function M.Impl:__init()
	local anim_data = Asset.anim.moving_square
	self.batcher = Animator.Batcher(
		anim_data, 4, Animator.BatchMode.Dynamic
	)
	self.moving_square = {
		Animator.Instance(anim_data, 1, Animator.Mode.Bounce),
		Animator.Instance(anim_data, 2, Animator.Mode.Bounce),
		Animator.Instance(anim_data, 1, Animator.Mode.Bounce),
		Animator.Instance(anim_data, 2, Animator.Mode.Bounce)
	}
	self.pending_pause = false
end

function M.Impl:push_intro()
	Screen.push(IntroScreen.new(
		Asset.intro_seq,
		Asset.atlas.intro_seq,
		false,
		false
	))
end

function M.Impl:pause(on)
	if not State.pause_lock then
		if self.screen_unit:is_top() then
			Core.pause(on)
		else
			self.pending_pause = on
		end
	end
end

function M.Impl:notify_pushed()
	-- self:push_intro()
end

function M.Impl:notify_became_top()
	if self.pending_pause then
		self.pending_pause = false
		Core.pause(true)
	end
end

function M.Impl:notify_popped()
	Hooker.clear_specific(Asset.hooklets.KUMQUAT)
end

function M.Impl:bind_gate(bind, ident, dt, kind)
	--if "escape" == ident then
	--	return true
	--end
	return not State.paused
end

function M.Impl:update(dt)
	if State.paused then
		return
	end

	Camera.update(dt)
	Hooker.update(dt)

	for _, anim in ipairs(self.moving_square) do
		anim:update(dt)
	end
end

function M.Impl:render()
	Camera.lock()

	local b, a, t

	Gfx.point(0, 0)

	a = Asset.atlas.sprites
	t = a.__tex
	Gfx.draw(t, 128,128)
	Gfx.draw(t, a.a, 160,192)
	Gfx.draw(t, a.b, 128,160)

	a = self.moving_square
	b = self.batcher

	Gfx.push()
	--Gfx.translate(-32.0, 0.0)
	b:batch_begin()
		b:add(a[1], 32, 32)
		b:add(a[2], 32, 64)
		b:add(a[3], 64, 64)
		b:add(a[4], 64, 32)
	b:batch_end()
	b:render()
	Gfx.pop()

	Gfx.setColor(0,255,0, 255)
	Gfx.rectangle("line",
		Camera.srel_x(HID.Mouse.getX() - 16),
		Camera.srel_y(HID.Mouse.getY() - 16),
		32, 32
	)

	Hooker.render()
	Camera.unlock()
end

-- MainScreen interface

local function __static_init()
	Camera.init(
		Core.display_width_half, Core.display_height_half,
		400.0
	)

	if not M.data.bind_group then
		M.data.bind_group = Bind.new_group(M.data.bind_table)
	end
	Hooker.init(Asset.hooklets, Asset.font.main)
end

local function new(transparent)
	__static_init()

	local impl = Util.new_object(M.Impl)
	return Screen.new(impl, M.data.bind_group, transparent)
end

function M.init(_)
	assert(not M.data.__initialized)
	M.data.instance = new(false)
	M.data.impl = M.data.instance.impl
	Core.set_focus_fn(focus_changed)
	M.data.__initialized = true

	return M.data.instance
end

function M.get_instance()
	return M.data.instance
end

function M.focus_changed(focused)
	if not State.pause_lock then
		M.data.impl:pause(not focused)
	end
end
