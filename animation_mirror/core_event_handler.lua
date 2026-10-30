local Event = require("./core_event")

local api = {}

local events = {}

function api.new(name)
	events[name] = Event.new()
end

local meta = {}

function meta.__index(_, key)
	return events[key]
end

function meta.__newindex(_, key, value)
	events[key]:register(value)
end

setmetatable(api, meta)

return api