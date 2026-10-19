local Utils = require("./../core_utils")

local api = {}

local function test_ik_angle(lengths, angles, multiplier)
	local result = vec(lengths[1], 0)
	local total_angle = 0
	for i, len in ipairs(lengths) do
		if i ~= 1 then
			local idx = i - 1
			local angle = angles[idx] * multiplier
			total_angle = total_angle + angle
			result = result + vec(math.cos(math.rad(total_angle)), math.sin(math.rad(total_angle))) * len
		end
	end
	return result:length()
end

local function compute_ik_angle_multiplier(lengths, angles, target_distance, max_distance)
	if target_distance > max_distance then
		return 0
	end
	local multiplier = 0
	local multiplier_test_diff = 0.5
	for _ = 1, 10 do
		local distance = test_ik_angle(lengths, angles, multiplier)
		if distance < target_distance then
			multiplier = multiplier - multiplier_test_diff
		else
			multiplier = multiplier + multiplier_test_diff
		end
		multiplier_test_diff = multiplier_test_diff / 2
	end
	return multiplier
end

function api.perpendicular(a, b)
	if Utils.is_zero_approx(a) or Utils.is_zero_approx(b) then
		return vec(1, 0, 0)
	end
	local output = a:crossed(b)
	if Utils.is_zero_approx(output) then
		if Utils.is_zero_approx(vec(0, a.y, a.z)) then
			return a:crossed(vec(0, 1, 0)):normalized()
		else
			return a:crossed(vec(1, 0, 0)):normalized()
		end
	else
		return output:normalized()
	end
end

function api.angle_between(a, b)
	if Utils.is_zero_approx(a) or Utils.is_zero_approx(b) then
		return 0
	end
	local dot = a:normalized():dot(b:normalized())
	local output = math.deg(math.acos(dot))
	if output ~= output then -- NaN check. Thanks, lua.
		return 0
	end
	return output
end

function api.flatten_vect(vect, plane_normal)
	local projection_offset = vect:dot(plane_normal)
	return vect - plane_normal * projection_offset
end

function api.mat3_rotated_around_axis(angle, mat, axis)
	return matrices.mat3(
		vectors.rotateAroundAxis(angle, mat:getColumn(1), axis),
		vectors.rotateAroundAxis(angle, mat:getColumn(2), axis),
		vectors.rotateAroundAxis(angle, mat:getColumn(3), axis)
	)
end

function api.mat3_augmented_with_pos(mat, pos)
	return matrices.mat4(
		mat:getColumn(1):augmented(0),
		mat:getColumn(2):augmented(0),
		mat:getColumn(3):augmented(0),
		pos:augmented(1)
	)
end

function api.set_part_mat(part, mat)
	local actual_mat = matrices.mat4()
	actual_mat:translate(-part:getPivot())
	actual_mat:multiply(mat:deaugmented():augmented())
	actual_mat:translate(part:getPivot())
	actual_mat:translate(mat:getColumn(4).xyz)
	part:setMatrix(actual_mat)
end

function api.get_root_space_mat_raw(part, root)
	if part == root then
		return matrices.mat4()
	end
	local part_mat = part:getPositionMatrixRaw()
	local part_mat3 = part_mat:deaugmented()
	local mat_pos = part_mat:getColumn(4).xyz
	local pivot = part:getPivot()
	local local_pivot = pivot - part:getParent():getPivot()
	local part_base_pos = pivot - part_mat3 * pivot
	local mat_offset = mat_pos - part_base_pos
	local final_pos = local_pivot + mat_offset
	local pivot_mat = api.mat3_augmented_with_pos(part_mat3, final_pos)
	return api.get_root_space_mat_raw(part:getParent(), root) * pivot_mat
end

function api.get_root_space_mat_raw_without_pivot_correction(part, root)
	if part == root then
		return matrices.mat4()
	end
	return api.get_root_space_mat_raw_without_pivot_correction(part:getParent(), root) * part:getPositionMatrixRaw()
end

function api.precompute_ik_params(sections, config)
	local params = {}
	params.section_count = #sections
	params.last_to_leaf = config.leaf - sections[params.section_count].part:getPivot()
	params.pre_adjust_rest_dir = sections[params.section_count].part:getPivot() - sections[1].part:getPivot() + params.last_to_leaf
	if config.start_dir ~= nil then
		params.rest_dir = config.start_dir
	else
		params.rest_dir = params.pre_adjust_rest_dir
	end
	local angle_to_multiply
	if config.angle_multiplier ~= nil then
		angle_to_multiply = config.angle_multiplier
	else
		local total_angle_multiplier = 0
		for i, section in ipairs(sections) do
			if i ~= 1 then
				total_angle_multiplier = total_angle_multiplier + section.angle_multiplier
			end
		end
		local total_angle = 360 - 360 / params.section_count
		angle_to_multiply = total_angle / total_angle_multiplier
	end
	local accumulated_mat = matrices.mat3()
	params.sections = {}
	params.lengths = {}
	params.angles = {}
	for i, section in ipairs(sections) do
		local angle = nil
		if i ~= 1 then
			angle = section.angle_multiplier * angle_to_multiply
			params.angles[i - 1] = angle
		end
		local section_vect
		if i == params.section_count then
			section_vect = params.last_to_leaf
		else
			section_vect = sections[i + 1].part:getPivot() - section.part:getPivot()
		end
		params.lengths[i] = section_vect:length()
		local pre_ik_mat = matrices.mat3()
		local pre_ik_mat_rot_axis = api.perpendicular(section_vect, params.rest_dir)
		local pre_ik_mat_rot_angle = api.angle_between(section_vect, params.rest_dir)
		pre_ik_mat = api.mat3_rotated_around_axis(pre_ik_mat_rot_angle, pre_ik_mat, pre_ik_mat_rot_axis)
		pre_ik_mat = accumulated_mat:inverted() * pre_ik_mat
		table.insert(params.sections, {
			part = section.part,
			leaf_twist = section.leaf_twist,
			leaf_twist_vect = section.leaf_twist_vect,
			bend_twist = section.bend_twist,
			bend_twist_vect = section.bend_twist_vect,
			angle = angle,
			pre_ik_mat = pre_ik_mat,
			inv_pre_ik_mat = pre_ik_mat:inverted(),
			pre_adjust_rest_dir = section_vect:normalized()
		})
		accumulated_mat = accumulated_mat * pre_ik_mat
	end
	params.max_dist = 0
	for _, len in ipairs(params.lengths) do
		params.max_dist = params.max_dist + len
	end
	params.leaf_twist_vect = config.leaf_twist_vect
	params.leaf_forward_vect = config.leaf_forward_vect
	return params
end

function api.do_ik(params, target, bend_target, root, keep_pos)
	local first_part = params.sections[1].part
	local parent_mat = api.get_root_space_mat_raw(first_part:getParent(), root):deaugmented()
	local inv_parent_mat = parent_mat:inverted()
	local starting_mat = inv_parent_mat
	local local_start_pos = vec(0, 0, 0)
	if keep_pos then
		local_start_pos = first_part:getPositionMatrixRaw():apply(first_part:getPivot()) - first_part:getPivot()
	end
	local start = api.get_root_space_mat_raw(first_part, root):getColumn(4).xyz
	local diff = target:getColumn(4).xyz - start
	local dir = diff:normalized()
	local first_axis = api.perpendicular(params.rest_dir, dir)
	local first_angle = api.angle_between(params.rest_dir, dir)
	local first_part_mat = api.mat3_rotated_around_axis(first_angle, starting_mat, inv_parent_mat * first_axis)
	local accumulated_mat = parent_mat * first_part_mat
	local bend_target_vect = bend_target - start
	local global_axis = api.perpendicular(bend_target_vect, diff)
	local deaugmented_target = target:deaugmented()
	local leaf_twist_vect = deaugmented_target * params.leaf_twist_vect
	local leaf_forward_vect = deaugmented_target * params.leaf_forward_vect
	local leaf_bend_angle = api.angle_between(leaf_forward_vect, dir)
	local leaf_bend_axis = api.perpendicular(leaf_forward_vect, dir)
	local perpendicular_leaf_twist_vect = vectors.rotateAroundAxis(leaf_bend_angle, leaf_twist_vect:copy(), leaf_bend_axis)
	local flattened_bend_twist_vect = api.flatten_vect(bend_target_vect, dir)
	local twist_matrices = {}
	for i, section in ipairs(params.sections) do
		local twist_matrix = matrices.mat3()
		if section.leaf_twist ~= nil then
			local part_leaf_twist_vect = accumulated_mat * section.pre_ik_mat * section.leaf_twist_vect
			local leaf_twist = api.angle_between(part_leaf_twist_vect, perpendicular_leaf_twist_vect)
			leaf_twist = leaf_twist * math.sign(dir:dot(api.perpendicular(part_leaf_twist_vect, perpendicular_leaf_twist_vect)))
			leaf_twist = leaf_twist * section.leaf_twist
			twist_matrix = api.mat3_rotated_around_axis(leaf_twist, twist_matrix, section.pre_adjust_rest_dir)
		end
		if section.bend_twist ~= nil then
			local part_bend_twist_vect = accumulated_mat * twist_matrix * section.pre_ik_mat * section.bend_twist_vect
			local bend_twist = api.angle_between(part_bend_twist_vect, flattened_bend_twist_vect)
			bend_twist = bend_twist * math.sign(dir:dot(api.perpendicular(part_bend_twist_vect, flattened_bend_twist_vect)))
			bend_twist = bend_twist * section.bend_twist
			twist_matrix = api.mat3_rotated_around_axis(bend_twist, twist_matrix, section.pre_adjust_rest_dir)
		end
		twist_matrix = section.pre_ik_mat * twist_matrix
		twist_matrices[i] = twist_matrix
		accumulated_mat = accumulated_mat * twist_matrix
	end
	local angle_multiplier = compute_ik_angle_multiplier(
		params.lengths,
		params.angles,
		diff:length(),
		params.max_dist
	)
	first_part_mat = first_part_mat * twist_matrices[1]
	api.set_part_mat(first_part, api.mat3_augmented_with_pos(first_part_mat, local_start_pos))
	accumulated_mat = parent_mat * first_part_mat
	for i, section in ipairs(params.sections) do
		if i ~= 1 then
			local angle = section.angle * angle_multiplier
			local part_mat = api.mat3_rotated_around_axis(angle, twist_matrices[i], accumulated_mat:inverted() * global_axis)
			api.set_part_mat(section.part, part_mat:augmented())
			accumulated_mat = accumulated_mat * part_mat
		end
	end
	local post_ik_point = api.get_root_space_mat_raw(params.sections[params.section_count].part, root):apply(params.last_to_leaf)
	local post_ik_diff = post_ik_point - start
	local post_ik_axis = api.perpendicular(post_ik_diff, diff)
	local post_ik_angle = api.angle_between(post_ik_diff, diff)
	first_part_mat = api.mat3_rotated_around_axis(post_ik_angle, first_part_mat, inv_parent_mat * post_ik_axis)
	api.set_part_mat(first_part, api.mat3_augmented_with_pos(first_part_mat, local_start_pos))
end

function api.do_vanilla_ik(
	part,
	part_height,
	start_pos,
	target,
	bend_target,
	leaf_forward,
	root
)
	local target_point = target:getColumn(4).xyz
	local diff = target_point - start_pos
	local distance = diff:length()
	local part_vect
	local part_pos
	if distance > part_height then
		part_vect = diff:normalized() * part_height
		part_pos = start_pos
	else
		local half_distance = distance / 2
		local segment_length = part_height / 2
		local bend_height = math.sqrt(segment_length * segment_length - half_distance * half_distance)
		local bend_dir = bend_target - start_pos
		bend_dir = api.perpendicular(diff, api.perpendicular(bend_dir, diff))
		local bend_vect = bend_dir * bend_height
		part_vect = (diff / 2 - bend_vect) * 2
		part_pos = target_point - part_vect
	end
	local part_mat_y = -part_vect:normalized()
	local part_mat_z
	local part_mat_x
	local target_mat3 = target:deaugmented()
	local actual_leaf_forward = target_mat3 * leaf_forward
	local actual_leaf_side = target_mat3:getColumn(3)
	local bend_axis = api.perpendicular(part_mat_y, actual_leaf_forward)
	local bend_angle = api.angle_between(part_mat_y, actual_leaf_forward)
	vectors.rotateAroundAxis(bend_angle, actual_leaf_side, bend_axis)
	part_mat_z = actual_leaf_side
	part_mat_x = api.perpendicular(part_mat_y, part_mat_z)
	part_mat_z = api.perpendicular(part_mat_x, part_mat_y)
	local part_mat = matrices.mat4()
	part_mat:translate(-part:getPivot())
	part_mat = matrices.mat3(part_mat_x, part_mat_y, part_mat_z):augmented() * part_mat
	part_mat:translate(part_pos)
	part_mat = api.get_root_space_mat_raw_without_pivot_correction(part:getParent(), root):inverted() * part_mat
	part:setMatrix(part_mat)
end

return api