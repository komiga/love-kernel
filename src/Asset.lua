
Asset = Asset or {}
local M = Asset

require("src/AudioManager")
require("src/FieldAnimator")
require("src/Hooker")

local InstancePolicy = AudioManager.InstancePolicy

-- assets

M.desc_root = {

font = {
	main = {18, default = true}
},

atlas = {
	intro_seq = {
		tex = {
			{"komiga", 0,0, 256,256},
			{"disclaimer", 0,256, 512,256},
		}
	},
	sprites = {
		indexed = true,
		size = {32,32},
		tex = {
			{"a", 0, 0},
			{"b", 32,0, 32,64}
		}
	}
},

anim = {
	moving_square = {
		duration = 0.05,
		size = {32,32},
		set = {
			{8}, -- normal set
			{8}  -- reverse set
		}
	}
},

sound = {
	waaauu = {
		InstancePolicy.Reserve,
		limit = 10
	}
}

} -- desc_root

-- intro sequences

M.intro_seq = {
	{name = "komiga"    , fade = 0.5, stay = 0.5},
	{name = "disclaimer", fade = 0.5, stay = 2.0}
}

-- hooklets

M.hooklets = {
	KUMQUAT = {
		text = "that's a kumquat!",
		color = {255,255,255},
		duration = 1.4,
		trans = {
			["tx"] = {
				{0.0, 24.0},
				{0.0,-24.0}
			},
			["ty"] = {
				{0.0, 8.0},
				{0.0,-8.0}
			},
			[{"sx", "sy"}] = {1.4,0.8},
			["angle"] = {
				{0.0, 1.2},
				{0.0,-1.2}
			}
		}
	}
}
