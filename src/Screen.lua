
Screen = Screen or {}
local M = Screen

require("src/Util")
require("src/Bind")

M.data = M.data or {
	__initialized = false,
	stack = nil
}

-- class Screen

M.Unit = class(M.Unit)

function M.Unit:__init(impl, bind_group, transparent)
	tcheck(impl, "table")
	tcheck(impl.notify_pushed, "function", true)
	tcheck(impl.notify_popped, "function", true)
	tcheck(impl.update, "function")
	tcheck(impl.render, "function")
	tcheck(impl.bind_gate, "function", true)
	Bind.tcheck(bind_group, true)
	tcheck(transparent, "boolean", true)

	self.impl = impl
	self.impl.screen_unit = self
	self.bind_group = bind_group
	self.transparent = optional(transparent, false)
end

function M.Unit:is_transparent()
	return self.transparent
end

function M.Unit:is_top()
	return Screen.current() == self
end

function M.Unit:notify_pushed()
	if nil ~= self.bind_group then
		Bind.push_group(self.bind_group)
	end
	if nil ~= self.impl.notify_pushed then
		self.impl:notify_pushed()
	end
end

function M.Unit:notify_became_top()
	if nil ~= self.impl.notify_became_top then
		self.impl:notify_became_top()
	end
end

function M.Unit:notify_popped()
	if nil ~= self.bind_group then
		Bind.pop_group(self.bind_group)
	end
	if nil ~= self.impl.notify_popped then
		self.impl:notify_popped()
	end
end

function M.Unit:bind_gate(bind, ident, dt, kind)
	if nil ~= self.impl.bind_gate then
		return self.impl:bind_gate(bind, ident, dt, kind)
	end
	return true
end

function M.Unit:update(dt)
	self.impl:update(dt)
end

function M.Unit:render()
	self.impl:render()
end

-- Screen interface

function M.new(impl, bind_group, transparent)
	return new_object(M.Unit, impl, bind_group, transparent)
end

function M.init()
	assert(not M.data.__initialized)
	M.data.stack = {}
	M.data.__initialized = true
end

function M.count()
	return #M.data.stack
end

function M.current()
	return 0 < M.count() and M.data.stack[M.count()] or nil
end

function M.push(screen)
	table.insert(M.data.stack, screen)
	screen:notify_pushed()
end

function M.pop(screen)
	if 0 == M.count() then
		log_debug("Screen.pop(): attempted to pop on empty stack")
	end
	assert(nil ~= screen and screen == M.current())

	table.remove(M.data.stack)
	screen:notify_popped()

	screen = M.current()
	if nil ~= screen then
		screen:notify_became_top()
	end
end

function M.clear()
	while 0 ~= M.count() do
		M.pop(M.current())
	end
end

function M.bind_gate(bind, ident, dt, kind)
	local screen = M.current()
	if nil ~= screen then
		return screen:bind_gate(bind, ident, dt, kind)
	end
	return true
end

function M.update(dt)
	local screen = M.current()
	if nil ~= screen then
		if screen:is_transparent() and 1 < M.count() then
			M.data.stack[M.count() - 1]:update(dt)
		end
		screen:update(dt)
	end
end

function M.render()
	local screen = M.current()
	if nil ~= screen then
		if screen:is_transparent() and 1 < M.count() then
			M.data.stack[M.count() - 1]:render()
		end
		screen:render()
	end
end
