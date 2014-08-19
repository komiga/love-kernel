
require("src/Util")
require("src/Math")
require("src/AudioManager")

local M = def_module_unit("Camera", {
	__initialized = false,
	current = nil
})

-- class Camera

M.Unit = class(M.Unit)

-- If speed is 0, :move() and :target()
-- are the same as :set_position()

function M.Unit:__init(position, t_speed)
	type_assert(position, Vec2)
	type_assert(t_speed, "number")

	self.position = Vec2(position)
	self.t_speed = math.max(0, t_speed)
	self.t_time = 0
	self.t_distance = 0
	self.t_origin = Vec2()
	self.t_position = Vec2()
	self.t_velocity = Vec2()
	self.locked = false
end

function M.Unit:set_position(xv, y)
	self.t_distance = 0
	self.position:set(xv, y)
end

function M.Unit:target(xv, y)
	local t = Vec2(xv, y)
	if 0 == self.t_speed then
		self.t_distance = 0
		self.position:set(t)
	elseif t ~= self.position then
		local d = t - self.position
		self.t_time = 0
		self.t_distance = d:length()
		self.t_origin:set(self.position)
		self.t_position:set(t)
		self.t_velocity = d:normalize()
	end
end

function M.Unit:move(xv, y)
	self:target(self.position + Vec2(xv, y))
end

function M.Unit:update(dt)
	if 0 ~= self.t_distance then
		self.t_time = self.t_time + dt
		local travelled = self.t_time * self.t_speed
		if travelled >= self.t_distance then
			self.t_distance = 0
			self.position:set(self.t_position)
		else
			self.position:set(self.t_origin + self.t_velocity * travelled)
		end
	end
end

function M.Unit:lock()
	assert(not self.locked)
	local trans = Core.display_size_half - self.position
	Gfx.push()
	Gfx.translate(trans.x, trans.y)
	self.locked = true
end

function M.Unit:unlock()
	assert(self.locked)
	Gfx.pop()
	self.locked = false
end

-- Camera interface

function M.init(position, t_speed)
	assert(not M.data.__initialized)
	M.data.__initialized = true
	M.data.current = Camera(position, t_speed)
	return M.data.current
end

function M.srel_x(x)
	return M.data.current.position.x - Core.display_size_half.x + x
end

function M.srel_y(y)
	return M.data.current.position.y - Core.display_size_half.y + y
end

function M.rel_x(x)
	return x + M.data.current.position.x
end

function M.rel_y(y)
	return y + M.data.current.position.y
end

function M.srel(x, y)
	return rel_x(x), rel_y(y)
end

function M.rel(x, y)
	return rel_x(x), rel_y(y)
end

function M.get()
	return M.data.current
end

function M.set(cam)
	M.data.current = cam
end

function M.set_position(xv, y)
	M.data.current:set_position(xv, y)
end

function M.target(xv, y)
	M.data.current:target(xv, y)
end

function M.move(xv, y)
	M.data.current:move(xv, y)
end

function M.update(dt)
	local cam = M.get()
	AudioManager.set_position(cam.position.x, cam.position.y)
	cam:update(dt)
end

function M.lock()
	M.data.current:lock()
end

function M.unlock()
	M.data.current:unlock()
end

return M
