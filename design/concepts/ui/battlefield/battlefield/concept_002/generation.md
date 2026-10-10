# 战场视觉改造候选 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/battlefield_redesign.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 初始提示词

```text
Use case: ui-mockup / precise-object-edit. Create a high quality battlefield visual redesign concept sheet based ONLY on the referenced CURRENT GAME SCREENSHOT. This is a Chinese campus auto-battler, horizontal left versus right, not a turn-based board game. Output one large landscape concept sheet with TWO complete equal-size wide game views stacked vertically, upper view labeled 整备, lower view labeled 战斗, tiny heading with candidate name, no extra decorative marketing. Preserve the original school entrance architecture, daylight, recognizable paving, original dark HUD style and same code resource strip and buttons. All existing character designs (blue-haired archer, male student, brown/purple pixel placeholders, two white pointed chalk spirits) MUST be reused faithfully with unchanged identities, proportions and art styles; do NOT redesign, beautify, replace or homogenize characters. Only ground, tactical UI, contact shadows and modest nameplate cleanup are in scope. No new characters or props. Preparation view: our four characters on left, enemies on right; exactly six deployment locations in two columns and three rows in left half, four occupied, two empty. Battle view: preserve character positions from screenshot, hide deployment overlays, highlight ONLY the blue-haired archer's attack reach as a smooth translucent ground-plane footprint with fine edge, not a vertical bubble; one enemy receives a small targeting marker. No thick gold ring, no full-screen grid, no floating sci-fi arena, no hexagonal chessboard. Campus remains predominant, effects low opacity, clean legible chinese. Concept mockup only, not a shipped screenshot. Candidate heading: B · 战术阵位. Ground direction B: clear graphic tactical stage integrated onto original paving. Shallow perspective rounded-rectangle play area, low contrast slate-blue gray translucent field mask with short edge ticks, preserve paving visible below. Preparation: six large flat chamfered rectangular deployment pads in floor perspective, no vertical volume, each separated by generous gaps, thin cyan borders with a distinct selected pad; opposing setup hinted with very faint rose corner brackets. Battle: pads disappear entirely, retain subtle stage border and short edge ticks; archer range is a smooth translucent cyan ground footprint with restrained evenly spaced dashed perimeter, one bright foot-level target bracket. Strongest clarity, no hexes and no chessboard.
```

### 2 · 定向修正提示词

```text
Precise correction of this battlefield concept sheet. Keep the two-panel layout, campus building, ground variant styling, title, all existing character ART and HUD unchanged. Correct ONLY tactical semantics. In LOWER battle panel REPLACE THE ENTIRE blue attack area with ONE FULL 360-degree smooth elliptical ring on the ground, CENTERED EXACTLY UNDER THE BLUE HAIRED ARCHER'S FEET. The archer must be at the CENTER of the ellipse, never on its edge. Ellipse reaches equally left and right of feet, approximately width 450px and height 160px in this 1672px wide sheet. It is a complete closed oval, NOT a cone, NOT a fan, NOT a sector, NOT a teardrop. Very faint cyan fill, thin clean edge. NO directional straight sides. REMOVE ALL target brackets/arrows on enemies, as they are outside this short sample reach. Do not draw a second giant ellipse. In upper preparation panel have exactly six deployment sockets, two columns three rows, four player units and two empty. Player units are brown pixel 冲刺手, purple pixel 应援者, blue-haired 远射手, blue-clothed male 守护者. ENEMY is green/brown pixel 错位黑板 and TWO white 粉笔精灵. These identities must not change. All enemies red health bars, all four players green bars. Do not redesign any character.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
