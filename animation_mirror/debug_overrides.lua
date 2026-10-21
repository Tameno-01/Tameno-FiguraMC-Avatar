local log_whitelist = {
	["d27f85e0-53cd-46f7-a95d-9274f73a6ca3"] = true,
	["3f4f211c-3594-4af9-955e-af1235433fa0"] = true,
}

local actual_log = log
function log(...)
	if log_whitelist[client:getViewer():getUUID()] == nil then
		return
	end
	actual_log(...)
end
print = log

local actual_logTable = logTable
function logTable(t, d, s)
	if log_whitelist[client:getViewer():getUUID()] == nil then
		return
	end
	actual_logTable(t, d, s)
end
printTable = logTable