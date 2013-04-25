
module("Core", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/AudioManager")
require("src/FieldAnimator")
require("src/Hooker")
require("src/Animator")
require("src/AssetLoader")
require("src/Asset")

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
			if State.paused then
				AudioManager:pause()
			else
				AudioManager:resume()
			end
		end
	},
	["f4"]={
		kind=Bind.Kind.RELEASE,
		handler=function(_, _)
			State.debug_mode=not State.debug_mode
			if State.debug_mode then
				print("debug mode enabled")
			else
				print("debug mode disabled")
			end
		end
	},
	[{" ", "mouse2"}]={
		kind=Bind.Kind.RELEASE,
		handler=function(_, _)
			AudioManager.spawn(Asset.sound.waaauu)
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
	AssetLoader.load("asset/", Asset.desc_root, Asset)
	Hooker.init(Asset.hooklets, Asset.font.main)

	AudioManager.init(Asset.sound)

	-- default rendering state
	Gfx.setFont(Asset.font.main)
	Gfx.setColor(255,255,255, 255)
	Gfx.setBackgroundColor(0,0,0, 255)

	Core.moving_square={
		Animator.instance(Asset.anim.moving_square, 1, Animator.Mode.Loop),
		Animator.instance(Asset.anim.moving_square, 2, Animator.Mode.Loop),
		i1=1, i2=2
	}
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
		AudioManager:update(dt)

		Core.moving_square[1]:update(dt)
		if not Core.moving_square[2]:update(dt) then
			Core.moving_square.i1,
			Core.moving_square.i2=
			Core.moving_square.i2,
			Core.moving_square.i1
		end
	end
end

function render()
	Gfx.reset()

	local a, t

	a=Asset.atlas.sprites
	t=a.__texture
	Gfx.draw(t, 128,128)
	Gfx.drawq(t, a.a, 160,192)
	Gfx.drawq(t, a.b, 128,160)

	a=Core.moving_square
	a[a.i1]:render(32, 32)
	a[a.i2]:render(32, 64)
	a[a.i1]:render(64, 64)
	a[a.i2]:render(64, 32)

	Hooker.render()
end
