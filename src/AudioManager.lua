
module("AudioManager", package.seeall)

InstancePolicy={
	-- Kill immediately, regardless of limit; grow past limit
	Immediate=1,
	-- Never kill, never grow
	Constant=2,
	-- Can grow past limit, does not go below limit
	Reserve=3
}

-- class SoundInstance

local SoundInstance={}
SoundInstance.__index=SoundInstance

function SoundInstance.new(sound_data, x, y, z)
	return Util.new_object(SoundInstance, sound_data, x, y, z)
end

function SoundInstance:__init(sound_data, x, y, z)
	self.source=Sfx.newSource(sound_data.data, "static")
	self:set_position(x, y, z)
end

function SoundInstance:set_position(x, y, z)
	self.source:setPosition(x, y, z)
end

function SoundInstance:play()
	self.source:play()
end

function SoundInstance:is_playing()
	return not self.source:isStopped()
end

function SoundInstance:update(_)
	return self:is_playing()
end

-- class Bucket

local Bucket={}
Bucket.__index=Bucket

function Bucket.new(sound_data)
	return Util.new_object(Bucket, sound_data)
end

function Bucket:__init(sound_data)
	Util.tcheck(sound_data, "table")
	Util.tcheck_obj(sound_data.data, "SoundData")

	self.data=sound_data
	self.active={}
	self.free={}

	if InstancePolicy.Immediate~=self.data.policy then
		for i=1, self.data.limit do
			table.insert(
				self.free,
				SoundInstance.new(sound_data, 0.0, 0.0, 0.0)
			)
		end
		self.count=self.data.limit
	end
end

function Bucket:spawn(x, y, z)
	local inst
	if 0<#self.free then
		inst=Util.last(self.free)
		table.remove(self.free)
	else
		if InstancePolicy.Constant~=self.data.policy then
			inst=SoundInstance.new(self.data, x, y, z)
			self.count=self.count+1
		end
	end
	if nil~=inst then
		table.insert(self.active, inst)
		Util.debug("SoundInstance started: "..#self.active)
		inst:play()
	end
end

function Bucket:update(dt)
	local policy=self.data.policy
	if 0<#self.active then
		for i, inst in pairs(self.active) do
			if not inst:update(dt) then
				Util.debug(
					"SoundInstance finished: "..i..
					" count="..self.count
				)
				table.remove(self.active, i)
				if
					InstancePolicy.Constant==policy
					or (InstancePolicy.Reserve==policy
						and self.count<=self.data.limit)
				then
					Util.debug("  (kept)")
					table.insert(self.free, inst)
				else
					Util.debug("  (murdered)")
					self.count=self.count-1
				end
			end
		end
	end
end

-- AudioManager interface

local data={
	__initialized=false,
	paused=nil,
	buckets=nil
}

function init(sound_table)
	Util.tcheck(sound_table, "table")
	assert(not data.__initialized)

	data.paused=false
	data.buckets={}
	data.__initialized=true

	for _, sd in pairs(sound_table) do
		data.buckets[sd.__id]=Bucket.new(sd)
	end
end

function set_position(x, y, z)
	Sfx.setPosition(x, y, Util.optional(z, 0.0))
end

function spawn(sound_data, x, y, z)
	local bkt=data.buckets[sound_data.__id]
	assert(nil~=bkt)

	bkt:spawn(
		Util.optional(x, 0.0),
		Util.optional(y, 0.0),
		Util.optional(z, 0.0)
	)
end

function pause()
	if not data.paused then
		Sfx.pause()
		data.paused=true
	end
end

function resume()
	if data.paused then
		Sfx.resume()
		data.paused=false
	end
end

function update(dt)
	if not data.paused then
		for _, bkt in pairs(data.buckets) do
			bkt:update(dt)
		end
	end
end
