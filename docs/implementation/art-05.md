# ART-05 · Manifest 驱动的美术资源台

- 功能 ID：ART-05
- 所属系统：美术工具

## 当前状态

- 状态：Manifest v3 与 Windows 桌面控制器已实现并完成验收。
- 功能入口：首次或源码更新后运行 `pwsh.exe -NoProfile -File .\tools\art\asset_manager\control\build-control.ps1`；日常用 `pwsh.exe -NoProfile -File .\run-art-manager-control.ps1` 打开桌面控制器。直接启动服务使用 `pwsh.exe -NoProfile -File .\tools\art\asset_manager\run-server.ps1`，本地页面为 `http://127.0.0.1:8765/`。
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
11. 资源台只消费 Manifest 已登记的预生成 GIF，并可启动无写入的统一动作预览；点击动作、展开版本或启动 Godot 均不得隐式生成预览文件。通用 GIF 导出属于 [ART-03](art-03.md#推荐改造骨骼序列帧通用生产与预览仅设计待实施) 的显式生产入口，尚待实施。

## 验证入口

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
