local AnimClass = require("anim/anim_class")
local AnimFSM = require("anim/anim_fsm")
local PartClass = require("model_parts/part_class")
local Parts = require("model_parts/parts")
local StateSynch = require("other_libs/state_synch")
local ActionWheelHandler = require("other_libs/action_wheel_handler")
local Emotes = require("emotes")
local Utils = require("other_libs/utils")

local MAX_YAW_DIFF = 70
local YAWING_SPEED = 15
local RUN_LEAN = 2
local MAX_RUN_LEAN = 30
local RUN_LEAN_STIFFNESS = 0.3
local SWING_ARM_TIME = 3

local main_model = models.main

function main_model:preRender()
	if player:isLoaded() then
		if player:isCrouching() then
			main_model:setPos(vec(0, 2.13, 0))
		else
			main_model:setPos(vec(0, 0, 0))
		end
	end
end

local arm_blend_groups = {
	LEFT = "left_arm",
	RIGHT = "right_arm"
}

local arm_anims = {
	LEFT = {
		swing = AnimClass.new("swing_left_arm"),
	},
	RIGHT = {
		swing = AnimClass.new("swing_right_arm"),
	},
}

local arm_swing_time_left = {
	LEFT = 0,
	RIGHT = 0,
}

local yaw
local yawing = false
local snap_yaw = false

local emoting = false

local running = false
local run_lean = 0

local prev_velocity = vec(0, 0, 0)

local tick_queue = {}

local function queueTickFunc(func)
	if player:isLoaded() then
		table.insert(tick_queue, func)
	else
		func()
	end
end

local function runJump()
	if AnimFSM.getState() == "run_jump" then
		AnimFSM.params.run_jump_left = not AnimFSM.params.run_jump_left
	else
		AnimFSM.params.run_jump_left = AnimClass.raw_anims.run:getTime() >= 1
	end
end

local function tickRot()
	local prev_yaw = yaw
	local rot = -player:getRot()
	local model_space_yaw = (rot.y + 180) % 360
	local idealYaw
	if running then
		local vel = player:getVelocity().xz
		if vel:length() < 0.0001 then
			idealYaw = yaw
		else
			idealYaw = math.deg(math.atan(-vel.x, -vel.y))
		end
	else
		idealYaw = model_space_yaw
	end
	if snap_yaw or running then
		yaw = idealYaw
		snap_yaw = false
	else
		local yaw_diff = math.shortAngle(yaw, idealYaw)
		local abs_yaw_diff = math.abs(yaw_diff)
		if abs_yaw_diff > MAX_YAW_DIFF then
			yawing = true
			if abs_yaw_diff - MAX_YAW_DIFF > YAWING_SPEED then
				yaw = yaw + yaw_diff - MAX_YAW_DIFF * math.sign(yaw_diff)
			else
				yaw = yaw + YAWING_SPEED * math.sign(yaw_diff)
			end
		elseif yawing then
			if abs_yaw_diff > YAWING_SPEED then
				yaw = yaw + YAWING_SPEED * math.sign(yaw_diff)
			else
				yaw = idealYaw
				yawing = false
			end
		end
		yaw = yaw % 360
	end
	AnimFSM.params.yaw = yaw
	AnimFSM.params.yawing = yawing
	Parts.main_model:setRot(vec(0, yaw, 0))
	Parts.neck:setRot(vec(rot.x / 2, math.shortAngle(yaw, model_space_yaw), 0))
	Parts.head:setRot(vec(rot.x / 2, 0, 0))
	if running then
		local yaw_speed = math.shortAngle(prev_yaw, yaw)
		local ideal_run_lean = yaw_speed * RUN_LEAN
		if math.abs(ideal_run_lean) > MAX_RUN_LEAN then
			ideal_run_lean = MAX_RUN_LEAN * math.sign(ideal_run_lean)
		end
		run_lean = math.lerp(run_lean, ideal_run_lean, RUN_LEAN_STIFFNESS)
		Parts.root:setRot(vec(0, 0, run_lean))
	else
		run_lean = 0
	end
end

local function swingArm(arm)
	arm_swing_time_left[arm] = SWING_ARM_TIME
	arm_anims[arm].swing:blend(1)
	AnimClass.setGroupBlend(arm_blend_groups[arm], 0)
end

local function tickArm(arm)
	local is_left = arm == "LEFT"
	local this_hand = Utils.tif(player:isLeftHanded() == is_left, "MAIN_HAND", "OFF_HAND")
	if arm_swing_time_left[arm] > 0 then
		arm_swing_time_left[arm] = arm_swing_time_left[arm] - 1
		local swing_blend = arm_swing_time_left[arm] / SWING_ARM_TIME
		arm_anims[arm].swing:blend(swing_blend)
		AnimClass.setGroupBlend(arm_blend_groups[arm], 1 - swing_blend)
	end
	if player:getSwingArm() == this_hand and player:getSwingTime() == 0 then
		swingArm(arm)
	end
end

local function tickAnimFsm()
	local vel = player:getVelocity()
	local state = AnimFSM.getState()
	if running then
		if player:isOnGround() then
			if state == "ground" then
				AnimFSM.transitionTo("run", 5)
			else
				if state == "run_jump" then
					if AnimFSM.params.run_jump_left then
						AnimClass.setSynchGroupTime("locomotion", 0.7)
					else
						AnimClass.setSynchGroupTime("locomotion", 1.7)
					end
				end
				AnimFSM.setState("run")
			end
		else
			if state ~= "run_jump" then
				runJump()
				AnimFSM.setState("run_jump")
			end
		end
	elseif player:isOnGround() then
		if state == "run" then
			AnimFSM.transitionTo("ground", 5)
		else
			AnimFSM.setState("ground")
		end
		if vel.xz:length() > 0.0001 then
			snap_yaw = true
		end
	else
		if state == "ground" or state == "run" and vel.y < 0.0001 then
			AnimFSM.transitionTo("air", 10)
		else
			AnimFSM.setState("air")
		end
	end
end

local function shouldStopEmote()
	if player:isSwingingArm() then
		return true
	end
	if player:getVelocity():length() > 0.01 then
		return true
	end
	if player:getPose() ~= "STANDING" then
		return true
	end
	return false
end

local function tickEmote()
	if host:isHost() then
		if shouldStopEmote() then
			ActionWheelHandler.setState("emote", 0)
		end
	end
	Parts.main_model:setRot(vec(0, yaw, 0))
end

local function tickRunning()
	local jumped = player:getVelocity().y > 0 and prev_velocity.y <= 0
	if player:isOnGround() or jumped then
		running = player:isSprinting()
	end
	if running then
		if AnimFSM:getState() ~= "run_jump" and player:getVelocity().y < 0.0001 and not player:isOnGround() then
			running = false
		end
		if running then
			local rot = -player:getRot().y
			local vel = player:getVelocity().xz
			local running_rot = math.deg(math.atan(vel.x, vel.y))
			if math.abs(math.shortAngle(rot, running_rot)) > MAX_YAW_DIFF then
				running = false
			end
		end
	end
	if running and AnimFSM:getState() == "run_jump" and jumped then
		runJump()
	end
end

function Emotes.start(emote_state)
	queueTickFunc(function()
		AnimFSM.params.emote = emote_state.anim
		AnimFSM.setState("emote")
		if player:isLoaded() then
			yaw = -player:getRot().y
			yaw = yaw + 180
			yaw = yaw % 360
		end
		vanilla_model.HELD_ITEMS:setVisible(false)
		emoting = true
	end)
end

function Emotes.stop()
	queueTickFunc(function()
		vanilla_model.HELD_ITEMS:setVisible(true)
		emoting = false
	end)
end

vanilla_model.ALL:setVisible(false)
vanilla_model.HELD_ITEMS:setVisible(true)
vanilla_model.HELMET_ITEM:setVisible(true)
renderer:setRootRotationAllowed(false)
avatar:store("color", "#a665b3")

function events.entity_init()
	yaw = player:getRot().y
end

function events.tick()
	AnimClass.tickStart()
	PartClass.tickStart()
	for _, func in ipairs(tick_queue) do
		func()
	end
	tick_queue = {}
	tickRunning()
	if emoting then
		tickEmote()
	else
		tickAnimFsm()
		tickArm("LEFT")
		tickArm("RIGHT")
		tickRot()
	end
	AnimFSM.tickEnd()
	AnimClass.tickEnd()
	PartClass.tickEnd()
	if host:isHost() then
		StateSynch.tick()
	end
	prev_velocity = player:getVelocity()
end

function events.render(delta, ctx, mtrx)
	if ctx ~= "PAPERDOLL" and ctx ~= "RENDER" then
		return
	end
	AnimClass.render(delta)
	PartClass.render(delta)
end