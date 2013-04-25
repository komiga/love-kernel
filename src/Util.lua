
module("Util", package.seeall)

--local M_lrandom=require("random")

--local rng=nil

function init()
	--rng=M_lrandom.new(os.time())
	math.randomseed(os.time())
end

function ternary(cond, x, y)
	return (cond)
		and x
		or  y
end

function optional(value, default)
	return (nil~=value)
		and value
		or default
end

function tcheck(x, tc, opt)
	opt=Util.optional(opt, false)
	if "table"==type(tc) then
		for _, t in pairs(tc) do
			if not
				(t==type(x)
				or (opt and "nil"==type(x)))
			then
				assert(false)
			end
		end
		return true
	else
		assert(
			tc==type(x)
			or (opt and "nil"==type(x))
		)
		return true
	end
end

function random(x, y)
	--return rng:value(x, y)
	return math.random(x, y)
end

function choose_random(table)
	return table[Util.random(1, #table)]
end

-- takes:
--	(rgba, alpha_opt),
--	(rgb, alpha), or
--	(rgb) with alpha=255
function set_color_table(rgb, alpha)
	alpha=Util.optional(
		alpha,
		Util.optional(rgb[4], 255)
	)
	Gfx.setColor(rgb[1],rgb[2],rgb[3], alpha)
end
