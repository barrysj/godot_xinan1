# 地点场景导航 · asset_001

制作要求：地点支持多张场景图，点击 UI 切换；小地图表达相对位置，以颜色区分高度和楼层。用户于 2026-10-11 明确豁免本次切换 UI 资源审批，授权制作、保留和接入。

生产方式：Codex 手写 SVG 几何，未调用生图模型，无随机种子或图像参考输入。保留的 next.svg、previous.svg、scene.svg 即完整可编辑源文件；32×32 透明画布、白色单色线条，运行时由共享 Token 派生的楼层颜色调制。箭头表达切换，线框立方体表达场景空间。

源 SVG 原样复制至 assets/art/ui/place_scenes/，Godot 原生导入；无裁切、位图缩放或其他后处理。底板、焦点、选中态与地图网格由 scenes/expedition/place_scene_navigation.gd 和既有 CampusUi 绘制，颜色事实源为 data/visual/colors.json，不复制样式参数。preview.png 为原玩家界面实际截图，由 place_scenes_check.tscn -- --capture 生成并原样复制。

图书馆背景均复用既有资源，未重绘，原批准状态不变。楼层和相对位置是可编辑玩法示意，不是建筑测绘。
