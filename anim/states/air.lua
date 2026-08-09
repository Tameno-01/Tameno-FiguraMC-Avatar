local Utils = require("other_libs/utils")
local AnimState = require("anim/anim_state")

local AIR_SPEED_BOUNDS = 0.42

local PREFIXES = {
	STAND = "",
	CROUCH = "crouch_",
}

local AirState = {}

function AirState:tick(params)
	local state = Utils.tif(player:isCrouching(), "CROUCH", "STAND")
	local prefix = PREFIXES[state]
	local speed = player:getVelocity().y
	local blends = {}
	if speed > AIR_SPEED_BOUNDS then
		blends[prefix .. "air_up"] = 1
		blends[prefix .. "air_up_left_arm"] = 1
		blends[prefix .. "air_up_right_arm"] = 1
	elseif speed < -AIR_SPEED_BOUNDS then
		blends[prefix .. "air_down"] = 1
		blends[prefix .. "air_down_left_arm"] = 1
		blends[prefix .. "air_down_right_arm"] = 1
	else
		local up_blend = speed / AIR_SPEED_BOUNDS / 2 + 0.5
		local down_blend = 1 - up_blend
		blends[prefix .. "air_up"] = up_blend
		blends[prefix .. "air_up_left_arm"] = up_blend
		blends[prefix .. "air_up_right_arm"] = up_blend
		blends[prefix .. "air_down"] = down_blend
		blends[prefix .. "air_down_left_arm"] = down_blend
		blends[prefix .. "air_down_right_arm"] = down_blend
	end
	return {
		blends = blends
	}
end

return AnimState:new(AirState)