# GitHub Pages 发布

目标地址：https://barrysj.github.io/godot_xinan1/

## 首次启用

1. 打开 https://github.com/barrysj/godot_xinan1/settings/pages ，将 Build and deployment → Source 设为 **GitHub Actions**。
2. 将本地代码提交并推送到 `main`。按项目约定，推送由仓库主人手动执行。
3. 在仓库 Actions 中查看 **Publish Web to GitHub Pages**：build 和 deploy 都成功后访问目标地址。
4. 首次发布后验证：Play → 校园基地 → 开始探索 → 编队 → 开战 → 结算，以及暂停/返回菜单。

后续推送 `main` 自动更新网站，也可在 Actions 页面选择 Run workflow。旧的通用模板工作流已由这条专用流程替代，避免同时向 gh-pages 分支部署。无需 PAT 或自建部署密钥。

## 构建约定

- 固定 Godot **4.7.2 标准版**。当前项目使用 GDScript；Mono 编辑器会拒绝 Web 导出。
- CI 从 Godot 官方发布下载引擎与模板并验证 SHA-512，只安装 Web 单线程模板，随后缓存。
- 使用 Compatibility 渲染器、单线程 Web 导出、默认相对资源路径；PWA 未启用。
- 中文字体随游戏打包：Google Fonts Noto Sans SC，许可证见 `assets/fonts/OFL.txt`。
- Web 预设保持全部正式运行资源，但排除 `design/*` 概念与评审资料、校园地点和主菜单的原始 4K PNG，以及全图的原始 5400×4500 PNG；Web 使用两组 1920×1080 WebP 背景与一组三态 1800×1500 PNG 全图。非 Web 导出使用原图并排除 Web 衍生图。`assets/art/holo_cards` 必须保留，供图鉴动态发现。基地、图书馆和记忆终端使用导入纹理，不依赖导出包中的原 PNG 字节。
- 本地构建和 Actions 上传前均检查整站体积，达到 900 MB 就失败，以留出 Pages 1 GB 限额余量。
- 上传 `builds/web` 为官方 Pages artifact，再通过 `actions/deploy-pages` 发布。
- `builds` 和 `.godot` 不提交。首次 CI 下载完整模板较大，后续命中缓存会更快。

## 平台素材规格映射

### 运行时如何选图

界面只传正式原图路径给 [平台路径适配层](../../game/visual/platform_asset_paths.gd) 的 `resolve(source_path)`。适配层先以 `OS.has_feature("web")` 识别 Web，否则使用 `OS.get_name().to_lower()`；再查 `VARIANTS[platform]`，仅对同时匹配源目录前缀和扩展名的文件替换目录与扩展名。没有匹配规则便返回原路径。`for_platform(source_path, platform)` 是同一套规则的显式平台入口，供生成器与检查工具调用。

例如 `res://assets/art/backgrounds/m1_main_menu/normal/library.png` 在 Web 映射为 `res://assets/art/web_backgrounds/m1_main_menu/normal/library.webp`；三态全图 `res://assets/art/campus_map/expanded_neutral/day.png` 映射为 `res://assets/art/web_campus_map/expanded_neutral/day.png`。Windows、Linux、macOS、Android 仍用各自原图。目前登记校园地点、主菜单和全图三组 Web 变体。此层按**导出平台**选文件，不根据设备屏幕或浏览器窗口大小动态切换档位。

[Web 背景生成器](../../tools/art/build_web_backgrounds.gd) 以 3840×2160 PNG 制作 1920×1080 WebP（Lanczos、品质 0.85）。全图三态使用 `asset_001/web` 留存的 1800×1500 PNG，逐字节复制到正式 Web 目录，独立于该 WebP 生成器。场景中的 `load()` 读取 Godot 导入后的纹理；[导出预设](../../export_presets.cfg)另行排除 Web 包里的三组原图，以及非 Web 包里的衍生图。映射表不自动修改导出预设，漏配衍生图会使该平台加载失败，不会安全回退到已被排除的原图。

美术 [Manifest](../../assets/art/asset_manifest.yaml) 管理版本、实际文件及人工批准；运行时不解析 YAML。衍生图的技术生成、原图批准和衍生视觉评审是不同状态，新增或改变衍生图后按[美术工作流](../art/WORKFLOW.md)记录，不能由检查通过推定获批。

### 接入后续图片

| 情况 | 需要做什么 | 适配层／导出规则 |
| --- | --- | --- |
| 同组新增校园地点或主菜单背景 | 将批准的 3840×2160 PNG 放入现有目录，并将新地点或菜单项接入相应列表；生成 WebP、登记 Manifest、检查画面 | 现有目录前缀自动匹配；当前导出筛选已覆盖，无需逐张加映射 |
| 全新图片组也要 Web 低规格 | 在 `VARIANTS.web` 增加该组的源／目标目录和扩展名，扩展衍生图生成与检查范围，并在 Web／非 Web 导出预设中分别排除多余版本 | 需要改一条组规则和对应导出筛选；当前生成器只扫描校园地点与主菜单 |
| Android 等平台另用规格 | 准备该平台的衍生文件，在 `VARIANTS` 增加平台规则，并配置对应导出预设与目标设备验证 | 目前没有 Android 专用衍生图；仍用原 PNG |
| 图片不需要多平台版本 | 直接按现有正式资源路径加载 | 不必登记映射 |

原有两组的新图不用改“30”这样的数量常量：生成器会扫描校园地点目录下的 `daily.png`／`anomaly.png`，以及菜单 `normal`／`anomaly` 目录下的 PNG。校园每个地点须有两种状态；主菜单实际播放列表仍在 [menu.gd](../../scenes/menu/menu.gd)，地点列表仍在 [campus_location_skin.gd](../../scenes/expedition/campus_location_skin.gd)。全图三态由 [expanded_campus_map.gd](../../scenes/expedition/expanded_campus_map.gd) 固定列出。新增全新图片组时，不能只加映射规则：来源、检查工具和导出筛选也须覆盖它。

### 生成与验收

在项目根目录用 PowerShell 7 和 Godot 4.7.2 标准版执行：

```powershell
$godot = '.\.godot\web-tools\engine\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path . --script res://tools/art/build_web_backgrounds.gd
& $godot --headless --path . --script res://tools/art/build_web_backgrounds.gd -- --check
& $godot --headless --editor --path . --import
& $godot --headless --path . res://tools/platform_asset_check.tscn
pwsh.exe -File .\build-web.ps1
```

`--check` 只读验证源图与衍生图的存在和尺寸；新增图片要先运行生成命令。检查成功会打印 `WEB_BACKGROUNDS_CHECK count=...`，映射检查会打印 `PLATFORM_ASSET_CHECK checked=... failures=0`。脚本模式退出时旧 GGT 自动加载项可能报告空场景属性错误，应同时核对退出码、上述成功标记和文件检查结果。实际 Web 包还应通过浏览器 `--web-background-check` 确认加载纹理，并查看画面；CI 使用已提交的衍生文件，不会重新生成。

原图或衍生图视觉效果变动后，按资产审批范围复核，不能仅凭路径和分辨率检查认定画质合适。线上 Pages、Android／iOS 真机仍需分别验收。

## 本地复现

PowerShell 7：

```powershell
pwsh.exe -File .\build-web.ps1
```

衍生图随代码提交仓库，普通 CI 构建不重新生成；新增或修改图片的完整接入与验收步骤见上节。当前 `m1_web_backgrounds` Manifest 的衍生视觉评审仍待完成。

本机默认使用 `.godot/web-tools/engine` 下的标准版。其他机器通过 `-Godot '完整可执行文件路径'` 指定标准版，并先安装 4.7.2 导出模板。

用 HTTP 服务提供 `builds` 目录，再打开 `/web/`。不要双击 HTML，也不要只上传 HTML；WASM、PCK、JS 等全部文件必须一起部署。

## 线上验收

- 确认在仓库子路径下加载成功、中文与像素素材正常。
- 桌面浏览器能完成一场战斗，暂停和返回菜单正常。
- 手机浏览器横屏验证加载与点击；电脑缩小窗口不能替代 Android/iOS 真机验收。
- 网页存档属于当前浏览器与站点，清理网站数据会清除存档。刷新后从最近一次节点检查点恢复；若在战斗中刷新，则从该场战前阵容重开，不恢复逐帧生命与位置。

如果 deploy 提示找不到 Pages 站点，优先检查首次启用的 Source 设置。如果 build 失败，查看 Import and export 日志；不要把未成功构建的产物当作已发布。

## 本次本地验证（2026-09-07）

Godot 4.7.2 标准版实际 release Web 导出成功；本地 `/web/` 子路径加载、主菜单进入、中文/像素资源、开始探索、进入编队和战斗暂停已通过浏览器检查。原生完整路线 smoke 通过。844×390 浏览器视口能进入游戏，但文字偏小；尚未完成 Android/iOS 真机验收。GitHub Actions 与线上地址须在手动推送、启用 Pages 后验证，不能用本地结果代替线上验收。

## 当前本地验证（2026-09-14）

当前提交使用 Godot 4.7.2 标准版重新导出 release Web 包，并在 Codex 应用内浏览器的默认桌面视口通过完整流程：模板主菜单 → 基地 → 新探索 → 首战部署 → 战斗／暂停／恢复 → 战报与奖励 → 路线事件 → Boss → 结算 → 返回基地与主菜单。中文字体、两名绘制角色、像素角色与三张战斗背景均从实际导出包加载；控制台没有游戏脚本错误。

在 Boss 前地图检查点刷新后，“继续”准确恢复到第 5/5 层。另复现了原子替换后立刻刷新可能读到旧 IndexedDB 检查点的问题；现于 Web 成功写入后强制同步持久文件系统。修复包已验证奖励后立刻刷新仍恢复到最新第 2/5 地图，战斗开始后立刻刷新则恢复同一场的 4/4 战前阵容。

844×390 仅作为小屏风险探针：页面可加载，地图与部署点选可触达，但中文、卡片和勾叉确认控件明显偏小，因此不判定为手机可用。Android／iOS 真机触控、浏览器后台切页、存储配额、音频以及线上 Pages 仍未验收；当前支持边界只到本地桌面浏览器流程。
