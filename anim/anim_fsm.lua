local AnimClass = require("anim/anim_class")

local AnimFSM = {
	params = {},
}

local anims = {
	stand = AnimClass.new("stand", {synch_group = "stand"}),
	stand_left_arm = AnimClass.new("stand_left_arm", {synch_group = "stand", blend_groups = {"left_arm"}}),
	stand_right_arm = AnimClass.new("stand_right_arm", {synch_group = "stand", blend_groups = {"right_arm"}}),
	yaw = AnimClass.new("yaw"),
	walk_forward = AnimClass.new("walk_forward", {synch_group = "locomotion"}),
	walk_back = AnimClass.new("walk_back", {synch_group = "locomotion"}),
	walk_left = AnimClass.new("walk_left", {synch_group = "locomotion"}),
	walk_right = AnimClass.new("walk_right", {synch_group = "locomotion"}),
	walk_left_arm = AnimClass.new("walk_left_arm", {synch_group = "locomotion", blend_groups = {"left_arm"}}),
	walk_right_arm = AnimClass.new("walk_right_arm", {synch_group = "locomotion", blend_groups = {"right_arm"}}),
	air_up = AnimClass.new("air_up"),
	air_up_left_arm = AnimClass.new("air_up_left_arm", {blend_groups = {"left_arm"}}),
	air_up_right_arm = AnimClass.new("air_up_right_arm", {blend_groups = {"right_arm"}}),
	air_down = AnimClass.new("air_down", {synch_group = "air"}),
	air_down_left_arm = AnimClass.new("air_down_left_arm", {synch_group = "air", blend_groups = {"left_arm"}}),
	air_down_right_arm = AnimClass.new("air_down_right_arm", {synch_group = "air", blend_groups = {"right_arm"}}),
	crouch_stand = AnimClass.new("crouch_stand", {synch_group = "crouch_stand"}),
	crouch_stand_left_arm = AnimClass.new("crouch_stand_left_arm", {synch_group = "crouch_stand", blend_groups = {"left_arm"}}),
	crouch_stand_right_arm = AnimClass.new("crouch_stand_right_arm", {synch_group = "crouch_stand", blend_groups = {"right_arm"}}),
	crouch_yaw = AnimClass.new("crouch_yaw"),
	crouch_walk_forward = AnimClass.new("crouch_walk_forward", {synch_group = "locomotion"}),
	crouch_walk_back = AnimClass.new("crouch_walk_back", {synch_group = "locomotion"}),
	crouch_walk_left = AnimClass.new("crouch_walk_left", {synch_group = "locomotion"}),
	crouch_walk_right = AnimClass.new("crouch_walk_right", {synch_group = "locomotion"}),
	crouch_walk_left_arm = AnimClass.new("crouch_walk_left_arm", {synch_group = "locomotion", blend_groups = {"left_arm"}}),
	crouch_walk_right_arm = AnimClass.new("crouch_walk_right_arm", {synch_group = "locomotion", blend_groups = {"right_arm"}}),
	crouch_air_up = AnimClass.new("crouch_air_up"),
	crouch_air_up_left_arm = AnimClass.new("crouch_air_up_left_arm", {blend_groups = {"left_arm"}}),
	crouch_air_up_right_arm = AnimClass.new("crouch_air_up_right_arm", {blend_groups = {"right_arm"}}),
	crouch_air_down = AnimClass.new("crouch_air_down", {synch_group = "air"}),
	crouch_air_down_left_arm = AnimClass.new("crouch_air_down_left_arm", {synch_group = "air", blend_groups = {"left_arm"}}),
	crouch_air_down_right_arm = AnimClass.new("crouch_air_down_right_arm", {synch_group = "air", blend_groups = {"right_arm"}}),
	dance_arona = AnimClass.new("dance_arona"),
	salute = AnimClass.new("salute"),
}
local states = {
	ground = require("anim/states/ground"),
	air = require("anim/states/air"),
	emote = require("anim/states/emote"),
}
local current_state = "ground"
local active_anims = {}
local transition = nil

local function completeTickOutput(tbl)
	tbl.blends = tbl.blends or {}
	tbl.speeds = tbl.speeds or {}
end

local function regularTick()
	local tickOutput = states[current_state]:tick(AnimFSM.params)
	completeTickOutput(tickOutput)
	local new_active_anims = {}
	for anim, blend in pairs(tickOutput.blends) do
		if blend ~= 0 then
			anims[anim]:blend(blend)
			new_active_anims[anim] = true
			active_anims[anim] = nil
		end
	end
	for anim, _ in pairs(active_anims) do
		anims[anim]:blend(0)
	end
	active_anims = new_active_anims
	for synch_group, speed in pairs(tickOutput.speeds) do
		AnimClass.setSynchGroupSpeed(synch_group, speed)
	end
end

local function transitionTick()
	local tickOutput = states[current_state]:tick(AnimFSM.params)
	completeTickOutput(tickOutput)
	local prevTickOutput = states[transition.from]:tick(AnimFSM.params)
	completeTickOutput(prevTickOutput)
	local blendValue = transition.progress / transition.duration
	local prevBlendValue = 1 - blendValue
	local new_active_anims = {}
	for anim, blend in pairs(tickOutput.blends) do
		if blend ~= 0 then
			local prevBlend = prevTickOutput.blends[anim] or 0
			anims[anim]:blend(math.lerp(prevBlend, blend, blendValue))
			new_active_anims[anim] = true
			active_anims[anim] = nil
		end
	end
	for anim, blend in pairs(prevTickOutput.blends) do
		if blend ~= 0 and new_active_anims[anim] == nil then
			anims[anim]:blend(blend * prevBlendValue)
			new_active_anims[anim] = true
			active_anims[anim] = nil
		end
	end
	for anim, _ in pairs(active_anims) do
		anims[anim]:blend(0)
	end
	active_anims = new_active_anims
	for synch_group, speed in pairs(tickOutput.speeds) do
		AnimClass.setSynchGroupSpeed(synch_group, speed)
	end
end

function AnimFSM.getState()
	return current_state
end

function AnimFSM.setState(state)
	if state == current_state then
		return
	end
	current_state = state
	transition = nil
end

function AnimFSM.transitionTo(state, duration)
	if state == current_state then
		return
	end
	transition = {
		from = current_state,
		duration = duration,
		progress = 0,
	}
	current_state = state
end

function AnimFSM.tickEnd()
	if transition ~= nil then
		transition.progress = transition.progress + 1
		if transition.progress == transition.duration then
			transition = nil
		end
	end
	if transition == nil then
		regularTick()
	else
		transitionTick()
	end
end

return AnimFSM