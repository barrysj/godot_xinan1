# 监考钟灵 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/exam_clock_boss.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 首轮完整提示词

```text
Use case: precise-object-edit. Create a revised three-pose landscape game enemy concept board using supplied image as identity reference. Preserve crisp 2D cel shading, navy outlines, cream/navy materials and restrained cyan/magenta accents. Warm pale gray opaque background, full uncropped forms, generous margins. Only Chinese title and three short pose captions; remove slogans and incidental writing. Consistent components and scale across poses. Title 监考钟灵. Preserve large circular clock torso, two brass bell domes, one center eye, two clock-hand blade arms, brass/ivory/navy palette. REMOVE both legs, feet, hip attachments AND dangling pendulum entirely; floating round clock with clean continuous lower rim. No stumps, no tiny feet. Remove slogan and placard writing; blank small plate or omit plate. 静止 hovering round clock holding two hand blades. 蓄力 same long blade lifted overhead, other short blade held aside, torso rotates slightly while hovering. 出手 same long blade sweeps diagonally down-right, tip ends near ground with small impact burst; other blade remains separate, bells ring with compact sound arcs. Shadow stays separated below round torso. Keep long and short blade identity consistent, no human torso or armored legs.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
