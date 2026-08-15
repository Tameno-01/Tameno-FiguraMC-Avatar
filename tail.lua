local RawParts = require("model_parts/raw_parts")

local TAIL_SECTION_ANGLE_RAD = math.pi / 5
local STIFFNESS = 0.5
local DAMPING_FACTOR = 0.6
local LENGTH_STIFFNESS = 0.5
local LENGTH_DAMPING = 2
local INITIAL_HEIGHT = 0.5
local INITIAL_HEIGHT_DIFFERENCE = 0.3

local tail_sections = {
	{
		parent = RawParts.tail_root,
		part = RawParts.tail_1,
		leaf = RawParts.tail_2,
	},
	{
		parent = RawParts.tail_1,
		part = RawParts.tail_2,
		leaf = RawParts.tail_3,
	},
	{
		parent = RawParts.tail_2,
		part = RawParts.tail_3,
		leaf = RawParts.tail_leaf,
	},
}

for i, section in ipairs(tail_sections) do
	section.length = (
		section.leaf:getPivot().z
		- section.part:getPivot().z
	)
	section.angle_rad = TAIL_SECTION_ANGLE_RAD * (i - 1)
	section.speed = vec(0, 0, 0)
end

local function renderTailSection(delta, section)
	local target_pos = math.lerp(section.prev_target_pos, section.target_pos, delta)
	local global_mat = section.parent:partToWorldMatrix()
	local inv_global_mat = global_mat:inverted()
	local target_pos_local = inv_global_mat:apply(target_pos)
	local target_vec = target_pos_local - (section.part:getPivot() - section.parent:getPivot())
	local yaw = math.deg(math.atan(target_vec.x, target_vec.z))
	local pitch = -math.deg(math.atan(target_vec.y, vec(target_vec.x, target_vec.z):length()))
	section.part:setRot(vec(pitch, yaw, 0))
end

function events.entity_init()
	for i, section in ipairs(tail_sections) do
		section.target_pos = player:getPos() + vec(0, INITIAL_HEIGHT + INITIAL_HEIGHT_DIFFERENCE * i, 0)
		section.prev_dist_to_parent = INITIAL_HEIGHT_DIFFERENCE
		section.prev_target_pos = section.target_pos
		function section.parent.midRender(delta)
			renderTailSection(delta, section)
		end
	end
end

function events.tick()
	local root_mat = RawParts.tail_root:partToWorldMatrix()
	local back = root_mat:getColumn(3).xyz
	local up = root_mat:getColumn(2).xyz
	for i, section in ipairs(tail_sections) do
		section.prev_target_pos = section.target_pos
		local ideal_pos_relative = (
			back * math.cos(section.angle_rad)
			+ up * math.sin(section.angle_rad)
		) * section.length
		local parent_pos
		if i == 1 then
			parent_pos = root_mat:getColumn(4).xyz
		else
			parent_pos = tail_sections[i - 1].target_pos
		end
		local ideal_pos = parent_pos + ideal_pos_relative
		local diff = ideal_pos - section.target_pos
		section.speed = section.speed + diff * STIFFNESS
		local length_vect = section.target_pos - parent_pos
		local distance = length_vect:length()
		local distance_accel_amount = section.length * back:length() - distance
		distance_accel_amount = distance_accel_amount * LENGTH_STIFFNESS
		local distance_speed = distance - section.prev_dist_to_parent
		if math.sign(distance_accel_amount) ~= math.sign(distance_speed) then
			distance_accel_amount = distance_accel_amount * LENGTH_DAMPING
		end
		local speed_len = section.speed:length()
		section.speed = section.speed + length_vect:normalized() * distance_accel_amount
		section.speed = section.speed:normalized() * speed_len
		section.speed = section.speed * DAMPING_FACTOR
		section.target_pos = section.target_pos + section.speed
		section.prev_dist_to_parent = distance
	end
end