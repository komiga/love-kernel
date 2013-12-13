
module("Timer", package.seeall)

require("src/Util")

-- class Timer

local Unit = {}
Unit.__index = Unit

function Unit:__init(duration)
	self.duration = 0.0
	self:reset(duration)
end

function Unit:reset(new_duration)
	Util.tcheck(new_duration, "number", true)
	self.duration = Util.optional(new_duration, duration)
	self.elapsed = 0.0
	self.ticks = 0
end

function Unit:has_duration()
	return 0.0 ~= self.duration
end

function Unit:duration()
	return self.duration
end

function Unit:elapsed()
	return self.elapsed
end

function Unit:ticks()
	return self.ticks
end

function Unit:update(dt)
	self.elapsed = self.elapsed + dt
	if self:has_duration() then
		if self.elapsed > self.duration then
			self.elapsed = self.elapsed - self.duration
			self.ticks = self.ticks + 1
			return true
		end
	end
	return false
end

-- Timer interface

function new(duration)
	return Util.new_object(Unit, duration)
end
