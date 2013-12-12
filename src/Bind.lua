
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
	binds = nil,
	gate_fn = nil,
	active = nil
}

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
		true == exec_gate(bind, ident, dt, kind) or
		true == bind.passthrough
	then
		if nil ~= bind.handler then
			bind.handler(ident, dt, kind, bind)
		end
	end
end

local function bind_press(ident, _)
	local bind = data.binds[ident]
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
	local bind = data.binds[ident]
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

-- Bind interface

function init(bind_table, gate_fn)
	Util.tcheck(bind_table, "table")
	Util.tcheck(gate_fn, "function")

	assert(not data.__initialized)

	data.binds = bind_table
	data.gate_fn = gate_fn
	data.active = {}

	local check = {}
	local expanded = {}
	for ident, bind in pairs(data.binds) do
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
		data.binds[ident] = bind
	end

	data.__initialized = true
end

function set_gate(gate_fn)
	data.gate_fn = gate_fn
end

function is_active(native)
	return nil ~= data.active[native]
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
	--Bind.mouse_press(x, y, button)
end

function love.mousereleased(x, y, button)
	--Bind.mouse_release(x, y, button)
end
