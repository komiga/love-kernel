
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

	Animator.init(Asset.anim)
	AudioManager.init(Asset.sound)

	-- default rendering state
	Gfx.setFont(Asset.font.main)
	Gfx.setColor(255,255,255, 255)
	Gfx.setBackgroundColor(0,0,0, 255)

	local anim_data=Asset.anim.moving_square
	Core.batcher=Animator.batcher(
		anim_data, 4, Animator.BatchMode.Dynamic
	)
	Core.moving_square={
		Animator.instance(anim_data, 1, Animator.Mode.Loop),
		Animator.instance(anim_data, 2, Animator.Mode.Loop),
		Animator.instance(anim_data, 1, Animator.Mode.Loop),
		Animator.instance(anim_data, 2, Animator.Mode.Loop),
		data=anim_data,
		i1=1, i2=2,
		i3=3, i4=4
	}

	-- Ensure debug_mode is disabled after init
	State.debug_mode=false
end

function deinit()
	Core.moving_square=nil
	Core.batcher=nil
end

function exit()
	-- Yes! I want to terminate!
	-- ... Wait, what? That's false?
	Core.deinit()
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
		Core.moving_square[2]:update(dt)
		Core.moving_square[3]:update(dt)
		if not Core.moving_square[4]:update(dt) then
			Core.moving_square.i1,
			Core.moving_square.i2=
			Core.moving_square.i2,
			Core.moving_square.i1
			Core.moving_square.i3,
			Core.moving_square.i4=
			Core.moving_square.i4,
			Core.moving_square.i3
		end
	end
end

function render()
	Gfx.reset()

	local b, a, t

	a=Asset.atlas.sprites
	t=a.__tex
	Gfx.draw(t, 128,128)
	Gfx.drawq(t, a.a, 160,192)
	Gfx.drawq(t, a.b, 128,160)

	a=Core.moving_square
	b=Core.batcher

	b:batch_begin()
		b:add(a[a.i1], 32, 32)
		b:add(a[a.i2], 32, 64)
		b:add(a[a.i3], 64, 64)
		b:add(a[a.i4], 64, 32)
	b:batch_end()
	b:render()

	Hooker.render()
end
