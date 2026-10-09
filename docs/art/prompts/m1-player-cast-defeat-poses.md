# M1 我方角色濒危／退场静态姿势提示词

2026-09-30 使用内置 imagegen 编辑每位候选的 `frames/idle.png`。输出为透明背景、横向双栏的姿势源图，左栏濒危、右栏退场；原图保留在各版本 `source/critical-death-sheet.png`。这些是动画候选的新增姿势，仍待人工评审。

## 通用约束

> Create a two-pose 2D anime game sprite sheet from the supplied reference. Use a wide 2:1 transparent canvas with exactly TWO fully separate full-body poses, centered in equal square halves, no borders or text. Keep the reference palette, proportions, shading, identity, weapon count and three-quarter side view facing screen right. Full body and equipment fully inside each half with margins. The left and right silhouettes must be clearly different from the original standing idle; these are static game key poses, not motion animation. No blood, gore, scenery, extra people or extra limbs. No blur, translucent ghosting, large VFX or changed weapon design.

## 各角色姿势和身份锁

| 角色 | 追加给 imagegen 的身份与动作描述 |
| --- | --- |
| 远射手 | Black high ponytail, cyan X hairclip, blue-gray short sleeve shirt, black cargo pants, student ID, shoulder bag, white sneakers, one cyan-white pistol in the right hand. Left critical: bent knees, hunched torso, head lowered, left hand bracing a knee, pistol down and complete. Right defeat: compact side-lying body, bent knees, pistol immediately beside right hand. |
| 冲刺手 | Short black hair with pink hairpin, black hoodie, cargo pants, lanyard, white sneakers, exactly one magenta-cyan glowing dagger in each hand. Left critical: exhausted upright bend, one hand near knee and both daggers pointing down. Right defeat: curled on right side with both separate complete daggers visible beside hands. |
| 发明家 | Brown messy hair, navy technical shirt, black cargo pants, student ID, backpack, white sneakers, exactly one complete large blue-white railgun. Left critical: staggered low crouch with both hands lowering the gun. Right defeat: compact side-lying pose with the gun beside the body; stock, muzzle and fins remain visible. |
| 应援者 | Brown fluffy hair, round glasses, mint green jacket, black trousers, lanyard, bag, white shoes and two green holographic wrist keyboards. Left critical: visibly exhausted, bent knees, slumped torso, lowered head and arms. Right defeat: side-lying body; glasses and both keyboards remain visible. |
| 远射手换貌 | Short silver-blue bob, round glasses, orange-white shirt, black cargo trousers, lanyard, shoulder bag, white sneakers and one cyan-white pistol in right hand. Left critical: hunched, bent knees, left hand bracing a knee, complete pistol pointing down. Right defeat: compact side-lying pose with glasses retained and pistol next to right hand. |

本页记录较早混合占位包的直接生图提示词；该方法已被原配 3D 动作导向转绘替代。旧裁切生成器与中间稿已清理，当前五人新版依据 WORKFLOW，人形新增姿势先完成 3D 动作。
