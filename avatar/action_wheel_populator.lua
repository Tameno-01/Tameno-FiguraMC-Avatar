local ActionWheelHandler = require("other_libs/action_wheel_handler")
local Emotes = require("emotes")
local Outfits = require("outfits")

if host:isHost() then
	ActionWheelHandler.newPage("emotes", "main", "Emotes", "minecraft:armor_stand")
	ActionWheelHandler.newPage("outfits", "main", "Outfits", "minecraft:leather_chestplate")
end

ActionWheelHandler.newState("emote", "emotes", Emotes.emote_states, Emotes.setState, Emotes.state_config)
ActionWheelHandler.newState("outfit", "outfits", Outfits.outfit_states, Outfits.setState, Outfits.state_config)