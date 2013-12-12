
module("Animator", package.seeall)

require("src/Util")

Mode = {
	Stop = 1,
	Loop = 2
}

BatchMode = {
	Dynamic = 1,
	Static = 2,
	Stream = 3
}

local BatchModeName = {
	"dynamic",
	"static",
	"stream"
}

-- class AnimInstance

local AnimInstance = {}
AnimInstance.__index = AnimInstance

function AnimInstance:__init(ad, sindex, mode)
	Util.tcheck(ad, "table")
	Util.tcheck(sindex, "number", true)
	Util.tcheck(mode, "number", true)

	assert(1 <= sindex and #ad.set >= sindex)

	sindex = Util.optional(sindex, 1)
	mode = Util.optional(mode, Mode.Stop)

	self.batch_id = nil
	self.data = ad
	self:reset(sindex, mode)
end

function AnimInstance:reset(sindex, mode)
	self.mode = mode
	self.playing = true
	self.set = self.data.set[sindex]
	self.accum = 0.0
	self.frame = 1
end

function rewind(frame)
	if nil ~= frame then
		self.accum = frame * self.data.duration
		self.frame = frame
	else
		self.accum = 0.0
		self.frame = 1
	end
	self.playing = true
end

function AnimInstance:is_playing()
	return self.playing
end

-- Will return false if either the animation is
-- not playing or if the animation has looped
function AnimInstance:update(dt)
	if self.playing then
		self.accum = self.accum + dt
		if self.data.duration <= self.accum then
			local amt = math.floor(self.accum/self.data.duration)
			local new_frame = self.frame + amt
			if new_frame > #self.set then
				if Mode.Loop == self.mode then
					self.accum = 0.0
					self.frame = 1
					return false
				else
					self.frame = #self.set
					self.playing = false
				end
			else
				self.accum = self.accum - (amt * self.data.duration)
				self.frame = new_frame
			end
		end
		return self.playing
	else
		return false
	end
end

function AnimInstance:render(x,y, r, sx,sy, ox,oy)
	Gfx.drawq(
		self.data.tex, self.set[self.frame],
		x,y, r, sx,sy, ox,oy
	)
end

-- class AnimBatcher

local AnimBatcher = {}
AnimBatcher.__index = AnimBatcher

function AnimBatcher:__init(ad, limit, mode)
	Util.tcheck(ad, "table")
	Util.tcheck(limit, "number")
	Util.tcheck(mode, "number", true)

	mode = Util.optional(mode, BatchMode.Dynamic)

	self.data = ad
	self.limit = limit
	self.mode = mode
	self.batch = Gfx.newSpriteBatch(
		self.data.tex,
		self.limit,
		BatchModeName[self.mode]
	)
	self.active = {}
end

function AnimBatcher:clear()
	self.batch:clear()
	self.active = {}
end

function AnimBatcher:batch_begin()
	self.batch:bind()
end

function AnimBatcher:batch_end()
	self.batch:unbind()
end

-- NOTE: add order determines render order
function AnimBatcher:add(inst, x,y, r, sx,sy, ox,oy)
	local batch_id = self.active[inst]
	if nil ~= batch_id then
		self.batch:setq(
			batch_id,
			inst.set[inst.frame],
			x,y, r, sx,sy, ox,oy
		)
	else
		if self.limit <= #self.active then
			Util.debug("AnimBatcher: batch full")
		else
			local batch_id = self.batch:addq(
				inst.set[inst.frame],
				x,y, r, sx,sy, ox,oy
			)
			self.active[inst] = batch_id
		end
	end
end

function AnimBatcher:render()
	Gfx.draw(self.batch, 0,0)
end

-- Animator interface

local data = {
	__initialized = false
}

function init(anim_table)
	Util.tcheck(anim_table, "table")
	assert(not data.__initialized)

	data.__initialized = true
end

function batcher(ad, limit, mode)
	return Util.new_object(AnimBatcher, ad, limit, mode)
end

function instance(ad, sindex, mode)
	return Util.new_object(AnimInstance, ad, sindex, mode)
end
