# 银桦食堂＋清真食堂异常候选 007

- 日期：2026-09-24；状态：`unselected + pending`，仅供单图精修评审，不代表正式资产批准或接入。
- 负责人反馈：006 的地面实体碎块不符合设定；保留蓝色矩形面板、地面投影裂隙、数据雨及建筑上的异常。根据 `create-game-assets` 的代表样图流程，本轮只改本地点，不批量重生其余11处。
- 编辑目标：006 原始生成源 `C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-c435e24e-e51c-4721-8f11-cb3b012fcb14.png`。第一步移除地面三角形／晶体状实体并修复地砖；第二步微调贴地、无体积的断续青紫投影裂隙。保留原有建筑、真实弧形门厅、墨蓝灰天空、矩形平面光块、立面裂缝和短数据雨。
- 第一轮中间源：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-228d4722-7377-4e3d-83d0-0bfd2110253b.png`；最终生成源：`C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-5d06da6e-fe95-4e3a-9da1-d53d2e704ba7.png`。
- 输出：`design/concepts/m1-campus-locations/m1_yinhua_halal_cafeterias/007/anomaly.png`；源 1672×941；交付 3840×2160、RGB 不透明 PNG。16:9 中心微裁后以高质量双三次重采样，非原生 4K、非 AI 超分。
- SHA-256：`F0B7EAC3F0D258BDF226A2AF4C7157BF459E53DFC7F9A418ADA279CD5A7803D9`。
- QA：最终生成源已实际目检，地面实体碎块已消失；投影裂隙贴着铺地透视分布，正常建筑和入口仍可辨。4K 文件属性和 Manifest 一致性见 ART-02。审美与资产批准仍待负责人。
- 来源权利：沿用用户提供实景的参考链，未额外核验公开／商业再分发权利；工具为 Codex 内置 imagegen，具体底层模型版本未披露。

## 第一步完整提示词

```text
Use case: precise-object-edit. Asset: one Chinese university campus anomaly background for Cyber Pop Campus, 16:9. Image 1 is the STRICT edit target and identity/composition source: the Yinhua + Halal cafeterias at night. Change ONLY one thing: REMOVE every solid, three-dimensional triangular/crystal-like cyan and magenta object resting on the foreground and midground paving, including bright pyramidal shard piles along the steps and under the curved hall. Repair the paving underneath with matching bricks, perspective, texture, soft reflections and lighting. These solid pieces must not remain, and do not introduce new physical debris, pickups, obstacles, cubes, rocks or hologram sculptures. PRESERVE unchanged: the left rectilinear cafeteria and right curved real cafeteria entrance, columns, roof, trees, bicycles, camera, dark ink-blue/slate sky, warm windows, existing angular violet fissures on architecture, thin blue RECTANGULAR planar light panels on facade, sparse short blue data-rain inside windows, and the thin flat ground-projected geometric fissures/linework and subtle glow/reflections. The ground anomaly should read as projected light on pavement, not material fragments. Keep generous ordinary paving visible and no glowing circular rings or arches. Do not add new effects, words, UI, people or flags. Preserve the original painted game-background style and all landmarks.
```

## 第二步完整提示词

```text
Use case: precise-object-edit. Image 1 is the strict edit target: the same Yinhua and Halal cafeterias campus anomaly scene. Preserve EVERYTHING in Image 1 exactly: composition, real architectural curved roof, facades, windows, trees, sky, all cyan rectangular planar panels on the buildings, sparse vertical cyan data rain, violet facade fissures, and brick pavement. The previous pass successfully removed solid ground crystal debris; do NOT recreate any physical shard, triangular object, protrusion, pickup, or obstacle. ONLY strengthen the existing ground-plane anomaly slightly: on foreground and midground paving add 3-5 thin interrupted cyan/violet light-projection fissures following paving seams and perspective, flat as light painted ON the ground, with short faint ghosted edge echoes and tiny subtle reflected glow. Keep 75%+ pavement visually ordinary and the central walking route clear. These marks are TWO-DIMENSIONAL projected light, zero height, no material thickness, no isolated glass pieces and no cube holograms. Preserve lighting and stylistic continuity; no rings/halos, new UI, words or figures. 16:9.
```
