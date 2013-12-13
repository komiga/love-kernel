
module("Bind", package.seeall)

require("src/Util")

Kind = {
	Press = 1,
	Active = 2,
	Release = 3
}

local MouseButton = {
	love = {
		["l"] = "mouse1",
		["r"] = "mouse2",
		["m"] = "mouse3",
		["wu"] = "mwheelup",
		["wd"] = "mwheeldown"
	},
	native = {
		["mouse1"] = "l",
		["mouse2"] = "r",
		["mouse3"] = "m",
		["mwheelup"] = "wu",
		["mwheeldown"] = "wd"
	}
}

local BadGateKeys = {
	["numlock"] = true,
	["capslock"] = true,
	["scrollock"] = true,
	["rshift"] = true,
	["lshift"] = true,
	["rctrl"] = true,
	["lctrl"] = true,
	["ralt"] = true,
	["lalt"] = true,
	["rmeta"] = true,
	["lmeta"] = true,
	["lsuper"] = true,
	["rsuper"] = true,
	["mode"] = true,
	["compose"] = true
}

local data = {
	__initialized = false,
	global_group = nil,
	gate_fn = nil,
	stack = nil,
	active = nil,
	mouse_enabled = nil
}

-- internal

local function make_bind(check, ident, bind, table)
	if true == check[ident] then
		error("multiple bind to ident '" .. ident .. "'")
	end
	table[ident] = bind
	check[ident] = true
end

local function exec_gate(bind, ident, dt, kind)
	local bad = BadGateKeys[ident]
	if not bad then
		return data.gate_fn(bind, ident, dt, kind)
	end
	return false
end

local function trigger(bind, ident, dt, kind)
	if
		true == bind.system or
		true == exec_gate(bind, ident, dt, kind) or
		true == bind.passthrough
	then
		if nil ~= bind.handler then
			bind.handler(ident, dt, kind, bind)
		end
	end
end

local function bind_press(ident, _)
	local bind = get_bind(ident)
	if nil ~= bind then
		if bind.on_press then
			trigger(bind, ident, 0.0, Kind.Press)
		else
			exec_gate(bind, ident, 0.0, Kind.Press)
		end
		if bind.on_active and exec_gate(bind, ident, 0.0, Kind.Active) then
			data.active[ident] = bind
		end
	else
		exec_gate(nil, ident, 0.0, Kind.Press)
	end
end

local function bind_release(ident)
	local bind = get_bind(ident)
	if nil ~= bind then
		if bind.on_active and exec_gate(bind, ident, 0.0, Kind.Active) then
			data.active[ident] = nil
		end
		if bind.on_release then
			trigger(bind, ident, 0.0, Kind.Release)
		else
			exec_gate(bind, ident, 0.0, Kind.Release)
		end
	else
		exec_gate(nil, ident, 0.0, Kind.Release)
	end
end

-- class BindGroup

local BindGroup = {}
BindGroup.__index = BindGroup

function BindGroup:__init(bind_table)
	Util.tcheck(bind_table, "table")

	self.bind_table = {}
	self:add(bind_table)
end

function BindGroup:has_ident(ident)
	return nil ~= self.bind_table[ident]
end

function BindGroup:get_bind(ident)
	return self.bind_table[ident]
end

function BindGroup:add(bind_table)
	Util.tcheck(bind_table, "table")

	local check = {}
	local expanded = {}
	for ident, bind in pairs(bind_table) do
		Util.tcheck(bind, "table")
		bind.ident = ident
		if "table" == type(ident) then
			for _, sub_ident in pairs(ident) do
				make_bind(check, sub_ident, bind, expanded)
			end
		else
			make_bind(check, ident, bind, expanded)
		end
	end
	for ident, bind in pairs(expanded) do
		self.bind_table[ident] = bind
	end
end

-- Bind interface

function tcheck(group, opt)
	opt = Util.optional(opt, false)
	Util.tcheck(group, "table", opt)
	assert((not group and opt) or BindGroup == group.__index)
end

function new_group(bind_table)
	return Util.new_object(BindGroup, bind_table)
end

function init(global_group, gate_fn, enable_mouse)
	Util.tcheck(global_group, "table")
	Util.tcheck(gate_fn, "function")
	Util.tcheck(enable_mouse, "boolean", true)

	assert(not data.__initialized)

	data.global_group = new_group(global_group)
	data.gate_fn = gate_fn
	data.stack = {}
	data.active = {}
	data.mouse_enabled = Util.optional(enable_mouse, true)

	data.__initialized = true
end

function count()
	return #data.stack
end

function set_gate(gate_fn)
	data.gate_fn = gate_fn
end

function push_group(group)
	Bind.tcheck(group)

	table.insert(data.stack, group)
end

function pop_group(group)
	assert(0 < count())
	Bind.tcheck(group)

	assert(group == data.stack[count()])
	table.remove(data.stack)
end

function active_group()
	return Util.ternary(
		0 < count(),
		data.stack[count()],
		data.global_group
	)
end

function is_active(native)
	return nil ~= data.active[native]
end

function get_bind(ident)
	local bind = nil
	for idx = count(), 1, -1 do
		bind = data.stack[idx]:get_bind(ident)
		if nil ~= bind then
			break
		end
	end
	return bind or data.global_group:get_bind(ident)
end

function mouse_press(_, _, button)
	local native = MouseButton.love[button]
	if nil ~= native then
		bind_press(native)
	end
end

function mouse_release(_, _, button)
	local native = MouseButton.love[button]
	if nil ~= native then
		bind_release(native)
	end
end

function update(dt)
	for ident, bind in pairs(data.active) do
		trigger(bind, ident, dt, Kind.Active)
	end
end

function clear_active()
	data.active = {}
end

-- LÖVE sinks
function love.keypressed(key, _)
	bind_press(key, _)
end

function love.keyreleased(key)
	bind_release(key, nil)
end

-- NB: For some reason disabling the mouse module does not disable
-- mouse events..
function love.mousepressed(x, y, button)
	if data.mouse_enabled then
		Bind.mouse_press(x, y, button)
	end
end

function love.mousereleased(x, y, button)
	if data.mouse_enabled then
		Bind.mouse_release(x, y, button)
	end
end
