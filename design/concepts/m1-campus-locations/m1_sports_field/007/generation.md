# 操场异常候选 007

- 日期：2026-09-24；状态：`unselected + pending`，供11地点扩展的资产评审，不代表正式批准或 Godot 接入。
- 负责人决定：银桦＋清真食堂008的非实体异常类型和强度可作为本组普通地点的生成基准；本地点保持相近密度。此前候选保留，不凭本轮自动改为 rejected。
- 来源工具：Codex 内置 imagegen 单图局部编辑。Image 1 是本地点006异常生成源（严格地点身份／镜头）；Image 2 是银桦＋清真食堂008生成源（只参照异常类型、色彩与密度，不移植建筑）。
- Image 1：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-3df7ef17-0785-45c0-9376-891071b1226b.png`。
- Image 2：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-984eca3b-843d-4d1a-bd32-816e703875a3.png`。
- 最终生成源：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-4449851f-7624-4204-9172-29c84d84a11b.png`。
- 输出：`design/concepts/m1-campus-locations/m1_sports_field/007/anomaly.png`。源 1671×941；交付 3840×2160、RGB不透明PNG。按16:9中心微裁并高质量双三次重采样，非原生4K、非AI超分。
- SHA-256：`07A7B1B416EECD60C3C71B3FA88DB2B13C7718A901DE20D1DE0B0AB5596305E5`。
- QA：生成源及12张汇总缩图已目检，地点、透视、真实建筑和墨蓝灰天空可辨；地面实体发光碎块已清除，新增异常为平面面板、短数据雨、贴地裂隙。广场或道路的湿亮感仍需负责人审美复核。技术校验见ART-02；不以技术通过冒充资产批准。
- 来源权利：沿用用户实景参考链，未额外核验公开／商业再分发权利；内置imagegen底层模型版本未披露。

## 完整提示词

```text
Use case: precise-object-edit. One 16:9 Chinese university sports field anomaly game background. Image 1 = STRICT identity and camera edit target: preserve football pitch, white soccer field markings, two small goal frames, red running track, surrounding tree line, distant REAL arched sports hall roof and dark slate sky. Image 2 = ONLY approved cafeteria sample for moderate nonphysical anomaly density and cyan-violet palette; do not copy cafeteria architecture or paving. Remove every raised crystal, physical shard and debris pile from grass and track, leaving playable level continuous turf. Recreate anomaly as flat faint broken cyan-violet light fissures and short projected digital marks laid ON grass and track, diminishing with distance; subtle low reflections only on track, not a mirror-gloss grass field. Add a handful of small blue planar window-like light blocks and angular violet seams to the distant sports hall and selected boundary structures, plus sparse short data-rain around the hall. Keep >75% of field dark green and readable and let stadium remain distant at true perspective scale. No floating luminous ring/arc/portal (the real stadium roof arch stays), no purple sky, no 3D fragments, extra buildings, text, UI, flags or altered goal positions.
```
