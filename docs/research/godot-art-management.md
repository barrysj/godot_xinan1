# Godot 美术资产管理调研

核实日期：2026-09-14。本文件记录方案比较，不代表已采用或安装；未在本项目 Windows Godot 4.7 中实测。玩法 Resource 表格与剧情录入工具另见 [Godot 内容录入工具调研](godot-content-tools.md)。

## 官方能力与需求边界

Godot 官方建议利用普通文件系统组织关联资产，没有要求另建资产数据库。其 FileSystem 面板适合查看和引用当前项目资源；按一个角色或对象归组文件，符合这种组织思路。官方还说明 `.gdignore` 会停止目录资源导入，同时将其从 FileSystem 面板隐藏，且不能再通过 `load()` / `preload()` 加载。因此被忽略的历史目录应交给系统图库或外部浏览器查看，不能承诺编辑器内仍可浏览。[官方项目组织文档](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)

## 社区候选

| 工具 | 已核实用途 | 对本项目的适用判断 |
|---|---|---|
| FileSystem Dock Tooltips | 扩充编辑器悬停预览，包括字体、Theme、StyleBox、SpriteFrames 等；SpriteFrames 展示若干帧及动画名称、帧数和 FPS。普通纹理和音频沿用 Godot 已有预览。作者标注 Godot 4.5+、MIT；当前下载页明确标记版本不稳定。 | 可改善查看已接入资源，但不是历史版本图库，也没有在所查说明中提供审批或并排版本比较。对只想看 PNG 的用户增益有限，暂不列为必要安装项。 |
| AssetPlus | 聚合 AssetLib、Godot Store 与 Godot Shaders，提供选择性安装、跨项目收藏和个人资源包库；作者定位 Godot 4.x。 | 适合获取和跨项目复用资源包。所查 README 未提供同一美术资产历版比较、审批与本项目 Manifest 写回能力，不应把它推荐成目前所需的本地评审工具。 |

来源：[FileSystem Dock Tooltips 作者发布页](https://store.godotengine.org/asset/tobias-lawrenz/filesystem-dock-tooltips/)、[AssetPlus 作者仓库](https://github.com/moongdevstudio/AssetPlus/)。以上“适用判断”是根据公开功能作出的工程判断，不是安装验收结论。

## 编号历史目录的建议

每个独立资产一个目录、历史按 `001`、`002`、`003` 保存，适合当前单人开发与人工看图。建议保留一个稳定的当前游戏引用位置，编号目录保存完整版本所需的图片及配套信息；最高编号只表示最新生成，不自动表示已批准或正在使用。多文件动画必须按完整版本保存，避免新旧帧、锚点或帧率混用。

Manifest 继续由 Codex 维护机器所需的路径与状态；用户通过带名称、版本号和当前使用标记的图片参与评审，不要求阅读 YAML。目录方案及预览工具仍需用户决定后再实施，本次未迁移资产、改变批准状态或安装插件。
