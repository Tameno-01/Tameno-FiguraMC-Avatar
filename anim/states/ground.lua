local AnimState = require("anim/anim_state")
local Utils = require("utils")

local VANILLA_WALK_SPEEDS = {
	STAND = 0.21585,
	CROUCH = 0.06475,
}

local BASE_WALK_SPEEDS = {
	STAND = 4.5,
	CROUCH = 2,
}

local PREFIXES = {
	STAND = "",
	CROUCH = "crouch_",
}

local GroundState = {}

function GroundState:tick(params)
	local state = Utils.tif(player:isCrouching(), "CROUCH", "STAND")
	local prefix = PREFIXES[state]
	local velocity = vectors.rotateAroundAxis(-params.yaw, player:getVelocity(), vec(0, 1, 0))
	local abs_velocity = vec(math.abs(velocity.x), math.abs(velocity.z))
	local speed = abs_velocity:length() / VANILLA_WALK_SPEEDS[state]
	local sum_speed = abs_velocity.x + abs_velocity.y
	local f_b_anim = Utils.tif(velocity.z < 0, prefix .. "walk_forward", prefix .. "walk_back")
	local l_r_anim = Utils.tif(velocity.x < 0, prefix .. "walk_left", prefix .. "walk_right")
	local yawing = Utils.tif(params.yawing, 1, 0)
	local walk_blend
	local walk_speed
	local blends = {}
	if speed == 0 then
		walk_blend = 0
		walk_speed = 0
	else
		if speed < 1 then
			walk_speed = math.sqrt(speed)
			walk_blend = speed / walk_speed
		else
			walk_speed = speed
			walk_blend = 1
		end
		blends[f_b_anim] = abs_velocity.y / sum_speed * walk_blend
		blends[l_r_anim] = abs_velocity.x / sum_speed * walk_blend
	end
	local stand_blend = 1 - walk_blend
	blends[prefix .. "stand"] = stand_blend * (1 - yawing)
	blends[prefix .. "stand_left_arm"] = stand_blend
	blends[prefix .. "stand_right_arm"] = stand_blend
	blends[prefix .. "yaw"] = stand_blend * yawing
	blends[prefix .. "walk_left_arm"] = walk_blend
	blends[prefix .. "walk_right_arm"] = walk_blend
	walk_speed = walk_speed * BASE_WALK_SPEEDS[state]
	return {
		blends = blends,
		speeds = {
			locomotion = walk_speed,
		},
	}
end

return AnimState:new(GroundState)