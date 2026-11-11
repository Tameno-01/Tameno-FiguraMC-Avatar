local RawParts = require("model_parts/raw_parts")

local POS_MARGIN = 0.01
local ANGLE_MARGIN = 12
local MAX_INITIAL_ANGLE = 100
local MULTIPLIER = 0.5
local RAISE = 0.05

local sides = {
	left = {
		front = RawParts.skirt_front_left,
		middle = RawParts.skirt_left,
		back = RawParts.skirt_back_left,
	},
	right = {
		front = RawParts.skirt_front_right,
		middle = RawParts.skirt_right,
		back = RawParts.skirt_back_right,
	},
}

local function get_leg_rotation(to_local, upper_leg_part, lower_leg_part)
	local upper_leg_vec = to_local:apply(upper_leg_part:partToWorldMatrix():getColumn(4).xyz)
	local lower_leg_vec = to_local:apply(lower_leg_part:partToWorldMatrix():getColumn(4).xyz)
	local leg_vec = lower_leg_vec - upper_leg_vec
	leg_vec = leg_vec:normalized()
	local x = 0
	if math.abs(leg_vec.z) > POS_MARGIN then
		x = -math.deg(math.atan2(leg_vec.z, -leg_vec.y))
		x = math.clamp(x, -MAX_INITIAL_ANGLE, MAX_INITIAL_ANGLE)
	end
	local z = 0
	if math.abs(leg_vec.x) > POS_MARGIN then
		z = math.deg(math.atan2(leg_vec.x, -leg_vec.y))
		z = math.clamp(z, -MAX_INITIAL_ANGLE, MAX_INITIAL_ANGLE)
	end
	return x, z
end

local function apply_leg_rotation(side, x_front, x_back, z)
	local side_table = sides[side]
	if side == "left" then
		z = math.min(z + ANGLE_MARGIN, 0)
	else
		z = math.max(z - ANGLE_MARGIN, 0)
	end
	z = z * MULTIPLIER
	local abs_z = math.abs(z)
	side_table.middle:setRot(0, 0, z)
	side_table.middle:setPos(0, abs_z * RAISE, 0)
	side_table.front:setRot(vec(x_front, 0, z))
	side_table.front:setPos(vec(0, (math.abs(x_front) + abs_z) / 2 * RAISE, 0))
	side_table.back:setRot(vec(x_back, 0, z))
	side_table.back:setPos(vec(0, (math.abs(x_back) + abs_z) / 2 * RAISE, 0))
end

function RawParts.skirt.midRender()
	local to_local = RawParts.skirt:partToWorldMatrix():inverted()
	local left_x, left_z = get_leg_rotation(to_local, RawParts.left_upper_leg, RawParts.left_lower_leg_1)
	local right_x, right_z = get_leg_rotation(to_local, RawParts.right_upper_leg, RawParts.right_lower_leg_1)
	local front_x = math.max(left_x, right_x)
	front_x = math.max(front_x - ANGLE_MARGIN, 0) * MULTIPLIER
	local back_x = math.min(left_x, right_x)
	back_x = math.min(back_x + ANGLE_MARGIN, 0) * MULTIPLIER
	RawParts.skirt_front:setRot(vec(front_x, 0, 0))
	RawParts.skirt_front:setPos(vec(0, math.abs(front_x) * RAISE, 0))
	RawParts.skirt_back:setRot(vec(back_x, 0, 0))
	RawParts.skirt_back:setPos(vec(0, math.abs(back_x) * RAISE, 0))
	apply_leg_rotation("left", front_x, back_x, left_z)
	apply_leg_rotation("right", front_x, back_x, right_z)
end