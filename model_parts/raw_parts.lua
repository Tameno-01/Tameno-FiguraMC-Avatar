local RawParts = {}

RawParts.main_model = models.main
RawParts.root = RawParts.main_model.root
RawParts.Hips = RawParts.root.Hips
RawParts.Spine1 = RawParts.Hips.Spine1
RawParts.Spine2 = RawParts.Spine1.Spine2
RawParts.Neck = RawParts.Spine2.Neck
RawParts.Head = RawParts.Neck.CustomHead
RawParts.tail_root = RawParts.Hips.TailRoot
RawParts.tail_1 = RawParts.tail_root.Tail1
RawParts.tail_2 = RawParts.tail_1.Tail2
RawParts.tail_3 = RawParts.tail_2.Tail3
RawParts.tail_leaf = RawParts.tail_3.TailLeaf

return RawParts