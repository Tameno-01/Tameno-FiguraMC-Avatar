local Utils = require("./../core_utils")

local api = {}

function api.make(
	upper,
	lower,
	hand,
	is_right,
	is_hand_real
)
	if is_hand_real == nil then
		is_hand_real = true
	end
	local upper_rest_mat = upper:getPositionMatrix()
	local lower_rest_mat = lower:getPositionMatrix()
	local hand_rest_mat = hand:getPositionMatrix()
	local hand_pose_mat_x = hand:getPivot() - lower:getPivot()
	local hand_name
	local bend_target_name
	local ik_start_dir
	if is_right then
		hand_name = "right_hand"
		bend_target_name = "right_arm_bend_target"
		ik_start_dir = vec(1, 0, 0)
	else
		hand_name = "left_hand"
		bend_target_name = "left_arm_bend_target"
		ik_start_dir = vec(-1, 0, 0)
		hand_pose_mat_x = -hand_pose_mat_x
	end
	local hand_pose_mat_z = vec(0, 0, 1)
	local hand_pose_mat_y = hand_pose_mat_z:crossed(hand_pose_mat_x)
	hand_pose_mat_z = hand_pose_mat_x:crossed(hand_pose_mat_y)
	local hand_pose_mat = matrices.mat3(
		hand_pose_mat_x:normalized(),
		hand_pose_mat_y:normalized(),
		hand_pose_mat_z:normalized()
	)
	local inv_hand_pose_mat = hand_pose_mat:inverted()
	local lower_section
	if is_hand_real then
		lower_section = {
			part = lower,
			angle_multiplier = 1,
			leaf_twist = 0.66,
			leaf_twist_vect = vec(0, 0, 1),
			bend_twist = 0.3,
			bend_twist_vect = vec(0, 0, 1),
		}
	else
		lower_section = {
			part = lower,
			angle_multiplier = 1,
			leaf_twist = 1,
			leaf_twist_vect = vec(0, 0, 1),
		}
	end
	local ik_params = Utils.precompute_ik_params(
		{
			{
				part = upper,
				leaf_twist = 0.25,
				leaf_twist_vect = vec(0, 0, 1),
				bend_twist = 0.5,
				bend_twist_vect = vec(0, 0, 1),
			},
			lower_section,
		},
		{
			leaf = hand:getPivot(),
			leaf_twist_vect = vec(0, 0, 1),
			leaf_forward_vect = ik_start_dir,
			start_dir = ik_start_dir,
		}
	)
	local output = {}
	function output.get_offset(torso_top)
		return upper:getPivot() - torso_top
	end
	function output.get_pose(root)
		local pose = {}
		pose.bend_target = Utils.get_root_space_mat_raw(lower, root):apply(vec(0, 0, 0.5))
		local global_hand_mat = Utils.get_root_space_mat_raw(hand, root)
		local global_hand_rot = global_hand_mat:deaugmented()
		global_hand_rot = global_hand_rot * hand_pose_mat
		global_hand_mat = matrices.mat4(
			global_hand_rot:getColumn(1):augmented(0),
			global_hand_rot:getColumn(2):augmented(0),
			global_hand_rot:getColumn(3):augmented(0),
			global_hand_mat:getColumn(4)
		)
		pose.hand = global_hand_mat
		return pose
	end
	function output.apply_pose(pose, root, start)
		if start ~= nil then
			local parent_mat = Utils.get_root_space_mat_raw_without_pivot_correction(upper:getParent(), root)
			local mat = matrices.mat4()
			mat:translate(-upper:getPivot())
			mat = start * mat
			mat = parent_mat:inverted() * mat
			upper:setMatrix(mat)
		end
		Utils.do_ik(ik_params, pose[hand_name], pose[bend_target_name], root, start ~= nil)
		if is_hand_real then			
			local hand_parent_mat = Utils.get_root_space_mat_raw(hand:getParent(), root):deaugmented()
			Utils.set_part_mat(hand, (hand_parent_mat:inverted() * (pose[hand_name]:deaugmented() * inv_hand_pose_mat)):augmented())
		end
	end
	function output.reset_pose()
		upper:setMatrix(upper_rest_mat)
		lower:setMatrix(lower_rest_mat)
		if is_hand_real then
			hand:setMatrix(hand_rest_mat)
		end
	end
	output.should_detach = false
	return output
end

return api