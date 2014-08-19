
require("src/Util")
require("src/AudioManager")

local M = def_module("Camera", {
	__love_translate = Gfx.translate,
	__initialized = false,
	cam = nil
})

M.data.__camera_translate = function(x, y)
	M.data.__love_translate(
		Core.display_width_half - M.data.cam.x + x,
		Core.display_height_half - M.data.cam.y + y
	)
end

-- class Camera

M.Unit = class(M.Unit)

function M.Unit:__init(x, y, speed)
	type_assert(x, "number")
	type_assert(y, "number")
	type_assert(speed, "number", true)

	speed = optional(speed, 0)

	self.x = x
	self.y = y
	self.speed = speed
	self.time = 0
	self.distance = 0
	self.x_origin = 0
	self.y_origin = 0
	self.x_target = 0
	self.y_target = 0
	self.x_speed = 0
	self.y_speed = 0
	self.locked = false
end

function M.Unit:set_position(x, y)
	self.distance = 0
	self.x = x
	self.y = y
end

function M.Unit:target(x, y)
	if 0 == self.speed then
		self.x = x
		self.y = y
	elseif x ~= self.x or y ~= self.y then
		local rx = x - self.x
		local ry = y - self.y
		self.time = 0
		self.distance = math.sqrt((rx * rx) + (ry * ry))
		self.x_origin = self.x
		self.y_origin = self.y
		self.x_target = x
		self.y_target = y
		self.x_speed = rx / self.distance
		self.y_speed = ry / self.distance
	end
end

function M.Unit:move(x, y)
	self:target(self.x + x, self.y + y)
end

function M.Unit:update(dt)
	if 0 ~= self.distance then
		self.time = self.time + dt
		local travelled = self.time * self.speed
		if travelled >= self.distance then
			self.distance = 0
			self.x = self.x_target
			self.y = self.y_target
		else
			self.x = self.x_origin + travelled * self.x_speed
			self.y = self.y_origin + travelled * self.y_speed
		end
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

-- If speed is 0, :move() and :target()
-- are the same as :set_position()
function M.new(x, y, speed)
	return new_object(M.Unit, x, y, speed)
end

function M.init(x, y, speed)
	assert(not M.data.__initialized)

	M.data.cam = Camera.new(x, y, speed)

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

return M
