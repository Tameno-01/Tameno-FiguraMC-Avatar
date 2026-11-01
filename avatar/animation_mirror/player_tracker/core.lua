local AnimationMirror = require("../core")

local api = {}

if host:isHost() then
	
	local trackers = {}
	local next_player = nil
	local players = world.getPlayers()
	local seen_players = {}
	local missing_players = {}
	
	
	function api.new(create_func, delete_func, render_func, tick_func)
		table.insert(trackers, {
			create_func = create_func,
			delete_func = delete_func,
			render_func = render_func,
			tick_func = tick_func,
			active_data = {},
		})
	end

	function events.world_render(delta)
		next_player = next(players, next_player)
		if next_player == nil then
			for player, _ in pairs(missing_players) do
				for _, tracker in ipairs(trackers) do
					local data = tracker.active_data[player]
					if data ~= nil then
						if tracker.delete_func ~= nil then
							tracker.delete_func(tracker.active_data[player])
						end
						tracker.active_data[player] = nil
					end
				end
			end
			missing_players = seen_players
			seen_players = {}
			players = world.getPlayers()
			next_player = next(players, next_player)
		end
		local player_uuid = players[next_player]:getUUID()
		seen_players[player_uuid] = true
		missing_players[player_uuid] = nil
		local can_copy = (
			world.getEntity(player_uuid) ~= nil
			and player_uuid ~= avatar:getUUID()
			and AnimationMirror.can_copy(player_uuid)
			and AnimationMirror.get_source_player_uuid() ~= AnimationMirror.get_others_source_uuid(player_uuid)
		)
		for _, tracker in ipairs(trackers) do
			local data = tracker.active_data[player_uuid]
			local is_active = data ~= nil
			if can_copy ~= is_active then
				if can_copy then
					if tracker.create_func ~= nil then
						tracker.active_data[player_uuid] = tracker.create_func(player_uuid)
					else
						tracker.active_data[player_uuid] = false
					end
				else
					if tracker.delete_func ~= nil then
						tracker.delete_func(tracker.active_data[player_uuid])
					end
					tracker.active_data[player_uuid] = nil
				end
			end
		end
		for _, tracker in ipairs(trackers) do
			for _, data in pairs(tracker.active_data) do
				if tracker.render_func ~= nil then
					tracker.render_func(data, delta)
				end
			end
		end
	end
	
	function events.world_tick()
		for _, tracker in ipairs(trackers) do
			for _, data in pairs(tracker.active_data) do
				if tracker.tick_func ~= nil then
					tracker.tick_func(data)
				end
			end
		end
	end

else -- Not host

	function api.new() end

end

return api