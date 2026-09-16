# ART-06 可复用照片全息卡

状态：已按用户授权接入主游戏“图鉴 → 闪卡”，支持缩略图、实时交互详情与目录自动发现；002 在 2587e92 的预览效果获用户认可，新增图鉴布局待用户体验，公开发布批准不由此推定。

入口：`scenes/holo_card/holo_card_preview.tscn`、`holo_card_view.tscn`；资源：`game/art/holo_card_visual.gd`；启动／验证：`run-holo-card.ps1`。操作和离线制作规则见[照片卡](../art/holo-cards.md)，批准事实源见[美术任务](../art/tasks/class-photo-holo-card.md)。

## 验证

- 2026-09-16 自动发现，基线 5b8728d：holo_card_catalog.gd 使用 ResourceLoader.list_directory，固定扫描活动目录直接子项、按目录名排序、类型与照片检查；进入闪卡页刷新，缺 review 回退原图。holo_catalog_check.tscn 在源码及项目外 PCK 运行均 PASS，测试空目录、新增两卡、排序和错误类型跳过，源码附模板替换加载检查；holo_card_check.tscn 自动发现后实际截图 PASS。模板位于技能 assets/holo_card/card.tres；需替换 ID 和文案、导入图片并生成 review。待统筹：已接入图鉴和自动发现，但不加解锁/存档；新增发布内容需重新导出，当前 all_resources 配置须保留或显式包含卡目录。非全平台验收。

- 2026-09-16 图鉴接入，基线 521c84d：新增 scenes/codex/holo_card_page.gd 与 holo_card_check.tscn；从现有图鉴进入缩略图列表与实时详情，关闭即释放。使用 Godot 图形模式运行 holo_card_check.tscn 与 menu.tscn -- --codex-check，均 PASS；截图覆盖三种桌面窗口目标，原有图鉴35项与战斗暂停恢复通过。项目旧像素图加载警告仍存在，不属于闪卡错误。用户已授权本地游戏接入，公开照片使用仍待另行确认。

- 2026-09-16 文档与技能整理，核对基线 `dc8da12`：`docs/art/holo-cards.md` 集中维护已完成功能、实现职责、最简制作与自动发现边界；现有 `.agents/skills/art-implementation/SKILL.md` 增加闪卡子流程，详细步骤引用主题文档，不新建独立技能或重复手册。仅静态检查技能格式、引用和 Git 差异，不重跑游戏、不改批准状态。待统筹：技能已纳入闪卡简化例外；运行时自动发现和主游戏展示仍未实施，总览与 Roadmap 本轮不改。

- 2026-09-16（基线 b9daea3）：活动卡移至 `assets/art/holo_cards/class_photo/`，保留历史实验；默认预览加载活动资源，共享 Resource 不再携带合照默认文案。新增 `tools/art/holo_card/render-review.ps1` 与 `scenes/holo_card/render_review.tscn`，运行 `-Card res://assets/art/holo_cards/class_photo/card.tres -Godot <引擎路径>` 生成实际 1600×1400 默认角度流光 review.png。Godot 4.7.2 Compatibility 渲染通过，无渲染报错；重复渲染 SHA256 一致。首次导入仍有项目原有字体缓存、插件常量及 EditorSettings 提示，不算全项目无错误。待统筹：活动卡采用原图 + 单份资源 + 截图最简流程，截图需在内容或共享特效改动后手动重建；不增加 Blender 依赖，主游戏未接入。

- 2026-09-16 归属盘点和清理，基线 `2587e92`：见[复用盘点与简化建议](../art/holo-cards.md#复用盘点与简化建议)。移除本工作树 304 个可重建缓存／临时文件，共 148.55 MiB；Git 忽略文件清单清空，保留全部源资产、评审证据和资源身份文件。本轮不改运行画面，不重启引擎；静态检查路径、Manifest、Git 差异。通用化建议未实施；待统筹项包含解耦样本、统一检查／导入和正式导出资源筛选，不改总览或 Roadmap。

- 2026-09-16 倾斜方向修复，基线 `3023205`：屏幕 Y 向下而旋转矩阵 pitch 未反号，导致上下与左右方向相反。仅反转垂直角，不改输入、流光或照片位移。新增 `scenes/holo_card/check_tilt_direction.tscn`，通过实际组件鼠标事件入口驱动四向输入并测量 GPU 渲染透明轮廓：修复前左右通过、上下失败（指针侧跨度 602 > 对侧 578），修复后四向通过（上下 578 < 602，左右 504 < 524）。用 Godot `--path . --rendering-method gl_compatibility res://scenes/holo_card/check_tilt_direction.tscn` 重跑，failures=0；既有 `--card-check` 全部通过，覆盖四分辨率及独立流光开关。证据位于 review/codex-workflow/tilt-direction/，含 up-before.png 与 checks-before.json；最终场景测试无脚本／shader 报错。初次脚本型测试触发项目 autoload 对 current_scene 的空引用，已改为常规场景测试避免该无关启动问题。

- 2026-09-16 照片流光增量，基线 `3f28db6`：002 新增照片虹彩和“照片光”独立按钮，原“流光”改称“框流光”；001 兼容保持无照片镀膜。使用 Godot console `--path . --rendering-method gl_compatibility res://scenes/holo_card/holo_card_preview.tscn -- --card-check` 直接运行（不经过有 EditorSettings 提示的导入步骤），结果 failures=0，无运行报错。检查覆盖四分辨率、新按钮信号连接、独立开关的照片区域像素、竖图留边不着色、静态稳定和既有交互。截图及 checks.json 位于原证据目录下 photo-foil-002/，旧证据保留。实际鼠标／手机触摸端到端和 Web 仍未验收。

- 日期：2026-09-16；基线 main d01b03e，新分支 art/class-photo-holo-card 的本功能提交。
- `./run-holo-card.ps1 -Mode Check`：Godot 4.7.2 Compatibility，全部检查通过、failures=0。截图覆盖 1920×1080、2560×1440、1920×1200、844×390；倾斜／流光变化检查实际渲染像素，静态稳定，竖图替换、多实例材质隔离、空图回退和模拟触摸通过。
- `./run-holo-card.ps1 -Mode Layers`：输出四张 1600×1400 PNG。
- `./tools/art/holo_card/build-blender.ps1 -Python <带 Pillow 的 Python>`：Blender 4.5.14 LTS，校验、源工程、三视角渲染和 GLB 导出完成。
- Godot 运行日志无脚本／shader 错误；编辑器导入退出时有 EditorSettings shutdown_adb_on_exit 提示，导入及后续实机渲染成功。上游 Blender 有 NodeSocket.default_value 警告，渲染和导出仍成功；不宣称所有第三方日志无警告。
- 原图 SHA256 一致；证据见任务链接及其 checks.json。程序检查不代表审美批准或手机/Web 验收。

## 边界与待统筹

新增可独立复用视觉能力，不绑定里程碑；无游戏运行时第三方依赖，可选离线制作使用 Blender/Pillow。待统筹：图鉴展示与自动发现已完成，回忆解锁/奖励/存档仍未接入；不改总览/Roadmap。未测批量卡片性能、真机和 Web，当前固定横向模板，正式发布前确认合照公开使用范围。
