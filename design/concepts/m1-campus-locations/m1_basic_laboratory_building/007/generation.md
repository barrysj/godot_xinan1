# 基础实验大楼异常候选 007

- 日期：2026-09-24；状态：`unselected + pending`，供11地点扩展的资产评审，不代表正式批准或 Godot 接入。
- 负责人决定：银桦＋清真食堂008的非实体异常类型和强度可作为本组普通地点的生成基准；本地点保持相近密度。此前候选保留，不凭本轮自动改为 rejected。
- 来源工具：Codex 内置 imagegen 单图局部编辑。Image 1 是本地点006异常生成源（严格地点身份／镜头）；Image 2 是银桦＋清真食堂008生成源（只参照异常类型、色彩与密度，不移植建筑）。
- Image 1：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-53df8b25-afa3-4570-bb6f-0b0657e52831.png`。
- Image 2：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-984eca3b-843d-4d1a-bd32-816e703875a3.png`。
- 最终生成源：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-4c42d9ef-fc09-4e54-82ac-b7b11f771d7a.png`。
- 输出：`design/concepts/m1-campus-locations/m1_basic_laboratory_building/007/anomaly.png`。源 1672×941；交付 3840×2160、RGB不透明PNG。按16:9中心微裁并高质量双三次重采样，非原生4K、非AI超分。
- SHA-256：`9B5872A52A8269F278763F95D837B14670B8BFB36B1438400FB24A38823DE1CB`。
- QA：生成源及12张汇总缩图已目检，地点、透视、真实建筑和墨蓝灰天空可辨；地面实体发光碎块已清除，新增异常为平面面板、短数据雨、贴地裂隙。广场或道路的湿亮感仍需负责人审美复核。技术校验见ART-02；不以技术通过冒充资产批准。
- 来源权利：沿用用户实景参考链，未额外核验公开／商业再分发权利；内置imagegen底层模型版本未披露。

## 完整提示词

```text
Use case: precise-object-edit. Image 1 is the strict location/camera edit target: the Basic Laboratory Building on the right, tree-lined path and grass on left, open plaza, bicycles and windows. Image 2 is ONLY a density/style reference for approved moderate blue/violet nonphysical cyber anomalies; do not copy cafeteria geometry. Maintain exact building floor count, perspective, scale, trees, bicycles, ink-blue-gray night sky, warm real windows. REMOVE all physical raised luminous debris, crystal prisms and shard piles from the foreground; repair paving. Add flat broken violet-blue light fissures projected along paving and path perspective, subtle light echoes/reflections, several thin cyan rectangular planar panes on the existing lab facade and selected windows, a few sparse short data-rain strands confined to the windows, and limited angular violet phase cracks. Density similar to Image 2, spread across left/right but keep majority of scene quiet. Preserve laboratory identity. No circular rings or portal, no purple sky, no solid ground pieces, no added buildings, signs, text, UI or flags. One 16:9 stylized painted-realistic game background.
```
