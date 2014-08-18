
Util = Util or {}
local M = Util

require("src/State")

--local M_lrandom = require("random")

--[[M.data = M.data or {
	rng = nil
}--]]

function M.init()
	--M.data.rng = M_lrandom.new(os.time())
	math.randomseed(os.time())
end

function ternary(cond, x, y)
	return (cond)
		and x
		or  y
end

function optional(value, default)
	return (nil ~= value)
		and value
		or default
end

function tcheck(x, tc, opt)
	opt = optional(opt, false)
	assert(
		tc == type(x)
		or (opt and nil == x)
	)
end

function tcheck_obj(x, tc, opt)
	opt = optional(opt, false)
	if nil == x then
		assert(opt)
	else
		if not x:typeOf(tc) then
			assert(false)
		end
	end
end

function last(table)
	assert(0 < #table)
	return table[#table]
end

function log_debug_sys(sys, msg, ...)
	if true == sys then
		local info = debug.getinfo(2, "Sl")
		print(info.short_src .. " @ " .. info.currentline .. ": debug: " .. msg, ...)
	end
end

function log_debug(msg, ...)
	if true == State.gen_debug then
		local info = debug.getinfo(2, "Sl")
		print(info.short_src .. " @ " .. info.currentline .. ": debug: " .. msg, ...)
	end
end

function random(x, y)
	--return M.data.rng:value(x, y)
	return math.random(x, y)
end

function choose_random(table)
	return table[random(1, #table)]
end

function class(c)
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

function new_object(c, ...)
	local obj = {}
	setmetatable(obj, c)

	obj:__init(...)
	return obj
end

-- takes:
--	(rgba, alpha_opt),
--	(rgb, alpha), or
--	(rgb) with alpha = 255
function set_color_table(rgb, alpha)
	alpha = optional(
		alpha,
		optional(rgb[4], 255)
	)
	Gfx.setColor(rgb[1],rgb[2],rgb[3], alpha)
end
