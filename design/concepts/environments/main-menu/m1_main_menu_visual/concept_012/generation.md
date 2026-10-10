# M1 主菜单视觉样板 · 来源与当前制作入口

此文件只说明现存源资料；不保留逐次生成、微调意见或审核流水账。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/m1_main_menu_visual.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 目标：保持地点身份、镜头构图、道路／入口中轴、原生 UI 安全区和异常状态叙事，提升远景建筑、植被、水面与数字异常纹理的清晰度，输出精确 3840×2160。
- 模式：逐张图像编辑（不是从零重绘）；每次只提供对应的一张源图。

## 原始生成提示词

原记录中标为摘要的文本仍是摘要，未补写为完整调用。

### 1 · 提示词摘要

```text
共同约束：`preserve the exact composition, camera position, landmark identity, building geometry, paths, UI-safe negative space and all approved anomaly-story elements; improve natural fine detail and edge coherence; no text, logo, watermark, extra roads, flags, poles, people or new focal subjects; 16:9 game main-menu background, 3840x2160 target`。
```

### 2 · 提示词摘要

```text
- 正常图书馆：保持湖岸建筑和宁静湖面，只增强建筑边缘、水波、树木与天空层次。
- 正常品学楼：保持正面中轴、喷泉、广场与树线，只增强立面、地砖与植被细节。
- 正常银杏主楼：保持大门中列与道路双黄线严格对齐，保持无旗帜、无旗杆、无左侧岔路。
- 异常图书馆：保持彩色断裂倒影，并严格只保留两只小型远景数字黑天鹅；左鸟低颈向左，右鸟抬颈向右并轻微展翼。
- 异常品学楼：保持分段数据水弧、电路线地砖、窗面与路径灯错误脉冲。
- 异常银杏主楼：保持入口中轴、几何落叶、重复枝形、青色道路脉冲和品红路径灯。
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
