# 美术资源台功能档案

## 当前状态

- 状态：已实现，待与粉笔精灵资产分支整合后做联合验证。
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
- 代码基线：分支 `codex/art-asset-manager`，功能提交 `dea8869`。
- 命令：`py -3 -m unittest discover -s tools/art/asset_manager/tests -v`。
- 结果：11 tests PASS。覆盖 Manifest-only 发现、未登记文件排除、概念／资产多版本、GIF HTTP 播放、clip、限定对象关系、真实哈希不一致、文件缺失、未选择／未接入、三种 binding、Unit+Animation+Projectile 参数、安全边界，以及六个旧对象迁移后全部基线一致。
- 实际数据：六个对象、12 个唯一登记文件（选取侧与正式生效侧分别保留校验视图），0 个哈希不一致、0 个缺失；所有已声明生效对象的引用 binding 通过。
- 页面验证：在 `http://127.0.0.1:8766/` 实际打开页面，显示 6 个 Manifest 对象、12 个登记文件、0 处不一致；守护者详情展开 7 个动作及各文件哈希，浏览器控制台无错误。点击“预览”返回 `预览窗口已启动 · res://resources/content/characters/guard.tres`，确认使用显式 Unit，并由自动化测试锁定 Unit+Animation+可选 Projectile 的参数数组顺序。

## 已知边界

- 粉笔精灵对象清单由 `art/chalk-spirit-concept` 分支单独产出；两分支尚未组合，当前不能宣称其概念 001、资产 002—005、七个 GIF、弹体关系和正式预览已在资源台联合通过。
- `BattleEffectSet` 当前没有独立 Godot 预览入口；可登记 GIF，或等待具体效果具备准确现有预览场景后再登记，不扩展通用播放器。
- Godot 仍读取 `.tres`，不读取 YAML。Manifest 的职责是生产追溯与验证，不替代运行时内容系统。
