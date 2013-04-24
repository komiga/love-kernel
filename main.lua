
Timer=love.timer
Gfx=love.graphics
Sfx=love.audio
Phys=love.physics

HID={
	Mouse=love.mouse,
	Keyboard=love.keyboard
}

require("src/Core")

love.load=Core.init
love.quit=Core.exit
love.focus=Core.focus_changed
love.update=Core.update
love.draw=Core.render
