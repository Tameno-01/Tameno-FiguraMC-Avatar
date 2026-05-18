local Utils = require("utils")

local AnimClass = {
	synch_groups = {},
	blend_groups = {},
	playing_anims = {},
}

AnimClass.__index = AnimClass

-- static
-- params is a table that can contain the following fields:
-- synch_group (string)
-- blend_groups (array of string)
function AnimClass:new(anim_name, params)
	params = params or {}
	params.prev_blend = 0
	params.input_blend = 0
	params.next_blend = 0
	params.anim = animations.main[anim_name]
	params.anim:blend(0)
	if params.synch_group ~= nil then
		if self.synch_groups[params.synch_group] == nil then
			self.synch_groups[params.synch_group] = {
				speed = 1,
				playing = {},
			}
		end
	end
	if params.blend_groups == nil then
		params.blend_groups = {}
	end
	for _, group in ipairs(params.blend_groups) do
		if self.blend_groups[group] == nil then
			self.blend_groups[group] = {
				blend = 1,
				anims = {},
			}
		end
		table.insert(self.blend_groups[group].anims, params)
	end
	setmetatable(params, self)
	return params
end

-- static
function AnimClass:setSynchGroupSpeed(group, speed)
	local group_table = self.synch_groups[group]
	group_table.speed = speed
	for anim, _ in pairs(group_table.playing) do
		anim.anim:setSpeed(speed)
	end
end

--static
function AnimClass:setGroupBlend(group, blend)
	self.blend_groups[group].blend = blend
	for _, anim in ipairs(self.blend_groups[group].anims) do
		anim:updateBlend()
	end
end

-- static
function AnimClass:tickStart()
	local to_delete = {}
	for anim, _ in pairs(self.playing_anims) do
		anim.prev_blend = anim.next_blend
		anim.anim:blend(anim.next_blend)
		if anim.next_blend == 0 then
			table.insert(to_delete, anim)
			anim.anim:stop()
			if anim.synch_group ~= nil then
				self.synch_groups[anim.synch_group].playing[anim] = nil
			end
		end
	end
	for _, anim in ipairs(to_delete) do
		self.playing_anims[anim] = nil
	end
end

-- static
function AnimClass:render(delta)
	for anim, _ in pairs(self.playing_anims) do
		anim.anim:blend(
			math.lerp(anim.prev_blend, anim.next_blend, delta)
		)
	end
end

function AnimClass:blend(blend)
	self.input_blend = blend
	self:updateBlend()
end

function AnimClass:setTime(time)
	self.anim:setTime(time)
end

-- private
function AnimClass:updateBlend()
	local blend = self.input_blend
	for _, group in ipairs(self.blend_groups) do
		blend = blend * AnimClass.blend_groups[group].blend
	end
	self:setActualBlend(blend)
end

-- private
function AnimClass:setActualBlend(blend)
	if self.next_blend == blend then
		return
	end
	self.next_blend = blend
	if self.prev_blend ~= 0 then
		return
	end
	self.anim:play()
	AnimClass.playing_anims[self] = true
	if self.synch_group == nil then
		return
	end
	local synch_group = AnimClass.synch_groups[self.synch_group]
	self.anim:setSpeed(synch_group.speed)
	local playing_anims = synch_group.playing
	local first = Utils.isEmpty(playing_anims)
	if not first then
		self.anim:setTime(Utils.getAnyKey(playing_anims).anim:getTime())
	end
	playing_anims[self] = true
end

return AnimClass