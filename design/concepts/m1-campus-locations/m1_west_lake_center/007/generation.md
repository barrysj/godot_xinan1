# 西湖中心异常候选 007

- 日期：2026-09-24；状态：`unselected + pending`，供11地点扩展的资产评审，不代表正式批准或 Godot 接入。
- 负责人决定：银桦＋清真食堂008的非实体异常类型和强度可作为本组普通地点的生成基准；本地点保留并细化湖面数字波纹与碎光。此前候选保留，不凭本轮自动改为 rejected。
- 来源工具：Codex 内置 imagegen 单图局部编辑。Image 1 是本地点006异常生成源（严格地点身份／镜头）；Image 2 是银桦＋清真食堂008生成源（只参照异常类型、色彩与密度，不移植建筑）；Image 3 是既有图书馆双数字天鹅图（只参照水面数字波纹和反光，不移植天鹅、建筑或天空）。
- Image 1：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-df72ad9d-65d8-43fe-8cae-93e011a030c2.png`。
- Image 2：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-984eca3b-843d-4d1a-bd32-816e703875a3.png`。
- Image 3：`E:/Documents/works/godot_xinan1/assets/art/backgrounds/m1_main_menu/anomaly/library-two-digital-swans.png`。
- 最终生成源：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-f9d790d2-512f-4904-9ffb-2c8fe3feb14a.png`。
- 输出：`design/concepts/m1-campus-locations/m1_west_lake_center/007/anomaly.png`。源 1672×941；交付 3840×2160、RGB不透明PNG。按16:9中心微裁并高质量双三次重采样，非原生4K、非AI超分。
- SHA-256：`209B5267D0FA52F66FBC6E68BCF512BEE3B56B25F4A0D29394D458EC0EA05837`。
- QA：生成源及12张汇总缩图已目检，地点、透视、真实建筑和墨蓝灰天空可辨；地面实体发光碎块已清除，新增异常为平面面板、短数据雨、贴地裂隙及水面断续碎光。广场或道路的湿亮感仍需负责人审美复核。技术校验见ART-02；不以技术通过冒充资产批准。
- 来源权利：沿用用户实景参考链，未额外核验公开／商业再分发权利；内置imagegen底层模型版本未披露。

## 完整提示词

```text
Use case: precise-object-edit. Asset: single 16:9 dark anomaly background, 西湖中心 / West Lake center campus boardwalk. Image 1 = STRICT edit target for this place: preserve its boardwalk, wooden rails, far pavilion, trees, lake edge, right-side water area, distant building and camera exactly. Image 2 = approved cafeteria sample ONLY for medium anomaly density, nonphysical cyan panels, angular violet seams, ground-projected hairline fissures, slate-blue sky; do NOT copy the cafeteria architecture. Image 3 = WATER EFFECT REFERENCE ONLY: borrow its broken cyan and magenta digital ripples, tiny fragmented luminous reflections, intermittent horizontal scanline-like water glints and displaced mirrored streaks, particularly across the visible lake surface; do NOT add its swans, building, skyline, sunset or large circle/rings. Image 1 already has some digital water effect; PRESERVE and refine it, making it clearly visible but not a solid glowing lake. Remove all physical glowing crystals/shards/debris on boardwalk, shoreline and water; restore intact boards and natural water, replace with subtle flat violet/blue projected lines on boards and reflections. Add only a few thin cyan rectangular light panes at existing pavilion/colonnade features and sparse localized data-rain. Match Image 2's moderate anomaly density across the whole scene, with the lake itself a location-specific focal effect. Keep more than half the water naturally dark and rippled. Preserve real geometry and ink-blue-gray sky. No floating arcs, portals, 3D debris, extra people, fake structures, text, logos, flags, UI or excessive neon.
```
