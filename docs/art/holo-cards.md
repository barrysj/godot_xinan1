# 可复用照片卡

本能力不绑定某个里程碑。当前为独立预览原型，不改变主游戏流程；人工评审见[合照卡任务](tasks/class-photo-holo-card.md)。

## 换图与复用

1. 复制 `design/concepts/class-photo-holo-card/card/002/card.tres` 为新卡资源，修改 `photo` 的纹理引用；可选修改 `title`、`subtitle`、`caption`、`edition`。001 是仅边框流光版本，002 新增照片镀膜扫光，原图共用、不重绘。
2. 实例化 `scenes/holo_card/holo_card_view.tscn`，给根节点的 `visual` 指定该资源。容器使用 8:7 比例，例如 AspectRatioContainer；建议一次仅展示少量详情卡。
3. 运行时使用 `set_visual(resource)` 换卡。虹彩、扫光、倾斜、指针／触摸／方向键输入均复用；不同实例独立材质，不串参数。

照片窗口为 4:3，其他比例完整 contain 留边，不拉伸、不裁脸。卡片整体为 8:7，主题版式当前固定；重设长宽比需改版式与 shader，不是只换图。文字保持短句，当前没有自动多行排版。

`foil_strength` 控制流光强度，`photo_depth` 控制整体照片轻微位移。`set_reduced_motion(true)` 固定正面；`set_effects_enabled(false)` 关闭流光。静止时不使用时间驱动闪烁。无人物分割、人物独立纵深或背面翻转；需要人物突出卡框时仍须专门制作遮罩／前景图，不能仅靠换整图实现。

## 运行与制作

002 新增 `photo_foil_strength`（0～1，默认 0 保持旧卡外观，样本 0.65），采用照片区域遮罩和柔和 Screen 混合，扫光随视角移动，不自动闪烁。照片窗口留边不着色。预览“照片光”调用 `set_photo_effects_enabled`，“框流光”调用 `set_frame_effects_enabled`，相互独立；原有 `set_effects_enabled` 仍是程序总开关。“原图”入口始终不加镀膜效果。

PowerShell 7，在项目根执行：

```powershell
./run-holo-card.ps1
./run-holo-card.ps1 -Mode Check
./run-holo-card.ps1 -Card res://你的卡牌.tres
./run-holo-card.ps1 -Mode Layers
./tools/art/holo_card/build-blender.ps1 -Python 'C:/Users/SongJun/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
```

可通过 `-Godot`、`-Blender` 覆盖本机工具路径。Layers 目前专用于本次样本，输出到样本的 ruic/assets；它不是批量生产命令。Blender 脚本可通过 `-CardDirectory` 指定另一套已准备的四图层目录。候选被批准后需要修改时创建新编号，不覆盖获批版本。

运行时只依赖项目 Godot、字体／Token 和原图，不加载 Blender、GLB、Three.js、浏览器或插件。每张活动卡使用一个 1600×1400 的静态 SubViewport 加一个 CanvasItem shader；大量列表应使用普通缩略图，点击详情才创建效果卡，未验证大量并发卡性能。

离线 RuiC 路线需要 Blender 4.5.x（实测 4.5.14 LTS）、Python + Pillow。包装器调用固定上游脚本，再修正横向卡比例及原照材质，隔离 Blender 用户配置。产出四图层、可编辑 blend、三视角渲染和几何 GLB。GLB 不是 Godot 最终效果资产；上游 Web shader 不包含在 GLB 内，不能将导入 GLB 等同于全息效果还原。

这次迁移保留全息卡的交互意图，不保证 Cycles／浏览器逐像素一致；没有运行上游 Three.js 页面。ruic 和工具目录均有 .gdignore，避免离线源文件参与 Godot 导入。上游 verification.json 是包装适配前报告；adapter-report.json 与最终 renders 才对应适配后结果。

## 验证范围

Windows Godot 4.7.2 Compatibility 实际渲染通过；四种窗口尺寸、两向倾斜、流光开关、静态、竖图替换、实例隔离和模拟触摸均有证据。实际手机触控、Web 导出、性能预算和正式主界面接入尚未验收。小屏卡内文字偏小，预览另提供标题与原图入口；正式列表不应把卡内小字作为唯一信息。
