local AnimClass = require("anim/anim_class")

local function completeTickOutput(tbl)
	tbl.blends = tbl.blends or {}
	tbl.speeds = tbl.speeds or {}
end

local AnimFSM = {
	anims = {
		stand = AnimClass:new("stand", {synch_group = "stand"}),
		stand_left_arm = AnimClass:new("stand_left_arm", {synch_group = "stand", blend_groups = {"left_arm"}}),
		stand_right_arm = AnimClass:new("stand_right_arm", {synch_group = "stand", blend_groups = {"right_arm"}}),
		yaw = AnimClass:new("yaw"),
		walk_forward = AnimClass:new("walk_forward", {synch_group = "locomotion"}),
		walk_back = AnimClass:new("walk_back", {synch_group = "locomotion"}),
		walk_left = AnimClass:new("walk_left", {synch_group = "locomotion"}),
		walk_right = AnimClass:new("walk_right", {synch_group = "locomotion"}),
		walk_left_arm = AnimClass:new("walk_left_arm", {synch_group = "locomotion", blend_groups = {"left_arm"}}),
		walk_right_arm = AnimClass:new("walk_right_arm", {synch_group = "locomotion", blend_groups = {"right_arm"}}),
		air_up = AnimClass:new("air_up"),
		air_up_left_arm = AnimClass:new("air_up_left_arm", {blend_groups = {"left_arm"}}),
		air_up_right_arm = AnimClass:new("air_up_right_arm", {blend_groups = {"right_arm"}}),
		air_down = AnimClass:new("air_down", {synch_group = "air"}),
		air_down_left_arm = AnimClass:new("air_down_left_arm", {synch_group = "air", blend_groups = {"left_arm"}}),
		air_down_right_arm = AnimClass:new("air_down_right_arm", {synch_group = "air", blend_groups = {"right_arm"}}),
		crouch_stand = AnimClass:new("crouch_stand", {synch_group = "crouch_stand"}),
		crouch_stand_left_arm = AnimClass:new("crouch_stand_left_arm", {synch_group = "crouch_stand", blend_groups = {"left_arm"}}),
		crouch_stand_right_arm = AnimClass:new("crouch_stand_right_arm", {synch_group = "crouch_stand", blend_groups = {"right_arm"}}),
		crouch_yaw = AnimClass:new("crouch_yaw"),
		crouch_walk_forward = AnimClass:new("crouch_walk_forward", {synch_group = "locomotion"}),
		crouch_walk_back = AnimClass:new("crouch_walk_back", {synch_group = "locomotion"}),
		crouch_walk_left = AnimClass:new("crouch_walk_left", {synch_group = "locomotion"}),
		crouch_walk_right = AnimClass:new("crouch_walk_right", {synch_group = "locomotion"}),
		crouch_walk_left_arm = AnimClass:new("crouch_walk_left_arm", {synch_group = "locomotion", blend_groups = {"left_arm"}}),
		crouch_walk_right_arm = AnimClass:new("crouch_walk_right_arm", {synch_group = "locomotion", blend_groups = {"right_arm"}}),
		crouch_air_up = AnimClass:new("crouch_air_up"),
		crouch_air_up_left_arm = AnimClass:new("crouch_air_up_left_arm", {blend_groups = {"left_arm"}}),
		crouch_air_up_right_arm = AnimClass:new("crouch_air_up_right_arm", {blend_groups = {"right_arm"}}),
		crouch_air_down = AnimClass:new("crouch_air_down", {synch_group = "air"}),
		crouch_air_down_left_arm = AnimClass:new("crouch_air_down_left_arm", {synch_group = "air", blend_groups = {"left_arm"}}),
		crouch_air_down_right_arm = AnimClass:new("crouch_air_down_right_arm", {synch_group = "air", blend_groups = {"right_arm"}}),
		dance_arona = AnimClass:new("dance_arona"),
		salute = AnimClass:new("salute"),
	},
	states = {
		ground = require("anim/states/ground"),
		air = require("anim/states/air"),
		emote = require("anim/states/emote"),
	},
	params = {},
	current_state = "ground",
	active_anims = {},
}

function AnimFSM:getState(state)
	return self.current_state
end

function AnimFSM:setState(state)
	if state == self.current_state then
		return
	end
	self.current_state = state
	self.transition = nil
end

function AnimFSM:transitionTo(state, duration)
	if state == self.current_state then
		return
	end
	self.transition = {
		from = self.current_state,
		duration = duration,
		progress = 0,
	}
	self.current_state = state
end

function AnimFSM:tickEnd()
	if self.transition ~= nil then
		self.transition.progress = self.transition.progress + 1
		if self.transition.progress == self.transition.duration then
			self.transition = nil
		end
	end
	if self.transition == nil then
		AnimFSM:regularTick()
	else
		AnimFSM:transitionTick()
	end
end

-- private
function AnimFSM:regularTick()
	local tickOutput = self.states[self.current_state]:tick(self.params)
	completeTickOutput(tickOutput)
	local new_active_anims = {}
	for anim, blend in pairs(tickOutput.blends) do
		if blend ~= 0 then
			self.anims[anim]:blend(blend)
			new_active_anims[anim] = true
			self.active_anims[anim] = nil
		end
	end
	for anim, _ in pairs(self.active_anims) do
		self.anims[anim]:blend(0)
	end
	self.active_anims = new_active_anims
	for synch_group, speed in pairs(tickOutput.speeds) do
		AnimClass:setSynchGroupSpeed(synch_group, speed)
	end
end

-- private
function AnimFSM:transitionTick()
	local tickOutput = self.states[self.current_state]:tick(self.params)
	completeTickOutput(tickOutput)
	local prevTickOutput = self.states[self.transition.from]:tick(self.params)
	completeTickOutput(prevTickOutput)
	local blendValue = self.transition.progress / self.transition.duration
	local prevBlendValue = 1 - blendValue
	local new_active_anims = {}
	for anim, blend in pairs(tickOutput.blends) do
		if blend ~= 0 then
			local prevBlend = prevTickOutput.blends[anim] or 0
			self.anims[anim]:blend(math.lerp(prevBlend, blend, blendValue))
			new_active_anims[anim] = true
			self.active_anims[anim] = nil
		end
	end
	for anim, blend in pairs(prevTickOutput.blends) do
		if blend ~= 0 and new_active_anims[anim] == nil then
			self.anims[anim]:blend(blend * prevBlendValue)
			new_active_anims[anim] = true
			self.active_anims[anim] = nil
		end
	end
	for anim, _ in pairs(self.active_anims) do
		self.anims[anim]:blend(0)
	end
	self.active_anims = new_active_anims
	for synch_group, speed in pairs(tickOutput.speeds) do
		AnimClass:setSynchGroupSpeed(synch_group, speed)
	end
end

return AnimFSM