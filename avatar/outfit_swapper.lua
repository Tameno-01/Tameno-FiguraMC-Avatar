local Utils = require("other_libs/utils")

local OutfitSwapper = {}

local TIME_BETWEEN_SYNCHS_MS = 1000

local received_sections = {}
local received_tex_id = 0
local receiving_texture = false

local on_outfit_finish

local root_part = models:newPart("texture_swap_root"):pos(vec(0, 20, 0))
local billboard = root_part:newPart("texture_swap_billboard"):parentType("Camera")
local text = billboard:newText("texture_swap_text"):outline(true):pos(vec(-12, 0, 0)):scale(vec(0.5, 0.5, 0.5))

if host:isHost() then
	
	local host_sections = {}
	local host_tex_id = 0
	local last_synch_time = client.getSystemTime()
	local section_idx_to_send
	
	local function synch()
		if host_tex_id == 0 then
			pings.outfitSection(0)
		else
			pings.outfitSection(host_tex_id, section_idx_to_send, #host_sections, host_sections[section_idx_to_send])
			section_idx_to_send = section_idx_to_send + 1
			if section_idx_to_send > #host_sections then
				section_idx_to_send = 1
			end
		end
		last_synch_time = client.getSystemTime()
	end

	function OutfitSwapper.setOutfit(b64)
		if b64 == nil then
			host_tex_id = 0
			synch()
			return
		end
		host_sections = Utils.splitStr(b64, 512)
		host_tex_id = host_tex_id + 1
		if host_tex_id > 32767 then
			host_tex_id = 1
		end
		section_idx_to_send = 1
		synch()
	end

	function events.render()
		local time = client.getSystemTime()
		if time - last_synch_time > TIME_BETWEEN_SYNCHS_MS then
			synch()
		end
	end

end

function pings.outfitSection(id, section_idx, section_count, b64)
	if id ~= received_tex_id then
		received_tex_id = id
		received_sections = {}
		if not receiving_texture then
			receiving_texture = true
			root_part:setVisible(true)
		end
	end
	if not receiving_texture then
		return
	end
	if received_tex_id == 0 then
		receiving_texture = false
		root_part:setVisible(false)
		on_outfit_finish(nil)
		return
	end
	received_sections[section_idx] = b64
	local received_section_count = Utils.elementCount(received_sections)
	if received_section_count == section_count then
		local full_b64 = ""
		for _, b64_section in ipairs(received_sections) do
			full_b64 = full_b64 .. b64_section
		end
		receiving_texture = false
		root_part:setVisible(false)
		on_outfit_finish(full_b64)
	else
		text:setText("< :loading: " .. tostring(math.floor(received_section_count / section_count * 100)) .. "%")
	end
end

function OutfitSwapper.setOnOutfitFinish(func)
	on_outfit_finish = func
end

return OutfitSwapper