
function love.conf(t)
	t.version = "0.9.1"
	t.identity = t.title .. "-save"
	t.console = false

	t.modules.audio = true
	t.modules.event = true
	t.modules.graphics = true
	t.modules.image = true
	t.modules.keyboard = true
	t.modules.math = true
	t.modules.mouse = true
	t.modules.sound = true
	t.modules.system = true
	t.modules.thread = true
	t.modules.timer = true
	t.modules.window = true

	t.modules.joystick = false
	t.modules.physics = false

	t.window.title = "Untitled"
	t.window.icon = nil
	t.window.width = 1024
	t.window.height = 768
	t.window.minwidth = 800
	t.window.minheight = 600
	t.window.borderless = false
	t.window.resizable = false
	t.window.fullscreen = false
	t.window.fullscreentype = "normal"
	t.window.vsync = true
	t.window.fsaa = 0
	t.window.display = 1
	t.window.highdpi = false
	t.window.srgb = false
end
