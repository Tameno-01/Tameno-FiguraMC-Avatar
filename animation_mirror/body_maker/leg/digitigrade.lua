local Utils = require("./../core_utils")

local api = {}

function api.make(
	upper,
	lower_1,
	lower_2,
	foot,
	is_right,
	is_foot_real
)
	if is_foot_real == nil then
		is_foot_real = true
	end
	local upper_rest_mat = upper:getPositionMatrix()
	local lower_1_rest_mat = lower_1:getPositionMatrix()
	local lower_2_rest_mat = lower_2:getPositionMatrix()
	local foot_rest_mat = foot:getPositionMatrix()
	local upper_forward = Utils.perpendicular(vec(1, 0, 0), lower_1:getPivot() - upper:getPivot())
	local lower_1_forward = Utils.perpendicular(vec(1, 0, 0), lower_2:getPivot() - lower_1:getPivot())
	local lower_2_forward = Utils.perpendicular(vec(1, 0, 0), foot:getPivot() - lower_2:getPivot())
	local lower_2_section
	if is_foot_real then
		lower_2_section ={
			part = lower_2,
			angle_multiplier = -1,
			leaf_twist = 0.75,
			leaf_twist_vect = lower_2_forward,
			bend_twist = 0.3,
			bend_twist_vect = lower_2_forward,
		}
	else
		lower_2_section = {
			part = lower_2,
			angle_multiplier = -1,
			leaf_twist = 1,
			leaf_twist_vect = lower_2_forward,
		}
	end
	local ik_params = Utils.precompute_ik_params(
		{
			{
				part = upper,
				leaf_twist = 0.25,
				leaf_twist_vect = upper_forward,
				bend_twist = 0.5,
				bend_twist_vect = upper_forward,
			},
			{
				part = lower_1,
				angle_multiplier = 1,
				leaf_twist = 0.5,
				leaf_twist_vect = lower_1_forward,
				bend_twist = 0.3,
				bend_twist_vect = lower_1_forward,
			},
			lower_2_section,
		},
		{
			leaf = foot:getPivot(),
			leaf_twist_vect = vec(0, 0, -1),
			leaf_forward_vect = vec(0, -1, 0),
			angle_multiplier = 180
		}
	)
	local foot_name
	local bend_target_name
	if is_right then
		foot_name = "right_foot"
		bend_target_name = "right_leg_bend_target"
	else
		foot_name = "left_foot"
		bend_target_name = "left_leg_bend_target"
	end
	local output = {}
	function output.get_offset(hips)
		return upper:getPivot() - hips
	end
	function output.get_pose(root)
		local pose = {}
		pose.bend_target = Utils.get_root_space_mat_raw(lower_1, root):apply(0, 0, -0.5)
		pose.foot = Utils.get_root_space_mat_raw(foot, root)
		return pose
	end
	function output.apply_pose(pose, root, start)
		if start ~= nil then
			local parent_mat = Utils.get_root_space_mat_raw(upper:getParent(), root)
			local mat = parent_mat:inverted() * start:copy():translate(-upper:getPivot())
			Utils.set_part_mat(upper, mat)
		end
		Utils.do_ik(ik_params, pose[foot_name], pose[bend_target_name], root, start ~= nil)
		if is_foot_real then
			local foot_parent_mat = Utils.get_root_space_mat_raw(foot:getParent(), root)
			Utils.set_part_mat(foot, (foot_parent_mat:deaugmented():inverted() * pose[foot_name]:deaugmented()):augmented())
		end
	end
	function output.reset_pose()
		upper:setMatrix(upper_rest_mat)
		lower_1:setMatrix(lower_1_rest_mat)
		lower_2:setMatrix(lower_2_rest_mat)
		if is_foot_real then
			foot:setMatrix(foot_rest_mat)
		end
	end
	output.should_detach = false
	return output
end

return api