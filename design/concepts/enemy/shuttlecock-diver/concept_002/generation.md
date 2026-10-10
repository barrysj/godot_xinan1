# 羽球突刺 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/shuttlecock_diver.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 完整提示词

```text
Use case: stylized-concept. Redesign the supplied concept into a cleaner mechanical campus enemy. Clean 2D cel-shaded game concept art, dark navy outlines, light warm gray opaque background, restrained cyan/magenta status lights, readable physical mechanisms rather than just glowing decorations. No human limbs, no horror, no scenery, no watermarks. Landscape action concept sheet. Input image previous shuttlecock is identity reference, replace attack completely. A recognizable badminton shuttlecock, white feather-shaped metal blades forming cone attached individually into sockets around a blue-gray mechanical cork-shaped head. Each feather a detachable dart, not biological. Three panels 待机 / 展羽 / 齐射. Idle clear badminton outline. Anticipation feather ring expands on individual hinges revealing socket rail and electromagnets. Firing: stationary hovering body on LEFT, THREE feather-blade darts fully detached flying to RIGHT with pointed ends leading and trails behind to left; three visibly vacant mounting slots in tail ring, other blades still attached. Body does NOT collide with target. Mechanical core and feather sockets visible, no ordinary gun barrel, no humanoid face. Title 羽片发射器.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
