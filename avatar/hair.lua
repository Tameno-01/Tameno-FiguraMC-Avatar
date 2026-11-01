local RawParts = require("model_parts/raw_parts")

local RAISE_SMOOTHING = 2

local hair_parts = {
	{
		part  = RawParts.hair_front_left,
		target = RawParts.hair_front_left_target,
		raise_dir = -1,
		raise_amount = 4,
	},
	{
		part  = RawParts.hair_front_right,
		target = RawParts.hair_front_right_target,
		raise_dir = -1,
		raise_amount = 4,
	},
	{
		part  = RawParts.hair_back,
		target = RawParts.hair_back_target,
		raise_dir = 1,
		raise_amount = 5,
	},
}

function RawParts.head.midRender()
	for _, hair_part in ipairs(hair_parts) do
		local part = hair_part.part
		local target = hair_part.target
		local raise_dir = hair_part.raise_dir
		local raise_amount = hair_part.raise_amount
		local parent = RawParts.head
		local part_pos = part:getPivot() - parent:getPivot()
		local parent_mat = parent:partToWorldMatrix()
		local target_mat = target:partToWorldMatrix()
		target_mat = parent_mat:inverted() * target_mat
		local target_pos = target_mat:getColumn(4).xyz
		target_pos = target_pos - part_pos
		local raised_target_pos = target_pos + target_mat:getColumn(2).xyz * raise_amount
		local raise_score = math.min(
			-raised_target_pos:dot(target_mat:getColumn(2).xyz:normalized()),
			raised_target_pos:dot(target_mat:getColumn(3).xyz:normalized()) * raise_dir
		)
		raise_score = raise_score / RAISE_SMOOTHING
		raise_score = math.clamp(raise_score, 0, 1)
		target_pos = math.lerp(target_pos, raised_target_pos, raise_score)
		local target_dir = target_pos:normalized()
		local pitch = math.deg(math.asin(target_dir.x))
		local yaw = -math.deg(math.atan(target_dir.y, target_dir.z)) -90
		part:setRot(vec(yaw, 0, pitch))
	end
end