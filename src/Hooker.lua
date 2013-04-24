
module("Hooker", package.seeall)

require("src/Util")
require("src/FieldAnimator")

local data={
	__initialized=false,
	active=nil
}

local Hooklet={}
Hooklet.__index=Hooklet

function Hooklet:__init(props, x, y)
	assert("table"==type(props))
	assert("number"==type(x))
	assert("number"==type(y))

	self.props=props
	self.x=x
	self.y=y
	self.fields={}
	self.animator=FieldAnimator.new(
		self.props.duration,
		self.fields,
		self.props.trans,
		true
	)
end

function Hooklet:update(dt)
	if self.animator:is_complete() then
		return false
	else
		self.animator:update(dt)
		return true
	end
end

function Hooklet:render()
	Util.set_color_table(self.props.color, self.fields.alpha)
	Gfx.translate(self.x+self.fields.tx, self.y+self.fields.ty)
	Gfx.rotate(self.fields.angle)
	Gfx.scale(self.fields.sx, self.fields.sy)
	Gfx.setFont(self.props.font)
	Gfx.print(
		self.props.text,
		-self.props.half_width,
		-self.props.half_height
	)
end

function init(hooklet_props, default_font)
	assert(not data.__initialized)

	if nil==default_font then
		default_font=Gfx.getFont()
		assert(nil~=default_font)
	end

	for _, props in pairs(hooklet_props) do
		if nil==props.font then
			props.font=default_font
		end
		props.half_width=0.5*props.font:getWidth(props.text)
		props.half_height=0.5*props.font:getHeight()
		if nil==props.trans["alpha"] then
			props.trans["alpha"]={255.0, 0.0}
		end
	end

	data.active={}
	data.__initialized=true
end

function num_active()
	return #data.active
end

function clear()
	data.active={}
end

function spawn(prop_table, x, y)
	local h={}
	setmetatable(h, Hooklet)

	h:__init(prop_table, x, y)
	table.insert(data.active, h)
end

function update(dt)
	local rmkeys={}
	for k, hooklet in pairs(data.active) do
		if not hooklet:update(dt) then
			table.insert(rmkeys, k)
		end
	end
	if 0<#rmkeys then
		for _, v in pairs(rmkeys) do
			table.remove(data.active, v)
		end
	end
end

function render()
	for _, hooklet in pairs(data.active) do
		Gfx.push()
		hooklet:render()
		Gfx.pop()
	end
end
