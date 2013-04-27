
module("Camera", package.seeall)

require("src/Util")

local data={
	__love_translate=Gfx.translate,
	__initialized=false,
	cam=nil
}

data.__camera_translate=function(x, y)
	data.__love_translate(
		x+data.cam.x-Core.display_width_half,
		y+data.cam.y-Core.display_height_half
	)
end

-- class Camera

local Unit={}
Unit.__index=Unit

function Unit:__init(x, y, x_speed, y_speed)
	Util.tcheck(x, "number")
	Util.tcheck(y, "number")
	Util.tcheck(x_speed, "number", true)
	Util.tcheck(y_speed, "number", true)

	x_speed=Util.optional(x_speed, 100.0)
	y_speed=Util.optional(y_speed, 100.0)

	self.x=x
	self.y=y
	self.x_speed=x_speed
	self.y_speed=y_speed
	self.x_target=x
	self.y_target=y
end

function Unit:set_position(x, y)
	self.x=x
	self.y=y
end

function Unit:target(x, y)
	if 0==self.x_speed then
		self.x=x
	else
		self.x_target=x
	end
	if 0==self.y_speed then
		self.y=y
	else
		self.y_target=y
	end
end

function Unit:move(x, y)
	self:target(self.x+x, self.y+y)
end

function Unit:update(dt)
	local delta
	if self.x~=self.x_target then
		delta=self.x_speed*dt
		self.x=Util.ternary(
			self.x<self.x_target,
			math.min(self.x+delta, self.x_target),
			math.max(self.x-delta, self.x_target)
		)
	end
	if self.y~=self.y_target then
		delta=self.y_speed*dt
		self.y=Util.ternary(
			self.y<self.y_target,
			math.min(self.y+delta, self.y_target),
			math.max(self.y-delta, self.y_target)
		)
	end
end

function Unit:lock()
	Gfx.push()
	Gfx.translate=data.__camera_translate
	Gfx.translate(0, 0)
end

function Unit:unlock()
	Gfx.translate=data.__love_translate
	Gfx.pop()
end

-- Camera interface

-- If x_speed or y_speed are 0, :move() and :target()
-- are the same as :set_position()
function new(x, y, x_speed, y_speed)
	return Util.new_object(Unit, x, y, x_speed, y_speed)
end

function init(x, y, x_speed, y_speed)
	assert(not data.__initialized)

	data.cam=Camera.new(x, y, x_speed, y_speed)

	data.__initialized=true
	return data.cam
end

function get_x()
	return data.cam.x
end

function get_y()
	return data.cam.y
end

function relative_x(x)
	return x+data.cam.x
end

function relative_y(y)
	return y+data.cam.y
end

function get_active()
	return data.cam
end

function set(cam)
	data.cam=cam
end

function target(x, y)
	data.cam:target(x, y)
end

function move(x, y)
	data.cam:move(x, y)
end

function update(dt)
	data.cam:update(dt)
end

function lock()
	data.cam:lock()
end

function unlock()
	data.cam:unlock()
end
