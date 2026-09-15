# 美术资源台

本工具只管理 [主索引](../../../assets/art/asset_manifest.yaml)引用的对象清单。`assets/art/` 与 `design/concepts/` 的目录输入仅作当前项目边界校验；未登记文件不会成为对象、版本或资产。

## 对象清单格式

```yaml
schema_version: 2
object:
  id: sample_character
  display_name: 示例角色
  type: character
  subtype: ally
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
    files:
      concept:
        path: design/concepts/sample/sample/001/concept.png
        role: concept
        sha256: <selection baseline>
  asset_002:
    stage: asset
    version: 002
    selection: selected
    approval: approved
    files:
      sheet:
        path: design/concepts/sample/sample/002/sheet.png
        role: atlas
        sha256: <selection baseline>
      frames:
        path: design/concepts/sample/sample/002/animation.frames.json
        role: frame_metadata
        sha256: <selection baseline>
      animation:
        path: design/concepts/sample/sample/002/animation.tres
        role: animation_resource
        sha256: <selection baseline>
      gif_idle:
        path: design/concepts/sample/sample/002/review/idle.gif
        role: preview_gif
        sha256: <selection baseline>
    animation:
      representation: sprite_frames
      resource_file: animation
      clips_from: frames
    previews:
      gifs:
        idle:
          file: gif_idle
      godot:
        unit: res://resources/content/characters/sample.tres
        animation: res://design/concepts/sample/sample/002/animation.tres
integration:
  status: active
  active_variant: asset_002
  owner_resource: resources/content/characters/sample.tres
  evidence: docs/art/tasks/sample.md
  effective_files:
    sheet:
      path: assets/art/characters/sample/sheet.png
      role: atlas
      sha256: <integration baseline>
  bindings:
    sheet_copy:
      compare: sha256_equal
      selected_file: sheet
      effective_file: sheet
    unit_animation:
      compare: resource_reference
      source: resources/content/characters/sample.tres
      source_sha256: <owner baseline>
      target: res://resources/content/animations/sample.tres
relationships:
  projectile:
    kind: projectile
    object_id: sample_projectile
    resource_ref: sample_projectile.files.runtime_resource
```

`selection`、`approval`、`integration.status` 分别表示选取、人工批准和真实接入，互不推导。`approval_evidence` 使用 `source/date/decision`，可补 `quote/commit`。旧资产没有选取证据时写 `selection: unknown`，即使 Godot 正在使用也不能补成 selected。

文件角色当前包括 `concept`、`atlas`、`source`、`frame_metadata`、`animation_resource`、`effect_resource`、`projectile_resource`、`preview_gif`、`review`、`dependency` 和 `image`。每个 SHA-256 都绑定该行确切路径；资源台重算实际文件，不会写回新哈希。

动画的 `representation` 可扩展；当前 `sprite_frames` 用 `clips_from` 指向 `.frames.json`，页面从真实文件读取动作、帧数、FPS 与循环状态。GIF 与 Godot 预览可独立存在。Godot 入口只使用清单显式登记的 Unit、Animation 和可选 Projectile。

## 生效绑定

- `sha256_equal`：选取文件和生效文件都必须符合各自基线，且两端实时哈希相等；用于确定性复制的 PNG 等。
- `baseline_hash`：生效文件必须符合接入时基线；用于正规化后内容本就不同的正式 `.frames.json`、`.tres`。
- `resource_reference`：来源文件必须符合保存基线、目标存在，且来源仍精确包含登记的 `res://` 引用。

检查结果分别显示 `matched`、`mismatch`、`missing`、`unset`、`unselected`、`not_integrated`。检查动作不修改选择、批准、生效或基线。

## 运行与验证

```powershell
pwsh.exe -NoProfile -File .\run-art-manager.ps1
py -3 -m unittest discover -s tools/art/asset_manager/tests -v
```

服务只监听 `127.0.0.1`，文件和预览均通过本次启动生成的令牌访问；预览脚本固定为项目根 `run-motion-preview.ps1`，不接受任意命令或跨项目路径。
