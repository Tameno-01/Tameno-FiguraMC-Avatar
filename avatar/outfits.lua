local Utils = require("other_libs/utils")
local AvatarConfig = require("avatar_config")
local RawParts = require("model_parts/raw_parts")
local TextureSwapper = require("texture_swapper")

local Outfits = {}

Outfits.outfit_states = {
	{
		name = "Default",
		item = "minecraft:purple_wool",
	},
	{
		texture_path = "outfits/main_texture_glorpian.png",
		name = "Glorpian Army",
		item = "minecraft:emerald",
	},
	{
		texture_path = "outfits/main_texture_niko.png",
		name = "Niko",
		item = "minecraft:nether_star",
	},
	{
		texture_path = "outfits/main_texture_undead.png",
		name = "Undead",
		item = "minecraft:skeleton_skull",
	},
}

Outfits.state_config = {
	default_idx = 1,
	allow_none = false,
	message = "Set outfit to: NAME",
	none_message = "Can't disable outfit, switch to default instead."
}

function Outfits.setState(outfit_state)
	local texture_path = outfit_state.texture_path
	if texture_path == nil then
		TextureSwapper.setTex(nil)
	else
		local stream = file:openReadStream(AvatarConfig.data_path .. texture_path)
		local buffer = data:createBuffer()
		buffer:readFromStream(stream)
		stream:close()
		buffer:setPosition(0)
		local b64 = buffer:readBase64()
		buffer:close()
		TextureSwapper.setTex(b64)
	end
end

return Outfits