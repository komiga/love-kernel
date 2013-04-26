
module("Asset", package.seeall)

require("src/AudioManager")
require("src/FieldAnimator")
require("src/Hooker")

InstancePolicy=AudioManager.InstancePolicy

-- assets

desc_root={

font={
	main={18, default=true}
},

atlas={
	sprites={
		indexed=true,
		size={32,32},
		tex={
			{"a", 0, 0},
			{"b", 32,0, 32,64}
		}
	}
},

anim={
	moving_square={
		duration=0.05,
		size={32,32},
		set={
			{8}, -- normal set
			{8}  -- reverse set
		}
	}
},

sound={
	waaauu={
		InstancePolicy.Reserve,
		limit=10
	}
}

}

-- hooklets

hooklets={
	KUMQUAT={
		text="that's a kumquat!",
		color={255,255,255},
		duration=1.4,
		trans={
			["tx"]={
				{0.0, 24.0},
				{0.0,-24.0}
			},
			["ty"]={
				{0.0, 8.0},
				{0.0,-8.0}
			},
			[{"sx", "sy"}]={1.4,0.8},
			["angle"]={
				{0.0, 1.2},
				{0.0,-1.2}
			}
		}
	}
}
