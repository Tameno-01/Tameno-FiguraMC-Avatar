local Utils = require("other_libs/utils")
local RawParts = require("model_parts/raw_parts")

local Outfits = {}

Outfits.outfit_states = {
	{
		texture = textures["main_texture"],
		name = "Default",
		item = "minecraft:purple_wool",
	},
	{
		texture = textures["main_texture_glorpian"],
		name = "Glorpian Army",
		item = "minecraft:emerald",
	},
	{
		texture = textures["main_texture_niko"],
		name = "Niko",
		item = "minecraft:nether_star",
	},
}

Outfits.state_config = {
	default_idx = 1,
	allow_none = false,
	message = "Set outfit to: NAME",
	none_message = "Can't disable outfit, switch to default instead."
}

function Outfits.setState(outfit_state)
	local texture = outfit_state.texture
	Utils.forAllChildrenRecursive(RawParts.main_model, function(part)
		if part:getType() == "CUBE" then
			part:setPrimaryTexture("Custom", texture)
		end
	end)
end

return Outfits