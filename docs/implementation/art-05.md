# ART-05 · Manifest 驱动的美术资源台

- 功能 ID：ART-05
- 所属系统：美术工具

## 当前状态

- 状态：已验证（本地资源登记、哈希核验与预览范围）。资源台与粉笔资产现已在同一集成工作树验证。
- 功能入口：`pwsh.exe -NoProfile -File .\run-art-manager.ps1`，本地页面 `http://127.0.0.1:8765/`。
- 管理入口：[主 Manifest](../../assets/art/asset_manifest.yaml)及 `assets/art/manifests/` 对象清单；格式说明见[工具说明](../../tools/art/asset_manager/README.md)。
- 范围：只处理当前项目登记对象；不兼容任意目录，不提供跨项目预览，不承担审批、编辑、生图或运行时内容加载。

## 已实现能力

1. Manifest 权威发现：对象、类型、版本、文件、关系和状态只来自主索引与对象清单；目录只验证登记文件位于项目边界，未登记文件不会进入受管列表。
2. 分阶段状态：概念／资产版本分别展示 selection 与 approval；integration 独立记录实际生效版本、正式文件及 Godot 引用，避免把“选中”“批准”“已接入”混成一个状态。
3. 多文件动画：同一版本登记图集、帧元数据、Godot Resource、必要依赖与 GIF；页面从指定 `.frames.json` 展开 clip，representation 可扩展，不假设所有动画都是帧图集。
4. 双预览入口：已登记 GIF 直接播放；Godot 预览以固定参数数组传入显式 Unit、Animation 与可选 Projectile，不回退默认对象。
5. 实时一致性：逐文件重算 SHA-256，报告一致、不一致、缺失或未设基线；`sha256_equal`、`baseline_hash`、`resource_reference` 分别验证确定性复制、正式基线与实际引用链，校验不写回基线。

## 迁移说明

- 旧 v1 的守护者、远射手、守护护盾、校园庭院、电子实验室与异变教室六个对象已拆入独立 v2 清单。
- 原有路径、分辨率、透明度、图集、画布、显示尺寸、锚点、头像裁切、用途、风格层与试接入说明均保留。
- 六项旧资产仍是 `approval: review`；因旧记录没有明确版本选取证据，写为 `selection: unknown`。Godot 当前引用存在，所以 integration 为 `authorized_active`。文件哈希明确作为 2026-09-15 迁移／接入基线，不冒充历史选择时基线；迁移没有把它们升级成 selected 或 approved。

## 验证记录

- 日期：2026-09-15。
- 代码基线：分支 `codex/art-asset-manager`，功能提交 `dea8869`、文档基线 `36b5c30`；粉笔精灵数据来自 `art/chalk-spirit-concept` 的对象清单提交 `8016e90` 与完整 v2 根索引提交 `b661bad`。
- 命令：`py -3 -m unittest discover -s tools/art/asset_manager/tests -v`。
- 结果：11 tests PASS。覆盖 Manifest-only 发现、未登记文件排除、概念／资产多版本、GIF HTTP 播放、clip、限定对象关系、真实哈希不一致、文件缺失、未选择／未接入、三种 binding、Unit+Animation+Projectile 参数、安全边界，以及六个旧对象迁移后全部基线一致。
- 实际数据：六个对象、12 个唯一登记文件（选取侧与正式生效侧分别保留校验视图），0 个哈希不一致、0 个缺失；所有已声明生效对象的引用 binding 通过。
- 页面验证：在 `http://127.0.0.1:8766/` 实际打开页面，显示 6 个 Manifest 对象、12 个登记文件、0 处不一致；守护者详情展开 7 个动作及各文件哈希，浏览器控制台无错误。点击“预览”返回 `预览窗口已启动 · res://resources/content/characters/guard.tres`，确认使用显式 Unit，并由自动化测试锁定 Unit+Animation+可选 Projectile 的参数数组顺序。
- 数据兼容验证：用 `dea8869` 解析器只读扫描 `art/chalk-spirit-concept@b661bad` 的完整 v2 Manifest，得到 8 个对象、71 个唯一登记文件、0 个不一致、0 个缺失、全部对象 0 warning。粉笔精灵包含 5 个版本，005 展开 7 个 clip 与 7 个可播放 GIF，正式接入和弹体关系均为 matched；粉笔弹体 001 的接入与 Godot 预览目标均通过。
- 组合页面验收：以 `dea8869` 的资源台服务只读指向 `art/chalk-spirit-concept@b661bad` 项目根，在 `http://127.0.0.1:8767/` 显示 8 个对象、71 个登记文件、0 处不一致。粉笔精灵详情准确展示概念 001、资产 002—005、正式 005 的 3 张图集、7 个动作、7 个 GIF、实际生效文件与弹体关系；同一 GIF 相隔 350 ms 的页面截图 SHA-256 不同，确认浏览器实际播放而非静态占位。
- 组合预览验收：实际点击正式 005 的“预览”后，页面返回 `预览窗口已启动 · res://resources/content/enemies/chalk.tres`。关闭该开发预览后再点击粉笔弹体 001 的“预览”，实际 Godot 子进程命令行包含 `--preview-unit=res://resources/content/enemies/chalk.tres`、`--preview-animation=res://design/concepts/chalk-spirit/chalk-spirit/005/battle_animation.tres` 与 `--preview-projectile=res://design/concepts/chalk-spirit/chalk-projectile/001/chalk_projectile.tres`，没有默认对象回退。
- 引擎验证：正式接入动画 `res://resources/content/animations/chalk.tres` 与候选动画＋弹体组合分别执行 `run-motion-preview.ps1 -Check`，均以退出码 0、`MOTION_PREVIEW_CHECK failures=0` 通过；待机、移动、远程、施法、受击、濒危、退场通过，近战按该单位能力正确跳过。候选动画＋弹体执行 `-Capture`，Godot OpenGL 实际渲染完成 1920×1080、2560×1440、1920×1200 三组截图，远程截图可见自定义序列帧角色与粉笔弹体。

## 已知边界

- 上述 8767 记录是合并前的固定提交组合验收；集成后的结果见下节，不新增跨项目预览产品能力。
- `BattleEffectSet` 当前没有独立 Godot 预览入口；可登记 GIF，或等待具体效果具备准确现有预览场景后再登记，不扩展通用播放器。
- Godot 仍读取 `.tres`，不读取 YAML。Manifest 的职责是生产追溯与验证，不替代运行时内容系统。

## 集成验证与维护

- 日期：2026-09-15；基线：main `1a2948e`、粉笔数据 `b661bad`、工具 `c44a862` 的本次合并树；精确合并提交由 Git 历史记录。
- 在同一项目重跑 11 项 Python 测试；迁移测试检查原六对象及粉笔两对象存在，不再假定全库只有六对象。实际清单为八对象、71 文件，无缺失和哈希差异。
- 集成时发现粉笔分支的 12 个登记文本含 CRLF 或混合换行，检出为 LF 会改变 SHA-256。逐个验证原工作树字节符合原基准、与合并文件仅换行不同后恢复原字节，通过 `.gitattributes` 的精确路径 `-text` 规则保存；没有重写 Manifest 哈希或批准记录。
- 新登记文本应在选取及计算基准前统一持久化字节与 Git 属性；不能在校验时自动正规化或重建基准。已有登记文件的字节保护不能随普通格式化移除。
- 启动脚本健康检查改为识别实际 v2 服务标识；使用 `pwsh.exe -NoProfile -File ./run-art-manager.ps1 -Port 8770 -NoOpen` 验证集成目录服务。
- 共享 Godot 检查与截图入口见 [E19](verification.md#美术集成验证-e19)，不在高层总览复制测试明细。

## 交接给统筹

已汇总至 2026-09-15 实现总览和功能目录；保留 main 的 M1 优先级与分层档案结构。此次仅纳入已授权的项目专用资源台例外。
