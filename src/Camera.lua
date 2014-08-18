
Camera = Camera or {}
local M = Camera

require("src/Util")
require("src/AudioManager")

M.data = M.data or {
	__love_translate = Gfx.translate,
	__initialized = false,
	cam = nil
}

M.data.__camera_translate = function(x, y)
	M.data.__love_translate(
		Core.display_width_half - M.data.cam.x + x,
		Core.display_height_half - M.data.cam.y + y
	)
end

-- class Camera

M.Unit = Util.class(M.Unit)

function M.Unit:__init(x, y, x_speed, y_speed)
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

function M.Unit:set_position(x, y)
	self.x = x
	self.y = y
	self.x_target = x
	self.y_target = y
end

function M.Unit:target(x, y)
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

function M.Unit:move(x, y)
	self:target(self.x + x, self.y + y)
end

function M.Unit:update(dt)
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

function M.Unit:lock()
	assert(not self.locked)
	Gfx.push()
	Gfx.translate = M.data.__camera_translate
	Gfx.translate(0, 0)
	self.locked = true
end

function M.Unit:unlock()
	assert(self.locked)
	Gfx.translate = M.data.__love_translate
	Gfx.pop()
	self.locked = false
end

-- Camera interface

-- If x_speed or y_speed are 0, :move() and :target()
-- are the same as :set_position()
function M.new(x, y, x_speed, y_speed)
	return Util.new_object(M.Unit, x, y, x_speed, y_speed)
end

function M.init(x, y, x_speed, y_speed)
	assert(not M.data.__initialized)

	M.data.cam = Camera.new(x, y, x_speed, y_speed)

	M.data.__initialized = true
	return M.data.cam
end

function M.srel_x(x)
	return M.data.cam.x - Core.display_width_half + x
end

function M.srel_y(y)
	return M.data.cam.y - Core.display_height_half + y
end

function M.rel_x(x)
	return x + M.data.cam.x
end

function M.rel_y(y)
	return y + M.data.cam.y
end

function M.srel(x, y)
	return rel_x(x), rel_y(y)
end

function M.rel(x, y)
	return rel_x(x), rel_y(y)
end

function M.get()
	return M.data.cam
end

function M.set(cam)
	M.data.cam = cam
end

function M.set_position(x, y)
	M.data.cam:set_position(x, y)
end

function M.target(x, y)
	M.data.cam:target(x, y)
end

function M.move(x, y)
	M.data.cam:move(x, y)
end

function M.update(dt)
	AudioManager.set_position(M.data.cam.x, M.data.cam.y)
	M.data.cam:update(dt)
end

function M.lock()
	M.data.cam:lock()
end

function M.unlock()
	M.data.cam:unlock()
end
