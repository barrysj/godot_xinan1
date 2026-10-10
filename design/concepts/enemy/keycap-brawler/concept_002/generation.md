# 键帽拳灵 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/keycap_brawler.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 首轮完整提示词

```text
Use case: precise-object-edit. Create a revised three-pose landscape game enemy concept board using supplied image as identity reference. Preserve crisp 2D cel shading, navy outlines, cream/navy materials and restrained cyan/magenta accents. Warm pale gray opaque background, full uncropped forms, generous margins. Only Chinese title and three short pose captions; remove slogans and incidental writing. Consistent components and scale across poses. Title 键帽拳灵. Preserve keycap boxer concept and two feet. Fix anatomy and key consistency: each fist is a simple rigid block with FOUR large blank keycaps arranged 2x2; identical arrangement in all poses, no random letters. Preserve Esc head, circuit chest, spacebar forearm guards without words. Exactly two arms and fists with clear shoulder-elbow-wrist chain. All three figures face right. 静止: boxing guard. 蓄力: pull ONE attacking fist behind torso to screen-left at waist height, elbow bent; other fist guards chest. 出手: the SAME arm extends horizontally screen-right into a small gray cube, knuckle keycaps depressed on contact; other fist still guards. No swapped attacking arm, no extra fingers, no detached joints. Show clean readable force and stable grounded stance.
```

### 2 · 定向迭代

```text
Fix only fists and arm continuity in this keycap boxer board. Keep all other design, colors, title and layout. Each fist now has exactly TWO large square blank keycaps SIDE BY SIDE on ONE rigid striking face, not four, no fingers. Same two-key face in all three poses, clear separated key edges. Middle anticipation: move attacking arm on screen-RIGHT side of torso back toward upper-right behind shoulder, with elbow bent, fist raised and retracted; screen-LEFT guarding fist remains in front of chest. Last pose: same screen-RIGHT arm extends rightward to punch cube, screen-LEFT fist stays guarding. Same shoulder cable colors. Delete EDU text on chest all poses. Preserve Esc. Two arms/two fists only. Target cube fully inside canvas with margin. Gray opaque background.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
