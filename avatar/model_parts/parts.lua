local PartClass = require("model_parts/part_class")
local RawParts = require("model_parts/raw_parts")

local Parts = {}

Parts.main_model = PartClass.new(RawParts.main_model)
Parts.root = PartClass.new(RawParts.root)
Parts.neck = PartClass.new(RawParts.neck)
Parts.head = PartClass.new(RawParts.head)

return Parts