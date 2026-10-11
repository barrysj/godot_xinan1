# asset_006 · 校园地图道路补全三态源包

基于负责人确认效果的asset_005（b16bb30），补全地图编辑器坐标(95,914)、(989,54)对应道路。前者四条边带接入最近横向道路，后者四条边带以缓弯连接现有断口；新增059道路对象，共946面，无建筑碰撞。负责人于2026-10-12确认当前版并授权仅保留最新整套、squash合入本地main。

## 当前交付

- day.blend、night.blend、anomaly.blend：自包含可编辑工程。保留原校园、西北／西南补景和沿原道路延长的外围；修正057集合地面与道路向下面的朝向。
- 原地面与扩展地面共用连续世界坐标的低频色调变化和一致的向上着色法线，淡化导出分块造成的明暗接缝。保留三态原配色；异常态在原着色链上乘入轻微变化，保留深色地面和发光区域。
- 058集合补6组右上角对应道路断口、1条外围弯接道路及2条汇入支路，按实际地面分面贴合并绕开原有建筑；两侧接缝分散补18栋简单建筑，共19对象、1382面。外围是装饰性推演，不代表实测或新增玩法区域。
- 根目录三张PNG为7680×3600、Cycles／OptiX／48 samples；web/为3200×1500、24 samples实际渲染。runtime-*.png为原Godot组件1920×1080运行截图。
- source/保留西北／西南DXF、GLB、许可与实际输入链；continuation/为原道路延长的必要制作依据，seams/为本版端点、网格、脚本、配方与对象保持核验。

## 投影与接入

本轮相机、原对象位置与顶点、核心网格拓扑均不变。只调整外围地面／道路面朝向、共享地面材质及新增接缝对象，核验记录见source/seams/preservation.json。

逻辑核心1800×1500，宽图3200×1500，纹理原点(-700,0)。游戏继续使用assets/art/campus_map/expanded_neutral与assets/art/web_campus_map/expanded_neutral。原路线、用户亮区布局、缩放与点击坐标保持。支持当前16:9／16:10窗口；超过32:15回退匹配底色。Web／移动平台完整验收未完成。

## 重渲染与核验

在项目根使用PowerShell 7：

```powershell
& 'E:/Games/SteamLibrary/steamapps/common/Blender/blender.exe' -b -t 8 --python-exit-code 1 --python design/concepts/environments/campus-map/campus-map/asset_006/render.py
& 'E:/Games/SteamLibrary/steamapps/common/Blender/blender.exe' -b -t 8 --python-exit-code 1 --python design/concepts/environments/campus-map/campus-map/asset_006/render.py -- --web
& 'E:/Games/SteamLibrary/steamapps/common/Blender/blender.exe' -b -t 2 --python-exit-code 1 --python design/concepts/environments/campus-map/campus-map/asset_006/verify_bundle.py
```

三份最终工程可直接编辑和重渲染，无需旧工程。render.py使用512像素分块控制显存，分辨率和采样不变。施工脚本保留实际使用路径；精确重放seams施工时，从Git 5042aae恢复asset_004，将seams中的脚本及端点／范围输入放回.godot/art-workflow/seam-blending，提供Shapely2.2.0及Blender自带NumPy1.26.4，依次执行find_ends.py、prepare.py、build.py。prepare.py确定性生成网格，不使用随机种子。build.py输出tmp_008，--skip-preview可只保存工程；最终工程、网格和参数已随本包保留。

placement_check.py用同一Shapely环境检查新增道路与既有建筑的重叠。原continuation施工链使用Shapely2.2.0／NumPy2.4.6，需从Git bb2d7c7恢复asset_002；将其端点和范围输入放回.godot/art-workflow/road-continuation，将base-geometry.json放回.godot/art-workflow/northwest-southwest/geometry.json。历史脚本保留实际路径和参数，不作为日常编辑依赖。新增制作未使用AI位图生成，无模型／提示词调用需要补造。

沿用已确认留存范围：仅保留最新三态源包、各档游戏底图、最终预览和必要制作输入；旧完整源版本由Git追溯。另一投影的full-*和裁切图仍是原路线现用依赖。验证结果见[美术验证](../../../../../../docs/art/verification.md#校园地图补景与旧版清理)。

2026-10-12运行预览更新：夜间／异常截图包含Godot分态外围压暗、降饱和及校园暗部环境光。参数入口为expanded_campus_map.gd的LIGHT_TREATMENT及expanded_campus_layout.json；三态Blender与底图未因此重渲染。

## 两处道路制作依据

source/road-completion保留地图坐标、匹配端点、网格、生成／应用脚本和原对象保持核验。制作环境为Blender4.5.14与Python3.12／NumPy／Shapely2.2.0；从Git b16bb30恢复asset_005作为输入，将plan.py、prepare.py、build.py放回.godot/art-workflow/road-two-points，Shapely依赖放入其deps。依次运行plan.py、prepare.py及Blender内build.py，输出tmp_009，然后按render.py重渲染三态两档；日常编辑直接使用本包工程。左侧延长到最近横向道路的两条边带之间，避免更远处058建筑16；上方使用95世界单位控制柄保持端点切线。

新增网格覆盖核验无缺口、无建筑重叠；原对象变换和网格拓扑指纹、相机完全保持。亮区代码和布局沿用b16bb30。
