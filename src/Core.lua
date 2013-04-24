
module("Core", package.seeall)

require("src/Util")
require("src/Bind")
require("src/FieldAnimator")
require("src/Hooker")
require("src/Asset")
require("src/State")

binds={
	["escape"]={
		kind=Bind.Kind.RELEASE,
		handler=function(_, _)
			love.event.quit()
		end
	},
	["pause"]={
		kind=Bind.Kind.RELEASE,
		passthrough=true,
		handler=function(_, _)
			State.pause_lock=not State.pause_lock
			State.paused=State.pause_lock
		end
	},
	[{" ", "mouse1"}]={
		kind=Bind.Kind.RELEASE,
		handler=function(_, _)
			Hooker.spawn(
				Asset.hooklets.KUMQUAT,
				HID.Mouse.getX(),
				HID.Mouse.getY()
			)
		end
	},
	["f1"]={
		kind=Bind.Kind.RELEASE,
		handler=function(_, _)
			Hooker.clear()
		end
	}
}

function bind_trigger_gate(_, _)
	return false==State.paused
end

function init(_)
	-- initialization
	Util.init()
	Bind.init(Core.binds, Core.bind_trigger_gate)

	-- assets
	Asset.load("asset/")
	Hooker.init(Asset.hooklets, Asset.font.main)

	-- default state
	Gfx.setFont(Asset.font.main)
	Gfx.setColor(255,255,255, 255)
	Gfx.setBackgroundColor(0,0,0, 255)

	Core.moving_square=FieldAnimator.new(
		8*0.05, -- 50ms/frame
		{s1=1, s2=2},
		{
			["frame"]={
				{1, 8}
			}
		},
		true
	)
end

function exit()
	-- Yes! I want to terminate!
	-- ... Wait, what? That's false?
	return false
end

function focus_changed(focused)
	if not State.pause_lock then
		State.paused=not focused
	end
end

function update(dt)
	if true==State.paused then
		Bind.update(0.0)
	else
		Bind.update(dt)
		Hooker.update(dt)

		local f=Core.moving_square
		if f:update(dt) then
			f:reset()
			f.fields.s1, f.fields.s2=
			f.fields.s2, f.fields.s1
		end
	end
end

function render()
	Hooker.render()

	Gfx.reset()

	local f,a,t

	a=Asset.atlas.sprites
	t=a.__texture
	Gfx.draw(t, 128, 128)
	Gfx.drawq(t, a.a, 160, 192)
	Gfx.drawq(t, a.b, 128, 160)

	f=Core.moving_square
	a=Asset.anim.moving_square
	t=a.__texture
	Gfx.drawq(
		t, a.set[f.fields.s1][math.floor(f.fields.frame)],
		32,32
	)
	Gfx.drawq(
		t, a.set[f.fields.s2][math.floor(f.fields.frame)],
		32,64
	)
	Gfx.drawq(
		t, a.set[f.fields.s1][math.floor(f.fields.frame)],
		64,64
	)
	Gfx.drawq(
		t, a.set[f.fields.s2][math.floor(f.fields.frame)],
		64,32
	)
end
