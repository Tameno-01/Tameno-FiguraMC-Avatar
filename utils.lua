local Utils = {}

function Utils.getAnyKey(tbl)
	for k, _ in pairs(tbl) do
		return k
	end
	return nil
end

function Utils.isEmpty(tbl)
	for _, _ in pairs(tbl) do
		return false
	end
	return true
end

function Utils.tif(condition, trueValue, falseValue)
	if condition then
		return trueValue
	else
		return falseValue
	end
end

function Utils.deaugmented(vect)
	return vec(vect.x, vect.y, vect.z)
end

function Utils.match(value, tbl)
	local func = tbl[value]
	if func == nil then
		if tbl.__default == nil then
			return
		end
		return tbl.__default
	end
	return func()
end

function Utils.forAllChildrenRecursive(root, func)
	func(root)
	for _, part in ipairs(root:getChildren()) do
		Utils.forAllChildrenRecursive(part, func)
	end
end

return Utils