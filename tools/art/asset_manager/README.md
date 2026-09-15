# 美术资源台

本工具只读取用户指定的主 Manifest。对象、版本和文件均由 Manifest 登记产生；不会扫描目录补对象，也不提供跨项目预览。

## 主 Manifest

```yaml
schema_version: 3
objects:
  sample_character: manifests/sample_character.yaml
  sample_projectile: manifests/sample_projectile.yaml
```

对象清单路径相对主 Manifest。页面只需要填写这个主 Manifest 的路径，不再填写资产目录。

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
      source: docs/art/tasks/sample.md
      date: 2026-09-15
      decision: approved
    root: design/concepts/sample/character/001
    files:
      concept: concept.png
  asset_002:
    stage: asset
    version: 002
    selection: selected
    approval: approved
    root: design/concepts/sample/character/002
    files:
      locomotion_sheet: locomotion_sheet.png
      frame_metadata: animation.frames.json
      gif_idle: review/idle.gif
    resource: design/concepts/sample/character/002/animation.tres
    animation:
      frames: frame_metadata
    previews:
      gifs:
        idle: gif_idle
      godot:
        unit: res://resources/content/characters/sample.tres
        animation: res://design/concepts/sample/character/002/animation.tres
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
  evidence: docs/art/tasks/sample.md
```

规则很短：

- `root` 相对项目根；`files` 中只写相对 `root` 的路径。单个 Godot `.tres` 使用 `resource`，避免为了一个不同目录的资源把整段路径重复到每个文件。
- `stage` 负责把版本放入概念、资产等选项卡。
- `selection` 表示当前流程选用哪个版本；`approval` 表示负责人是否批准这个版本。选用不等于批准，技术验证也不等于批准。
- 动画只登记帧元数据文件键；资源台从 `.frames.json` 读取动作，并从 `.tres` 自动识别资源类型和引用，不登记 `representation`。
- 关联只登记目标对象 ID。资源台自动提供目标缩略图、状态和详情跳转，不登记目标内部文件路径。
- Manifest 不保存 SHA-256、`compare` 或引用检查策略。校验时实时计算选用文件与正式文件的 SHA-256，并直接解析 `.tres` 检查引用与缺失依赖。

## 运行与验证

```powershell
pwsh.exe -NoProfile -File .\run-art-manager.ps1
py -3 -m unittest discover -s tools/art/asset_manager/tests -v
```

资源台启动动作预览前会先让 Godot 增量导入当前项目资源；这是为了修复切换分支后 `.godot/imported` 目录存在但内部缓存不完整时出现的灰屏。

服务只监听 `127.0.0.1`。文件和预览由本次启动令牌保护；预览入口固定为当前项目的 `run-motion-preview.ps1`。
