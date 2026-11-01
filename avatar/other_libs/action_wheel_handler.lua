local StateSynch = require("other_libs/state_synch")

local ActionWheelHandler = {}

local pages

if host:isHost() then

	pages = {
		main = action_wheel:newPage()
	}

end

local synched_states = {}

local function registerSynchedState(name, states, update_func, default_idx)
	StateSynch.newState("ActionWheel_" .. name, default_idx, function(state_idx, prev_state_idx)
		local prev_state = nil
		if prev_state_idx ~= 0 then
			prev_state = states[prev_state_idx]
		end
		local state = nil
		if state_idx ~= 0 then
			state = states[state_idx]
		end
		update_func(state, prev_state)
	end)
end

local addSynchedStateToWheel

if host:isHost() then
	
	addSynchedStateToWheel = function(name, page_id, states, state_config)
		local page = pages[page_id]
		local prev_active = state_config.default_idx
		local state_table = {
			state = {}
		}
		function state_table.set(idx, no_disable)
			if prev_active == idx then
				if no_disable then
					return
				end
				if state_config.allow_none == true then
					state_table.state[prev_active].action:setToggled(false)
					StateSynch.setState("ActionWheel_" .. name, 0)
					prev_active = 0
				end
				if state_config.none_message ~= nil then
					host:setActionbar(state_config.none_message)
				end
			else
				if prev_active ~= 0 then
					state_table.state[prev_active].action:setToggled(false)
				end
				StateSynch.setState("ActionWheel_" .. name, idx)
				if idx == 0 then
					if state_config.none_message ~= nil then
						host:setActionbar(state_config.none_message)
					end
				else
					if state_config.message ~= nil then
						local message = state_config.message:gsub("NAME", states[idx].name)
						host:setActionbar(message)
					end
					state_table.state[idx].action:setToggled(true)
				end
				prev_active = idx
			end
		end
		for i, state in ipairs(states) do
			local action = page:newAction()
				:setTitle(state.name)
				:setItem(state.item)
			action:onLeftClick(function()
				state_table.set(i, false)
			end)
			table.insert(state_table.state, {
				action = action
			})
			if i == state_config.default_idx then
				action:setToggled(true)
			end
		end
		synched_states[name] = state_table
	end

end

--[[
state_config is a table with the following fields:
{
	default_idx int MANDATORY
	allow_none bool MANDATORY
	message string
	none_message string
}
]]
function ActionWheelHandler.newState(name, page_id, states, update_func, state_config)
	registerSynchedState(name, states, update_func, state_config.default_idx)
	if host:isHost() then
		addSynchedStateToWheel(name, page_id, states, state_config)
	end
end

if host:isHost() then

	function ActionWheelHandler.newPage(id, parent_id, name, item)
		local new_page = action_wheel:newPage()
		pages[id] = new_page
		local parent = pages[parent_id]
		parent:newAction()
			:setTitle(name)
			:setItem(item)
			:onLeftClick(function()
				action_wheel:setPage(new_page)
			end)
		new_page:newAction()
			:setTitle("Back")
			:setItem("minecraft:barrier")
			:onLeftClick(function()
				action_wheel:setPage(parent)
			end)
	end

	function ActionWheelHandler.setState(name, idx)
		synched_states[name].set(idx, true)
	end

	action_wheel:setPage(pages.main)

end

return ActionWheelHandler