# concept_012 · 主菜单六背景 4K 修订

## 目标与来源

- 来源：当前已批准的 `asset_001` 六张主菜单背景。
- 目标：保持地点身份、镜头构图、道路／入口中轴、原生 UI 安全区和异常状态叙事，提升远景建筑、植被、水面与数字异常纹理的清晰度，输出精确 3840×2160。
- 模式：逐张图像编辑（不是从零重绘）；每次只提供对应的一张源图。

## 提示词摘要

共同约束：`preserve the exact composition, camera position, landmark identity, building geometry, paths, UI-safe negative space and all approved anomaly-story elements; improve natural fine detail and edge coherence; no text, logo, watermark, extra roads, flags, poles, people or new focal subjects; 16:9 game main-menu background, 3840x2160 target`。

- 正常图书馆：保持湖岸建筑和宁静湖面，只增强建筑边缘、水波、树木与天空层次。
- 正常品学楼：保持正面中轴、喷泉、广场与树线，只增强立面、地砖与植被细节。
- 正常银杏主楼：保持大门中列与道路双黄线严格对齐，保持无旗帜、无旗杆、无左侧岔路。
- 异常图书馆：保持彩色断裂倒影，并严格只保留两只小型远景数字黑天鹅；左鸟低颈向左，右鸟抬颈向右并轻微展翼。
- 异常品学楼：保持分段数据水弧、电路线地砖、窗面与路径灯错误脉冲。
- 异常银杏主楼：保持入口中轴、几何落叶、重复枝形、青色道路脉冲和品红路径灯。

## 输出与规范化

AI 编辑输出为 1672×941。为避免非等比拉伸，仅对高度做约 0.5 源像素的居中裁切以校正至 16:9，再使用 `System.Drawing` 的 `HighQualityBicubic` 插值规范为 3840×2160、24bpp RGB PNG。六张候选分别位于本目录的 `normal/` 与 `anomaly/`；正式副本位于 `assets/art/backgrounds/m1_main_menu/`。

质量结论：`PASS_WITH_NOTES`。六张构图与关键身份约束保持；像素尺寸达到 4K，细节属于生成增强，不等同于原生 4K 摄影采样。
