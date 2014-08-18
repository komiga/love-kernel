
Util = Util or {}
local M = Util

require("src/State")

--local M_lrandom = require("random")

--[[local data = {
	rng = nil
}--]]

function M.init()
	--data.rng = M_lrandom.new(os.time())
	math.randomseed(os.time())
end

function M.ternary(cond, x, y)
	return (cond)
		and x
		or  y
end

function M.optional(value, default)
	return (nil ~= value)
		and value
		or default
end

function M.tcheck(x, tc, opt)
	opt = Util.optional(opt, false)
	assert(
		tc == type(x)
		or (opt and nil == x)
	)
end

function M.tcheck_obj(x, tc, opt)
	opt = Util.optional(opt, false)
	if nil == x then
		assert(opt)
	else
		if not x:typeOf(tc) then
			assert(false)
		end
	end
end

function M.last(table)
	assert(0 < #table)
	return table[#table]
end

function M.debug_sub(sub, msg, ...)
	if true == sub then
		print("debug: "..msg, ...)
	end
end

function M.debug(msg, ...)
	if true == State.gen_debug then
		print("debug: "..msg, ...)
	end
end

function M.random(x, y)
	--return data.rng:value(x, y)
	return math.random(x, y)
end

function M.choose_random(table)
	return table[Util.random(1, #table)]
end

function M.class(c)
	if nil == c then
		c = {}
		c.__index = c

		c.__class_static = {}
		c.__class_static.__index = c.__class_static
		c.__class_static.__call = function(c, ...)
			local obj = {}
			setmetatable(obj, c)
			obj:__init(...)
			return obj
		end
		setmetatable(c, c.__class_static)
	end
	return c
end

function M.new_object(c, ...)
	local obj = {}
	setmetatable(obj, c)

	obj:__init(...)
	return obj
end

-- takes:
--	(rgba, alpha_opt),
--	(rgb, alpha), or
--	(rgb) with alpha = 255
function M.set_color_table(rgb, alpha)
	alpha = Util.optional(
		alpha,
		Util.optional(rgb[4], 255)
	)
	Gfx.setColor(rgb[1],rgb[2],rgb[3], alpha)
end
