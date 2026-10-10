# 可复用照片闪卡

本能力不绑定某个里程碑。已接入主游戏“图鉴 → 闪卡”，保留独立预览；人工评审见[合照卡任务](holo-cards.md)。

## 当前能力与实现

已完成原照保留、原生卡框、边框虹彩与照片镀膜、独立开关、四向倾斜修正、共享卡片组件、集合登记及可复用截图。`5b8728d` 接入图鉴第六页“闪卡”：静态缩略图点击打开实时详情，支持鼠标、拖动和方向键；Esc 先返回列表，下一次退出图鉴。详情关闭释放渲染实例，不在列表逐卡渲染。自动发现由 `game/art/holo_card_catalog.gd` 提供。

| 层次 | 实现入口 | 职责 |
| --- | --- | --- |
| 每卡内容 | `assets/art/holo_cards/<id>/card.tres`；`game/art/holo_card_visual.gd` | 引用原图、四项文案及效果强度；共享 Resource 文案默认值为空 |
| 版式与交互 | `scenes/holo_card/card_art.gd`、`holo_card_view.gd/tscn` | 在静态 SubViewport 绘制卡框、文字与原照，管理尺寸、输入及每实例材质 |
| GPU 效果 | `scenes/holo_card/holo_card.gdshader` | 对卡面做视角变换、边框虹彩和照片区域镀膜；随视角变化而非时间闪烁 |
| 图片交付 | `tools/art/holo_card/render-review.ps1` → `scenes/holo_card/render_review.tscn` | 加载同份资源、固定正面、实际渲染并覆盖同目录 review.png，不带预览界面 |
| 资产浏览 | `tools/art/asset_manager/catalog.py`、`server.py`、`static/app.js` | 在登记集合内发现资源，解析文案和引用，展示 review/原图，向 Godot 传递同一资源路径 |

`card.tres → 共享组件 → 游戏效果／review.png`；资源台读取同份 `.tres` 和已生成 PNG，不维护另一份卡片文案，不在游戏内加载 YAML。

**自动发现边界：**游戏每次进入闪卡页以 `ResourceLoader.list_directory` 枚举固定目录的直接子目录，按目录名排序，再加载 `card.tres`；类型错误或缺照片跳过，缺 review 回退原图。资源台仍由 Manifest 登记同一目录，不需要逐卡索引。使用 [Godot 的资源枚举接口](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html#class-resourceloader-method-list-directory) 保留导出后的逻辑路径，已验证项目外运行 PCK 可发现当前卡。新增图片先经编辑器或截图脚本导入，重新进入页即可发现；导出游戏必须重新构建并包含卡资源，不能向已发布 exe 旁放图实现热更新。无解锁和存档逻辑，不承诺手机/Web或大量卡片性能。

## 换图与复用

### 当前最简流程（2026-09-16）

活动卡统一放在 `assets/art/holo_cards/<id>/`：`photo.jpg` 是原图，`card.tres` 是图片引用与文案的唯一事实源，`review.png` 是 Godot 实际正面流光截图。Godot 自动生成的 `.import` / `.uid` 元数据另行保留。无需 Blender，也无需每卡单独 Manifest 或 concept/asset 阶段。

用户提供原图和文案即可由 Codex 制作。创建新 ID 目录，复制样本 `card.tres`（不要复制旧 `.import` 的资源身份），放入原图并修改图片路径及 `title`、`subtitle`、`caption`、`edition`；文字使用短句，缺少必要文案时询问或明确标为草案，不冒充用户原文。照片流光按样本的 `photo_foil_strength = 0.65` 起步；新建空 Resource 默认是 0，仅开边框光。然后执行：

优先使用技能中的 [card.tres 模板](../../.agents/skills/art-implementation/assets/holo_card/card.tres)，替换 `REPLACE_CARD_ID` 与文案，放到对应活动卡目录；模板自身不进入游戏扫描范围。现有导出预设为 all_resources，可包含新增活动卡；若以后改为选择性导出，必须显式包含整个卡目录与依赖，并重新跑 PCK 检查。

```powershell
./tools/art/holo_card/render-review.ps1 -Card res://assets/art/holo_cards/class_photo/card.tres -Godot '你的 Godot 可执行文件'
```

也可通过 `GODOT_PATH` 指定引擎。默认先导入；已导入且只调整文案时可加 `-SkipImport`。脚本用真实 Compatibility 渲染器生成 1600×1400、固定正面、无调试 UI 的截图；照片与边框效果打开，强度取自资源。不可用 headless 替代截图渲染。输出覆盖同目录 `review.png`；改图、文案或共享特效后应重新运行，浏览工具不会自动重绘或判断截图新旧。

主 Manifest 只登记一次集合：

```yaml
objects:
  holo_cards:
    type: holo_card
    root: assets/art/holo_cards
```

资源台仅发现该集合下一层的 `*/card.tres`，读取同份文案，以 `review.png` 作缩略图，保留原图查看与 Godot 预览。刷新扫描即可发现新卡；缺图、缺截图会提示。图片引用必须留在对应卡目录内。普通对象沿用原 Manifest 流程。

完成后查看实际 review，核对文字、原照完整性、流光和默认角度；资源台刷新校验，确认以 review 为缩略图，预览传入同份资源。更换内容不需要修改共享 shader。修改已有卡时以 Git 追溯旧版，不额外建立每卡阶段文档；保留必要的原图来源和使用范围说明。

下面的 001/002 与 Blender 路线是历史实验记录，不是新增卡片的必经步骤。活动默认预览已指向 `assets/art/holo_cards/class_photo/card.tres`。

### 在 Godot 中复用组件

1. 使用最简流程制作的 `assets/art/holo_cards/<id>/card.tres`。历史 001 是仅边框流光版本，002 新增照片镀膜扫光；两者留存对照，不作为新的活动目录。
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

可通过 `-Godot`、`-Blender` 覆盖本机工具路径。Layers 目前专用于历史样本，输出到样本的 ruic/assets；它不是新卡生产命令。Blender 脚本可通过 `-CardDirectory` 指定另一套已准备的四图层目录。历史编号候选不覆盖；活动卡使用上述稳定目录与 Git 追溯。

运行时只依赖项目 Godot、字体／Token 和原图，不加载 Blender、GLB、Three.js、浏览器或插件。每张活动卡使用一个 1600×1400 的静态 SubViewport 加一个 CanvasItem shader；大量列表应使用普通缩略图，点击详情才创建效果卡，未验证大量并发卡性能。

离线 RuiC 路线需要 Blender 4.5.x（实测 4.5.14 LTS）、Python + Pillow。包装器调用固定上游脚本，再修正横向卡比例及原照材质，隔离 Blender 用户配置。产出四图层、可编辑 blend、三视角渲染和几何 GLB。GLB 不是 Godot 最终效果资产；上游 Web shader 不包含在 GLB 内，不能将导入 GLB 等同于全息效果还原。

这次迁移保留全息卡的交互意图，不保证 Cycles／浏览器逐像素一致；没有运行上游 Three.js 页面。ruic 和工具目录均有 .gdignore，避免离线源文件参与 Godot 导入。上游 verification.json 是包装适配前报告；adapter-report.json 与最终 renders 才对应适配后结果。

## 验证范围

2026-09-16 图鉴与自动发现：`scenes/codex/holo_card_check.tscn` 实际渲染三种桌面窗口、检查开关页与 Esc；`menu.tscn -- --codex-check` 覆盖菜单/暂停里的闪卡打开、原35项浏览和战斗冻结恢复；`scenes/codex/holo_catalog_check.tscn` 覆盖实际集合、隔离新增、排序、空集合、错误资源跳过及模板替换后加载。导出 Windows Desktop PCK 后从项目外用 `--main-pack <pck>` 运行目录检查 PASS。截图位于 `.godot/holo-detail-*.png`、`.godot/holo-list.png`。打包仍有原项目 EditorSettings 退出错误提示，运行检查通过；不等于整个游戏导出验收。

`dc8da12`：资源台 25 项测试通过，实际页面 9 对象／102 登记文件／0 不一致；截图脚本实际输出 1600×1400 PNG，重复生成 SHA256 一致，预览进程参数核对为活动卡资源。命令：`py -3 -B -m unittest discover -s tools/art/asset_manager/tests`。这是已记录的实现验证，不表示每次文档更新都重跑引擎。

新增内容至少重建并查看 review、检查资源台引用与独立预览；修改共享效果还应运行 `run-holo-card.ps1 -Mode Check` 及 `scenes/holo_card/check_tilt_direction.tscn` 四向检查。后者尚未包含在 Mode Check 中；样本预览和四向检查的临时证据输出到.godot/art-review/holo-card-sample，不登记过程截图。截图脚本失败要查看日志并核对输出，不将既有 PNG 当成本次成功结果。

Windows Godot 4.7.2 Compatibility 实际渲染通过；四种窗口尺寸、两向倾斜、流光开关、静态、竖图替换、实例隔离和模拟触摸均有证据。实际手机触控、Web 导出、性能预算和批量性能与最终发布适配尚未验收。小屏卡内文字偏小，预览另提供标题与原图入口；正式列表不应把卡内小字作为唯一信息。



## 合照样本与来源

活动卡位于 `assets/art/holo_cards/class_photo/`，由主 Manifest 的集合目录自动发现；共享模板位于 `assets/holo_card/card.tres`。原照和文案只存于具体卡资源，不进入共享默认值。Godot 是日常制作、预览和 review 生成入口；RuiC／Blender 保留为可选离线支线，其许可证随工具保存。主游戏图鉴已有闪卡页，未接入回忆解锁或存档。照片公开使用范围仍需单独确认。小改动与初版审批过程不再作为活动文档。
