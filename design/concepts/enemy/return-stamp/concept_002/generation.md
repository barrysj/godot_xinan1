# 归还印章怪 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/return_stamp.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 首轮完整提示词

```text
Use case: precise-object-edit. Create a revised three-pose landscape game enemy concept board using supplied image as identity reference. Preserve crisp 2D cel shading, navy outlines, cream/navy materials and restrained cyan/magenta accents. Warm pale gray opaque background, full uncropped forms, generous margins. Only Chinese title and three short pose captions; remove slogans and incidental writing. Consistent components and scale across poses. Title 归还印章怪. Preserve wooden handle face, brass housing with exactly four date wheels, red rubber rectangular base and TWO receipt-paper arms. No human legs. 静止 upright. 蓄力 handle compresses straight DOWN into housing using a clearly visible telescoping collar, not deformed wood. 出手: show stamp just REBOUNDING vertically above its newly stamped red rectangular footprint, underside horizontally parallel to floor, slight gap between stamp and floor. Small neutral gray target cube sits INSIDE CENTER of red rectangular seal, fully enclosed by seal border. Seal aligned exactly below stamp base, same perspective and footprint, with slight magical expansion allowed; no humanoid flying away. Abstract red bars encircle but do not obscure cube. Vertical impact marks show down/up action, no sideways kick. No actual lettering on wheels or seal.
```

### 2 · 定向迭代

```text
Fix ONLY wooden handle continuity and telescoping movement. Use EXACT same rigid tall pear-shaped wooden handle silhouette and height in all THREE poses, copied from left idle shape, never squashed into a bowl. Middle handle moves DOWN into brass collar, collar shorter/compressed; handle itself does NOT flatten or change proportions. Right extended collar with same wooden handle. Keep existing target cube centered inside red stamped rectangle, rebound pose, four date wheels, two paper arms, warm gray background, title and layout unchanged. Preserve wood rigidity and material.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
