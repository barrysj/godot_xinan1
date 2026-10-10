# 生成记录：战斗状态组件 tmp_001

2026-10-07，内置 image_gen（非 CLI、未使用外部付费 API）。待人工评审的概念，不是运行资产。

参考：`.godot/enemies-final-1920x1080.png`实际游戏截图；已先用view_image查看。

初稿来源：`C:/Users/SongJun/.codex/generated_images/01a1166c-888e-71d3-ba3f-a08e73a9554b/exec-8efa1f26-12cc-49db-ab86-e8a8810335da.png`，复制为styleboard-draft.png。修正稿来源：同目录`exec-d5fa1133-c5e1-42ea-a025-776e41269953.png`，复制为styleboard.png。两次transparent_background=false。

工具实际输出1448×1086 RGB；目标尺寸只属提示词，不伪称实测。下方人物和战场仅视觉比例示意，不交付新人物或动画。未改正式资产、Manifest与运行代码。

## 初次生成完整提示词

```
Use case: ui-mockup. Create ONE polished, restrained 2048x1536 landscape concept presentation board for Cyber Pop Campus battle HUD components, not a production sprite atlas. Input reference is the actual existing game screenshot; reference it for ink-black sharply cut panels, warm ivory text, flat saturated accents, light campus background and existing game identity. Do not redesign characters or add characters. Show four clean sections with ample breathing space on ivory paper background, fine slate divider lines, quiet precise typography; top headline Chinese "战斗信息组件 · 概念 01" and small "CYBER POP CAMPUS".

Section 1, strongest visual priority, titled "产码与库存": a handsome larger inventory strip of FOUR separated angled ink panels, each with huge easily read white tabular numerals and small filled/empty nodes: red command chevron > with 2 / 6, blue data {} with 1 / 6, green protocol ↔ with 3 / 6, violet permission # with 1 / 6. Tiny Chinese labels 指令 数据 协议 权限. Below it show a distinct, compact PERSONAL PRODUCTION widget red > plus three sturdy outlined square nodes, two filled, and readable 2 / 3. Label "个人产码". Separate purple SHARED SHIELD ABSORPTION badge with shield symbol and 48 / 80, label "全队吸收"; it is a shared team threshold, NOT a personal counter and NOT another unit timer. Tiny diagram simple bright chip travels from full local three nodes to red team inventory, but no dense arrows.

Section 2 titled "血量与行动": magnified two compact unit status clusters, no character names. In each: a thick horizontal health bar on dark backing, tiny heart at left, thin separate shield indicator; UNDER it exactly ONE action timing bar. First cluster: cyan-blue filling action bar with a small sword icon. Second cluster: same single action bar in warm amber, clear casting star icon and very restrained short diagonal ticks. Make health green for friendly and muted coral for enemy variant; never recolor HP on casting. Keep action width same as health. No multiple action bars on a single unit. Label examples "普攻" and "施法" outside component.

Section 3 titled "敌人意图": one cohesive row of 6 bold monochrome ivory silhouettes in 28px dark chamfered square plates: melee sword, ranged bolt/arrow, area ground-ring with downward arrow, shield, healing cross, hourglass. Icons must be unmistakable, thick, geometrically simple, legible small, no intricate artwork. Show normal, hover with amber rim, casting with amber corner flash. Beside it small dark tooltip example with only readable heading "范围攻击", line "释放后影响标记范围", line "剩余 2.1 秒"; tooltip text is concept only and will be native code text.

Bottom wide inset titled "战场比例示意 · 非运行截图": use a recognizable cropped region of the supplied campus battle screenshot for CONTEXT. Retain its existing actors unchanged. Replace nameplates with clear small health+single action clusters under their feet, compact local production icon+three nodes next to friendly clusters, compact intent icon next to enemy cluster. No names displayed. Keep bodies unobscured; the treatment must feel plausible at real game scale. Inset should occupy about one quarter of the board, not compete with component family.

Art direction: clean flat 2D vector-like rendering, strong silhouettes, no chrome bevels, no 3D glossy UI, no massive glows, no constant glitch, no random tech runes, no extra stats. Palette mainly ink #11151C, ivory #F6F8FA and slate #252B33; cyan #22B8D6 / #22E0F0 for ordinary actions, warm amber #F2A36B for casting, green #36D399 health, coral #FF4D6D enemy, violet #8B5CF6 permission. 4px chamfers and crisp high contrast. Information hierarchy clear. This is ONE candidate visual style board, not ready-to-use assets; never suggest raster text is shipped. Match reference's restrained graphic game UI rather than enterprise dashboard.
```

## 定向修改完整提示词

```
Edit this concept board only to CORRECT GAMEPLAY SEMANTICS while preserving its attractive ink/ivory/cyan/amber vector-like graphic family, overall composition and the 4 panels. Important corrections:
1. Every unit's status cluster must contain exactly TWO horizontal bars total: ONE health bar and ONE action timing bar. REMOVE EVERY separate purple shield bar, from upper-right magnified examples AND all bottom battlefield clusters. Shield amount, when present, is a tiny plain white shield icon + integer "30" at far right of the HEALTH row, NOT a bar and NOT a fraction. The "48 / 80" absorption fraction must appear ONLY in the shared team absorption component in upper-left panel, never on a unit.
2. Upper-left "全队吸收" caption must read exactly "全队实际吸收累计，满 80 产出权限。" Shared purple component remains 48 / 80; it is a resource production threshold, not health or remaining shield.
3. Bottom inset must be simplified for clarity: keep just THREE existing actors from the reference design: left female ranged student, middle male cyan shield guardian, right chalk spirit. Keep their original identity/design, no invented actors. Place at generous horizontal spacing. Left student's widget: small red > and three nodes (2 filled), then green health bar, then cyan action bar. Middle guardian's widget: green health bar + tiny shield "30", then amber action bar, with NO personal production nodes, NO purple badge. Right chalk spirit's widget: enemy coral health bar and cyan action bar, with a ranged arrow intent icon. No names. None of the bars cover body art. Each total widget is compact, under feet.
4. Enemy intent row keep the same six clear silhouettes; captions only "普攻", "远程", "范围", "护盾", "治疗", "蓄力". Change "悬停高亮" to correct Chinese if necessary. Final image is still labeled concept 01, non-runtime mockup. No other additions, no claims of functioning UI. Keep top-left inventory number panels and personal red 2/3 counter unchanged. No more than 2 bars beneath any actor.
```

## QA

初稿错误把盾量与全队吸收阈值混同、显示个人紫色进度、堆叠三条状态条。修正稿已经移除这些错误；仍有微小AI文字不适合正式使用，所有运行文本须原生重新排版，不能裁切概念板成品。暂存两稿供留存决定，推荐只保留修正版和本记录；未批准不删除。


2026-10-08 留存：用户选择保留当前版本与必要证据；修正版正式留存为concept_001。初稿按授权删除，以上来源／提示词／失败原因作为历史追溯保留。概念批准绑定SHA 22eb41470ed5959d958e47c0ab5fb89106931e38c04a6f3c9ee0fd11cea3abcf。
