# 基础实验大楼异常候选 008

- 日期：2026-09-24；状态：`unselected + pending`，非正式批准、未接入 Godot。
- 模式：Codex 内置 imagegen 精确编辑。Image 1 严格地点／机位：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-4c42d9ef-fc09-4e54-82ac-b7b11f771d7a.png`（上一版 007 生成源）；Image 2 只取会堂009短分叉暗影裂隙形态：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-b2318647-68dc-49f4-ba6a-d35282d673d3.png`，不移植建筑。
- 最终生成源：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-834ea597-5e4f-4d20-a285-9a2ce9ae2fb0.png`；底层模型版本未披露。
- 交付：`anomaly.png`，原始 1672×941，按16:9中心微裁并高质量双三次重采样至3840×2160，RGB不透明PNG；非原生4K、非AI超分。SHA-256：`F881282DA8868201A9650BBDAAD4B9C89AB745CB48891B13D6F4B65F98FA1430`。
- QA：`PASS_WITH_NOTES`；真实地点、构图与墨蓝灰天空可辨；无新增实体碎块、圆环或紫天。裂隙附着中央玻璃侧的屋檐／立面节点，玻璃幕墙与楼层可读；铺地偏湿亮。 技术检查与人工批准分开。
- 来源权利：沿用用户实景参考链；未额外核验公开／商业再分发权利。

## 完整提示词

```text
Use case: precise-object-edit. Image 1 is the STRICT edit target for basic laboratory building, a long white-tiled academic facade on the right with a central glass stairwell, many windows, trees and a broad paved forecourt, a 16:9 campus anomaly game background. Image 2 is the calibrated Chengdian sample ONLY for the morphology and darkness of a short building-anchored dimensional tear: uneven dark violet/near-black displaced inner seam, narrow soft purple glowing lip, two small branches, no full-height lightning. Do not copy Image 2's actual auditorium or camera. Location-specific change: form one short dark-shadowed branching violet tear along the junction of the roof parapet and the central GLASS stairwell's tiled frame, cascading through only two or three upper window bays, while leaving the building's entrance and floor pattern clear; secondary small nick on one right-side window jamb. Keep all Image 1 architecture, proportions, viewpoint, trees, windows, warm lights, cyan rectangular panels, sparse data rain, subtle planar ground/light projections and low-saturation ink-blue-gray sky. The principal new effect is localized to built structure rather than spread everywhere; retain location readability at thumbnail game scale. No solid debris, no shards, no circles/rings, no purple-sky recolor, no portals, no new objects, no annotations or text.
```
