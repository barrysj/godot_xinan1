# 战斗组件正式候选 tmp_002

依据：2026-10-07 用户“看起来不错，生成正式资产吧”，批准 tmp_001/styleboard.png 的视觉方向。上一轮概念由 image_gen 生成；本轮正式资产按该方向用可编辑 SVG 原生几何制作，未裁切或修改概念位图，未使用外部图标包。

来源：data/visual/colors.json；resources/combat/code_rules.tres；code_resource_glyph.gd。界面字体沿用项目 SourceHanSansSC-Medium，预览借用现有 battle_courtyard/day.png；字体与背景不包含在正式组件运行子集中。

正式运行子集为 frames/、icons/、png/、styles/，frames.json、icons/icons.json 与 components.json 给出精确尺寸及用途。所有 SVG 均透明且无文字，PNG 为 Godot 对同一源文件的 2 倍栅格化，非 AI 重绘。SVG 为首选源，不必同时装载 PNG。

## 预览与重建

在项目根执行 Godot --path . --rendering-method gl_compatibility res://design/concepts/battle-status-components/hud-family/asset_001/review.tscn。

review.gd 从当前目录载入源 SVG，校验 Alpha、导出 PNG 与 validation.json，并渲染三个窗口尺寸的 review 图片。预览只是资产 QA，不会创建战役或读写存档。author_frames.py 可重建边框源，图标源即 icons/*.svg。批准留存后目录改名时只需更新此命令路径，脚本资源引用均相对目录。

## 状态

正式资产候选，等待人工评审；尚未提升、未接入。技术通过不能代替资产批准。tmp_001 两张概念图完整保留，未将方向批准推定为删稿授权。


## 实际验收

Godot 4.7.2 Compatibility 渲染26 SVG与对应26张2×PNG，Alpha范围均0..255，尺寸逐项匹配、XML无文字/外部图片/script。三尺寸1920×1080、2560×1440、1920×1200输出review图，已检查20逻辑px意图以及亮暗背景。原生隔离导入26个SVG，并直接加载15个边框纹理与8份StyleBoxTexture，尺寸和九宫格全部通过；真实结果为import-validation.json。

首次独立SceneTree预览触发现有GGT插件current_scene为空，已换正常review.tscn；最终预览无脚本错误。原生SVG保持Godot默认1×，交付.tres的texture_margin和content_margin均使用逻辑像素；2×PNG供显式目标Rect绘制，不能直接替换.tres中的SVG。预览PNG包含排版说明，属于证据，不属于正式运行纹理。没有新增安装依赖。

2026-10-08 留存收尾：当前套件留存为asset_001；源SVG／PNG／样式未修改，运行引用仍为assets/art/ui/battle_status。已批准概念为concept_001；旧草稿和重复ZIP按用户留存决定删除。资产与接入视觉效果仍待评审，留存不等于批准。旧临时目录说明为历史记录，不是活动路径。
