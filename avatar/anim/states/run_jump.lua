local AnimState = require("anim/anim_state")
local Utils = require("other_libs/utils")

local RunJumpState = {}

function RunJumpState:tick(params)
	local left = Utils.tif(params.run_jump_left, 1, 0)
	local right = Utils.tif(params.run_jump_left, 0, 1)
	return {
		blends = {
			run_jump_left = left,
			run_jump_left_left_arm = left,
			run_jump_left_right_arm = left,
			run_jump_right = right,
			run_jump_right_left_arm = right,
			run_jump_right_right_arm = right,
		}
	}
end

return AnimState:new(RunJumpState)