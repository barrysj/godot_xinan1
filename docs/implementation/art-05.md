# ART-05 · Manifest 驱动的美术资源台

- 功能 ID：ART-05
- 所属系统：美术工具

## 当前状态

- 2026-09-16（基线32387d4）：按用户要求，控制器构建输出改为与 ArtManagerControl.cs 同目录的 `tools/art/asset_manager/control/ArtManagerControl.exe`，根启动入口同步，EXE 加入精确 Git 忽略项；不再受 .godot 清理影响。旧路径的记录仅作历史验证。待统筹：控制器构建位置变化，不改资源台协议或功能。

- 2026-09-16（基线 fad0254）启动恢复：复现清除 .godot/art-manager-control/ArtManagerControl.exe 后根入口抛出 Controller is not built。run-art-manager-control.ps1 现会在 EXE 缺失或 C#／构建脚本较新时自动编译，构建错误终止启动并提示关闭占用窗口；无需清缓存后另跑构建。直接运行的 EXE 仍须先构建并保留项目内位置，以便向上定位项目根。

- 页面实测：9 个对象、102 个登记文件、0 处不一致；卡片详情显示真实 review.png 与原图、同份文案，没有阶段审批页。点击预览后已核对 Godot 进程参数为 `--card=res://assets/art/holo_cards/class_photo/card.tres`，运行日志无错误。卡片列表标签使用“校验通过”，不暗示主游戏已接入。浏览器实际截图已在对话展示。

- 2026-09-16（基线 b9daea3）：新增 `holo_card` 集合目录登记，自动发现直接子目录的卡资源；详情读取同份 `.tres` 文案，展示 review/原图并将同份资源传入 Godot 预览。入口为 catalog.py、server.py、static/app.js；普通对象规则不变。验证：`py -3 -B -m unittest discover -s tools/art/asset_manager/tests`，25 项通过（含 9 项卡片测试）；JavaScript 语法检查通过。目录约束、缺图、缺截图、恶意路径、文案刷新和启动参数均覆盖。待统筹：Manifest 允许显式卡片集合扫描，卡片不走阶段审批。

- 状态：Manifest v3 与 Windows 桌面控制器已实现并完成验收。
- 功能入口：运行 `pwsh.exe -NoProfile -File .\run-art-manager-control.ps1`，首次或源码更新时自动补建控制器；直接启动服务使用 `pwsh.exe -NoProfile -File .\tools\art\asset_manager\run-server.ps1`，本地页面为 `http://127.0.0.1:8765/`。
- 管理入口：[主 Manifest](../../assets/art/asset_manifest.yaml)及 `assets/art/manifests/` 对象清单；格式见[工具说明](../../tools/art/asset_manager/README.md)。
- 范围：只处理当前项目登记对象；不兼容任意目录，不提供跨项目预览，不承担审批、编辑、生图或运行时内容加载。

## 当前接口

1. 页面只接收一个主 Manifest 路径。主文件索引对象清单，目录不再作为输入；路径可手填或通过 Windows 文件选择器选取。
2. 对象版本使用一个项目相对 `root`，`files` 仅保存相对路径；单个 Godot 文件用 `resource` 登记。
3. `stage` 决定概念、资产等详情选项卡。`selection` 表示当前选用版本；`approval` 表示负责人是否批准，二者独立显示；`integration` 记录真实接入。
4. 动画动作直接读取 `.frames.json`；资源类型和依赖直接解析 `.tres`，不在 Manifest 保存 `representation`、`role` 或 `resource_reference` 比较规则。
5. Manifest 不保存 SHA-256。资源台每次校验都根据选用路径与正式路径实时计算内容哈希；Godot 所有者引用与缺失依赖则从 `.tres` 实时检查。
6. 跨对象关系只登记目标对象 ID。详情展示目标缩略图、状态与跳转入口。
7. 详情内容用响应式网格适配可用宽度；不同 stage 不再纵向平铺。版本默认折叠为摘要，展开后分为图集、动画、其他三个子页。
8. 概念与资产页可独立筛选选用和批准状态；生效版本及关联对象支持带返回入口的详情跳转。
9. 校验状态只描述版本文件和 Godot 引用的实时完整性，由管理器计算而非 Manifest 字段，并以颜色标签显示；不从校验结果推断 `selection` 或 `approval`。
10. Windows 桌面控制器只包含“启动服务”“打开页面”“停止服务”三个动作按钮，并显示实时服务状态、PID 和当前工作目录。健康接口返回服务 PID 与项目根；控制器核对应用 ID 和项目根后才允许停止，避免误杀同端口程序或其他工作树服务。
11. 资源台只消费 Manifest 已登记的预生成 GIF，并可启动无写入的统一动作预览；点击动作、展开版本或启动 Godot 均不得隐式生成预览文件。通用 GIF 导出属于 [ART-03](art-03.md#骨骼序列帧通用生产与预览) 的显式生产入口，已完成并通过单动作及七动作导出验证。

## 验证入口

- 2026-09-16 main 合并验收（双亲 `48acc51` / `f32fa4f`）：保留 main 动画后端、近战/远程动作及 `.tscn` 识别，同时接入闪卡集合与按需原图；控制器合并“源码旁 EXE”与 main 的内容哈希重建机制，保留 PassThru。33 项 Python 测试、JS 语法、控制器构建与实际启动通过；Godot HYBRID_CONTRACT_CHECK、PRESENTATION_CHECK、HOLO_CATALOG_CHECK、HOLO_CODEX_CHECK 与菜单 CODEX_CHECK（35 条目）通过。闪卡三尺寸截图 `.godot/holo-detail-*.png`，1920×1080 已在对话展示。待统筹：原高层总览未改；继承的 Android EditorSettings 退出噪声、像素图直读警告与菜单检查退出时单个 ObjectDB 泄漏仍存在，未作为本次功能扩展处理。

- 预览启动与原图交互修复（2026-09-16，基线 `43c91ab`）：浏览器默认图形版 Godot 经 PowerShell `&` 启动不可靠等待，导致闪卡脚本过早检查退出码而失败；网页只保留初始提示，未跟踪退出结果。`run-holo-card.ps1` 改为 Start-Process 显式等待导入及预览，导入超时 120 秒；网页轮询已有状态接口，在详情按钮旁显示运行/结束/失败，请求超时 10 秒。运行状态仅代表进程存活（包含导入），不冒充画面就绪。原图按钮复用文件信息下的动作栏样式；弹窗空白区域点击关闭，图片本体点击不关闭。验证：26 项 Python 测试通过；`pwsh.exe -NoProfile -File tools/art/asset_manager/tests/check-holo-launch.ps1 -Godot '<图形版Godot.exe>'` 修复前 exit1，修复后 HOLO_LAUNCH_CHECK PASS；该集成检查沿用 Check 模式，会刷新历史验证截图。浏览器真实点击启动卡片进程，日志无错误；关闭窗口后页面显示结束、按钮恢复。DOM/截图验证按钮位置、按需加载、点击图片保持打开、遮罩关闭并清空 src。截图已在对话展示。JavaScript 语法与 Git 差异检查通过。

- 闪卡独立分类与按需原图（2026-09-16，基线 `5a01a53`）：`catalog.py` 将 holo_card 归入“闪卡”，缩略图仅允许有效 review；`static/app.js` 详情仅显示 review，点击“原图”才加载原照并打开现有模态子窗口，关闭清空图片。缺 review 不回退原照，缺原照禁用按钮；Godot 预览和游戏资源加载不变。25 项 Python 测试通过，新增分类计数与缺 review 无缩略图断言；JavaScript 语法、Git 差异检查通过。8876 独立测试服务实测分类计数闪卡1/UI0，详情 DOM 只有 review 图片与无 src 弹窗，点击后原照显示、关闭后 src 清空；实际截图已在对话展示。边界：按需加载约束针对浏览器图片请求，后端完整性校验仍读取源文件。

- 同目录构建验证（2026-09-16）：根启动脚本自动生成源码旁 EXE 并打开窗口；从临时目录直接运行该 EXE 的 --screenshot 模式退出码0，工作目录识别正确，截图 .godot/control-source-dir.png 已展示。git check-ignore 确认二进制不入库，git diff --check 通过；仅改构建路径，未改服务实现。

- 2026-09-16 启动恢复实测：临时移开确切 EXE 后，旧入口报 Controller is not built；修复入口自动构建并创建控制器进程。再次启动文件时间戳不变（不重复编译）。从项目外直接运行 EXE `--self-test <报告路径>`：initial=未启动、started=True、open_enabled=True、stopped=True，退出码0。实际截图 `.godot/art-manager-control-fixed.png` 已展示。服务健康检查 project_root 指向卡片工作树。未复现当前已有 EXE 状态下的启动失败，确认修复的是缓存清理/首次工作树缺构建产物的可靠复现路径。

- `py -3 -m unittest discover -s tools/art/asset_manager/tests -v`
- `node --check tools/art/asset_manager/static/app.js`
- `py -3 -m py_compile tools/art/asset_manager/catalog.py tools/art/asset_manager/server.py`
- 页面需核对 Manifest 单输入、stage 切换、宽屏网格、粉笔弹体缩略图与跳转、GIF 播放和 Godot 预览入口。

## 2026-09-15 验证记录

- 自动测试：15 项通过；Python 编译、JavaScript 语法与 Git 差异检查通过。
- 数据校验：8 个对象、71 个登记文件，0 缺失、0 不一致。
- 响应式：1600 px 视口为两列版本卡；700 px 视口自动降为单列，无横向溢出。
- 交互：概念选项卡只显示版本 001；关联素材展示粉笔弹体缩略图，并可跳转到粉笔弹体详情。
- 交互补充：版本默认折叠，筛选、三子页、生效版本跳转及两类返回入口通过；系统文件选择器接口通过服务端测试。
- 状态与动画：版本摘要同时显示选用、批准、校验三类颜色标签；展开页只保留评审依据，不重复显示决定字段。动画动作以七项纵向按钮列表展示，点击“待机”与“攻击”时右侧均只出现对应的一个 GIF；子页与外层卡片使用不同背景层级。
- Godot 预览：切分支后先增量导入再启动，1920×1080、2560×1440、1920×1200 三种截图均恢复正常画面。
- 截图：`.godot/art-manager-v3-stage-tabs-20260915.png`、`.godot/art-manager-v3-related-20260915.png`（本地验收产物，不入库）。
- 本轮截图：`.godot/art-manager-v4-version-summaries-20260915.png`、`.godot/art-manager-v4-version-animation-20260915.png`、`.godot/art-manager-v4-active-jump-20260915.png`、`.godot/art-manager-v4-manifest-picker-20260915.png`、`.godot/motion-preview-3-1920x1080.png`（本地验收产物，不入库）。
- 状态与动作截图：`.godot/art-manager-v5-summary-status-20260915.png`、`.godot/art-manager-v5-animation-list-20260915.png`（本地验收产物，不入库）。
- 展开层级截图：`.godot/art-manager-v6-expanded-contrast-20260915.png`；折叠卡、展开摘要、详情底层与子页面板使用独立背景，并以青色边框和左侧轨道标识当前展开版本（本地验收产物，不入库）。

## 2026-09-16 桌面控制器验证

- 构建：Windows .NET Framework C# 编译器生成无控制台 WinForms 可执行程序；构建脚本与服务脚本归入 `tools/art/asset_manager/`，根目录入口只启动已构建控制器。
- 状态：未启动时只启用“启动服务”；运行后显示实际 PID 并启用“打开页面”“停止服务”。工作目录显示当前项目根。
- 生命周期自检：`initial=未启动`、`started=True`、`open_enabled=True`、`stopped=True`，退出码 0；结束后 8765 无监听。
- 入口拆分回归：独立构建成功；根目录启动脚本成功创建控制器进程；工具目录服务脚本返回正确应用 ID、PID 与项目根，停止后 8765 无监听。
- 后端回归：16 项 Python 测试通过，新增健康接口进程 ID 与项目根测试；PowerShell 脚本语法、Python 编译及 Git 差异检查通过。
- 截图：`.godot/art-manager-control-running-v2-20260916.png`、`.godot/art-manager-control-script-layout-20260916.png`（本地验收产物，不入库）。

## 已知边界

- 桌面控制器只支持 Windows，并依赖系统 .NET Framework 4.x C# 编译器；Web 资源台本身的范围与跨项目边界不变。
- “打开页面”使用 Windows 默认浏览器；关闭控制器窗口不会自动停止服务，服务生命周期由三个明确按钮管理。

## 历史迁移

- v2 曾以逐文件 SHA-256、显式 role／representation 与三类 binding 保存完整迁移基线；该方案在 2026-09-15 通过 8 对象、71 文件与 Godot 组合验收。
- v3 根据负责人反馈删除可从文件和 `.tres` 推导的字段。原有选择、批准、评审依据、接入状态、预览参数和有效视觉元数据保持不变；六项旧资产仍为 `approval: review`、`selection: unknown`，没有借迁移升级批准状态。
- Godot 仍读取 `.tres`，不读取 YAML。Manifest 只负责生产对象、版本和路径语义。

## 通用动画运行包校验（2026-09-16）

资源台递归检查 .tres／.tscn 依赖；候选与正式场景／动画资源按已登记包根归一引用后比较，图片与 JSON 仍逐字节比较。不新增 Manifest 哈希字段。新增 melee／ranged 中文标签。22 项单测通过，8 个对象／101 个文件无缺失或不一致；候选 GIF 仍只读消费。

2026-09-16 F 清理树（父基线 56dc3aa）：删除旧专用脚本登记后，扫描为 8 对象／101 文件、0 缺失／不一致；历史 attack 按角色元数据展示近战或远程，双能力可映射两个入口。006 七动作页面和点击 GIF 已实际检查，资源台启动及预览无候选生产写入。待统筹：递归依赖与资源路径归一比较已替代仅顶层 .tres 校验。

## 控制器缓存修复（2026-09-16）

基线 dc938ab。旧入口在新工作树缺少 EXE 时直接报错；现根据源码和构建脚本 SHA-256 自动补建或重建，无需先运行构建命令。

验证：`pwsh.exe -File tools/art/asset_manager/control/test-launcher.ps1`，缺失缓存、缓存复用、过期签名三种真实窗口启动通过；截图 `.godot/art-manager-control-fixed.png`。待统筹：日常启动入口已自包含，仍依赖 Windows .NET Framework 编译器。

## 动作列表后端标记（2026-09-16）

基线 09dccf7。版本的动画子页在每项动作名下显示“骨骼动画”或“序列帧”，复用 catalog 的 backend 数据；不只在选中后的详情中说明。node --check 通过，实际浏览器核对 006 六骨骼动作＋退场序列帧，并点击退场验证 GIF 切换。截图：`.godot/art-manager-action-backends.png`。
