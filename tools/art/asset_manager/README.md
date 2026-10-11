# 美术资源台

## 开发工具集启动

PowerShell 7 在项目根运行 `./run-tool-suite-control.ps1`：缺少 EXE 或控制器源码更新时自动构建，再打开窗口。旧入口 `./run-art-manager-control.ps1` 也会打开同一个工具集。EXE 与 C# 源码同目录，清理 .godot 不会移除它；构建产物被 Git 忽略。需系统 .NET Framework C# 编译器；若重新编译时报文件占用，关闭控制器窗口后重试，不需要停止已启动的服务。

可直接双击项目内 `tools/art/asset_manager/control/ArtManagerControl.exe`；也可执行 `& './tools/art/asset_manager/control/ArtManagerControl.exe'`。EXE 从自身目录向上查找项目，不依赖启动时的当前目录；不要单独搬到项目外。直接运行 EXE 不自动编译，新工作树首次请先用根启动脚本。窗口分别管理“美术资源”和“地图编辑”，显示服务状态、PID 和运行目录，各有“启动／打开／停止”按钮。资源台默认使用 `127.0.0.1:8765`，地图编辑器默认使用 `127.0.0.1:8767`。关闭工具集窗口不会停止服务。

工具集只会停止健康接口核验为当前工作树、且 PID 未变化的服务；同端口若被其他程序或工作树占用，显示“端口占用”并禁用对应操作。地图编辑器需要 Node.js；美术资源台需要 Python。

本工具只读取用户指定的主 Manifest。普通对象由对象清单登记；索引清单可以继续指向子索引，浏览器会按相对路径递归读取并保留对象 ID。`holo_card` 集合允许在显式登记的目录内发现卡片，不扫描其他目录，也不提供跨项目预览。

全息卡登记：在 `objects` 下增加 `holo_cards: {type: holo_card, root: assets/art/holo_cards}`。每个直接子目录放 `card.tres`、其引用的本目录原图和 `review.png`。资源台直接读取 `.tres` 文案、显示实际截图、启动同份 Godot 资源，不显示 concept/asset 审批阶段。闪卡为独立分类；列表与详情仅使用 `review.png` 的浏览缓存，缺少截图时不回退原照。点击“原图”才加载原照并在弹窗显示，关闭后清空弹窗图片；完整校验仍读取原照。截图生成命令与限制见 [照片卡工作流](../../../docs/art/holo-cards.md#当前最简流程2026-09-16)。

## 主 Manifest

```yaml
schema_version: 3
objects:
  sample_character: manifests/sample_character.yaml
  sample_projectile: manifests/sample_projectile.yaml
  enemy: manifests/enemy.yaml
```

子索引也使用 `schema_version: 3` 和 `objects` 映射，例如 `manifests/enemy.yaml` 可将 `chalk_spirit` 指向 `enemy/chalk_spirit.yaml`。每一级路径都相对当前索引文件；循环引用、重复对象 ID 和越出项目的路径会报错。页面只需要填写主 Manifest 路径；“敌人”筛选按 `enemy` 集合归属显示，原有类别筛选不变。

## 对象清单

```yaml
schema_version: 3
object:
  id: sample_character
  display_name: 示例角色
  type: character
  subtype: enemy
variants:
  concept_001:
    stage: concept
    version: 001
    selection: selected
    approval: approved
    approval_evidence:
      source: docs/art/characters/sample.md
      date: 2026-09-15
      decision: approved
    root: design/concepts/characters/sample/concept_001
    files:
      concept: concept.png
  asset_002:
    stage: asset
    version: 002
    selection: selected
    approval: approved
    root: design/concepts/characters/sample/asset_002
    files:
      locomotion_sheet: locomotion_sheet.png
      frame_metadata: animation.frames.json
      gif_idle: review/idle.gif
    resource: design/concepts/characters/sample/asset_002/animation.tres
    animation:
      frames: frame_metadata
    previews:
      gifs:
        idle: gif_idle
      godot:
        unit: res://resources/content/characters/sample.tres
        animation: res://design/concepts/characters/sample/asset_002/animation.tres
relationships:
  projectile: sample_projectile
integration:
  status: active
  active_variant: asset_002
  owner: resources/content/characters/sample.tres
  root: assets/art/characters/sample
  files:
    locomotion_sheet: locomotion_sheet.png
  resource: resources/content/animations/sample.tres
  evidence: docs/art/characters/sample.md
```

规则很短：

- `root` 相对项目根；`files` 中只写相对 `root` 的路径。单个 Godot `.tres` 使用 `resource`，避免为了一个不同目录的资源把整段路径重复到每个文件。
- `stage` 负责把版本放入概念、资产等选项卡。
- `selection` 表示当前流程选用哪个版本；`approval` 表示负责人是否批准这个版本。选用不等于批准，技术验证也不等于批准。
- 动画只登记帧元数据文件键；资源台从 `.frames.json` 读取动作，并从 `.tres` 自动识别资源类型和引用，不登记 `representation`。
- 关联只登记目标对象 ID。资源台自动提供目标缩略图、状态和详情跳转，不登记目标内部文件路径。
- Manifest 不保存 SHA-256、`compare` 或引用检查策略。校验时实时计算选用文件与正式文件的 SHA-256，并直接解析 `.tres` 检查引用与缺失依赖。

## 页面交互

- 主视图优先展示素材、名称搜索、分类与已生成筛选。右上“刷新”重新读取目录；“工具”默认折叠，包含 Manifest／Godot 路径、文件选择器和“完整校验”。选择结果仍必须位于当前项目。
- 版本默认折叠。摘要显示对象名、版本、日期、首图、静态图片数、动作数，以及选用／批准状态。路径、哈希、校验与评审依据收在“文件信息”中；校验结果不等于 `selection` 或 `approval`。
- 概念和资产页可按是否选用、是否批准筛选。展开版本后使用“图集 / 动画 / 其他”三个子页，帧元数据放在“其他”。
- 生效页可跳到对应资产版本；生效跳转与关联对象跳转都会显示“返回”。

### 加载与校验

- 日常刷新用 `POST /api/load`（`validate: false`），后台读取登记目录，不计算 SHA-256、不遍历 Godot 依赖链、不比较正式复制；文件存在性与版本信息仍读取实际文件。未做完整校验的文件／版本／接入显示“未校验／待核验”，不冒充校验通过。
- `GET /api/load/status?id=…` 返回阶段、已处理项和总项。进度统计登记项处理数量，同一文件在不同版本重复登记时会计入多次；汇总文件数按实际路径去重。索引阶段尚不知道总量时显示等待状态，目录就绪后另显示当前可见缩略图的真实完成数量。
- 首屏仅返回对象摘要；`GET /api/object?id=…&revision=…` 按需返回详情，版本展开才创建子页。同一服务只运行一个加载任务，相同任务复用；刷新完成后原子替换目录，完成前旧目录仍可浏览。目录修订不一致时要求刷新，不混用两个版本的详情。
- “完整校验”使用同一后台任务的 `validate: true`，实时计算文件哈希、检查依赖和生效复制。`AssetCatalog.scan()` 与兼容 `POST /api/scan` 默认仍为完整校验；扫描内复用重复文件信息，扫描之间不保留哈希结果。启动 Godot 预览时再次核对目标与依赖。
- 列表和静态详情使用长边不超过 480px 的等比例缩略图，原图按钮与动作 GIF 保持原媒体。PNG／JPEG／BMP／GIF 在 Windows 使用系统解码器，无需增加 Python 依赖；其他平台及 WebP 可使用 Pillow，缺少解码器或解码失败时回退原媒体，SVG直接使用原文件。
- 缩略图只写入 Git 忽略的 `.godot/art-workflow/asset-manager/thumbnails/`，以源路径、大小、修改时间和尺寸为键，变化后自动更新。图片 HTTP 使用 ETag 条件请求；这些文件只是可清除的浏览缓存，不写源包、Manifest 或批准状态，不生产交付预览。

## 运行与验证

推荐使用开发工具集：

```powershell
pwsh.exe -NoProfile -File .\run-tool-suite-control.ps1
```

构建脚本用 Windows 自带的 .NET Framework C# 编译器，在源码同目录生成兼容原名称的 `tools/art/asset_manager/control/ArtManagerControl.exe`。根启动脚本在缺失或源码／构建脚本内容哈希变化时自动构建，同目录 `.exe.sources` 保存签名，两者均不入库。两张工具卡独立检测、启停；停止动作只接受健康接口返回的本项目进程，不会根据端口猜测或终止其他程序。

也可以直接启动服务：

```powershell
pwsh.exe -NoProfile -File .\tools\art\asset_manager\run-server.ps1
py -3 -m unittest discover -s tools/art/asset_manager/tests -v
```

资源台启动动作预览前会先让 Godot 增量导入当前项目资源；这是为了修复切换分支后 `.godot/imported` 目录存在但内部缓存不完整时出现的灰屏。

服务只监听 `127.0.0.1`。文件和预览由本次启动令牌保护；预览入口限定为当前项目的 `run-motion-preview.ps1` 或闪卡的 `run-holo-card.ps1`。预览按钮旁跟踪进程运行、结束和失败；运行包含导入阶段，不代表画面已经就绪。闪卡导入最多等待 120 秒，导入失败可查 `.godot/holo-import.log`，运行失败可查 `.godot/holo-card.log`。原图按钮统一位于文件信息下面，弹窗可点空白区域或“关闭”退出。
