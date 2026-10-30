pcall(require, "./debug_overrides")

local api = {}

api.__index = api

function api.new()
	local obj = {
		listeners = {}
	}
	setmetatable(obj, api)
	return obj
end

function api:register(func)
	table.insert(self.listeners, func)
end

function api:remove(func)
	for i, f in ipairs(self.listeners) do
		if f == func then
			table.remove(self.listeners, i)
			return
		end
	end
end

function api:emit(...)
	for _, f in ipairs(self.listeners) do
		f(...)
	end
end

return api