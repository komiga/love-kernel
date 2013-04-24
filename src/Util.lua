
module("Util", package.seeall)

--local M_lrandom=require("random")

--local rng=nil

function init()
	--rng=M_lrandom.new(os.time())
	math.randomseed(os.time())
end

function random(x, y)
	--return rng:value(x, y)
	return math.random(x, y)
end

function choose_random(table)
	return table[Util.random(1, #table)]
end

function ternary(cond, x, y)
	return (cond)
		and x
		or  y
end

-- takes:
--	(rgba, alpha_opt),
--	(rgb, alpha), or
--	(rgb) with alpha=255
function set_color_table(rgb, alpha)
	alpha=Util.ternary(
		nil==alpha,
		Util.ternary(
			nil~=rgb[4],
			rgb[4],
			255
		),
		alpha
	)
	Gfx.setColor(rgb[1],rgb[2],rgb[3], alpha)
end
