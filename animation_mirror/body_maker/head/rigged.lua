local Utils = require("./../core_utils")

local api = {}

function api.make(
	head,
	neck
)
	local neck_rest_mat
	local head_rest_mat = head:getPositionMatrix()
	local pose_application_part
	if neck ~= nil then
		neck_rest_mat = neck:getPositionMatrix()
		pose_application_part = neck
	else
		pose_application_part = head
	end
	local output = {}
	function output.get_offset(torso_top)
		return pose_application_part:getPivot() - torso_top
	end
	function output.get_pose(root)
		local pose = {}
		pose.head = Utils.get_root_space_mat_raw(head, root):deaugmented()
		return pose
	end
	function output.apply_pose(pose, root, start)
		if start ~= nil then
			local global_head_mat = pose.head:augmented():translate(start:getColumn(4).xyz)
			local parent = Utils.get_root_space_mat_raw_without_pivot_correction(pose_application_part:getParent(), root)
			local head_mat = matrices.mat4()
			head_mat:translate(-pose_application_part:getPivot())
			head_mat = global_head_mat * head_mat
			head_mat = parent:inverted() * head_mat
			pose_application_part:setMatrix(head_mat)
		else
			local parent_mat = Utils.get_root_space_mat_raw(pose_application_part:getParent(), root):deaugmented()
			Utils.set_part_mat(pose_application_part, (parent_mat:inverted() * pose.head):augmented())
		end
	end
	function output.reset_pose()
		if neck ~= nil then
			neck:setMatrix(neck_rest_mat)
		end
		head:setMatrix(head_rest_mat)
	end
	output.should_detach = false
	return output
end

return api