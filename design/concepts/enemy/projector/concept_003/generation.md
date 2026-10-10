# 教室投影仪 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/projector.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 首轮完整提示词

```text
Use case: precise-object-edit. Create a revised three-pose landscape game enemy concept board using supplied image as identity reference. Preserve crisp 2D cel shading, navy outlines, cream/navy materials and restrained cyan/magenta accents. Warm pale gray opaque background, full uncropped forms, generous margins. Only Chinese title and three short pose captions; remove slogans and incidental writing. Consistent components and scale across poses. Title 投影独眼灵. Preserve projector body, single cyan lens, shutter eyelids and folded ceiling bracket on top. REMOVE BOTH LEGS AND FEET ENTIRELY in all poses; smooth closed underside, no limb stumps. Hover clearly above separate soft oval shadow. 静止: level floating projector. 蓄力: body leans slightly forward, shutters narrow cyan iris, top bracket folds compactly. 出手: shutters open, shoots narrow beam straight screen-right from center lens; body tilts back under recoil, visibly airborne. Exactly same FOUR shutter plates all poses, same bracket components. No text or branding on casing.
```

### 2 · 定向迭代

```text
Keep all three hovering legless projector poses EXACTLY as shown, all text, mechanical components and cyan beam unchanged. Correct ONLY background and edge quality: solid opaque warm pale gray #e4e1dc throughout entire image, no transparency, no black background, no checkerboard. Smooth clean cel-shaded edges, eliminate speckled alpha fringe around beam and shadows. Preserve separated oval hover shadows, all forms and same image aspect.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
