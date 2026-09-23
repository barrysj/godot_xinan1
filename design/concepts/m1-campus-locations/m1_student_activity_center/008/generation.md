# 学生活动中心异常候选 008

- 日期：2026-09-24；状态：`unselected + pending`，供11地点扩展的资产评审，不代表正式批准或 Godot 接入。
- 负责人决定：银桦＋清真食堂008的非实体异常类型和强度可作为本组普通地点的生成基准；本地点保持相近密度。此前候选保留，不凭本轮自动改为 rejected。
- 来源工具：Codex 内置 imagegen 单图局部编辑。Image 1 是本地点007异常生成源（严格地点身份／镜头）；Image 2 是银桦＋清真食堂008生成源（只参照异常类型、色彩与密度，不移植建筑）。
- Image 1：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-a37a9010-69c1-4e52-99a1-dd3bb3d06dd3.png`。
- Image 2：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-984eca3b-843d-4d1a-bd32-816e703875a3.png`。
- 最终生成源：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-a589295f-5093-4335-8337-5e0445e2bdc4.png`。
- 输出：`design/concepts/m1-campus-locations/m1_student_activity_center/008/anomaly.png`。源 1672×941；交付 3840×2160、RGB不透明PNG。按16:9中心微裁并高质量双三次重采样，非原生4K、非AI超分。
- SHA-256：`86BEC9340B06A0E6F995F2A225FE6DBC0B8586261D4EA0A6297409AB3A99BA31`。
- QA：生成源及12张汇总缩图已目检，地点、透视、真实建筑和墨蓝灰天空可辨；地面实体发光碎块已清除，新增异常为平面面板、短数据雨、贴地裂隙。广场或道路的湿亮感仍需负责人审美复核。技术校验见ART-02；不以技术通过冒充资产批准。
- 来源权利：沿用用户实景参考链，未额外核验公开／商业再分发权利；内置imagegen底层模型版本未披露。

## 完整提示词

```text
Use case: precise-object-edit. Asset: one 16:9 dark anomaly game background for 学生活动中心 at the Chinese university campus. Image 1 is the STRICT identity/composition/camera edit target; Image 2 is ONLY the approved anomaly density, palette, and nonphysical effect-language reference (cafeterias), NEVER copy its buildings or scene. Preserve Image 1's exact real landmark architecture, camera, perspective, paths, stairs, railings, trees, windows and rooflines, natural ink-blue-gray sky and warm uncorrupted windows. REMOVE every solid luminous crystal, raised geometric debris, 3D shard or glowing rock from foreground and middle ground; repair intact paving underneath. Replace them with flat, thin, interrupted blue-violet projected fissures on paving following ground perspective, faint fragmented light echoes/reflections, a moderate scattering of small flat cyan light rectangles on existing architectural surfaces, localized angular violet phase seams on facade, and sparse short cyan vertical data rain in selected window bays. Target the clear medium anomaly density of Image 2, not a stronger all-over neon scene: distribute interest between left/right architecture and a few foreground patches while most real-world surfaces stay legible. Ground effects must be zero-height light, NEVER objects. No floating arc/ring/portal, no purple sky, no structural collapse, no extra building wings, no added signage/UI/text/logos/flags, no excessive sparkle. Keep normal walking route clear. Preserve stylized painted-realistic game background finish.
```
