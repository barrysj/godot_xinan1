# 地点通行热点 · asset_002

2026-10-11 制作要求：移除场景栏“上一处／下一处”，底板按内容收拢，左侧标注“探索场景”；增加点击后进入后续场景或离开地点的热点。沿用本任务用户已明确豁免审批的 UI 制作授权。

passage.svg 为 Codex 手写的 128×128 透明原生 SVG：门框与向右箭头、深色底及青色／白色线条。文件本身是完整可编辑几何源，无生图模型、种子或参考图输入；色彩依据 data/visual/colors.json 的既有品牌与夜间颜色。原样复制到 assets/art/ui/place_scenes/passage.svg，无裁切或位图处理。scene.svg 沿用 asset_001 的源文件，不修改已有图书馆背景。

动作、焦点、悬停沿用 exploration_hotspot.gd；禁用态降低图标亮度，passage_hotspot.gd 绘制锁和目的地短标签。原生场景栏尺寸由 place_scene_navigation.gd 按标题及按钮内容计算，超过画板宽度才滚动。preview.png 是 place_scenes_check.tscn -- --capture 产生的实机截图，未做图片后处理。上一版源包保留，Manifest 的现用版本为 asset_002。
