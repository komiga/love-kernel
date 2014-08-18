
STUBScreen = STUBScreen or {}
local M = STUBScreen

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Screen")
require("src/Camera")
require("src/AudioManager")
require("src/FieldAnimator")
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
	}
}

-- class Impl

M.Impl = Util.class(M.Impl)

function M.Impl:__init()
	-- TODO: INITIALIZE
end

function M.Impl:notify_pushed()
	-- TODO: PUSH-INIT
end

function M.Impl:notify_became_top()
end

function M.Impl:notify_popped()
	-- TODO: POP-DEINIT
end

function M.Impl:focus_changed(focused)
	if not State.pause_lock then
		Core.pause(not focused)
	end
end

function M.Impl:bind_gate(bind, ident, dt, kind)
	return not State.paused
end

function M.Impl:update(dt)
	if not State.paused then
		-- TODO: UPDATE THE THINGS
	end
end

function M.Impl:render()
	Camera.lock()

	-- TODO: RENDER ALL THE THINGS

	Camera.unlock()
end

-- STUBScreen interface

local function __static_init()
	if not data.bind_group then
		data.bind_group = Bind.new_group(data.bind_table)
	end
end

-- Make local if singleton
--[[local--]] function M.new(transparent)
	__static_init()

	local impl = Util.new_object(M.Impl)
	return Screen.new(impl, data.bind_group, transparent)
end

-- Singleton
--[[

function M.init(_)
	assert(not data.__initialized)
	data.instance = M.new(false)
	data.impl = data.instance.impl
	data.__initialized = true

	return data.instance
end

function M.get_instance()
	return data.instance
end

--]]
