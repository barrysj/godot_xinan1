# ART-05 · Manifest 驱动的美术资源台

- 功能 ID：ART-05
- 所属系统：美术工具

## 当前状态

- 状态：Manifest v3 已实现并完成页面验收。
- 功能入口：`pwsh.exe -NoProfile -File .\run-art-manager.ps1`，本地页面 `http://127.0.0.1:8765/`。
- 管理入口：[主 Manifest](../../assets/art/asset_manifest.yaml)及 `assets/art/manifests/` 对象清单；格式见[工具说明](../../tools/art/asset_manager/README.md)。
- 范围：只处理当前项目登记对象；不兼容任意目录，不提供跨项目预览，不承担审批、编辑、生图或运行时内容加载。

## 当前接口

1. 页面只接收一个主 Manifest 路径。主文件索引对象清单，目录不再作为输入。
2. 对象版本使用一个项目相对 `root`，`files` 仅保存相对路径；单个 Godot 文件用 `resource` 登记。
3. `stage` 决定概念、资产等详情选项卡。`selection` 表示当前选用版本；`approval` 表示负责人是否批准，二者独立显示；`integration` 记录真实接入。
4. 动画动作直接读取 `.frames.json`；资源类型和依赖直接解析 `.tres`，不在 Manifest 保存 `representation`、`role` 或 `resource_reference` 比较规则。
5. Manifest 不保存 SHA-256。资源台每次校验都根据选用路径与正式路径实时计算内容哈希；Godot 所有者引用与缺失依赖则从 `.tres` 实时检查。
6. 跨对象关系只登记目标对象 ID。详情展示目标缩略图、状态与跳转入口。
7. 详情内容用响应式网格适配可用宽度；不同 stage 不再纵向平铺。

## 验证入口

- `py -3 -m unittest discover -s tools/art/asset_manager/tests -v`
- `node --check tools/art/asset_manager/static/app.js`
- `py -3 -m py_compile tools/art/asset_manager/catalog.py tools/art/asset_manager/server.py`
- 页面需核对 Manifest 单输入、stage 切换、宽屏网格、粉笔弹体缩略图与跳转、GIF 播放和 Godot 预览入口。

## 2026-09-15 验证记录

- 自动测试：13 项通过；Python 编译、JavaScript 语法与 Git 差异检查通过。
- 数据校验：8 个对象、71 个登记文件，0 缺失、0 不一致。
- 响应式：1600 px 视口为两列版本卡；700 px 视口自动降为单列，无横向溢出。
- 交互：概念选项卡只显示版本 001；关联素材展示粉笔弹体缩略图，并可跳转到粉笔弹体详情。
- 截图：`.godot/art-manager-v3-stage-tabs-20260915.png`、`.godot/art-manager-v3-related-20260915.png`（本地验收产物，不入库）。

## 历史迁移

- v2 曾以逐文件 SHA-256、显式 role／representation 与三类 binding 保存完整迁移基线；该方案在 2026-09-15 通过 8 对象、71 文件与 Godot 组合验收。
- v3 根据负责人反馈删除可从文件和 `.tres` 推导的字段。原有选择、批准、评审依据、接入状态、预览参数和有效视觉元数据保持不变；六项旧资产仍为 `approval: review`、`selection: unknown`，没有借迁移升级批准状态。
- Godot 仍读取 `.tres`，不读取 YAML。Manifest 只负责生产对象、版本和路径语义。
