# M1 主菜单视觉样板 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/m1_main_menu_visual.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 生成工具：Codex 内置 `image_gen`，使用编辑模式完成定向构图修订。
- 编辑目标：`design/concepts/environments/main-menu/m1_main_menu_visual/004/ginkgo-main-building.png`。

## 原始生成提示词

### 1 · 编辑提示词

```text
Use case: precise-object-edit. Asset type: 16:9 horizontal main-menu background concept for Cyber Pop Campus. Input image: Image 1 is the clean current ginkgo-main-building concept and is the edit target. This is a correction of the previous alignment attempt. In the current image, the center of the main entrance doorway / central arched gate column is visibly left of the road's double-yellow centerline. Shift the entire main-building group slightly to the RIGHT as one coherent unit: both wings, the central facade, the entrance, the front steps, and the landing. Move it only enough that the exact center of the main entrance column is precisely superimposed on the existing straight yellow road centerline. Use the entrance column and the road line as the hard alignment guides, not the visual center of the roof or the overall building width. Keep the road, yellow line, curbs, ginkgo trees, path lights, sky, sun, autumn leaves, camera framing, building scale, perspective, warm golden palette, cyan lights, and small magenta accent unchanged. Do not move or bend the road. Do not shift the trees independently. Do not add flags, poles, people, cars, signs, text, logos, watermarks, UI, HUD, or red markup. Do not redesign or mirror the building. Preserve the clean 2D painted game-concept look and exact 16:9 framing. This is a non-destructive revision candidate, not a finished production asset.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
