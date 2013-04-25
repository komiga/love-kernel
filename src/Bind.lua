
module("Bind", package.seeall)

require("src/Util")

Kind={
	PRESS=1,
	WHILE=2,
	RELEASE=4
}

local MouseButton={
	love={
		["l"]="mouse1",
		["r"]="mouse2",
		["m"]="mouse3",
		["wu"]="mwheelup",
		["wd"]="mwheeldown"
	},
	native={
		["mouse1"]="l",
		["mouse2"]="r",
		["mouse3"]="m",
		["mwheelup"]="wu",
		["mwheeldown"]="wd"
	}
}

local data={
	__initialized=false,
	binds=nil,
	gate_fn=nil,
	active=nil
}

local function make_bind(check, ident, bind, table)
	if true==check[ident] then
		error("multiple bind to ident '"..ident.."'")
	end
	table[ident]=bind
	check[ident]=true
end

local function trigger(bind, ident, dt)
	if nil~=bind.handler and (
			true==data.gate_fn(bind, ident)
			or true==bind.passthrough
		) then
		bind.handler(ident, dt)
	end
end

local function bind_press(ident)
	local bind=data.binds[ident]
	if nil~=bind then
		if Kind.PRESS==bind.kind then
			trigger(bind, ident, 0.0)
		elseif Kind.WHILE==bind.kind then
			data.active[ident]=bind
		end
	end
end

local function bind_release(ident)
	local bind=data.binds[ident]
	if nil~=bind then
		if Kind.RELEASE==bind.kind then
			trigger(bind, ident, 0.0)
		elseif Kind.WHILE==bind.kind then
			data.active[ident]=nil
		end
	end
end

-- Bind interface

function init(bind_table, gate_fn)
	Util.tcheck(bind_table, "table")
	Util.tcheck(gate_fn, "function")

	data.binds=bind_table
	data.gate_fn=gate_fn
	data.active={}

	local check={}
	local expanded={}
	for ident, bind in pairs(data.binds) do
		Util.tcheck(bind, "table")
		bind.ident=ident
		if "table"==type(ident) then
			for _, sub_ident in pairs(ident) do
				make_bind(check, sub_ident, bind, expanded)
			end
		else
			make_bind(check, ident, bind, expanded)
		end
	end
	for ident, bind in pairs(expanded) do
		data.binds[ident]=bind
	end

	data.__initialized=true
end

function is_active(native)
	return nil~=data.active[native]
end

function key_press(key, _)
	bind_press(key)
end

function key_release(key, _)
	bind_release(key)
end

function mouse_press(_, _, button)
	local native=MouseButton.love[button]
	if nil~=native then
		bind_press(native)
	end
end

function mouse_release(_, _, button)
	local native=MouseButton.love[button]
	if nil~=native then
		bind_release(native)
	end
end

function update(dt)
	for ident, bind in pairs(data.active) do
		trigger(bind, ident, dt)
	end
end

function love.keypressed(key, unicode)
	Bind.key_press(key, unicode)
end

function love.keyreleased(key, unicode)
	Bind.key_release(key, unicode)
end

function love.mousepressed(x, y, button)
	Bind.mouse_press(x, y, button)
end

function love.mousereleased(x, y, button)
	Bind.mouse_release(x, y, button)
end
