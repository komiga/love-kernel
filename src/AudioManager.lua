
AudioManager = AudioManager or {}
local M = AudioManager

M.InstancePolicy = {
	-- Kill immediately, regardless of limit; grow past limit
	Immediate = 1,
	-- Never kill, never grow
	Constant = 2,
	-- Can grow past limit, does not go below limit
	Reserve = 3,
	-- Never kill, never grow; trample active sounds
	Trample = 4
}

-- class SoundInstance

M.SoundInstance = Util.class(M.SoundInstance)

function M.SoundInstance.new(sound_data, x, y, z)
	return Util.new_object(M.SoundInstance, sound_data, x, y, z)
end

function M.SoundInstance:__init(sound_data, x, y, z)
	self.source = Sfx.newSource(sound_data.data, "static")
	self:set_position(x, y, z)
end

function M.SoundInstance:set_position(x, y, z)
	self.source:setPosition(x, y, z)
end

function M.SoundInstance:stop()
	self.source:stop()
end

function M.SoundInstance:play()
	self.source:play()
end

function M.SoundInstance:restart()
	self.source:rewind()
end

function M.SoundInstance:is_playing()
	return not self.source:isStopped()
end

function M.SoundInstance:update(_)
	return self:is_playing()
end

-- class Bucket

M.Bucket = Util.class(M.Bucket)

function M.Bucket.new(sound_data)
	return Util.new_object(M.Bucket, sound_data)
end

function M.Bucket:__init(sound_data)
	Util.tcheck(sound_data, "table")
	Util.tcheck_obj(sound_data.data, "SoundData")

	self.data = sound_data
	self.active = {}
	self.free = {}

	if M.InstancePolicy.Immediate ~= self.data.policy then
		for i = 1, self.data.limit do
			table.insert(
				self.free,
				M.SoundInstance.new(sound_data, 0.0, 0.0, 0.0)
			)
		end
		self.count = self.data.limit
	end
end

function M.Bucket:can_grow()
	return
		M.InstancePolicy.Constant ~= self.data.policy and
		M.InstancePolicy.Trample ~= self.data.policy
end

function M.Bucket:spawn(x, y, z)
	local inst
	if 0 < #self.free then
		inst = Util.last(self.free)
		table.remove(self.free)
	else
		if self:can_grow() then
			inst = M.SoundInstance.new(self.data, x, y, z)
			self.count = self.count + 1
		elseif
			M.InstancePolicy.Trample == self.policy
			and 0 < #self.active
		then
			self.active[1]:rewind()
		end
	end
	if nil ~= inst then
		table.insert(self.active, inst)
		Util.debug_sub(State.sfx_debug,
			"sound spawned: " .. self.data.__name .. ": " .. #self.active
		)
		inst:play()
	end
end

function M.Bucket:update(dt)
	local policy = self.data.policy
	if 0 < #self.active then
		for i, inst in pairs(self.active) do
			if not inst:update(dt) then
				Util.debug_sub(State.sfx_debug,
					"sound ended: " .. self.data.__name .. ": " .. i
				)
				table.remove(self.active, i)
				if
					M.InstancePolicy.Constant == policy
					or M.InstancePolicy.Trample == policy
					or (M.InstancePolicy.Reserve == policy
						and self.count <= self.data.limit)
				then
					Util.debug_sub(State.sfx_debug, "  (kept)")
					table.insert(self.free, inst)
				else
					Util.debug_sub(State.sfx_debug, "  (murdered)")
					self.count = self.count - 1
				end
			end
		end
	end
end

-- AudioManager interface

local data = {
	__initialized = false,
	paused = nil,
	buckets = nil
}

function M.init(sound_table)
	Util.tcheck(sound_table, "table")
	assert(not data.__initialized)

	data.paused = false
	data.buckets = {}
	data.__initialized = true

	for _, sd in pairs(sound_table) do
		data.buckets[sd.__id] = M.Bucket.new(sd)
	end
end

function M.set_position(x, y, z)
	Sfx.setPosition(x, y, Util.optional(z, 0.0))
	--Util.debug("AudioManager.set_position: ", x, y, z)
end

function M.spawn(sound_data, x, y, z)
	local bkt = data.buckets[sound_data.__id]
	assert(nil ~= bkt)

	bkt:spawn(
		Util.optional(x, 0.0),
		Util.optional(y, 0.0),
		Util.optional(z, 0.0)
	)
end

function M.pause()
	if not data.paused then
		Sfx.pause()
		data.paused = true
	end
end

function M.resume()
	if data.paused then
		Sfx.resume()
		data.paused = false
	end
end

function M.update(dt)
	if not data.paused then
		for _, bkt in pairs(data.buckets) do
			bkt:update(dt)
		end
	end
end
