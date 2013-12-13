
module("Screen", package.seeall)

require("src/Util")
require("src/Bind")

local data = {
	__initialized = false,
	stack = nil
}

-- class Screen

local Unit = {}
Unit.__index = Unit

function Unit:__init(impl, bind_group, transparent)
	Util.tcheck(impl, "table")
	Util.tcheck(impl.notify_pushed, "function", true)
	Util.tcheck(impl.notify_popped, "function", true)
	Util.tcheck(impl.update, "function")
	Util.tcheck(impl.render, "function")
	Util.tcheck(impl.bind_gate, "function", true)
	Bind.tcheck(bind_group, true)
	Util.tcheck(transparent, "boolean", true)

	self.impl = impl
	self.impl.screen_unit = self
	self.bind_group = bind_group
	self.transparent = Util.optional(transparent, false)
end

function Unit:is_transparent()
	return self.transparent
end

function Unit:notify_pushed()
	if nil ~= self.bind_group then
		Bind.push_group(self.bind_group)
	end
	if nil ~= self.impl.notify_pushed then
		self.impl:notify_pushed()
	end
end

function Unit:notify_popped()
	if nil ~= self.bind_group then
		Bind.pop_group(self.bind_group)
	end
	if nil ~= self.impl.notify_popped then
		self.impl:notify_popped()
	end
end

function Unit:bind_gate(bind, ident, dt, kind)
	if nil ~= self.impl.bind_gate then
		return self.impl:bind_gate(bind, ident, dt, kind)
	end
	return true
end

function Unit:update(dt)
	self.impl:update(dt)
end

function Unit:render()
	self.impl:render()
end

-- Screen interface

function new(impl, bind_group, transparent)
	return Util.new_object(Unit, impl, bind_group, transparent)
end

function init()
	assert(not data.__initialized)
	data.stack = {}
	data.__initialized = true
end

function count()
	return #data.stack
end

function current()
	return 0 < count() and data.stack[count()] or nil
end

function push(screen)
	table.insert(data.stack, screen)
	screen:notify_pushed()
end

function pop(screen)
	if 0 == #data.stack then
		Util.debug("Screen.pop(): attempted to pop on empty stack")
	end
	assert(nil ~= screen and screen == current())

	table.remove(data.stack)
	screen:notify_popped()
end

function clear()
	while 0 ~= count() do
		pop(current())
	end
end

function bind_gate(bind, ident, dt, kind)
	local screen = current()
	if nil ~= screen then
		return screen:bind_gate(bind, ident, dt, kind)
	end
	return true
end

function update(dt)
	local screen = current()
	if nil ~= screen then
		if screen:is_transparent() and 1 < count() then
			data.stack[count() - 1]:update(dt)
		end
		screen:update(dt)
	end
end

function render()
	local screen = current()
	if nil ~= screen then
		if screen:is_transparent() and 1 < count() then
			data.stack[count() - 1]:render()
		end
		screen:render()
	end
end
