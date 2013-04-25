
module("Animator", package.seeall)

require("src/Util")

Mode={
	Stop=1,
	Loop=2
}

-- class AnimInstance

local AnimInstance={}
AnimInstance.__index=AnimInstance

function AnimInstance:__init(anim_data, sindex, mode)
	Util.tcheck(anim_data, "table")
	Util.tcheck(sindex, "number", true)
	Util.tcheck(mode, "number", true)

	sindex=Util.optional(sindex, 1)
	mode=Util.optional(mode, Mode.Stop)

	self.data=anim_data
	self:reset(sindex, mode)
end

function AnimInstance:reset(sindex, mode)
	self.mode=mode
	self.playing=true
	self.set=self.data.set[sindex]
	self.accum=0.0
	self.frame=1
end

function rewind(frame)
	if nil~=frame then
		self.accum=frame*self.data.duration
		self.frame=frame
	else
		self.accum=0.0
		self.frame=1
	end
	self.playing=true
end

function AnimInstance:is_playing()
	return self.playing
end

-- Will return false if either the animation is not playing or if
-- the animation has looped
function AnimInstance:update(dt)
	if self.playing then
		self.accum=self.accum+dt
		if self.data.duration<=self.accum then
			local amt=math.floor(self.accum/self.data.duration)
			local new_frame=self.frame+amt
			if new_frame>#self.set then
				if Mode.Loop==self.mode then
					self.accum=0.0
					self.frame=1
					return false
				else
					self.frame=#self.set
					self.playing=false
				end
			else
				self.accum=self.accum-(amt*self.data.duration)
				self.frame=new_frame
			end
		end
		return self.playing
	else
		return false
	end
end

function AnimInstance:render(x, y)
	Gfx.drawq(
		self.data.tex, self.set[self.frame],
		x, y
	)
end

-- Animator interface

local data={
	__initialized=false
}

function init(anim_table)
	Util.tcheck(anim_table, "table")
	assert(not data.__initialized)

	data.__initialized=true
end

function instance(anim_data, sindex, mode)
	local anim={}
	setmetatable(anim, AnimInstance)

	anim:__init(anim_data, sindex, mode)
	return anim
end
