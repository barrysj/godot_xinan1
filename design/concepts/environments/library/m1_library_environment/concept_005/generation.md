# M1 图书馆环境 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/m1_library_environment.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · atrium-down.png

```text
Edit this image locally. On the LEFT SIDE ONLY, REMOVE the diagonal stair flight directly linking the second and third balcony levels (the middle-left stacked stair run between those two floors). That bay should be OPEN AIRY EMPTY atrium-side space with orderly horizontal balcony slab edges and railings at each separate level, not continuous zigzag stairs. Do not replace removed stairs with a wall, bookshelves, ramps or tables; open void must be visible. Retain lower left stair where appropriate and right-side stairs. Preserve all other scene details, exact camera, octagonal floor shape, art exhibition, cafe and sofas, warm palette, light contrast and cel-shaded style. No text or people.
```

### 2 · window-corridor.png

```text
Edit this same library image. Keep bookshelf RADIAL orientation, camera, palette and architecture EXACTLY as input. Change only the RIGHT ENDS of the middle tall bookshelf runs: retract/shorten those ends away from the atrium railing to create a CONTINUOUS CLEAR WALKWAY between all bookshelf ends and railing. It must be visibly about a person's comfortable walking width, a continuous pale stone floor ribbon running along the inner polygonal railing from foreground into distance, no shelf touches railing or sticks into walkway. Do not rotate shelves or remove the railing. Do not move foreground desks. Retain art exhibit below, warm lighting, same 2D cel shading, no people/text/UI.
```

### 3 · shelf-to-atrium.png

```text
Edit ONLY the distant atrium architecture in provided image. Every floor in PLAN is the SAME REGULAR OCTAGON, centered on SAME vertical axis. Stack identical octagonal balcony slabs vertically, same footprint on all levels, same floor-to-floor height, white slab edges have exactly corresponding straight sides and 45-degree plan corners. Corresponding corners and columns line up vertically through all floors in perspective. Far central straight face, symmetrical chamfered diagonal faces left/right, then side faces continuing toward camera; no irregular extra kinks, no curved rounded perimeter, no level has different polygon or shifted corners, no cascading setback. Clean precise orderly repeated white slab edges. Keep same number of floors and overall atrium size. Preserve foreground bookshelf/table geometry, floor, cross aisle, desks tight to railing, warm colors and contrast, exact camera, skylight and clean 2D cel shaded drawing. Only correct octagonal geometric alignment, no extra furnishings or text.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
