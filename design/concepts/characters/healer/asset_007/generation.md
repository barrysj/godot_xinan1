# M1 应援者动画友好种子资产 007 生成记录

生成日期：2026-09-21  
生成方式：Codex 内置 `image_gen`，以已批准的 `m1_healer_long_sleeve_concept_006.png` 为身份与服装参考独立生成；无外部图片来源、无在世艺术家风格指令。  
用途：验证应援者从批准概念进入动画生产前的最小资产结构。本批是待人工评审的资产种子，不是已拆层骨骼、动画图集或 Godot 接入资源。

## 资产内容

| 文件 | 用途 | 尺寸／格式 | SHA-256 |
| --- | --- | --- | --- |
| `m1_healer_battle_composite_asset_007.png` | 四至四点五头身战斗合成候选 | 1145×1374／RGBA | `1357138bf90194039eca2a1a027517fddf014bdeaf64a8290674d5516e740c85` |
| `m1_healer_rig_master_asset_007.png` | 无工具、四肢分离的后续拆层母版 | 1086×1448／RGBA | `02b62aee41c391d4581107bb5c93ff97f0d1695907089ace9f5154ed64f3b956` |
| `m1_healer_split_keyboards_asset_007.png` | 左右独立的双键盘组件表 | 2048×768／RGBA | `897c8da11cd32a0a00954aa989c6a82b36ab11f1f2adcc8e54a63fb595027cd5` |
| `m1_healer_portrait_asset_007.png` | 同源头像母版 | 1254×1254／RGBA | `3956aac1c0e6ce1b1b9eba62d67d1f5f4bb1454d907a5edc5bb6ac0e0b9056c8` |
| `processed/m1_healer_battle_composite_384.png` | 384×384 脚底锚点预览，脚底 `(192,336)` | 384×384／RGBA | `c9f21a8dbcfa75a582e29291b3d0396da060a888ffedd5c9123f6b98619944cf` |
| `processed/m1_healer_rig_master_384.png` | 384×384 拆层母版尺度预览，脚底 `(192,336)` | 384×384／RGBA | `0e1ad1910a9b581db0085040e8d3b125fa9c8d4735bbb74ebd1d79486cd2400c` |
| `processed/m1_healer_portrait_140.png` | 现有角色资源规格的头像预览 | 140×140／RGBA | `c8f9345a9fc20b98bd59ea8bad025790f284181791e9985ccac244318749078b` |
| `review/codex-workflow/m1_healer_seed_007_contact.png` | 四件源资产透明底同屏检查 | 1200×820／RGBA | `55bbc5323b3a4ff66b0fd76ce1961e6080603b2a1c8eacae648eb8925eb55a76` |
| `review/codex-workflow/m1_healer_seed_007_128_compare.png` | 战斗合成在 128×128 浅／深背景的实际尺寸检查 | 640×280／RGBA | `16426abaf08ce324aae93ee9444c0c33dd7628c58a51994efb021907e55c2d0a` |

`rejected/` 保留第一次生成的正常立绘比例版本。两张图虽然身份、透明度和肢体均可用，但约六至七头身，不符合 `CHARACTER_SPEC` 的战斗四头身目标，因此不纳入资产候选。

## 提示词摘要

### 战斗合成

```text
Preserve the approved healer identity, single mint long-sleeve crewneck, charcoal trousers,
white sneakers, backpack and student ID. Redraw as one 4–4.5-head right-facing light-chibi
battle unit. Keep exactly two separate compact holographic keyboards and restrained green
binary ribbons close to the forearms. True transparent RGBA; no ground, backdrop or text.
```

### 拆层母版

```text
Preserve the same identity and outfit, but use a neutral right-facing 4–4.5-head stance.
Keep arms slightly away from the torso, hands visible, legs and shoes separated, and the
backpack behind the body. No keyboards or VFX. Transparent source for later cutout work.
```

### 双键盘与头像

```text
Generate exactly two isolated mirrored mint holographic split keyboards with a wide gap,
without character or effects. Separately generate one transparent identity-locked bust
portrait with no keyboard, hands, VFX, frame or text.
```

## 归一化规则

- 战斗合成与母版均从可见 Alpha 包围盒等比缩放到最大 352×320，再放入 384×384 透明画布。
- 水平中心为 `x=192`，脚底为 `y=336`，对应归一化锚点 `[0.5, 0.875]`。
- 头像从可见 Alpha 包围盒等比缩放进 132×132 安全区，再放入 140×140 透明画布。
- 这些处理图只用于资产评审和未来接入测量；源图保持不变。

## 图片质量闸门

```yaml
quality_result:
  schema_version: 1
  task_id: m1-player-cast-healer-seed-007
  status: PASS_WITH_NOTES
  eligible_for_asset_review: true
  checks:
    technical_integrity: PASS
    subject_and_identity: PASS
    anatomy_and_physics: PASS
    prompt_and_content: PASS
    composition_and_readability: PASS
    generation_artifacts: PASS
  failures: []
  notes:
    - "四件候选均可正常解码且具有真实透明 Alpha；无额外角色、背景、边框、可读伪文字或水印。"
    - "战斗合成与母版经定向重绘达到约四至四点五头身；首轮正常立绘比例版本已归入 rejected，不参与评审。"
    - "角色脸、发型、单件薄荷长袖、深色长裤、白鞋、背包与学生证在战斗体、母版和头像之间连续。"
    - "战斗体恰有两块分体键盘，手指与键盘表面分离；组件表恰有两块互不连接的键盘。"
    - "128×128 时人物、双手和双键盘可读，细密二进制退化为辅助光效，不承担核心职责识别。"
    - "rig master 仍是单张扁平 RGBA；头发、躯干、上臂、前臂、手、腿、背包尚未实际拆层，也没有骨骼、动作或动画资源。"
  repair_directives: []
  next_step: human_asset_review
```

