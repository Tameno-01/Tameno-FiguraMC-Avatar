local AnimState = require("anim/anim_state")

local EmoteState = {}

function EmoteState:tick(params)
	if params.emote == nil then
		return {}
	end
	return {
		blends = {
			[params.emote] = 1
		}
	}
end

return AnimState:new(EmoteState)