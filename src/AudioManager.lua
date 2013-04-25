
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

function SoundInstance.new(sound, x, y, z)
	local inst={}
	setmetatable(inst, SoundInstance)

	inst:__init(sound, x, y, z)
	return inst
end

function SoundInstance:__init(sound, x, y, z)
	self.source=Sfx.newSource(sound.data, "static")
	self:set_position(x, y, z)
end

function SoundInstance:set_position(x, y, z)
	self.source:setPosition(x, y, z)
end

function SoundInstance:play()
	self.source:play()
end

function SoundInstance:update(_)
	return not self.source:isStopped()
end

-- class Bucket

local Bucket={}
Bucket.__index=Bucket

function Bucket.new(sound)
	local bkt={}
	setmetatable(bkt, Bucket)

	bkt:__init(sound)
	return bkt
end

function Bucket:__init(sound)
	Util.tcheck(sound, "table")
	Util.tcheck_obj(sound.data, "SoundData")

	self.sound=sound
	self.active={}
	self.free={}

	if InstancePolicy.Immediate~=self.sound.policy then
		for i=1, self.sound.limit do
			table.insert(self.free, SoundInstance.new(sound, 0.0, 0.0, 0.0))
		end
		self.count=self.sound.limit
		print("#free: "..#self.free)
	end
end

function Bucket:spawn(x, y, z)
	local inst
	if 0<#self.free then
		inst=Util.last(self.free)
		table.remove(self.free)
	else
		if InstancePolicy.Constant~=self.sound.policy then
			inst=SoundInstance.new(self.sound, x, y, z)
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
	local policy=self.sound.policy
	if 0<#self.active then
		for i, inst in pairs(self.active) do
			if not inst:update(dt) then
				Util.debug("SoundInstance finished: "..i)
				table.remove(self.active, i)
				if
					InstancePolicy.Constant==policy
					or (InstancePolicy.Reserve==policy
						and self.count<=self.sound.limit)
				then
					Util.debug("  (kept) - count="..self.count)
					table.insert(self.free, inst)
				else
					Util.debug("  (murdered) - count="..self.count)
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
		data.buckets[sd]=Bucket.new(sd)
	end
end

function set_position(x, y, z)
	Sfx.setPosition(x, y, Util.optional(z, 0.0))
end

function spawn(sound, x, y, z)
	local bkt=data.buckets[sound]
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
