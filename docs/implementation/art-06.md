# ART-06 可复用照片全息卡

状态：独立原型已验证，视觉待人工评审，主游戏未接入。

入口：`scenes/holo_card/holo_card_preview.tscn`、`holo_card_view.tscn`；资源：`game/art/holo_card_visual.gd`；启动／验证：`run-holo-card.ps1`。操作和离线制作规则见[照片卡](../art/holo-cards.md)，批准事实源见[美术任务](../art/tasks/class-photo-holo-card.md)。

## 验证

- 日期：2026-09-16；基线 main d01b03e，新分支 art/class-photo-holo-card 的本功能提交。
- `./run-holo-card.ps1 -Mode Check`：Godot 4.7.2 Compatibility，全部检查通过、failures=0。截图覆盖 1920×1080、2560×1440、1920×1200、844×390；倾斜／流光变化检查实际渲染像素，静态稳定，竖图替换、多实例材质隔离、空图回退和模拟触摸通过。
- `./run-holo-card.ps1 -Mode Layers`：输出四张 1600×1400 PNG。
- `./tools/art/holo_card/build-blender.ps1 -Python <带 Pillow 的 Python>`：Blender 4.5.14 LTS，校验、源工程、三视角渲染和 GLB 导出完成。
- Godot 运行日志无脚本／shader 错误；编辑器导入退出时有 EditorSettings shutdown_adb_on_exit 提示，导入及后续实机渲染成功。上游 Blender 有 NodeSocket.default_value 警告，渲染和导出仍成功；不宣称所有第三方日志无警告。
- 原图 SHA256 一致；证据见任务链接及其 checks.json。程序检查不代表审美批准或手机/Web 验收。

## 边界与待统筹

新增可独立复用视觉能力，不绑定里程碑；无游戏运行时第三方依赖，但可选离线制作引入 Blender/Pillow。待统筹：确认未来放入图鉴、回忆解锁还是其他入口；本次不改总览/Roadmap，不连存档／奖励逻辑。未测批量卡片性能、真机和 Web，当前固定横向模板，正式发布前确认合照公开使用范围。
