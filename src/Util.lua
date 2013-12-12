
module("Util", package.seeall)

require("src/State")

--local M_lrandom = require("random")

local data = {
	--rng = nil
}

function init()
	--data.rng = M_lrandom.new(os.time())
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
	opt = Util.optional(opt, false)
	assert(
		tc == type(x)
		or (opt and nil == x)
	)
end

function tcheck_obj(x, tc, opt)
	opt = Util.optional(opt, false)
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

function debug_sub(sub, msg, ...)
	if true == sub then
		print("debug: "..msg, ...)
	end
end

function debug(msg, ...)
	if true == State.gen_debug then
		print("debug: "..msg, ...)
	end
end

function random(x, y)
	--return data.rng:value(x, y)
	return math.random(x, y)
end

function choose_random(table)
	return table[Util.random(1, #table)]
end

function new_object(class, ...)
	local obj = {}
	setmetatable(obj, class)

	obj:__init(...)
	return obj
end

-- takes:
--	(rgba, alpha_opt),
--	(rgb, alpha), or
--	(rgb) with alpha = 255
function set_color_table(rgb, alpha)
	alpha = Util.optional(
		alpha,
		Util.optional(rgb[4], 255)
	)
	Gfx.setColor(rgb[1],rgb[2],rgb[3], alpha)
end
