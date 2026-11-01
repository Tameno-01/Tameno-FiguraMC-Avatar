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

function Utils.elementCount(tbl)
	local output = 0
	for _, _ in pairs(tbl) do
		output = output + 1
	end
	return output
end

function Utils.tif(condition, trueValue, falseValue)
	if condition then
		return trueValue
	else
		return falseValue
	end
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

function Utils.splitStr(str, section_chars)
	local output = {}
	local section_count = math.ceil(#str / section_chars)
	for i=1, section_count do
		local section_start = section_chars * (i - 1) + 1
		table.insert(output, string.sub(str, section_start, section_start + section_chars - 1))
	end
	return output
end

return Utils