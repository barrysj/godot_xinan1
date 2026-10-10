# 馆藏巨典 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/great_volume_boss.yaml)为准。

现存参数／处理入口：[build-config.json](build-config.json)、[rig_manifest.json](rig_manifest.json)、[battle_animation.frames.json](battle_animation.frames.json)、[action-cards.json](action-cards.json)、[action-input.json](action-input.json)。源图和输出均随本包保留；重新生成云端图片不保证逐像素复现。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 生成工具：内置 imagegen；透明背景；source/projectile.png。
- 日期：2026-10-07；工具：内置 imagegen。
- 概念依据：docs/art/tasks/m1-enemy-animation.md 与原对象 concept 版本。

## 原始生成提示词

### 1 · tmp_002 定向修改（2026-10-07）

```text
Use case: stylized-concept. Asset type: single transparent 2D game projectile sprite for the approved hovering book enemy. One familiar sharply folded white/cream paper airplane, side three-quarter view, NO scene. SHARP single nose is the RIGHTMOST point pointing SCREEN RIGHT and very slightly downward, the two broad wing trailing edges and open folded tail are at LEFT. One central fold ridge connects left rear to the right sharp nose. Long horizontal dart shape, crisp dark navy 2px outlines, three simple cream/gray cel shading planes, restrained matching campus illustration style. Airplane occupies 70% width, entire silhouette uncropped with generous transparent margin. True transparent background, no shadow, no speed lines, no glow, no letters, no labels, no duplicated planes. Clean isolated readable raster game asset.
```

### 2 · 完整提示词

```text
Use case: identity-preserve. Asset type: transparent nine-pose 2D game sprite atlas of GREAT VOLUME enemy. The attached approved thick hovering hardcover book concept is strict identity and action reference. ONE thick dark navy hardcover book, brass four corner protectors, cream page block, two small magenta eyes on visible page edges or open pages, EXACTLY TWO dark red long ribbon bookmarks emerging from binding. No legs, feet, arms, teeth or humanoid features. Faithful clean navy outlines and precise cel-shading in navy/brass/cream/red, not 3D. Produce square true-alpha RGBA atlas with NINE isolated sprites in regular THREE COLUMN by THREE ROW grid, generous 12% margin around complete silhouettes, same physical scale, fixed 3/4 camera toward screen-right. No text, borders, labels, target cubes, shadow or ground. Nine cells row-major: 1 idle book CLOSED upright floating with two ribbons trailing rear/left; 2 moving closed book tilted 12 degrees forward toward screen-right, two ribbons behind; 3 anticipation closed book upright lifted and tilted slightly backward; 4 melee IMPACT closed book rotated 30 degrees forward/down with lower-front corner reaching imaginary floor, page block clear, no debris; 5 recovery closed book settling upright; 6 CAST clearly OPENED LEFT-RIGHT like a conventional book being read, TWO broad flat rectangular cream page surfaces, ONE central recessed binding gutter, same navy covers and brass corners underneath, two magenta eyes one on each page, exactly two red ribbon bookmarks behind, only two subtle lifted page corners; NO feather fan, no wings, no accordion; NO planes baked into this cell; 7 critical closed book sagging with slightly separated covers, two eyes dim, ribbons hanging weakly; 8 death-start book tipping flat, eyes dark, page block loosening but same book; 9 death-end book lying flat HALF OPEN, navy cover and brass corners present, two red bookmarks limp, eyes extinguished. Preserve same book dimensions and page thickness through rotation/opening. All nine cutout silhouettes fully inside cells with safe margins. Production sprite sheet, no labels.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
