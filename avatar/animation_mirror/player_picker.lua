local AnimationMirror = require("./core")

local api = {}

function api.pick_player()
	if not host:isHost() then
		return nil, "NOT_HOST"
	end
	if not player:isLoaded() then
		return nil, "PLAYER_NOT_LOADED"
	end
	local start_pos = player:getPos()
	start_pos.y = start_pos.y + player:getEyeHeight()
	local end_pos = start_pos + player:getLookDir() * host:getReachDistance()
	local entity, _ = raycast:entity(start_pos, end_pos, function(entity)
		return entity ~= player
	end)
	if entity == nil then
		return nil, "NO_ENTITY"
	end
	if not entity:isPlayer() then
		return nil, "NOT_PLAYER", entity
	end
	local uuid = entity:getUUID()
	if not AnimationMirror.can_copy(uuid) then
		return nil, "NOT_COPYABLE", entity
	end
	return uuid
end

return api