local AnimState = require("anim/anim_state")

local EmoteState = {}

function EmoteState:tick(params)
	return {
		blends = {
			[params.emote] = 1
		}
	}
end

return AnimState:new(EmoteState)