
require("src/State")
require("src/Util")
require("src/Bind")
require("src/Scene")
require("src/Camera")
require("src/AudioManager")
require("src/Hooker")
require("src/Animator")
require("src/AssetLoader")
require("src/Asset")

require("src/Scene/Intro")

local M = def_module("MainScene", {
	__initialized = false,

	bind_table = nil,
	bind_group = nil,
	impl = nil,
	instance = nil
})

M.data.bind_table = Bind.redefine_group(M.data.bind_table, {
	["escape"] = {
		on_release = true,
		passthrough = false,
		handler = function(_, _, _, _)
			Event.quit()
		end
	},
	["mouse1"] = {
		on_press = true,
		on_active = true,
		on_release = true,
		data = {
			x_origin = 0,
			y_origin = 0,
		},
		handler = function(_, _, kind, bind)
			if Bind.Kind.Press == kind then
				bind.data.x_origin = Camera.srel_x(HID.Mouse.getX())
				bind.data.y_origin = Camera.srel_y(HID.Mouse.getY())
			elseif Bind.Kind.Active == kind then
				Camera.set_position(
					bind.data.x_origin + Core.display_width_half - HID.Mouse.getX(),
					bind.data.y_origin + Core.display_height_half - HID.Mouse.getY()
				)
			end
		end
	},
	["mouse2"] = {
		on_press = true,
		on_active = true,
		handler = function(_, _, kind, _)
			if
				Bind.Kind.Active ~= kind or
				Bind.has_modifiers_any("lctrl", "rctrl")
			then
				Camera.target(
					Camera.srel_x(HID.Mouse.getX()),
					Camera.srel_y(HID.Mouse.getY())
				)
			end
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
			AudioManager.spawn(Asset.sound.waaauu)
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
})

-- class Impl

M.Impl = class(M.Impl)

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
	Scene.push(IntroScene.new(
		Asset.intro_seq,
		Asset.atlas.intro_seq,
		false,
		false
	))
end

function M.Impl:pause(on)
	if not State.pause_lock then
		if self.scene_unit:is_top() then
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

-- MainScene interface

local function __static_init()
	Camera.init(
		Core.display_width_half, Core.display_height_half,
		400.0
	)

	if not M.data.bind_group then
		M.data.bind_group = Bind.Group(M.data.bind_table)
	end
	Hooker.init(Asset.hooklets, Asset.font.main)
end

local function new(transparent)
	__static_init()

	local impl = new_object(M.Impl)
	return Scene.new(impl, M.data.bind_group, transparent)
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

return M
