local AnimClass = require("anim/anim_class")
local AnimFSM = require("anim/anim_fsm")
local PartClass = require("model_parts/part_class")
local Parts = require("model_parts/parts")
local StateSynch = require("other_libs/state_synch")
local Utils = require("other_libs/utils")

local MAX_YAW_DIFF = 70
local YAWING_SPEED = 15
local SWING_ARM_TIME = 3

vanilla_model.ALL:setVisible(false)
vanilla_model.HELD_ITEMS:setVisible(true)
vanilla_model.HELMET_ITEM:setVisible(true)
renderer:setRootRotationAllowed(false)

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

local emotes = {
	{
		anim = "dance_arona",
		name = "Arona Dance",
		item = "minecraft:light_blue_wool",
	},
	{
		anim = "salute",
		name = "Salute",
		item = "minecraft:turtle_helmet",
	},
}


local outfits = {
	{
		texture = textures["main_texture"],
		name = "Default",
		item = "minecraft:purple_wool",
	},
	{
		texture = textures["main_texture_glorpian"],
		name = "Glorpian Army",
		item = "minecraft:emerald",
	},
	{
		texture = textures["main_texture_niko"],
		name = "Niko",
		item = "minecraft:nether_star",
	},
}

local yaw
local yawing = false
local snap_yaw = false

local emoting = false

local tick_queue = {}

local function queueTickFunc(func)
	if player:isLoaded() then
		table.insert(tick_queue, func)
	else
		func()
	end
end

local function startEmote(emote)
	AnimFSM.params.emote = emote.anim
	AnimFSM.setState("emote")
	if player:isLoaded() then
		yaw = -player:getRot().y
		yaw = yaw + 180
		yaw = yaw % 360
	end
	emoting = true
	if host:isHost() then
		host:setActionbar("Started emote: " .. emote.name)
	end
end

local function tickRot()
	local rot = -player:getRot()
	local idealYaw = rot.y + 180
	idealYaw = idealYaw % 360
	if snap_yaw then
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
	Parts.neck:setRot(vec(rot.x / 2, math.shortAngle(yaw, idealYaw), 0))
	Parts.head:setRot(vec(rot.x / 2, 0, 0))
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
	if player:isOnGround() then
		AnimFSM.setState("ground")
		if vec(vel.x, vel.z):length() > 0.0001 then
			snap_yaw = true
		end
	else
		if AnimFSM.getState() == "ground" and vel.y < 0.0001 then
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
			StateSynch.setState("emote", 0)
		end
	end
	Parts.main_model:setRot(vec(0, yaw, 0))
end

function events.entity_init()
	yaw = player:getRot().y
end

StateSynch.newState("emote", 0, function(emote_idx)
	if emote_idx == 0 then
		emoting = false
		if host:isHost() then
			host:setActionbar("Emote stopped.")
		end
	else
		queueTickFunc(function()
			startEmote(emotes[emote_idx])
		end)
	end
end)

StateSynch.newState("outfit", 1, function(outfit_idx)
	local outfit = outfits[outfit_idx]
	local texture = outfit.texture
	Utils.forAllChildrenRecursive(Parts.main_model.part, function(part)
		if part:getType() == "CUBE" then
			part:setPrimaryTexture("Custom", texture)
		end
	end)
	if host:isHost() then
		host:setActionbar("Switched outfit to: " .. outfit.name)
	end
end)

function events.tick()
	AnimClass.tickStart()
	PartClass.tickStart()
	for _, func in ipairs(tick_queue) do
		func()
	end
	tick_queue = {}
	if emoting then
		tickEmote()
	else
		tickAnimFsm()
		tickArm("LEFT")
		tickArm("RIGHT")
		tickRot()
	end
	AnimFSM.tickEnd()
	PartClass.tickEnd()
	if host:isHost() then
		StateSynch.tick()
	end
end

function events.render(delta, ctx, mtrx)
	if ctx ~= "PAPERDOLL" and ctx ~= "RENDER" then
		return
	end
	AnimClass.render(delta)
	PartClass.render(delta)
end

if host:isHost() then

	local main_page = action_wheel:newPage()
	local emote_page = action_wheel:newPage()
	local outfit_page = action_wheel:newPage()

	for i, emote in ipairs(emotes) do
		emote_page:newAction()
		:title(emote.name)
		:item(emote.item)
		:onLeftClick(function()
			StateSynch.setState("emote", i)
		end)
	end

	emote_page:newAction()
	:title("Back")
	:item("minecraft:barrier")
	:onLeftClick(function()
		action_wheel:setPage(main_page)
	end)
	
	main_page:newAction()
	:title("Emotes")
	:item("minecraft:armor_stand")
	:onLeftClick(function()
		action_wheel:setPage(emote_page)
	end)

	for i, outfit in ipairs(outfits) do
		outfit_page:newAction()
		:title(outfit.name)
		:item(outfit.item)
		:onLeftClick(function()
			StateSynch.setState("outfit", i)
		end)
	end

	outfit_page:newAction()
	:title("Back")
	:item("minecraft:barrier")
	:onLeftClick(function()
		action_wheel:setPage(main_page)
	end)

	main_page:newAction()
	:title("Outfits")
	:item("minecraft:leather_chestplate")
	:onLeftClick(function()
		action_wheel:setPage(outfit_page)
	end)

	action_wheel:setPage(main_page)

end