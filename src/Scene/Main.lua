
require("src/State")
require("src/Util")
require("src/Math")
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
			origin = Vec2(),
		},
		handler = function(_, _, kind, bind)
			if Bind.Kind.Press == kind then
				bind.data.origin = Camera.camera_to_world(HID.Mouse.pos) + Core.display_size_half
			elseif Bind.Kind.Active == kind then
				Camera.set_position(bind.data.origin - HID.Mouse.pos)
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
				Camera.target(Camera.camera_to_world(HID.Mouse.pos))
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
			local r = Camera.camera_to_world(HID.Mouse.pos)
			AudioManager.spawn(Asset.sound.waaauu)
			Hooker.spawn(Asset.hooklets.KUMQUAT, r.x, r.y)
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
	self.moving_square[1].x, self.moving_square[1].y = 32, 32
	self.moving_square[2].x, self.moving_square[2].y = 32, 64
	self.moving_square[3].x, self.moving_square[3].y = 64, 64
	self.moving_square[4].x, self.moving_square[4].y = 64, 32
	self.batcher:batch_begin()
	for _, i in pairs(self.moving_square) do
		self.batcher:add(i)
	end
	self.batcher:batch_end()
	self.pending_pause = false
end

function M.Impl:push_intro()
	Scene.push(IntroScene(
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
	self.batcher:update(dt)
end

function M.Impl:render()
	Camera.lock()

	Gfx.draw(Asset.atlas.sprites.tex, 128,128)
	Gfx.draw(Asset.atlas.sprites.tex, Asset.atlas.sprites.a, 200,128)
	Gfx.draw(Asset.atlas.sprites.tex, Asset.atlas.sprites.b, 240,128)

	self.batcher:render()

	if State.gfx_debug_cross then
		Gfx.setColor(255,128,0, 255)
		local pos = Camera.get().position - 16
		Gfx.rectangle("line", pos.x, pos.y, 32, 32)
	end

	Hooker.render()
	Camera.unlock()

	Gfx.setColor(0,255,0, 255)
	Gfx.rectangle("line",
		HID.Mouse.pos.x - 16,
		HID.Mouse.pos.y - 16,
		32, 32
	)
end

-- MainScene interface

function M.init(_)
	assert(not M.data.__initialized)
	if not M.data.bind_group then
		M.data.bind_group = Bind.Group(M.data.bind_table)
	end
	Camera.init(Core.display_size_half, 400.0)
	Hooker.init(Asset.hooklets, Asset.font.main)

	M.data.instance = Scene(M.Impl(), M.data.bind_group, false)
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
