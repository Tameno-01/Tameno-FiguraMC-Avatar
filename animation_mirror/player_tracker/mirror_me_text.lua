local PlayerTracker = require("./core")

PlayerTracker.new(
	function(uuid) -- create
		local player = world.getEntity(uuid)
		local world = models:newPart("", "World")
		local part = world:newPart("", "Camera")
		local text = part:newText(""):text("Mirror me >"):alignment("RIGHT"):setScale(vec(0.25, 0.25, 0.25)):setOutline(true)
		return {
			player = player,
			part = world,
			text = text,
		}
	end,
	function(data) -- delete
		data.part:remove()
	end,
	function(data, delta) -- render
		if not data.player:isLoaded() then
			return
		end
		data.part:setPos(data.player:getPos(delta) * 16 + vec(
			0, data.player:getBoundingBox().y / 2 * 16 + 2, 0
		))
		data.text:setPos(vec(data.player:getBoundingBox().x * 20, 0, 0))
	end
)