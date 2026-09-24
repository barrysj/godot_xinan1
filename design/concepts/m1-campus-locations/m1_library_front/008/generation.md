# 图书馆正面异常候选 008

- 日期：2026-09-24；状态：`unselected + pending`，供11地点扩展的资产评审，不代表正式批准或 Godot 接入。
- 负责人决定：银桦＋清真食堂008的非实体异常类型和强度可作为本组普通地点的生成基准；图书馆为 Boss 区，建筑主体左右窗侧提高异常密度。此前候选保留，不凭本轮自动改为 rejected。
- 来源工具：Codex 内置 imagegen 单图局部编辑。Image 1 是本地点007异常生成源（严格地点身份／镜头）；Image 2 是银桦＋清真食堂008生成源（只参照异常类型、色彩与密度，不移植建筑）。
- Image 1：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-104e0f73-c2c9-41b2-9946-5e0ad34a1ccb.png`。
- Image 2：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-984eca3b-843d-4d1a-bd32-816e703875a3.png`。
- 最终生成源：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-ded1c5ee-bae9-4182-a8f6-5fa5e746a603.png`。
- 输出：`design/concepts/m1-campus-locations/m1_library_front/008/anomaly.png`。源 1672×941；交付 3840×2160、RGB不透明PNG。按16:9中心微裁并高质量双三次重采样，非原生4K、非AI超分。
- SHA-256：`F2FD6F2DD7F8A92216F58D6B99E3DB34F780F0AB0E452010BF6F9FEDD1862962`。
- QA：生成源及12张汇总缩图已目检，地点、透视、真实建筑和墨蓝灰天空可辨；地面实体发光碎块已清除，新增异常为平面面板、短数据雨、贴地裂隙；图书馆窗侧密度高于普通地点，旗帜／旗杆未恢复。广场或道路的湿亮感仍需负责人审美复核。技术校验见ART-02；不以技术通过冒充资产批准。
- 来源权利：沿用用户实景参考链，未额外核验公开／商业再分发权利；内置imagegen底层模型版本未披露。

## 完整提示词

```text
Use case: precise-object-edit. Asset: one 16:9 LIBRARY FRONT BOSS-AREA anomaly game background. Image 1 is the STRICT identity, camera and composition target: preserve the actual symmetrical library with a central glazed entrance tower, long LEFT and RIGHT window wings, steps, trees and very broad foreground plaza; maintain original skyline and ink-blue-gray sky. Image 2 is the approved cafeteria sample ONLY for cyan/violet nonphysical effect language and normal-location density; do not copy its architecture. This library BOSS location must have MORE anomaly than Image 2, but concentrate that extra density ON THE MAIN BUILDING'S WINDOW SIDES: both left and right banks of vertical windows and adjoining masonry. Add clear layered cyan rectangular planar light panes integrated into selected window bays; short broken cascades of cyan data-rain INSIDE multiple windows; angular violet fracture seams connecting some window jambs and facade panels; a few subtle displaced light echoes behind glass. Strengthen the central glass tower moderately but keep front entrance readable. The distribution should be visibly richer across the TWO WINDOW WINGS, not only the center and not primarily the plaza. REMOVE ALL solid crystal shards, triangular physical debris, floating rocks and gem objects from foreground plaza, path and steps; reconstruct the intact tiles. Replace with only a sparse network of thin, flat, perspective-following cyan/violet projected fissures and weak ghost reflections on the plaza, leaving large areas ordinary. Keep building shape, floor count, stair position, trees, real dark sky and warm window lights. Absolutely NO flags or flagpoles, no rings/halos/portals, no purple sky, no physical debris, no new wings, no illegible signage, no UI or text. Boss intensity through window-side digital interference, not clutter. Polished painted-realistic campus game backdrop.
```
