local AvatarConfig = require("avatar_config")
local RawParts = require("model_parts/raw_parts")
local TextureSwapper = require("outfit_swapper")

local Outfits = {}

local extra_parts = {
	skirt = RawParts.skirt,
}

local is_extra_part = {}

for _, part in pairs(extra_parts) do
	is_extra_part[part] = true
end

Outfits.outfit_states = {
	{
		name = "Default",
		item = "minecraft:purple_wool",
	},
	{
		texture_path = "outfits/glorpian_main.png",
		name = "Glorpian Army",
		item = "minecraft:emerald",
	},
	{
		texture_path = "outfits/niko_main.png",
		name = "Niko",
		item = "minecraft:nether_star",
	},
	{
		texture_path = "outfits/undead_main.png",
		name = "Undead",
		item = "minecraft:skeleton_skull",
	},
	{
		texture_path = "outfits/garma_main.png",
		name = "Garma",
		item = "minecraft:orange_wool",
	},
	{
		texture_path = "outfits/mar_main.png",
		name = "Mar",
		item = "minecraft:red_wool",
	},
	{
		texture_path = "outfits/blockbench_main.png",
		name = "Blockbench",
		item = "minecraft:crafting_table",
	},
	{
		texture_path = "outfits/maid_main.png",
		extras = {
			skirt = "outfits/maid_skirt.png",
		},
		name = "Maid",
		item = "minecraft:brush",
	},
}

Outfits.state_config = {
	default_idx = 1,
	allow_none = false,
	message = "Set outfit to: NAME",
	none_message = "Can't disable outfit, switch to default instead."
}

local function setTex(part, tex)
	if is_extra_part[part] then
		return
	end
	if part:getType() == "CUBE" then
		part:setPrimaryTexture("Custom", tex)
	end
	for _, child in ipairs(part:getChildren()) do
		setTex(child, tex)
	end
end

local function setExtraTex(part, tex)
	if part:getType() == "CUBE" then
		part:setPrimaryTexture("Custom", tex)
	end
	for _, child in ipairs(part:getChildren()) do
		setTex(child, tex)
	end
end

local function resetTex(part)
	if part:getType() == "CUBE" then
		part:setPrimaryTexture("PRIMARY")
	end
	for _, child in ipairs(part:getChildren()) do
		resetTex(child)
	end
end

local function encodeOutfit(tex_path, extras)
	local stream = file:openReadStream(AvatarConfig.data_path .. tex_path)
	local buffer = data:createBuffer()
	buffer:readFromStream(stream)
	stream:close()
	buffer:setPosition(0)
	local output = buffer:readBase64()
	buffer:close()
	local header = ""
	for extra, path in pairs(extras) do
		local start = #output + 1
		local extra_stream = file:openReadStream(AvatarConfig.data_path .. path)
		local extra_buffer = data:createBuffer()
		extra_buffer:readFromStream(extra_stream)
		extra_stream:close()
		extra_buffer:setPosition(0)
		output = output .. extra_buffer:readBase64()
		extra_buffer:close()
		local header_section = extra .. "=" .. tostring(start)
		header = header .. header_section .. ","
	end
	return header .. "|" .. output
end

local function decodeOutfit(input)
	local header_end = string.find(input, "|")
	if header_end == 1 then
		return textures:read("outfit_1", string.sub(input, 2, #input)), {}
	end
	local extras = {}
	local header = string.sub(input, 1, header_end - 1)
	local b64_data = string.sub(input, header_end + 1, #input)
	local header_extra_start = 1
	local prev_extra_name = ""
	local prev_extra_start = 1
	local idx = 1
	local tex
	while true do
		local header_extra_end = string.find(header, ",", header_extra_start)
		if header_extra_end == nil then
			local prev_extra_b64 = string.sub(b64_data, prev_extra_start, #b64_data)
			local prev_extra_tex = textures:read("outfit_" .. tostring(idx), prev_extra_b64)
			extras[prev_extra_name] = prev_extra_tex
			break
		end
		local extra_header = string.sub(header, header_extra_start, header_extra_end - 1)
		local equals_location = string.find(extra_header, "=")
		local next_extra_name = string.sub(extra_header, 1, equals_location - 1)
		local start_idx = string.sub(extra_header, equals_location + 1, #extra_header)
		local next_extra_start = tonumber(start_idx)
		local prev_extra_b64 = string.sub(b64_data, prev_extra_start, next_extra_start - 1)
		local prev_extra_tex = textures:read("outfit_" .. tostring(idx), prev_extra_b64)
		if prev_extra_name == "" then
			tex = prev_extra_tex
		else
			extras[prev_extra_name] = prev_extra_tex
		end
		header_extra_start = header_extra_end + 1
		prev_extra_name = next_extra_name
		prev_extra_start = next_extra_start
		idx = idx + 1
	end
	return tex, extras
end

function Outfits.setState(outfit_state)
	local texture_path = outfit_state.texture_path
	if texture_path == nil then
		TextureSwapper.setOutfit(nil)
		return
	else
		local extras = outfit_state.extras
		if extras == nil then
			extras = {}
		end
		local b64 = encodeOutfit(texture_path, extras)
		TextureSwapper.setOutfit(b64)
	end
end

TextureSwapper.setOnOutfitFinish(function(b64)
	for _, part in pairs(extra_parts) do
		part:setVisible(false)
	end
	if b64 == nil then
		resetTex(RawParts.main_model)
		return
	end
	local tex, extras = decodeOutfit(b64)
	for extra, extra_tex in pairs(extras) do
		local part = extra_parts[extra]
		part:setVisible(true)
		setExtraTex(part, extra_tex)
	end
	setTex(RawParts.main_model, tex)
end)

return Outfits