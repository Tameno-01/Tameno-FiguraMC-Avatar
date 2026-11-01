local PartClass = {}

PartClass.__index = PartClass

local parts = {}

-- static
function PartClass.new(part)
	local obj = {
		part = part,
	}
	setmetatable(obj, PartClass)
	table.insert(parts, obj)
	return obj
end

function PartClass.tickStart()
	for _, part in ipairs(parts) do
		if part.rotation ~= nil then
			part.rotation.prev = part.rotation.next
			part.rotation.next = vec(0, 0, 0)
		end
	end
end

function PartClass.tickEnd()
	for _, part in ipairs(parts) do
		if part.rotation ~= nil then
			if part.rotation.prev == vec(0, 0, 0) and part.rotation.next == vec(0, 0, 0) then
				part.rotation = nil
				part.part:setOffsetRot(vec(0, 0, 0))
			end
		end
	end
end

function PartClass.render(delta)
	for _, part in ipairs(parts) do
		if part.rotation ~= nil then
			part.part:setOffsetRot(math.lerpAngle(part.rotation.prev, part.rotation.next, delta))
		end
	end
end

function PartClass:setRot(rot)
	if self.rotation == nil then
		self.rotation = {
			prev = vec(0, 0, 0),
			next = vec(0, 0, 0),
		}
	end
	self.rotation.next = self.rotation.next + rot
end

return PartClass