# 餐盘格挡怪 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/meal_tray_guard.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 完整提示词

```text
Use case: precise-object-edit. Edit the supplied cafeteria enemy action concept sheet. Preserve the large LEFT idle illustration, title, TOP RIGHT soup pouring panel and BOTTOM RIGHT fork stabbing panel exactly. Replace ONLY the MIDDLE RIGHT panel currently labeled 夹击. Change its label to 抛食. Retain the same floating four-compartment steel tray at left, now with a small mound of white rice and a few clean cooked-food bones in its compartments. Exactly TWO independent floating chopsticks near tray act as a pair, just finishing a throwing flick with curved motion marks. They stay beside tray, never approach or grip target. Show a white rice clump with visible grains and one clean cartoon food bone FULLY DETACHED from chopstick tips, flying in a clearly curved left-to-right projectile arc across a large air gap toward a gray target cube at far right. Motion trails behind food, impact rice flecks on cube. Weapon is throwing FOOD, not throwing chopsticks, not pinching victim. No mechanical arms, no duplicated chopsticks, no hands. Keep same cel shading, steel/cyan/magenta palette and gray background. No gore. The food projectile is the clear focal point in this action panel.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
