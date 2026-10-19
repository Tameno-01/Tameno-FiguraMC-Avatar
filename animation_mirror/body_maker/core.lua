pcall(require, "./debug_overrides")

local api = {}

local VANILLA_NECK_HEIGHT = 24

function api.make(
	head,
	torso,
	left_arm,
	right_arm,
	left_leg,
	right_leg,
	root,
	auto_reset
)
	if root == nil then
		root = models
	end
	if auto_reset == nil then
		auto_reset = true
	end
	local torso_top_pivot = torso.get_top_pivot()
	local hips_pivot = torso.get_hips_pivot()
	local offsets = {}
	if torso.should_detach or head.should_detach then
		offsets.head = head.get_offset(torso_top_pivot)
	end
	if  torso.should_detach or left_arm.should_detach then
		offsets.left_arm = left_arm.get_offset(torso_top_pivot)
	end
	if  torso.should_detach or right_arm.should_detach then
		offsets.right_arm = right_arm.get_offset(torso_top_pivot)
	end
	if  torso.should_detach or left_leg.should_detach then
		offsets.left_leg = left_leg.get_offset(hips_pivot)
	end
	if  torso.should_detach or right_leg.should_detach then
		offsets.right_leg = right_leg.get_offset(hips_pivot)
	end
	local output = {}
	output.root = root
	output.scale = torso_top_pivot.y / VANILLA_NECK_HEIGHT
	function output.get_pose()
		local head_pose = head.get_pose(root)
		local torso_pose = torso.get_pose(root)
		local left_arm_pose = left_arm.get_pose(root)
		local right_arm_pose = right_arm.get_pose(root)
		local left_leg_pose = left_leg.get_pose(root)
		local right_leg_pose = right_leg.get_pose(root)
		local pose = {}
		pose.head = head_pose.head
		pose.torso_top = torso_pose.top
		pose.hips = torso_pose.hips
		pose.left_hand = left_arm_pose.hand
		pose.right_hand = right_arm_pose.hand
		pose.left_foot = left_leg_pose.foot
		pose.right_foot = right_leg_pose.foot
		pose.torso_bend_target = torso_pose.bend_target
		pose.left_arm_bend_target = left_arm_pose.bend_target
		pose.right_arm_bend_target = right_arm_pose.bend_target
		pose.left_leg_bend_target = left_leg_pose.bend_target
		pose.right_leg_bend_target = right_leg_pose.bend_target
		return pose
	end
	function output.apply_pose(pose)
		local starts = {}
		local hips_mat3 = pose.hips:deaugmented()
		local torso_top_mat3 = pose.torso_top:deaugmented()
		if offsets.head ~= nil then
			starts.head = pose.torso_top:copy():translate(torso_top_mat3 * offsets.head)
		end
		if offsets.left_arm ~= nil then
			starts.left_arm = pose.torso_top:copy():translate(torso_top_mat3 * offsets.left_arm)
		end
		if offsets.right_arm ~= nil then
			starts.right_arm = pose.torso_top:copy():translate(torso_top_mat3 * offsets.right_arm)
		end
		if offsets.left_leg ~= nil then
			starts.left_leg = pose.hips:copy():translate(hips_mat3 * offsets.left_leg)
		end
		if offsets.right_leg ~= nil then
			starts.right_leg = pose.hips:copy():translate(hips_mat3 * offsets.right_leg)
		end
		torso.apply_pose(pose, root)
		head.apply_pose(pose, root, starts.head)
		left_arm.apply_pose(pose, root, starts.left_arm)
		right_arm.apply_pose(pose, root, starts.right_arm)
		left_leg.apply_pose(pose, root, starts.left_leg)
		right_leg.apply_pose(pose, root, starts.right_leg)
	end
	if auto_reset then
		function output.reset_pose()
			head.reset_pose()
			torso.reset_pose()
			left_arm.reset_pose()
			right_arm.reset_pose()
			left_leg.reset_pose()
			right_leg.reset_pose()
		end
	end
	return output
end

return api