
module("AssetLoader", package.seeall)

require("src/Util")
require("src/AudioManager")

local function fix_path(path, name)
	return string.gsub(path, "@", name)
end

local Kind={}

--[[

NOTE: '@' in descriptor paths will be replaced with the name of the asset.

]]

--[[

With path:

	name={
		"@.ext",
		18
	}

Or default font with size:

	name={18}

]]
Kind.font={
	slug="font/",
	loader=function(root_path, name, desc)
		local path=desc[1]
		local size=desc[2]
		Util.tcheck(path, "string", true)
		Util.tcheck(size, "number")

		if nil==path then
			return Gfx.newFont(size)
		else
			return Gfx.newFont(root_path..fix_path(path, name), size)
		end
	end
}

--[[

With positions and sizes:

	name={
		"@.ext",
		tex={
			{"t0",  0,0, 32,32},
			{"t1", 32,0, 32,32},
			{"t2", 64,0, 32,32}
		}
	}

With constant size:

	name={
		"@.ext",
		size={32,32},
		tex={
			{"t0",  0,0},
			{"t1", 32,0},
			{"t2", 64,0}
		}
	}

With constant size and indexed positions:

	name={
		"@.ext",
		indexed=true,
		size={32,32},
		tex={
			{"t0", 0,0},
			{"t1", 1,0},
			{"t2", 2,0}
		}
	}

All of the descriptors above describe the same atlas.

In the last two forms, full quads are still permitted
(in which form the position for the texture does not use indexing).

]]
Kind.atlas={
	slug="atlas/",
	loader=function(root_path, name, desc)
		local path=desc[1]
		local indexed=desc.indexed
		local size=desc.size
		local tex=desc.tex
		Util.tcheck(path, "string")
		Util.tcheck(indexed, "boolean", true)
		Util.tcheck(size, "table", true)
		Util.tcheck(tex, "table")

		local atlas={
			__texture=Gfx.newImage(root_path..fix_path(path, name))
		}

		local aw=atlas.__texture:getWidth()
		local ah=atlas.__texture:getHeight()
		local x0,y0, sw,sh
		local idx, t

		for idx, t in pairs(tex) do
			if 3~=#t and 5~=#t then
				error(
					"atlas subtexture descriptor "..
					idx.." is malformed"
				)
			end
			if 5~=#t and not size then
				error(
					"atlas subtextures must be full "..
					"quads if 'size' is absent."
				)
			end
			x0=t[2]
			y0=t[3]
			if 5==#t then
				sw=t[4]
				sh=t[5]
			else
				if indexed then
					x0=size[1]*x0
					y0=size[2]*y0
				end
				sw=size[1]
				sh=size[2]
			end
			atlas[t[1]]=Gfx.newQuad(x0,y0, sw,sh, aw,ah)
		end
		return atlas
	end
}

--[[

Animation data.

	name={
		"@.ext",
		duration=0.2,
		size={32,32},
		set={
			{10},
			{10},
			{10}
		}
	}

'duration' is the duration of a frame (in seconds).

'size' is the size of each frame.

'set' defines sequence sets. Each set contains only a frame count.

A set will automatically move to the next row if the end of a row is
reached before all of its frames are loaded.

If a set is completed and the frame isn't the last frame in the row,
the next row will be used for the next set. This can be disabled with
tight_packing=true.

Once loaded, a frame quad is accessed by index:

	anim.set[set][frame]

Each frame is a Quad.

See Animator/AnimInstance.

]]
Kind.anim={
	slug="anim/",
	loader=function(root_path, name, desc)
		local path=desc[1]
		local duration=desc.duration
		local size=desc.size
		local set=desc.set
		local tight_packing=desc.tight_packing
		Util.tcheck(path, "string")
		Util.tcheck(duration, "number")
		Util.tcheck(size, "table")
		Util.tcheck(set, "table")
		Util.tcheck(tight_packing, "boolean", true)

		local anim={
			duration=duration,
			frame_width=size[1],
			frame_height=size[2],
			set={},
			tex=Gfx.newImage(root_path..fix_path(path, name))
		}
		anim.tex_width=anim.tex:getWidth()
		anim.tex_height=anim.tex:getHeight()

		local dw=anim.frame_width
		local dh=anim.frame_height
		local x0, y0=0, 0

		assert(dw<=anim.tex_width)
		assert(dh<=anim.tex_height)

		local y0_overflow=function(sidx)
			error("anim set "..sidx.." overflows image")
		end

		for sidx, s in pairs(set) do
			anim.set[sidx]={}
			x0=0
			for frame=1, s[1] do
				if anim.tex_width<x0+dw then
					x0=0
					y0=y0+dh
					if anim.tex_height<y0 then
						y0_overflow(sidx)
					end
				end
				anim.set[sidx][frame]=Gfx.newQuad(
					x0,y0, dw,dh, anim.tex_width,anim.tex_height
				)
				x0=x0+dw
			end
			if not tight_packing then
				y0=y0+dh
				if anim.tex_height<y0 then
					y0_overflow(sidx)
				end
			end
		end
		return anim
	end
}

--[[

With path, instance policy, and instance limit:

	name={
		"@.ext",
		InstancePolicy.Constant,
		limit=10
	}

'limit' is 0 by default.

The second parameter is the instance policy. This is defaulted to
Constant if limit>0, or Immediate if limit<=0.

See AudioManager/SoundInstance.

--]]
Kind.sound={
	slug="sound/",
	loader=function(root_path, name, desc)
		local path=desc[1]
		local policy=desc[2]
		local limit=desc.limit
		Util.tcheck(path, "string")
		Util.tcheck(policy, "number", true)
		Util.tcheck(limit, "number", true)

		limit=Util.optional(limit, 0)
		policy=Util.optional(
			policy,
			Util.ternary(
				0<limit,
				AudioManager.InstancePolicy.Constant,
				AudioManager.InstancePolicy.Immediate
			)
		)
		if AudioManager.InstancePolicy.Constant==policy and 0==limit then
			error("policy cannot be Constant when limit=0")
		end

		local sound={
			data=love.sound.newSoundData(
				root_path..fix_path(path, name)
			),
			policy=policy,
			limit=limit
		}

		return sound
	end
}

local LoadOrder={
	"font",
	"atlas",
	"anim",
	"sound"
}

local function load_kind(root_path, kind_name, desc_table, asset_table)
	local kind=Kind[kind_name]
	root_path=root_path..kind.slug
	for name, desc in pairs(desc_table) do
		asset_table[kind_name][name]=kind.loader(root_path, name, desc)
	end
end

function load(root_path, desc_root, asset_table)
	Util.tcheck(root_path, "string")
	Util.tcheck(desc_root, "table")
	Util.tcheck(asset_table, "table")

	for _, kind_name in pairs(LoadOrder) do
		local desc_table=desc_root[kind_name]
		if nil~=desc_table then
			if nil==asset_table[kind_name] then
				asset_table[kind_name]={}
			end
			load_kind(root_path, kind_name, desc_table, asset_table)
		end
	end
end
