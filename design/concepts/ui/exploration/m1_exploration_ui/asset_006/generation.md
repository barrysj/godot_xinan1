# M1 探索 UI · 图书馆布局概念 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/m1_exploration_ui.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · Panel

```text
Generate a production-ready isolated game UI popup panel skin, no text, no icons, no buttons. Cyber Pop Campus: contemporary anime campus digital terminal corrupted by a localized anomaly, elegant graphic design, not military sci-fi or heavy metal. Landscape 3:2 panel centered on genuinely transparent RGBA background with generous transparent margin. Front-facing orthographic perfectly straight flat screen asset. Blue-black smoked glass #101321, subtle cool gradient and translucent inner surface, exquisitely smooth antialiased edges, restrained asymmetrical geometry with ONE clipped upper-right corner, thin layered rim, short luminous cyan #00F0FF vertical accent on left edge, very small magenta #FF2DAA signal-break accents on right edge. Subtle diffused cyan bloom restricted near border. Large totally empty dark central area, 85 percent of panel is calm readable space for runtime text. Sophisticated clean 2D anime game UI craftsmanship, tiny controlled highlights, thin floating shadow. No text, letters, numbers, fake technical writing, grid, circuit clutter, screws, bevelled metal, perspective, scene, checkerboard or presentation board. One panel only, actual alpha outside silhouette, high resolution.
```

### 2 · Button

```text
Generate ONE production-ready isolated blank game UI primary button skin, no text or icon. Cyber Pop Campus anime campus digital terminal affected by anomaly. Front-facing orthographic horizontal button, width to height ratio 3:1, centered on genuinely transparent RGBA canvas with generous transparent margins. Elegant graphic silhouette with restrained small clipped upper-right and lower-left corners. Luminous frosted cyan fill #57BCD0 with subtle cyan glass gradient, delicate pale cyan top edge, sophisticated hairline inset rim, dark teal lower edge, tiny magenta signal interruption only at extreme right corner. Soft very narrow outer glow, superb smooth antialiased edges, not plastic 3D, no heavy bevel, not metallic. Keep center entirely clean for dark runtime Chinese action label. Cohesive premium 2D game interface, understated high polish. No words, numbers, symbols, circuitry, surrounding interface, background scene or checkerboard. Actual transparency outside button. One button only, high resolution.
```

### 3 · Panel targeted edit

```text
Remove all background outside the panel silhouette including broad cyan haze; actual transparent alpha outside, retain panel and empty interior, narrow halo. 使用首张生成面板为编辑目标，交付编辑结果。
```

### 4 · Icons

```text
guardian: mandatory guardian encounter: a shield containing a clear yellow exclamation mark, three very short magenta lightning strokes pointing inward toward shield
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
