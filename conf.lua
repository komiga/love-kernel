
function love.conf(t)
	t.version="0.8.0"

	t.title="Untitled"
	t.author="Unnamed"
	t.url=nil
	t.identity=t.title.."-save"
	t.release=false

	t.screen.width=800
	t.screen.height=600
	t.screen.fullscreen=false
	t.screen.vsync=true
	t.screen.fsaa=0

	t.console=false

	t.modules.event=true
	t.modules.timer=true

	t.modules.joystick=false
	t.modules.keyboard=true
	t.modules.mouse=true

	t.modules.audio=true
	t.modules.sound=true
	t.modules.graphics=true
	t.modules.image=true

	t.modules.physics=false
end
