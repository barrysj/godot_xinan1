# Codex 中文 Prompt 模板

## 1. 通用视觉实现

请实现【功能名】。

读取：
- `docs/art/ART_CONTRACT.md`
- `【当前任务 Spec 路径】`
- `docs/art/asset_manifest.yaml`

只在需要时读取：`data/visual/`

要求：严格按 Spec 实现；使用 Manifest 已批准资产；复用现有 Theme/组件；不重新设计 UI；不生成新美术；不读取完整 STYLE_BIBLE，除非 Spec 与 Contract 无法解决冲突。

验证：1920×1080、2560×1440、16:10，并运行相关 Godot 检查。

完成后只汇报：修改文件、实现结果、验证结果、遗留问题。

---

## 2. UI 页面实现

请实现 UI 页面【页面名】。

读取：
- `docs/art/ART_CONTRACT.md`
- `docs/art/UI_SPEC.md`
- `tasks/【任务文件】`
- `docs/art/asset_manifest.yaml`

要求：使用现有 Theme；品牌色从 `data/visual/colors.json` 读取；使用 Container/Anchor 做响应式；不要硬编码重复色值；不要自行调整冻结布局；不要生成或替换视觉资产。

验证：1920×1080、2560×1440、16:10。

如果实际资源尺寸与 Manifest 不一致，不要猜测，在最终报告中明确指出。

---

## 3. 场景资产接入

请将已批准场景资产【asset key】接入【Godot Scene】。

读取：
- `docs/art/ART_CONTRACT.md`
- `docs/art/ENVIRONMENT_SPEC.md`
- `docs/art/asset_manifest.yaml`

要求：使用 Manifest 路径；遵守 crop_mode/anchor/layer；不重画、不替换、不重新设计场景；保持现有 Gameplay 逻辑不变。

验证：目标分辨率无明显裁切；交互节点可用；无新增报错。

---

## 4. 视觉 QA 修复

根据以下明确问题修复，不扩大范围：

【粘贴 QA 问题清单】

读取当前相关 Scene/UI、`docs/art/ART_CONTRACT.md` 和必要 Token。

禁止：重构无关模块、重新设计其他区域、替换美术资产、额外加入特效。

完成后逐条说明是否已修复。
