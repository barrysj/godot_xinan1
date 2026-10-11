# 美术与工具验证

当前对象由[主Manifest](../../assets/art/asset_manifest.yaml)索引；格式与工具参数归[资源台](../../tools/art/asset_manager/README.md)和[工具目录](../../tools/art/README.md)。

## 可重跑入口

```powershell
py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v
node --check tools/art/asset_manager/static/app.js
pwsh.exe -File run-motion-preview.ps1 -EnsureImport -Check
py -3 tools/art/promotion/promote_animation.py guard --variant asset_002 --check
```

Python需具备项目工具要求的版本／依赖，本机PATH中的python可能为旧版本；可显式指定Python3。资源台AssetCatalog.scan应无missing／mismatch／errors，批准和试接入状态保持。普通预览不生成GIF；制作使用显式ExportPreviews。

## 当前证据

2026-10-11、资源台施工基线`0e117af`：`py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v` 45项通过，`node --check tools/art/asset_manager/static/app.js`、`git diff --check`通过；完整扫描54对象／2042去重文件，missing／mismatch／errors均0。默认`scan()`保留完整校验；浏览显式`validate=False`，回归确认不计算哈希、更新后完整校验仍发现复制差异。

本机Python3.7、同一数据集cProfile计时：原加载8.703秒，改后轻量目录1.083秒（普通无profiler样本0.826秒）；完整校验普通样本4.011秒。首屏JSON序列化测量从3421989降至22024字节；52份首图总量255.954MiB，480px浏览缓存／WebP回退共11.650MiB，约减少95.4%。这是目录和全套媒体体积，不把它当作浏览器整页耗时或所有硬件承诺；冷缓存仍须按需解码大图。

真实浏览器完成名称搜索、版本按需展开、角色近战GIF切换、完整校验真实计数进度；1920×1080、2560×1440、1920×1200画面检查。截图为`.godot/art-workflow/asset-desk/`临时证据，不入Git。未重新构建控制器或启动Godot预览；预览目标再次核验由Python回归覆盖。用户要求同时纳入当前地图布局，主工作目录JSON原字节复制，SHA-256 `37aa8a257c550e76d25c6b2160efbe0a1a84f6dfca9a3846cd4cb04732878b6b`；地图编辑器12项通过，未把数据登记当作新战役玩法验收。

2026-10-10、地图回退ed4d275＋人物c3dc5c2合并树：资源台40项、Node12项通过；扫描整理前54对象／2383登记文件无缺失／不一致／索引错误。五人正式包提升核验、七态预览、正式模型重开和许可保留；真实战斗／状态联合结果见[战斗验证](../combat/verification.md)。最新源包与正式帧由Manifest定位，逐次生成记录不再作为活动入口。

## 闪卡

run-holo-card.ps1 -Mode Check、scenes/holo_card/check_tilt_direction.tscn以及scenes/codex/holo_card_check.tscn／holo_catalog_check.tscn覆盖四向倾斜、换图、集合发现与图鉴详情。Mode Check尚未包含四向专项；样本／四向检查过程输出在.godot/art-review，不作为永久记录。日常review用render-review.ps1显式生成，制作步骤与边界见[闪卡说明](holo-cards.md)。未验批量性能、手机和最新Web。

## 清理核验

本分支核对最终文件路径、依赖、来源文档和状态，不生成新美术、不改变运行画面、不把静态整理当接入审批。

2026-10-10目录整理（e1b6281之后）：扫描54对象／2042文件，missing／mismatch／errors均0；保留版本的selection／approval／integration与整理前相同。502份运行图片／模型／矢量／字体逐文件哈希不变。校园源包三份Blender只读重开，无外部依赖缺失；高清5400×4500和Web1800×1500三态与登记输出一致。

源包验证可在项目根重跑：

```powershell
& 'E:/Games/SteamLibrary/steamapps/common/Blender/blender.exe' -b -t 2 --python-exit-code 1 --python design/concepts/environments/campus-map/campus-map/asset_001/verify_bundle.py
```

生成文档保留原始生成／编辑提示词、必要输入关系及最终参数入口；五套由动作JSON派生的重复Markdown已移除，生成工具不再重建它们，七动作JSON及输入参数保持。仍被源包预览引用的旧版本作为技术依赖保留，不作为过程档案。整理不删除Git中的素材历史；按负责人授权把两个整理提交重放到main，重放前后文件树相同，用户布局未修改。

本分支工具复验：资源台40项、文档检查器5项通过；敌人源包契约13160／0，原战斗人物38／0和五正式包／0。通用motion-preview的施法抓取检查仍有1项失败，使用未改动正式资源及预设也能复现；这是现有检查／时序边界，不以其他通过结果覆盖。依赖加载单独核验，不把目录整理宣称为全动作预览通过。编辑器导入在受限环境保存用户设置时报权限错误；后续直接console核验完成，不改系统配置。

Godot直接加载搬迁后的粉笔帧包／混合包、弹体、两份闪卡和四份探索预览，共11个资源／0失败；2211条资源路径核对未发现本次迁移新增缺失。已清理残余JSON中的旧文档指向及重复留存对话，最终批准／接入授权、来源许可和机器运行参数保留。

## 生成配方与浏览预览保留

2026-10-10，代码基线main的2e520dd，整理基线d08ba91：核对99份保留生成文档／调用文件，补回原始提示词及制作依据，摘要维持摘要，机器可读调用中的14份提示词完整保留。保留版本在main中登记的1316份媒体文件全部存在，图像／GIF内容与基线一致，预览GIF入口未减少；资源台54对象／2042文件、missing／mismatch／errors均0。

规则见[源资料与版本](WORKFLOW.md#源资料与版本)。.gitignore覆盖.godot/art-workflow、旧codex-workflow中间文件及旧工具的质量报告，保留三个已有演示GIF例外；交付预览与生成配方不被忽略。本次只修改文档及忽略规则，原图、运行资产、生成参数和Manifest未改变，不重新宣称视觉／施法预览验收通过。
