# 守护护盾 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../manifests/guard_shield.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 完整提示词

```text
Create a genuine transparent RGBA production 2D game VFX sprite sheet. Exactly 4 columns x 4 rows = 16 chronological frames, equal square cells, no frame labels, no grid, no text, no character, no ground, no opaque backdrop, no checkerboard. Same centered pivot in every cell, transparent gutters at least 12% of cell dimensions.
Effect: protective data shield activation for Cyber Pop Campus, elegant anime cel graphic cyan translucent hexagonal shield, a few magenta accent pixels, white luminous strokes, readable navy fine inner edges. The shield is a vertical hexagonal outline with EMPTY TRANSPARENT CENTER so a character remains visible inside. Fine connected circuit lines and sparse geometric diamond sparks create an authored animated burst. Do not fill shield with solid color. Each frame is distinct progression, fixed camera and orientation; biggest outline fits within 75% of cell.
Read left to right then top to bottom:
1 tiny cyan diamond seed. 2 growing two cyan arcs. 3 four angular arcs and sparks. 4 half assembled hex shield.
5 complete small hex shield. 6 rapidly growing hex outline with delicate interior edge circuit marks. 7 full-size double outline luminous protective shield. 8 full-size strongest white cyan hex shield with six outward sparks.
9 full-size stable cyan shield. 10 same outline fading slightly, small detached circuit fragments. 11 shield begins breaking into angular pieces. 12 fewer separated cyan arcs drifting outward.
13 six thin departing fragments. 14 three faint small sparks. 15 two very faint diamond particles. 16 one tiny almost invisible cyan dot.
Crisp handcrafted graphic shapes with narrow soft light halos, not photographic smoke, not rainbow fire, no medieval ornament, no runes. Real alpha transparency both outside and inside the shield. Square canvas, exactly 16 independent effect frames, smoothly developing a single coherent shield burst.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../docs/art/WORKFLOW.md#源资料与版本)。
