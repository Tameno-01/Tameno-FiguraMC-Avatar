pcall(require, "./debug_overrides")

local api = {}

local function contains_only_numbers(tbl)
	for _, v in ipairs(tbl) do
		if type(v) ~= "number" then
			return false
		end
	end
	return true
end

local function is_equal_approx(vect_a, vect_b)
	return api.is_zero_approx(vect_a - vect_b)
end

local function is_normalized_vect_aligned(vect_a, vect_b)
	return is_equal_approx(vect_a, vect_b) or is_equal_approx(vect_a, -vect_b)
end

local function is_normalized_mat3_salvageable(x, y, z)
	if x == vec(0, 0, 0) then
		return false
	end
	if y == vec(0, 0, 0) then
		return false
	end
	if z == vec(0, 0, 0) then
		return false
	end
	if is_normalized_vect_aligned(x, y) then
		return false
	end
	if is_normalized_vect_aligned(x, z) then
		return false
	end
	if is_normalized_vect_aligned(y, z) then
		return false
	end
	return true
end

local function make_mat3_valid(mat)
	local x = mat:getColumn(1):normalized()
	local y = mat:getColumn(2):normalized()
	local z = mat:getColumn(3):normalized()
	if not is_normalized_mat3_salvageable(x, y, z) then
		return matrices.mat3()
	end
	y = z:crossed(x):normalized()
	z = x:crossed(y):normalized()
	return matrices.mat3(x, y, z)
end

local function make_mat4_valid(mat)
	local x = mat:getColumn(1).xyz:normalized()
	local y = mat:getColumn(2).xyz:normalized()
	local z = mat:getColumn(3).xyz:normalized()
	if not is_normalized_mat3_salvageable(x, y, z) then
		return matrices.mat4(
			vec(1, 0, 0, 0),
			vec(0, 1, 0, 0),
			vec(0, 0, 1, 0),
			mat:getColumn(4).xyz:augmented(1)
		)
	end
	y = z:crossed(x):normalized()
	z = x:crossed(y):normalized()
	return matrices.mat4(
		x:augmented(0),
		y:augmented(0),
		z:augmented(0),
		mat:getColumn(4).xyz:augmented(1)
	)
end

function api.deep_copy_tbl(tbl)
	local output = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			output[k] = api.deep_copy_tbl(v)
		else
			output[k] = v
		end
	end
	return output
end

function api.is_zero_approx(vect)
	if -0.001 > vect.x or vect.x > 0.001 then
		return false
	end
	if -0.001 > vect.y or vect.y > 0.001 then
		return false
	end
	if -0.001 > vect.z or vect.z > 0.001 then
		return false
	end
	return true
end

function api.add_vec_to_avar(name, input, output, scale)
	local vect = input[name] * scale
	output[name] = {vect.x, vect.y, vect.z}
end

function api.add_mat3_to_avar(name, input, output)
	local mat = input[name]
	local x = mat:getColumn(1)
	local y = mat:getColumn(2)
	local z = mat:getColumn(3)
	output[name] = {
		x.x, x.y, x.z,
		y.x, y.y, y.z,
		z.x, z.y, z.z,
	}
end

function api.add_mat4_to_avar(name, input, output, scale)
	local mat = input[name]
	local x = mat:getColumn(1)
	local y = mat:getColumn(2)
	local z = mat:getColumn(3)
	local w = mat:getColumn(4)
	output[name] = {
		x.x, x.y, x.z,
		y.x, y.y, y.z,
		z.x, z.y, z.z,
		w.x * scale, w.y * scale, w.z * scale,
	}
end

function api.add_vec_from_avar(name, input, output, scale)
	local vec_table = input[name]
	if type(vec_table) ~= "table" then
		output[name] = vec(0, 0, 0)
		return
	end
	if #vec_table ~= 3 then
		output[name] = vec(0, 0, 0)
		return
	end
	if not contains_only_numbers(vec_table) then
		output[name] = vec(0, 0, 0)
		return
	end
	output[name] = vec(vec_table[1], vec_table[2], vec_table[3]) * scale
end

function api.add_mat3_from_avar(name, input, output)
	local mat_table = input[name]
	if type(mat_table) ~= "table" then
		output[name] = matrices.mat3()
		return
	end
	if #mat_table ~= 9 then
		output[name] = matrices.mat3()
		return
	end
	if not contains_only_numbers(mat_table) then
		output[name] = matrices.mat3()
		return
	end
	local mat = matrices.mat3(
		vec(mat_table[1], mat_table[2], mat_table[3]),
		vec(mat_table[4], mat_table[5], mat_table[6]),
		vec(mat_table[7], mat_table[8], mat_table[9])
	)
	mat = make_mat3_valid(mat)
	output[name] = mat
end

function api.add_mat4_from_avar(name, input, output, scale)
	local mat_table = input[name]
	if type(mat_table) ~= "table" then
		output[name] = matrices.mat4()
		return
	end
	if #mat_table ~= 12 then
		output[name] = matrices.mat4()
		return
	end
	if not contains_only_numbers(mat_table) then
		output[name] = matrices.mat4()
		return
	end
	local mat = matrices.mat4(
		vec(mat_table[1], mat_table[2], mat_table[3], 0),
		vec(mat_table[4], mat_table[5], mat_table[6], 0),
		vec(mat_table[7], mat_table[8], mat_table[9], 0),
		vec(mat_table[10] * scale, mat_table[11] * scale, mat_table[12] * scale, 1)
	)
	mat = make_mat4_valid(mat)
	output[name] = mat
end

return api