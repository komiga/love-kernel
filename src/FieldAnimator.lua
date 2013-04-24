
module("FieldAnimator", package.seeall)

require("src/Util")

local FieldAnimator={}
FieldAnimator.__index=FieldAnimator

function new(duration, fields, trans, capped)
	local fa={}
	setmetatable(fa, FieldAnimator)

	fa:__init(duration, fields, trans, capped)
	return fa
end

function FieldAnimator:__init(duration, fields, trans, capped)
	self.duration=duration
	self.fields=fields
	self.trans=trans
	self.capped=Util.ternary(nil~=capped, capped, true)
	self:reset()
end

function FieldAnimator:is_complete()
	return 1.0<=self.total
end

function FieldAnimator:reset()
	self.time=0.0
	self.total=0.0
	self.picked={}
	for f, t in pairs(self.trans) do
		if "table"==type(t[1]) then
			-- trans for field is a table of variants
			-- instead of a direct (base,target) pair
			local index=Util.random(1, #t)
			self.picked[f]=index
		end
		if "table"==type(f) then
			for _, af in pairs(f) do
				self.fields[af]=self:get_field_trans(f)[1]
			end
		else
			self.fields[f]=self:get_field_trans(f)[1]
		end
	end
end

function FieldAnimator:get_field_trans(f)
	local index=self.picked[f]
	if nil~=index then
		return self.trans[f][index]
	else
		return self.trans[f]
	end
end

function FieldAnimator:__update_field_table(f, t)
	for _, af in pairs(f) do
		self:__update_field(af, t)
	end
end

function FieldAnimator:__update_field(f, t)
	local diff=t[2]-t[1]
	self.fields[f]=t[1]+(diff*self.total)
end

function FieldAnimator:update(dt)
	self.time=self.time+dt
	if true==self.capped and self.time>=self.duration then
		self.time=self.duration
		self.total=1.0
	else
		self.total=self.time/self.duration
	end
	for f, _ in pairs(self.trans) do
		if "table"==type(f) then
			self:__update_field_table(f, self:get_field_trans(f))
		else
			self:__update_field(f, self:get_field_trans(f))
		end
	end
	return self:is_complete()
end
