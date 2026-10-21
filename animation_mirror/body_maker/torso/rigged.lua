local Utils = require("./../core_utils")

local api = {}

function api.make(
	spine,
	neck
)
	local spine_count = #spine
	local spine_center_idx = math.ceil(#spine / 2) + 1
	local start_part = spine[1]
	local center_part = spine[spine_center_idx]
	local end_part = spine[spine_count]
	local rest_poses = {}
	for i, v in ipairs(spine) do
		rest_poses[i] = v:getPositionMatrix()
	end
	local accumulated_twist = 0
	local sections = {}
	for i, part in ipairs(spine) do
		local ideal_twist = (i - 1) / (spine_count - 1)
		local ideal_difference = 1 - ideal_twist
		local actual_difference = 1 - accumulated_twist
		local leaf_twist = 1 - ideal_difference / actual_difference
		sections[i] = {
			part = part,
			angle_multiplier = 1,
			leaf_twist = leaf_twist,
			leaf_twist_vect = vec(1, 0, 0),
		}
		accumulated_twist = accumulated_twist + leaf_twist
	end
	local ik_params = Utils.precompute_ik_params(sections, {
		leaf = neck:getPivot(),
		leaf_twist_vect = vec(1, 0, 0),
		leaf_forward_vect = vec(0, 1, 0),
		keep_pos = true,
	})
	local output = {}
	function output.get_pose(root)
		local pose = {}
		pose.hips = Utils.get_root_space_mat_raw(start_part, root)
		pose.bend_target = Utils.get_root_space_mat_raw(center_part, root):getColumn(4).xyz
		local top_pos = Utils.get_root_space_mat_raw(neck, root)
		local top_basis = Utils.get_root_space_mat_raw(end_part, root)
		pose.top = matrices.mat4(
			top_basis:getColumn(1),
			top_basis:getColumn(2),
			top_basis:getColumn(3),
			top_pos:getColumn(4)
		)
		return pose
	end
	function output.apply_pose(pose, root)
		local parent_mat = Utils.get_root_space_mat_raw_without_pivot_correction(spine[1]:getParent(), root)
		local mat = matrices.mat4()
		mat:translate(-spine[1]:getPivot())
		mat = pose.hips * mat
		mat = parent_mat:inverted() * mat
		spine[1]:setMatrix(mat)
		Utils.do_ik(ik_params, pose.torso_top, pose.torso_bend_target, root, true)
	end
	function output.reset_pose()
		for i, v in ipairs(spine) do
			v:setMatrix(rest_poses[i])
		end
	end
	function output.get_top_pivot()
		return neck:getPivot()
	end
	function output.get_hips_pivot()
		return spine[1]:getPivot()
	end
	output.should_detach = false
	return output
end

return api