local Utils = require("utils")

-- A few lines of code here are yoinked from https://github.com/lua-gods/figura-libraries/blob/main/plushie/plushie.lua

local head_root = models.head.Skull.root
local short_front = head_root.front
local short_back = head_root.back
local long_root = head_root.long_root
local long_front = long_root.long_front
local long_back = long_root.long_back

local rotations = {
	["0"] = {
		front_vec = vec(0, 0, -1),
		diagonal = false
	},
	["2"] = {
		front_vec = vec(1, 0, -1),
		diagonal = true
	},
	["4"] = {
		front_vec = vec(1, 0, 0),
		diagonal = false
	},
	["6"] = {
		front_vec = vec(1, 0, 1),
		diagonal = true
	},
	["8"] = {
		front_vec = vec(0, 0, 1),
		diagonal = false
	},
	["10"] = {
		front_vec = vec(-1, 0, 1),
		diagonal = true
	},
	["12"] = {
		front_vec = vec(-1, 0, 0),
		diagonal = false
	},
	["14"] = {
		front_vec = vec(-1, 0, -1),
		diagonal = true
	},
}

local my_uuid = avatar:getUUID()

local function isBlockSame(pos, orientation, wall)
	local block = world.getBlockState(pos)
	if block.id ~= Utils.tif(wall, "minecraft:player_wall_head", "minecraft:player_head") then
		return false
	end
	if wall then
		if block.properties.facing ~= orientation then
			return false
		end
	else
		if block.properties.rotation ~= orientation then
			return false
		end
	end
	local data = block:getEntityData()
	if data == nil then
		return false
	end
	if data.SkullOwner == nil then
		return false
	end
	if data.SkullOwner.Id == nil then
		return false
	end
	return client.intUUIDToString(table.unpack(data.SkullOwner.Id)) == my_uuid
end

function events.skull_render(delta, block, item, entity, mode)
	head_root:setPos(vec(0, 0, 0))
	head_root:setRot(vec(0, 0, 0))
	short_front:setVisible(true)
	short_back:setVisible(true)
	long_root:setScale(vec(1, 1, 1))
	long_front:setVisible(false)
	long_back:setVisible(false)
    local match = {
		HEAD = function()
			head_root:setPos(0, 6.7, 0)
		end,
		BLOCK = function()
			local orientation
			local wall = false
			local front
			if block.id == "minecraft:player_wall_head" then
				head_root:setPos(vec(0, 4, 4))
				head_root:setRot(vec(-90, 0, 180))	
				orientation = block.properties.facing
				front = vec(0, 1, 0)
				wall = true
			else -- head is ground head
				orientation = block.properties.rotation
				local rotation_data = rotations[orientation]
				if rotation_data == nil then
					return
				end
				front = rotation_data.front_vec
				if rotation_data.diagonal then
					long_root:setScale(vec(1, 1, 1.4142136))
				end
			end
			if isBlockSame(block:getPos() + front, orientation, wall) then
				short_front:setVisible(false)
				long_front:setVisible(true)
			end
			if isBlockSame(block:getPos() - front, orientation, wall) then
				short_back:setVisible(false)
				long_back:setVisible(true)
			end
		end,
	}
	Utils.match(mode, match)
end