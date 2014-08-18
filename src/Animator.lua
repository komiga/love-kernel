
Animator = Animator or {}
local M = Animator

require("src/Util")

M.Mode = {
	Stop = 1,
	Loop = 2,
	Bounce = 3
}

M.BatchMode = {
	Dynamic = 1,
	Static = 2,
	Stream = 3
}

local BatchModeName = {
	"dynamic",
	"static",
	"stream"
}

-- class Instance

M.Instance = Util.class(M.Instance)

function M.Instance:__init(ad, sindex, mode)
	Util.tcheck(ad, "table")
	Util.tcheck(sindex, "number", true)
	Util.tcheck(mode, "number", true)

	assert(1 <= sindex and #ad.set >= sindex)

	sindex = Util.optional(sindex, 1)
	mode = Util.optional(mode, M.Mode.Stop)

	self.batch_id = nil
	self.data = ad
	self:reset(sindex, mode)
end

function M.Instance:reset(sindex, mode)
	self.mode = mode
	self.playing = true
	self.set = self.data.set[sindex]
	self.accum = 0.0
	self.frame = 1
	self.reverse = false
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

function M.Instance:is_playing()
	return self.playing
end

-- Will return false if either the animation is
-- not playing or if the animation has looped
function M.Instance:update(dt)
	if self.playing then
		self.accum = self.accum + dt
		if self.data.duration <= self.accum then
			local amt = math.floor(self.accum / self.data.duration)
			local new_frame = self.frame + (self.reverse and -amt or amt)
			if 0 >= new_frame or new_frame > #self.set then
				if M.Mode.Bounce == self.mode then
					self.accum = 0.0
					self.frame = self.reverse and 1 or #self.set
					self.reverse = not self.reverse
					return false
				elseif M.Mode.Loop == self.mode then
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

function M.Instance:render(x,y, r, sx,sy, ox,oy)
	Gfx.draw(
		self.data.tex, self.set[self.frame],
		x,y, r, sx,sy, ox,oy
	)
end

-- class Batcher

M.Batcher = Util.class(M.Batcher)

function M.Batcher:__init(ad, limit, mode)
	Util.tcheck(ad, "table")
	Util.tcheck(limit, "number")
	Util.tcheck(mode, "number", true)

	mode = Util.optional(mode, Animator.BatchMode.Dynamic)

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

function M.Batcher:clear()
	self.batch:clear()
	self.active = {}
end

function M.Batcher:batch_begin()
	self.batch:bind()
end

function M.Batcher:batch_end()
	self.batch:unbind()
end

-- NOTE: add order determines render order
function M.Batcher:add(inst, x,y, r, sx,sy, ox,oy)
	local batch_id = self.active[inst]
	if nil ~= batch_id then
		self.batch:set(
			batch_id,
			inst.set[inst.frame],
			x,y, r, sx,sy, ox,oy
		)
	else
		if self.limit <= #self.active then
			Util.debug("Batcher: batch full")
		else
			local batch_id = self.batch:add(
				inst.set[inst.frame],
				x,y, r, sx,sy, ox,oy
			)
			self.active[inst] = batch_id
		end
	end
end

function M.Batcher:render()
	Gfx.draw(self.batch, 0, 0)
end

-- Animator interface

M.data = M.data or {
	__initialized = false
}

function M.init(anim_table)
	Util.tcheck(anim_table, "table")
	assert(not M.data.__initialized)

	M.data.__initialized = true
end
