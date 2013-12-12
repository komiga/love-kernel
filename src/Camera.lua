
module("Camera", package.seeall)

require("src/Util")
require("src/AudioManager")

local data = {
	__love_translate = Gfx.translate,
	__initialized = false,
	cam = nil
}

data.__camera_translate = function(x, y)
	data.__love_translate(
		Core.display_width_half - data.cam.x + x,
		Core.display_height_half - data.cam.y + y
	)
end

-- class Camera

local Unit = {}
Unit.__index = Unit

function Unit:__init(x, y, x_speed, y_speed)
	Util.tcheck(x, "number")
	Util.tcheck(y, "number")
	Util.tcheck(x_speed, "number", true)
	Util.tcheck(y_speed, "number", true)

	x_speed = Util.optional(x_speed, 0)
	y_speed = Util.optional(y_speed, 0)

	self.x = x
	self.y = y
	self.x_speed = x_speed
	self.y_speed = y_speed
	self.x_target = x
	self.y_target = y
	self.locked = false
end

function Unit:set_position(x, y)
	self.x = x
	self.y = y
	self.x_target = x
	self.y_target = y
end

function Unit:target(x, y)
	if 0 == self.x_speed then
		self.x = x
	else
		self.x_target = x
	end
	if 0 == self.y_speed then
		self.y = y
	else
		self.y_target = y
	end
end

function Unit:move(x, y)
	self:target(self.x + x, self.y + y)
end

function Unit:update(dt)
	local delta
	if self.x ~= self.x_target then
		delta = self.x_speed * dt
		self.x = Util.ternary(
			self.x < self.x_target,
			math.min(self.x + delta, self.x_target),
			math.max(self.x - delta, self.x_target)
		)
	end
	if self.y ~= self.y_target then
		delta = self.y_speed * dt
		self.y = Util.ternary(
			self.y < self.y_target,
			math.min(self.y + delta, self.y_target),
			math.max(self.y - delta, self.y_target)
		)
	end
end

function Unit:lock()
	assert(not self.locked)
	Gfx.push()
	Gfx.translate = data.__camera_translate
	Gfx.translate(0, 0)
	self.locked = true
end

function Unit:unlock()
	assert(self.locked)
	Gfx.translate = data.__love_translate
	Gfx.pop()
	self.locked = false
end

-- Camera interface

-- If x_speed or y_speed are 0, :move() and :target()
-- are the same as :set_position()
function new(x, y, x_speed, y_speed)
	return Util.new_object(Unit, x, y, x_speed, y_speed)
end

function init(x, y, x_speed, y_speed)
	assert(not data.__initialized)

	data.cam = Camera.new(x, y, x_speed, y_speed)

	data.__initialized = true
	return data.cam
end

function rel_x(x)
	return x - data.cam.x
end

function rel_y(y)
	return y - data.cam.y
end

function rel(x, y)
	return rel_x(x), rel_y(y)
end

function get()
	return data.cam
end

function set(cam)
	data.cam = cam
end

function set_position(x, y)
	data.cam:set_position(x, y)
end

function target(x, y)
	data.cam:target(x, y)
end

function move(x, y)
	data.cam:move(x, y)
end

function update(dt)
	AudioManager.set_position(data.cam.x, data.cam.y)
	data.cam:update(dt)
end

function lock()
	data.cam:lock()
end

function unlock()
	data.cam:unlock()
end
