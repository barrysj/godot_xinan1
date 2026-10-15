# 美术与工具验证

当前对象由[主Manifest](../../assets/art/asset_manifest.yaml)索引；格式与工具参数归[资源台](../../tools/art/asset_manager/README.md)和[工具目录](../../tools/art/README.md)。

## 可重跑入口

```powershell
py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v
node --check tools/art/asset_manager/static/app.js
pwsh.exe -File tools/art/run-motion-preview.ps1 -EnsureImport -Check
py -3 tools/art/promotion/promote_animation.py guard --variant asset_002 --check
```

Python需具备项目工具要求的版本／依赖，本机PATH中的python可能为旧版本；可显式指定Python3。资源台AssetCatalog.scan应无missing／mismatch／errors，批准和试接入状态保持。普通预览不生成GIF；制作使用显式ExportPreviews。

## 当前证据

2026-10-11、资源台施工基线`0e117af`：`py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v` 45项通过，`node --check tools/art/asset_manager/static/app.js`、`git diff --check`通过；完整扫描54对象／2042去重文件，missing／mismatch／errors均0。默认`scan()`保留完整校验；浏览显式`validate=False`，回归确认不计算哈希、更新后完整校验仍发现复制差异。

本机Python3.7、同一数据集cProfile计时：原加载8.703秒，改后轻量目录1.083秒（普通无profiler样本0.826秒）；完整校验普通样本4.011秒。首屏JSON序列化测量从3421989降至22024字节；52份首图总量255.954MiB，480px浏览缓存／WebP回退共11.650MiB，约减少95.4%。这是目录和全套媒体体积，不把它当作浏览器整页耗时或所有硬件承诺；冷缓存仍须按需解码大图。

真实浏览器完成名称搜索、版本按需展开、角色近战GIF切换、完整校验真实计数进度；1920×1080、2560×1440、1920×1200画面检查。截图为`.godot/art-workflow/asset-desk/`临时证据，不入Git。未重新构建控制器或启动Godot预览；预览目标再次核验由Python回归覆盖。用户要求同时纳入当前地图布局，主工作目录JSON原字节复制，SHA-256 `37aa8a257c550e76d25c6b2160efbe0a1a84f6dfca9a3846cd4cb04732878b6b`；地图编辑器12项通过，未把数据登记当作新战役玩法验收。

2026-10-10、地图回退ed4d275＋人物c3dc5c2合并树：资源台40项、Node12项通过；扫描整理前54对象／2383登记文件无缺失／不一致／索引错误。五人正式包提升核验、七态预览、正式模型重开和许可保留；真实战斗／状态联合结果见[战斗验证](../combat/verification.md)。最新源包与正式帧由Manifest定位，逐次生成记录不再作为活动入口。

## 闪卡

tools/art/run-holo-card.ps1 -Mode Check、scenes/holo_card/check_tilt_direction.tscn以及scenes/codex/holo_card_check.tscn／holo_catalog_check.tscn覆盖四向倾斜、换图、集合发现与图鉴详情。Mode Check尚未包含四向专项；样本／四向检查过程输出在.godot/art-review，不作为永久记录。日常review用render-review.ps1显式生成，制作步骤与边界见[闪卡说明](holo-cards.md)。未验批量性能、手机和最新Web。

## 清理核验

本分支核对最终文件路径、依赖、来源文档和状态，不生成新美术、不改变运行画面、不把静态整理当接入审批。

2026-10-10目录整理（e1b6281之后）：扫描54对象／2042文件，missing／mismatch／errors均0；保留版本的selection／approval／integration与整理前相同。502份运行图片／模型／矢量／字体逐文件哈希不变。校园源包三份Blender只读重开，无外部依赖缺失；高清5400×4500和Web1800×1500三态与登记输出一致。

源包验证可在项目根重跑：

```powershell
& 'E:/Games/SteamLibrary/steamapps/common/Blender/blender.exe' -b -t 2 --python-exit-code 1 --python design/concepts/environments/campus-map/campus-map/asset_002/verify_bundle.py
```

生成文档保留原始生成／编辑提示词、必要输入关系及最终参数入口；五套由动作JSON派生的重复Markdown已移除，生成工具不再重建它们，七动作JSON及输入参数保持。仍被源包预览引用的旧版本作为技术依赖保留，不作为过程档案。整理不删除Git中的素材历史；按负责人授权把两个整理提交重放到main，重放前后文件树相同，用户布局未修改。

本分支工具复验：资源台40项、文档检查器5项通过；敌人源包契约13160／0，原战斗人物38／0和五正式包／0。通用motion-preview的施法抓取检查仍有1项失败，使用未改动正式资源及预设也能复现；这是现有检查／时序边界，不以其他通过结果覆盖。依赖加载单独核验，不把目录整理宣称为全动作预览通过。编辑器导入在受限环境保存用户设置时报权限错误；后续直接console核验完成，不改系统配置。

Godot直接加载搬迁后的粉笔帧包／混合包、弹体、两份闪卡和四份探索预览，共11个资源／0失败；2211条资源路径核对未发现本次迁移新增缺失。已清理残余JSON中的旧文档指向及重复留存对话，最终批准／接入授权、来源许可和机器运行参数保留。

## 生成配方与浏览预览保留

2026-10-10，代码基线main的2e520dd，整理基线d08ba91：核对99份保留生成文档／调用文件，补回原始提示词及制作依据，摘要维持摘要，机器可读调用中的14份提示词完整保留。保留版本在main中登记的1316份媒体文件全部存在，图像／GIF内容与基线一致，预览GIF入口未减少；资源台54对象／2042文件、missing／mismatch／errors均0。

规则见[源资料与版本](WORKFLOW.md#源资料与版本)。.gitignore覆盖.godot/art-workflow、旧codex-workflow中间文件及旧工具的质量报告，保留三个已有演示GIF例外；交付预览与生成配方不被忽略。本次只修改文档及忽略规则，原图、运行资产、生成参数和Manifest未改变，不重新宣称视觉／施法预览验收通过。

## 校园地图补景与旧版清理

2026-10-12，施工基线5042aae，基于asset_004制作asset_005。修正扩展地面3072面、道路3064面的朝向；共享地面采用连续世界坐标的柔和色调变化与一致向上着色。异常态保留原深色／发光材质链，在其上乘入轻微变化。右上角接通6组对应道路断口，以一条弯道和两条支路衔接外围；两侧接缝补18栋简单建筑，共新增19对象、1382面。平面重叠检查确认新道路不穿过已有建筑，18栋新增建筑避开道路。

三态原对象位置、顶点及核心网格拓扑逐一保持，相机参数不变；外围地面／道路只调整面朝向。source/seams/preservation.json记录9403／9453／9467个原对象核验，场景分别增加19对象。用户布局JSON SHA-256保持37aa8a257c550e76d25c6b2160efbe0a1a84f6dfca9a3846cd4cb04732878b6b。

源包入口：design/concepts/environments/campus-map/campus-map/asset_005。render.py输出桌面7680×3600／48 samples，--web输出3200×1500／24 samples，Blender4.5.14／Cycles／OptiX；采用512像素分块降低显存压力。三态自包含工程直接可编辑，不依赖旧完整源包。

```powershell
& 'E:/Games/SteamLibrary/steamapps/common/Blender/blender.exe' -b -t 2 --python-exit-code 1 --python design/concepts/environments/campus-map/campus-map/asset_005/verify_bundle.py
& 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe' --path . --rendering-method gl_compatibility res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check
```

最终高清与小尺寸三态各通过220／0检查，覆盖1920×1080／2560×1440／1920×1200、两侧实际纹理与画布覆盖、缩放／拖动／复位、点击与选区。六张实际导入纹理的尺寸和基础层像素与PNG逐字节一致；平台映射33／0。Blender源包检查通过，三态9422／9472／9486对象，无缺失外部依赖，058集合数量／面数、外围面朝向、原异常材质链与相机宽度均符合配方。最终runtime三张1920×1080截图来自高清底图。

沿用原地图组件、shader纹理原点与编辑器适配，未改游戏逻辑、路线或存档。原双路线的兼容投影仍是现用依赖，其670／0及编辑器12项是e88bc48的已有结果，本轮不冒充重跑。

旧源包中的26份必要制作输入已逐字节保留，新增端点、网格、参数和施工／重叠核验脚本随source/seams保留。按既有授权删除旧asset_004和tmp_008，只保留asset_005完整源包；不重写Git历史。AssetCatalog扫描54对象／2073文件，缺失／不一致／错误均0，资源台45项测试通过。文档链接和Git差异检查通过；临时试渲染、检查截图及本轮工作缓存在收尾清理，最终预览与必要制作依据随源包保留。

Godot编辑器导入与三态实际运行正常退出0；仍有用户设置保存权限、Android编辑器设置销毁和根证书读取的环境告警，未阻断截图和像素核验。临时小尺寸／像素检查直接读取PNG产生export警告，正式组件使用导入资源。本版授权试接入，视觉效果待负责人复核，不继承上一版批准。Web验收限于原组件低分辨率显示、图片导入与平台映射，不包含新浏览器导出或移动设备；超过32:15仍回退匹配底色。

### 夜间／异常亮区

2026-10-12，基线9860507。沿用上述Godot expanded-map-check命令，三态×1920×1080／2560×1440／1920×1200共220检查、0失败；node --test tools/campus-map-editor/editor-core.test.mjs为6项、0失败。查看两态未选区截图和夜间16:10选区截图：外围退后，真实校园暗部更连续，路线高亮仍清楚。当前日间与保留基线截图逐像素比较仅2像素最大通道差1/255，属着色计算舍入，视觉保持。

夜间／异常runtime预览随asset_005更新；三态Blender、两档底图未修改。image-quality-check复核PASS_WITH_NOTES：技术、主体、内容、构图和伪影检查通过，解剖不适用；异常右侧亮区内既有光斑仍可见，边界附近原材质差异未完全消除。未重新导出Web或验证移动设备。运行有根证书和shader缓存写入权限告警，进程正常退出0。

### 两处指定道路补全

2026-10-12，基线b16bb30，当前源包asset_006。用户确认坐标来自地图编辑器：(95,914)处四条边带接入最近横向道路，(989,54)处四条边带按原端点切线缓弯连接。三态各新增059道路对象1个、946面；已有9422／9472／9486个对象的变换、网格顶点与拓扑指纹和相机保持。几何贴地未覆盖面积0、建筑重叠0；原36份source输入逐字节保留，新增6份制作依据随source/road-completion保留。

重跑入口沿用expanded-map-check，源包核验改为asset_006/verify_bundle.py。高清与小尺寸在原地图组件分别220检查／0失败，覆盖三态、1920×1080／2560×1440／1920×1200与缩放、拖动、点击、选区；最终保留的runtime截图来自高清底图。Blender三态只读重开、自包含依赖、059面数与法线、三态两档源图与运行图逐字节相等均通过。资源台54对象／2079文件，missing／mismatch／errors均0；docs检查192文档／41功能／855链接，0错误。布局JSON及亮区两份代码与b16bb30一致，布局SHA-256为dafbd8e8eb8c1a2efec18794a620e6f27402d73739500653b0a0b9bbec26bd73。

两处道路视觉复查通过，无新增建筑穿插，夜间／异常外围仍较暗；新增道路为授权试接入、待负责人复核。按已有留存授权删除asset_005，仅保留asset_006整套，必要源输入和预览继续登记，不改Git历史。Web验证限原生组件的小尺寸图，不包括浏览器导出或手机。Godot原生运行仍有根证书／shader缓存权限告警；临时SceneTree小尺寸检查还触发GGT插件current_scene为空的启动异常，但地图脚本完成220项、进程退出0；正式场景高清检查无该脚本异常。编辑器导入仍有用户设置保存／Android退出设置环境告警，退出0。

## 派遣与准备页面统一

2026-10-14，6a4b0be后：派遣地图／材质／三名后勤、四种准备物品和分析员绘制立绘接入原主线。来源和授权边界分别见[派遣白板](ui/dispatch-board.md)、[分析员](characters/analyst.md)及相应Manifest。三种桌面分辨率实机通过，准备页按钮边界、派遣地图等比、往返演出和结算层通过；两人出发、招募和完整战役验证见[META-02](../progression/meta-02.md#本次整体接入收尾)。资源台59对象／2106文件，缺失／不一致／错误均0；动画和表现回归PASS。原始生成输入链保留，不升级为逐图人工批准。未重绘全部原控件与战斗特效，未验浏览器或移动导出。
