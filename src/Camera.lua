
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

function M.Unit:get_position()
	return Vec2(self.position)
end

function M.Unit:set_position(xv, y)
	self.t_distance = 0
	self.position:set(xv, y)
end

-- World space -> camera space
function M.Unit:world_to_camera(xv, y)
	local world = Vec2(xv, y)
	return world + self.position + Core.display_size_half
end

-- Camera space -> world space
function M.Unit:camera_to_world(xv, y)
	local camera = Vec2(xv, y)
	return camera + self.position - Core.display_size_half
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
	Camera.set(Camera(position, t_speed))
	return M.data.current
end

function M.get()
	return M.data.current
end

function M.set(cam)
	M.data.current = cam
end

function M.get_position()
	return Camera.get():get_position()
end

function M.set_position(xv, y)
	Camera.get():set_position(xv, y)
end

function M.world_to_camera(xv, y)
	return Camera.get():world_to_camera(xv, y)
end

function M.camera_to_world(xv, y)
	return Camera.get():camera_to_world(xv, y)
end

function M.target(xv, y)
	Camera.get():target(xv, y)
end

function M.move(xv, y)
	Camera.get():move(xv, y)
end

function M.update(dt)
	local cam = Camera.get()
	AudioManager.set_position(cam.position.x, cam.position.y)
	cam:update(dt)
end

function M.lock()
	Camera.get():lock()
end

function M.unlock()
	Camera.get():unlock()
end

return M
