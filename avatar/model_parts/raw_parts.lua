local RawParts = {}

RawParts.main_model = models.main
RawParts.root = RawParts.main_model.root
RawParts.hips = RawParts.root.Hips
RawParts.left_upper_leg = RawParts.hips.LeftUpperLeg
RawParts.left_lower_leg_1 = RawParts.left_upper_leg.LeftLowerLeg1
RawParts.left_lower_leg_2 = RawParts.left_lower_leg_1.LeftLowerLeg2
RawParts.left_foot = RawParts.left_lower_leg_2.LeftToes
RawParts.right_upper_leg = RawParts.hips.RightUpperLeg
RawParts.right_lower_leg_1 = RawParts.right_upper_leg.RightLowerLeg1
RawParts.right_lower_leg_2 = RawParts.right_lower_leg_1.RightLowerLeg2
RawParts.right_foot = RawParts.right_lower_leg_2.RightToes
RawParts.spine_1 = RawParts.hips.Spine1
RawParts.spine_2 = RawParts.spine_1.Spine2
RawParts.left_upper_arm = RawParts.spine_2.LeftUpperArm
RawParts.left_lower_arm = RawParts.left_upper_arm.LeftLowerArm
RawParts.left_hand = RawParts.left_lower_arm.LeftHand
RawParts.right_upper_arm = RawParts.spine_2.RightUpperArm
RawParts.right_lower_arm = RawParts.right_upper_arm.RightLowerArm
RawParts.right_hand = RawParts.right_lower_arm.RightHand
RawParts.neck = RawParts.spine_2.Neck
RawParts.head = RawParts.neck.CustomHead
RawParts.hair_front_left = RawParts.head.HairFrontLeft
RawParts.hair_front_right = RawParts.head.HairFrontRight
RawParts.hair_back = RawParts.head.HairBack
RawParts.hair_front_left_target = RawParts.spine_2.HairFrontLeftTarget
RawParts.hair_front_right_target = RawParts.spine_2.HairFrontRightTarget
RawParts.hair_back_target = RawParts.spine_2.HairBackTarget
RawParts.tail_root = RawParts.hips.TailRoot
RawParts.tail_1 = RawParts.tail_root.Tail1
RawParts.tail_2 = RawParts.tail_1.Tail2
RawParts.tail_3 = RawParts.tail_2.Tail3
RawParts.tail_leaf = RawParts.tail_3.TailLeaf

return RawParts
