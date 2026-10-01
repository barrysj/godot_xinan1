# Guard H3 近战抽帧试验提示词

状态：试验稿，未生成、未评审、未替换正式角色。目标是先检验视频生成时剑与盾的完整性，再决定是否制作新的动作组。

## 输入与比较条件

- 图生视频首帧：`design/concepts/guard-animation-study/h3-input/first-frame.png`。先复用 004 的同一首帧比较提示词效果；此首帧约 5～6 头身。本轮依负责人 2026-09-27 的意见，不以未达到 4 头身为由淘汰动画试验；正式比例仍需结合实际战斗尺寸评审。
- 同首帧 A/B 能隔离提示词变化，但这张首帧的盾已靠近右边缘。若新视频仍把盾缘或剑尖推出画面，应先把**整个人物与完整剑盾一起缩小并居中**、四周留出动作安全边距，再重复同一提示词；只写“不得出画”无法创造原图中没有的空间。
- 建议沿用本次已验证的 MiniMax H3、768P、4 秒、固定绿幕。首帧模式不同时传参考图；不自动提交付费生成。
- 原 004 的 4 秒视频每 0.5 秒固定采九帧，曾出现剑尖出画、盾牌侧转和剑盾形状漂移。新片先逐帧检查原视频，再决定抽取时刻；不要因旧管线只有九帧而错过清楚的出手姿势。
- 下面的结构参考用户在 2026-09-27 提供的[文章](https://mp.weixin.qq.com/s/vn0qUmBqrkmbONcS7HncKA?click_id=2047251715)提示词摘录：固定朝向和机位、完整入框、道具形状稳定、单一动作与明确禁项。文章网页及参考视频未在本环境独立核实。身份、右剑左盾、出手时序依据本项目[Guard 002](../tasks/m1-player-cast.md)与[动作研究](../tasks/guard-animation-study.md)。

## 可复制的图生视频提示词

使用上述首帧作为第一帧；只生成一次原地近战剑击。

```text
Use the supplied image as the exact first frame and visual identity reference. A single full-body 2D cel-shaded game character animation on a perfectly uniform solid green screen (#18FF66). This is the same young campus Guard: short brown hair, round glasses, charcoal jacket, pale blue shirt, cyan student ID, shoulder bag, dark trousers, white sneakers. Preserve the exact face, outfit, proportions, colors, sword and shield from the first frame. Keep the same three-quarter viewing angle and face screen right for the entire shot; never turn toward the camera or switch sides.

One compact, grounded sword slash in place, four seconds, one continuous fixed-camera shot. 0.0–0.4 s: hold the original ready pose. 0.4–1.2 s: draw the right arm and sword back for a readable wind-up; the left shield stays separate and visible. 1.2–1.8 s: perform one controlled diagonal slash toward screen right in the flat plane of the image, with a small weight shift but no large lunge or thrust toward the camera. At 1.8 s: reach the clear impact pose with the complete sword visible. 1.8–2.2 s: hold this impact silhouette. 2.2–3.2 s: recover. 3.2–4.0 s: return to the original ready pose and hold still. Both feet remain grounded; the body and equipment stay centered and entirely inside the frame throughout.

The right hand, on the viewer-left side in the first frame, grips the SAME sword hilt throughout. Treat the sword as one rigid, continuous prop: one short grip, one angular cyan-magenta guard, one straight translucent cyan blade with its magenta edge, one sharp tip. Preserve its length, width and silhouette in every frame. The hilt-to-tip connection must always be visible. The blade tip must never cross the image border. The left forearm, on viewer-right, carries the SAME tall translucent firewall shield with the same polygonal outline, segmented dark border and cyan-magenta accents. Keep its size and shape constant; the shield must not become a thin edge, split, fold, merge with the sword, or cover the sword tip. Keep a readable gap between sword and shield whenever possible.

Leave clear green space around the entire moving silhouette, including the sword tip, shield edge, hair and shoes. Clean cel shading and crisp edges. No zoom, camera motion, cuts, perspective change, mirroring, duplicate weapons, extra limbs or fingers, hand deformation, sword bending, blade growth or disappearance, shape-changing shield, large glowing trails, motion blur, scenery, text, shadows or background gradients. Do not change the solid green background.
```

## 验收重点

先看原视频的每帧：剑柄到剑尖是否连续且未出画；右手是否始终握住同一把剑；盾始终属于左前臂且轮廓稳定；出手姿势至少持续数帧。再择帧、抠像和压到游戏中的约 0.45 秒行动时钟，确认 128×128 实际显示时仍能读出挥剑。若原视频武器变形或越界，提示词不能替代重生成、修帧或单独重绘武器。
