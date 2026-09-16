# 可复用照片卡

本能力不绑定某个里程碑。当前为独立预览原型，不改变主游戏流程；人工评审见[合照卡任务](tasks/class-photo-holo-card.md)。

## 换图与复用

### 当前最简流程（2026-09-16）

活动卡统一放在 `assets/art/holo_cards/<id>/`：`photo.jpg` 是原图，`card.tres` 是图片引用与文案的唯一事实源，`review.png` 是 Godot 实际正面流光截图。Godot 自动生成的 `.import` / `.uid` 元数据另行保留。无需 Blender，也无需每卡单独 Manifest 或 concept/asset 阶段。

复制 `assets/art/holo_cards/class_photo/` 到新 ID，替换原图，修改 `card.tres` 的图片路径和四项文案，再执行：

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

下面的 001/002 与 Blender 路线是历史实验记录，不是新增卡片的必经步骤。活动默认预览已指向 `assets/art/holo_cards/class_photo/card.tres`。

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

## 复用盘点与简化建议

以下为 2026-09-16 对实现基线 2587e92 的代码盘点与建议，尚未实施通用化重构。按 codebase-design 的小 Interface / 深 Module 原则分析：调用方应只提供卡内容、可选样式和显示状态，不应知道 shader uniform、SubViewport 或制作目录。

### 已完成改动

- 调研：d01b03e 的 RuiC 适用性文档，区分上游 Blender/Web 材质与 Godot 原生实现。
- 首版：3f28db6，原照保留、Resource 数据、原生卡框与 shader、倾斜与输入、预览和检查、可选 Blender 制作／GLB、Manifest 与工作流。
- 照片镀膜：3023205，002 共用原照，新增照片扫光和“照片光／框流光”独立控制，保留 001。
- 方向修复：2587e92，只反转 pitch，新增四向实际渲染回归。已确认窗口适配、开关隔离、换图、静态、模拟触摸；不将模拟检查写成真实设备验收。
- 没有替换主游戏界面、修改玩法／存档、增加玩家端 Blender 或 Three.js 依赖，也没有推送远程。

### 归属分类

| 类别 | 当前文件／内容 | 判断 |
| --- | --- | --- |
| 通用运行 Module | game/art/holo_card_visual.gd；scenes/holo_card 下 view.gd/tscn、gdshader | 已支持换图，但默认文案、类型约束和生命周期仍需收口 |
| 项目共享样式 | card_art.gd、项目字体、颜色和动画 Token | 可复用到同一校园风格，不能宣称任意比例／主题即插即用 |
| 待解耦的工具 | preview.gd/tscn、方向检查、run-holo-card.ps1 | 展示、测试、图层导出混合，存在合照样本和输出路径硬编码 |
| 可选离线 Adapter | tools/art/holo_card 下包装器、固定上游源码和 LICENSE | 保留制作能力与许可，不作为每张 Godot 卡的必经步骤 |
| 对象独有 | 原照、标题／说明／编号、001/002 配置、ruic 图层／blend／渲染／GLB、generation.md、对象 Manifest、任务 | 应绑定该对象与具体版本，不进入通用默认值 |
| 归档证据 | review/codex-workflow 下截图、失败与通过的 checks.json | 是评审／回归证据，不是缓存；可重建不等于应删除 |
| 缓存与临时产物 | 工作树 .godot、未跟踪且忽略的评审图 .import、自动 .blend1 | 可清理；受 Git 跟踪的 .import 和 .uid 是元数据，不按缓存删除 |

### 优先改进顺序

1. **先清掉对象耦合（低成本、高收益）**：把合照文案从 Resource 默认值移进 001/002 .tres；默认值保持中性。预览只读传入 Resource；换卡时标题、原图入口和所有展示状态一起更新。无效路径、空图、错误 Resource 类型要给清晰提示而不是异常。
2. **制作输出参数化（低到中成本）**：统一 Card、Output、Godot 路径来源，参数优先，其次环境配置／PATH；不把本机磁盘路径当通用默认。Layers 必须显式指定输出目录，拒绝默默覆盖 001 或获批资产。测试输出默认写缓存，只有选定证据才归档，避免每次检查改动已提交截图。
3. **分离运行与开发工具（中成本）**：预览只展示，测试场景负责检查，Blender Adapter 单独调用。统一 Check 入口必须同时执行原功能与四向方向检查，当前 -Mode Check 尚未自动调用方向检查。让测试尽量通过 Module 的 Interface，而不是直接修改 material_instance 或调用私有输入函数；保留少量真实输入路由检查。
4. **布局数据只有一个事实源（中成本）**：目前 1600×1400、照片矩形、比例在 card_art、shader、view、预览和 Blender 包装器多处重复。先集中为一份小型布局配置，并把矩形／比例传给 shader；只有第二种真实卡框需求出现时再增加样式 Resource，不提前建设任意卡牌设计器。
5. **收紧 Module 的 Interface（中成本）**：调用方只需设置内容、照片／边框开关、静态状态和复位；内部负责每实例材质、尺寸、输入和资源变化。补齐入树前设置、运行时更换 Resource、Resource.changed、空内容等生命周期测试；不要求调用方直接接触 viewport/art/material_instance。
6. **最后优化批量展示（按场景验证）**：1600×1400 RGBA 渲染目标按 4 字节估算约 8.5 MiB/张，未计其他 GPU 分配；当前原图导入未限尺寸且未生成 mipmap。先量测目标设备，再决定运行纹理尺寸、mipmap、共享静态框纹理或烘焙；列表用缩略图，详情才激活交互卡。不能据此承诺手机／Web 性能。

### 推荐最短工作流

`提供原图与文案 → 生成一份卡 Resource → 共用 Godot Module 预览 → 检查＋保留关键证据 → 用户确认该版本`。

只在确实需要离线渲染、可编辑三维源文件或几何参考时追加 Blender 支线；普通换图不做抠图，不重生成四图层，不要求 AI 生图，不重新做 GLB。用户确认后由工具提取 Resource 更新 Manifest 与任务引用，避免手填多份重复参数；Manifest 仍是管理记录，不引入运行时 YAML 加载。

第一批建议只实施 1～3，再拿第二张内容完全不同的图片验收“无需改共享代码”；样式抽象与性能优化依据真实需求推进。建议验收还包括新环境从无缓存启动、失败日志判定、重新运行不覆盖归档证据，以及两个实例不同照片／开关不互相影响。

发布前需另行核查导出范围：当前 export_presets 使用 all_resources 且未配置排除；虽然 ruic 和 review 被 .gdignore 隔离，合照 source.jpg 与 .tres 仍可被 Godot 导入，不能把“主流程没引用”当作“不会进包”。默认发布包应只包含批准且授权公开的卡资源，候选与测试场景应排除。

### 缓存清理规则与本次结果

2026-09-16 清理仅针对 E:/Documents/works/godot_xinan1-card：移除 .godot 中 256 个文件（引擎导入／编辑器缓存、RuiC 下载与解压副本、隔离 Blender 配置、日志和 UID 缓存副本）、47 个忽略且未跟踪的评审图导入文件、1 个 card.blend1，共 304 个文件、155763811 字节（148.55 MiB）。清理前确认该工作树无引擎占用，目标无重解析点且不含受跟踪文件。

没有动其他工作树、原项目其他缓存、源照片／.blend／四图层／GLB、已归档证据、受跟踪导入配置，以及 tools/art/asset_manager/control/ArtManagerControl.cs.uid。后者是恢复的资源身份元数据，不是缓存；本轮保留未跟踪状态，不混入卡牌清理提交。

临时文件未进回收站；引擎缓存可由导入重建，下载副本可重新获取，Blender 自动备份被删除但已归档 card.blend 未动。删除原项目的七个中转补丁已在前轮完成，本轮未新增中转文件。清理后不启动引擎以免重建缓存，验证采用 Git 状态、Manifest 路径与文件存在性检查。

首次重新预览请用 run-holo-card.ps1 先导入；此前跳过导入的直接场景命令不适用于无缓存状态。现有编辑器导入 EditorSettings 提示尚未修复；应在工具改造中区分导入、运行日志并收集标准错误，不能仅以退出码 0 判定所有问题消失。
