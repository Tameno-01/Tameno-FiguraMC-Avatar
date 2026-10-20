local Utils = require("./core_utils")

local api = {}

local current_state = "OFF"
local source_player_uuid = nil
local current_pose = nil
local pose_getter = nil
local state_change_functions = {}
local source_change_functions = {}
local body = nil

-- this function will be given a body later in this script
local stop_copying

local function is_allowed_to_copy(uuid)
	return true
end

local function exposed_is_allowed_to_copy(uuid)
	return is_allowed_to_copy(uuid)
end

avatar:store("AnimationMirror_is_allowed_to_copy", exposed_is_allowed_to_copy)

local function set_pose_getter(value)
	if type(value) ~= "function" then
		return
	end
	pose_getter = value
end

local function get_pose()
	if current_pose == nil then
		return nil
	end
	return Utils.deep_copy_tbl(current_pose)
end

local function send_pose_getter(to)
	if current_pose == nil then
		return
	end
	if not exposed_is_allowed_to_copy(to) then
		return
	end
	local vars = world.avatarVars()[to]
	if vars == nil then
		return
	end
	local setter_of_pose_getter = vars.AnimationMirror_set_pose_getter
	if type(setter_of_pose_getter) ~= "function" then
		return
	end
	pcall(setter_of_pose_getter, get_pose)
end

local function change_state(to)
	local from = current_state
	current_state = to
	if from == "COPYING" then
		if body.reset_pose ~= nil then
			body.reset_pose()
		end
	end
	for func, _ in pairs(state_change_functions) do
		func(from, to)
	end
end

local function source_render()
	local pose = body.get_pose()
	local avar = {}
	local inv_scale = 1 / body.scale
	Utils.add_mat3_to_avar("head", pose, avar)
	Utils.add_mat4_to_avar("torso_top", pose, avar, inv_scale)
	Utils.add_mat4_to_avar("hips", pose, avar, inv_scale)
	Utils.add_mat4_to_avar("left_hand", pose, avar, inv_scale)
	Utils.add_mat4_to_avar("right_hand", pose, avar, inv_scale)
	Utils.add_mat4_to_avar("left_foot", pose, avar, inv_scale)
	Utils.add_mat4_to_avar("right_foot", pose, avar, inv_scale)
	Utils.add_vec_to_avar("torso_bend_target", pose, avar, inv_scale)
	Utils.add_vec_to_avar("left_arm_bend_target", pose, avar, inv_scale)
	Utils.add_vec_to_avar("right_arm_bend_target", pose, avar, inv_scale)
	Utils.add_vec_to_avar("left_leg_bend_target", pose, avar, inv_scale)
	Utils.add_vec_to_avar("right_leg_bend_target", pose, avar, inv_scale)
	current_pose = avar
end

local function copying_render()
	local success, avar = pcall(pose_getter)
	if not success then
		stop_copying()
		change_state("OFF")
		return
	end
	if type(avar) ~= "table" then
		stop_copying()
		change_state("OFF")
		return
	end
	local pose = {}
	Utils.add_mat3_from_avar("head", avar, pose)
	Utils.add_mat4_from_avar("torso_top", avar, pose, body.scale)
	Utils.add_mat4_from_avar("hips", avar, pose, body.scale)
	Utils.add_mat4_from_avar("left_hand", avar, pose, body.scale)
	Utils.add_mat4_from_avar("right_hand", avar, pose, body.scale)
	Utils.add_mat4_from_avar("left_foot", avar, pose, body.scale)
	Utils.add_mat4_from_avar("right_foot", avar, pose, body.scale)
	Utils.add_vec_from_avar("torso_bend_target", avar, pose, body.scale)
	Utils.add_vec_from_avar("left_arm_bend_target", avar, pose, body.scale)
	Utils.add_vec_from_avar("right_arm_bend_target", avar, pose, body.scale)
	Utils.add_vec_from_avar("left_leg_bend_target", avar, pose, body.scale)
	Utils.add_vec_from_avar("right_leg_bend_target", avar, pose, body.scale)
	body.apply_pose(pose)
end

local function begin_being_source()
	avatar:store("AnimationMirror_send_pose_getter", send_pose_getter)
	events.POST_RENDER:register(source_render)
end

local function stop_being_source()
	current_pose = nil
	avatar:store("AnimationMirror_send_pose_getter", nil)
	events.POST_RENDER:remove(source_render)
end

local function begin_copying(uuid)
	local prev_source_player_uuid = source_player_uuid
	local player_vars = world.avatarVars()[uuid]
	source_player_uuid = player_vars.AnimationMirror_source
	if source_player_uuid == nil then
		source_player_uuid = uuid
	end
	if source_player_uuid == avatar:getUUID() then
		return false
	end
	if prev_source_player_uuid == source_player_uuid then
		return false
	end
	player_vars = world.avatarVars()[source_player_uuid]
	if player_vars == nil then
		return false
	end
	local pose_getter_sender = player_vars.AnimationMirror_send_pose_getter
	if type(pose_getter_sender) ~= "function" then
		return false
	end
	avatar:store("AnimationMirror_set_pose_getter", set_pose_getter)
	pcall(pose_getter_sender, avatar:getUUID())
	avatar:store("AnimationMirror_set_pose_getter", nil)
	if pose_getter == nil then
		return false
	end
	if prev_source_player_uuid == nil then
		events.RENDER:register(copying_render)
	end
	avatar:store("AnimationMirror_source", uuid)
	if prev_source_player_uuid ~= nil then
		for func, _ in pairs(source_change_functions) do
			func(prev_source_player_uuid, source_player_uuid)
		end
	end
	return true
end

-- "local" is missing because we declared "stop_copying" earlier
function stop_copying()
	source_player_uuid = nil
	pose_getter = nil
	events.RENDER:remove(copying_render)
	avatar:store("AnimationMirror_source", nil)
end

function api.set_body(p_body)
	if body ~= nil then
		error("AnimationMirror: Tried to set a body but one was already set.")
	end
	body = p_body
end

function api.set_allow_copy_func(func)
	is_allowed_to_copy = func
end

function api.begin_being_source()
	if body == nil then
		error("AnimationMirror: No body was provided")
	end
	if current_state == "SOURCE" then
		return
	elseif current_state == "COPYING" then
		stop_copying()
	end
	begin_being_source()
	change_state("SOURCE")
end

function api.can_copy(uuid)
	local player_vars = world.avatarVars()[uuid]
	if player_vars == nil then
		return false
	end
	if type(player_vars.AnimationMirror_is_allowed_to_copy) ~= "function" then
		return false
	end
	local player_is_allowed_to_copy = player_vars.AnimationMirror_is_allowed_to_copy
	if type(player_vars.AnimationMirror_source) == "string" then
		local success, output = pcall(player_is_allowed_to_copy, player_vars.AnimationMirror_source)
		if success and output then
			return true
		else
			return false
		end
	elseif type(player_vars.AnimationMirror_send_pose_getter) == "function" then
		local success, output = pcall(player_is_allowed_to_copy, uuid)
		if success and output then
			return true
		else
			return false
		end
	end
	return false
end

function api.begin_copying(uuid)
	if body == nil then
		error("AnimationMirror: No body was provided")
	end
	if not api.can_copy(uuid) then
		return false
	elseif current_state == "SOURCE" then
		stop_being_source()
	end
	if not begin_copying(uuid) then
		change_state("OFF")
		return false
	end
	change_state("COPYING")
	return true
end

function api.stop()
	if current_state == "OFF" then
		return
	end
	if current_state == "SOURCE" then
		stop_being_source()
	elseif current_state == "COPYING" then
		stop_copying()
	end
	change_state("OFF")
end

function api.get_current_state()
	return current_state
end

function api.get_source_player_uuid()
	return source_player_uuid
end

function api.register_state_change_func(func)
	state_change_functions[func] = true
end

function api.remove_state_change_func(func)
	state_change_functions[func] = nil
end

function api.register_source_change_func(func)
	source_change_functions[func] = true
end

function api.remove_source_change_func(func)
	source_change_functions[func] = nil
end

local meta = {}

function meta.__newindex(_, k, v)
	if k == "state_change" then
		api.register_state_change_func(v)
	elseif k == "source_change" then
		api.register_source_change_func(v)
	end
end

setmetatable(api, meta)

return api