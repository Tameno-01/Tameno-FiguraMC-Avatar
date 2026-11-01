local AnimState = require("anim/anim_state")

local RunState = {}

local ANIMATION_SPEED = 14

function RunState:tick(params)
	local velocity = vectors.rotateAroundAxis(-params.yaw, params.smooth_speed, vec(0, 1, 0)).xz
	local speed = velocity:length()
	return {
		blends = {
			run = 1,
			run_left_arm = 1,
			run_right_arm = 1,
		},
		speeds = {
			locomotion = speed * ANIMATION_SPEED
		},
	}
end

return AnimState:new(RunState)