
module("STUBScreen", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Screen")
require("src/Camera")
require("src/AudioManager")
require("src/FieldAnimator")
require("src/Hooker")
require("src/Animator")
require("src/AssetLoader")
require("src/Asset")

local data = {
	bind_table = nil,
	bind_group = nil,

	-- Singleton
	--[[
	__initialized = false,
	instance = nil,
	impl = nil
	--]]
}

data.bind_table = {
	["mouse1"] = {
		on_active = true,
		handler = function(_, _, _, _)
			Camera.target(
				Camera.srel_x(HID.Mouse.getX()),
				Camera.srel_y(HID.Mouse.getY())
			)
		end
	},
	[{"up", "down", "left", "right"}] = {
		on_active = true,
		handler = function(ident, _, _, _)
			local xm, ym = 40.0, 40.0
			if "up" == ident then
				Camera.move(0.0, -ym)
			elseif "down" == ident then
				Camera.move(0.0,  ym)
			elseif "left" == ident then
				Camera.move(-xm, 0.0)
			elseif "right" == ident then
				Camera.move( xm, 0.0)
			end
		end
	}
}

-- class Impl

local Impl = {}
Impl.__index = Impl

function Impl:__init()
	-- TODO: INITIALIZE
end

function Impl:notify_pushed()
	-- TODO: PUSH-INIT
end

function Impl:notify_popped()
	-- TODO: POP-DEINIT
end

function Impl:update(dt)
	if not State.paused then
		-- TODO: UPDATE THINGS
	end
end

function Impl:render()
	Camera.lock()

	-- TODO: RENDER ALL THE THINGS

	Camera.unlock()
end

function Impl:bind_gate(bind, ident, dt, kind)
	return not State.paused
end

-- STUBScreen interface

local function __static_init()
	if not data.bind_group then
		data.bind_group = Bind.new_group(data.bind_table)
	end
end

-- Make local if singleton
--[[local--]] function new(transparent)
	__static_init()

	local impl = Util.new_object(Impl)
	return Screen.new(impl, data.bind_group, transparent)
end

-- Singleton
--[[

function init(_)
	assert(not data.__initialized)
	data.instance = new(false)
	data.impl = data.instance.impl
	data.__initialized = true

	return data.instance
end

function get_instance()
	return data.instance
end

--]]
