local Emotes = {}

Emotes.emote_states = {
	{
		anim = "dance_arona",
		name = "Arona Dance",
		item = "minecraft:light_blue_wool",
	},
	{
		anim = "salute",
		name = "Salute",
		item = "minecraft:turtle_helmet",
	},
}

Emotes.state_config = {
	default_idx = 0,
	allow_none = true,
	message = "Started emote: NAME",
	none_message = "Stopped Emote.",
}

function Emotes.setState(emote_state)
	if emote_state == nil then
		Emotes.stop()
	else
		Emotes.start(emote_state)
	end
end

return Emotes