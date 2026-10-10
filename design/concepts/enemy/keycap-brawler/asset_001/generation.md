# 键帽拳灵 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/keycap_brawler.yaml)为准。

现存参数／处理入口：[build-config.json](build-config.json)、[rig_manifest.json](rig_manifest.json)、[battle_animation.frames.json](battle_animation.frames.json)、[action-cards.json](action-cards.json)、[action-input.json](action-input.json)。源图和输出均随本包保留；重新生成云端图片不保证逐像素复现。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 完整提示词

```text
Use case: identity-preserve. Asset type: production transparent 2D game enemy pose atlas. Use the attached approved KEYCAP BRAWLER concept solely as identity, mechanical component, palette, and rendering reference. Produce a square 1536x1536 RGBA atlas with EXACTLY NINE isolated complete poses arranged in a perfectly regular THREE COLUMN by THREE ROW grid, each invisible square cell 512x512. All poses centered with at least 35px clear space around each full silhouette, consistently same body/head scale, feet baseline at cell y=455 for standing poses. No labels, no dividers, no shadows, no ground, no target cubes, no text except the unchanged small Esc on head cap. Transparent background, actual alpha, no checkerboard. Crisp navy outlines and clean cel shading, cream keycaps, charcoal mechanical joints, cyan chest core and magenta eyes/wiring, no gradients beyond subtle material highlights. Identity locked: one Esc head, two arms, two legs, exactly TWO cream keys on EACH rectangular fist, never extra keys, same magenta cables and cyan core. Approx four-head tall sturdy robot. Camera fixed 3/4 facing SCREEN RIGHT in all living poses, full body, no perspective or identity redesign. Nine cells in row-major order: 1 idle guarded stance; 2 moving stride with visibly bent knees; 3 anticipation draw screen-right punching arm BACK with elbow bent while opposite fist guards chest; 4 IMPACT fully extend punching arm toward screen-right at chest height with rigid two-key fist, torso twists and bent knees, no beam; 5 recovery elbow retracting toward guarded idle; 6 CAST both fists close to chest, keys visibly pressed inward with brighter cyan chest core, controlled focused pose, no floating effects; 7 CRITICAL crouch low with one fist supporting weakened body, dim core, intact limbs; 8 DEATH START knees collapse, head drops, fists low, core dark; 9 DEATH END robot lying on side with head still attached, both legs and two intact two-key fists visible, same body proportions. Every cell is one complete same robot; clear separated cutout sprites, no silhouettes touching grid boundaries. Clean usable game sprite art, faithful to supplied concept, not a concept board.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
