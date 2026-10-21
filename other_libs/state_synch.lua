local StateSynch = {}

local TIME_BETWEEN_SYNCHS = 10

local states = {}
local states_list = {}
local time_since_last_synch = 0
local state_list_idx = 0

function StateSynch.newState(name, initial_value_or_getter, update_func)
	-- "state" doesn't need to be a table, I'm making it one in case i need more data in the future
	local state = {}
	local use_getter = type(initial_value_or_getter) == "function"
	if use_getter then
		state.getter = initial_value_or_getter
	else
		state.value = initial_value
		state.getter = function()
			return state.value
		end
	end
	pings["StateSynch_" .. name] = function(value)
		if state.getter() ~= value then
			if use_getter then
				update_func(value)
			else
				update_func(value, state.value)
				state.value = value
			end
		end
	end
	states[name] = state
	table.insert(states_list, name)
end

function StateSynch.getState(name, value)
	return states[name].value
end

if host:isHost() then

	function StateSynch.setState(name, value)
		pings["StateSynch_" .. name](value)
	end

	function StateSynch.tick()
		time_since_last_synch = time_since_last_synch + 1
		if time_since_last_synch == TIME_BETWEEN_SYNCHS then
			state_list_idx = state_list_idx + 1
			if state_list_idx > #states_list then
				state_list_idx = 1
			end
			local state_name = states_list[state_list_idx]
			local state = states[state_name]
			pings["StateSynch_" .. state_name](state.value)
			time_since_last_synch = 0
		end
	end

end

return StateSynch