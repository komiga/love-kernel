
module("MainScreen", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Screen")
require("src/Camera")
require("src/AudioManager")
require("src/FieldAnimator")
require("src/Hooker")
require("src/Animator")
require("src/AssetLoader")
require("src/Asset")

local data = {
	__initialized = false,

	bind_table = nil,
	instance = nil
}

data.bind_table = {
	["mouse1"] = {
		on_active = true,
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
	[{" ", "mouse2"}] = {
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
			Hooker.clear()
		end
	}
}

-- class Unit

local Unit = {}
Unit.__index = Unit

function Unit:__init()
	self.bind_group = Bind.new_group(data.bind_table)

	local anim_data = Asset.anim.moving_square
	self.batcher = Animator.batcher(
		anim_data, 4, Animator.BatchMode.Dynamic
	)
	self.moving_square = {
		Animator.instance(anim_data, 1, Animator.Mode.Loop),
		Animator.instance(anim_data, 2, Animator.Mode.Loop),
		Animator.instance(anim_data, 1, Animator.Mode.Loop),
		Animator.instance(anim_data, 2, Animator.Mode.Loop),
		data = anim_data,
		i1 = 1, i2 = 2,
		i3 = 3, i4 = 4
	}
end

function Unit:notify_pushed()
end

function Unit:notify_popped()
	self.batcher = nil
	self.moving_square = nil
end

function Unit:update(dt)
	self.moving_square[1]:update(dt)
	self.moving_square[2]:update(dt)
	self.moving_square[3]:update(dt)
	if not self.moving_square[4]:update(dt) then
		self.moving_square.i1, self.moving_square.i2 =
		self.moving_square.i2, self.moving_square.i1
		self.moving_square.i3, self.moving_square.i4 =
		self.moving_square.i4, self.moving_square.i3
	end
end

function Unit:render()
	Camera.lock()

	local b, a, t

	Gfx.point(0, 0)

	a = Asset.atlas.sprites
	t = a.__tex
	Gfx.draw(t, 128,128)
	Gfx.drawq(t, a.a, 160,192)
	Gfx.drawq(t, a.b, 128,160)

	a = self.moving_square
	b = self.batcher

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

	Gfx.setColor(0,255,0, 255)
	Gfx.rectangle("line",
		Camera.srel_x(HID.Mouse.getX() - 16),
		Camera.srel_y(HID.Mouse.getY() - 16),
		32, 32
	)

	Hooker.render()
	Camera.unlock()
end

function Unit:bind_gate(bind, ident, dt, kind)
	return false
end

-- MainScreen interface

function init()
	assert(not data.__initialized)

	local impl = Util.new_object(Unit)
	data.instance = Screen.new(impl, impl.bind_group, false)

	data.__initialized = true

	return data.instance
end
