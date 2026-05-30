local PartClass = require("model_parts/part_class")
local RawParts = require("model_parts/raw_parts")

local Parts = {}

Parts.main_model = PartClass:new(RawParts.main_model)
Parts.Head = PartClass:new(RawParts.Head)

return Parts