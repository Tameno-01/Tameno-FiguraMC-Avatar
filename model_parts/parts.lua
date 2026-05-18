local PartClass = require("model_parts/part_class")

local Parts = {}

local main_model = models.main
local root = main_model.root
local Hips = root.Hips
local Spine1 = Hips.Spine1
local Spine2 = Spine1.Spine2
local Neck = Spine2.Neck
local Head = Neck.CustomHead

Parts.main_model = PartClass:new(main_model)
Parts.Head = PartClass:new(Head)

return Parts