# 美术任务：M1 主菜单视觉样板

状态：`concept_001` 已生成，当前为 `unselected + pending + not_integrated`，等待负责人进行**概念阶段**人工评审。生成成功、技术检查和本地提交均不代表标题方向、正式资产或接入效果已批准。

## 目标与范围

- 用途、数量与本次要求：建立一个主菜单 hero 概念样板，验证游戏标题标识、主视觉构图和原生导航区之间的关系；首轮只制作一个代表性版本，不批量生产标题家族、背景家族或按钮资产。
- 对应规范、已有身份参考：`docs/art/STYLE_BIBLE.md`、`docs/art/ART_CONTRACT.md`、`docs/art/WORKFLOW.md`、`docs/art/specs/UI_SPEC.md`、`docs/art/specs/ENVIRONMENT_SPEC.md`、`data/visual/colors.json`、`data/visual/typography.json`、`data/visual/spacing.json`。
- 已批准连续性参考：M1 图书馆日常／异常环境（`m1_library_environment`）与三色记忆终端家族（`m1_memory_artifact`）仅用于配色、光影和数字层级协调，不修改它们、不把它们烘焙进本候选。
- 目标 Godot 场景与现状：`scenes/menu/menu.tscn`；当前仍是 Godot 模板观感，标题为 `Godot Game Template`，使用 Open Sans Bold；本轮不改场景、不改 Theme、不改运行时代码。
- 不在本次范围内的内容：不实现主菜单、不制作正式可接入背景、不制作可发布标题字标、不修改 `scenes/menu/menu.tscn`、不替换字体、不加入新按钮或交互、不虚构真实校园建筑、不生成动画资产。

## 当前版本与方案

- 当前使用版：无；项目主菜单仍使用模板实现。本任务没有获得接入授权，保持 `not_integrated`。
- 本轮候选：Manifest 对象 `m1_main_menu_visual`，版本 `concept_001`，阶段 `concept`，文件 `design/concepts/m1-main-menu/m1_main_menu_visual/001/hero.png`。
- 方案名称：**抽象校园网络中庭 / Abstract Campus Node Plaza**。
- 主视觉：以中央圆形网络节点、放射式校园路径和少量通用理工建筑块面表达“校园系统正在被记忆重新连接”；画面明确是虚构抽象构图，不冒充真实校园地图或建筑。
- 标题标识方向：右上区域的青／品红双波形与节点组合，先作为不可读徽记占位；如果概念获批，正式标题需拆成独立可编辑标识或由原生／矢量方案实现，不能把菜单文字烘焙进背景。
- 导航关系：左侧三分之一保持低信息、低亮度，供原生 `开始`、`设置`、`退出` 等短动作按钮垂直排列；按钮文字只在 Godot 中实现，概念图不承诺最终文案。右侧中部保留中央节点焦点，避免导航遮挡核心世界观图形。
- 复用的批准方向／资产及原评审记录：`docs/art/tasks/m1-library-environment.md`、`docs/art/tasks/m1-memory-artifact.md` 及其 Manifest；本候选没有复制或修改其中任何文件。
- 技术依据：主视觉候选为 1672×941、非透明整屏 PNG；色彩沿用 `colors.json` 的 night／evening 角色，标题使用 `typography.json` 的 display 角色，按钮与正文继续使用原生 Theme 和 `spacing.json` 的 4px 倍数。精确接入裁切、字体字重和多分辨率适配待概念批准后另行制定。
- 提前试接入授权：无。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `design/concepts/m1-main-menu/m1_main_menu_visual/001/hero.png`；`78356ed97ea3f0568d0bb452bb18067285fb98cb88a4b7fcc0f9656680fe5090` | 待评审 | | 待负责人决定 |
| 资产 | 尚未制作 | 待评审 | 需先通过概念阶段 | |
| 接入效果 | 尚未制作 | 待评审 | 需先获得明确接入授权 | |

## 验证与结果

- 本任务验收条件：概念需在几秒内读出“校园＋数字连接”的主视觉；左侧能容纳原生导航，右上能容纳可编辑标题标识；不能出现真实校园身份冒充、可读伪文字、烘焙菜单或不可编辑的正式标题；概念状态必须保持 `unselected + pending + not_integrated`。
- 技术检查结果：`PASS_WITH_NOTES`。实际文件可读取，PNG，1672×941，`Format24bppRgb`，非透明，1,944,697 bytes；无文字、水印或签名。完整提示词、来源和质量闸门记录见同目录 `generation.md`。
- 复现检查命令：
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile('design/concepts/m1-main-menu/m1_main_menu_visual/001/hero.png'); $img.Width; $img.Height; $img.PixelFormat; $img.Dispose()`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/001/hero.png'`
- Manifest 回写：新增 `assets/art/manifests/m1_main_menu_visual.yaml` 并在 `assets/art/asset_manifest.yaml` 登记对象；`concept_001` 保持 `selection: unselected`、`approval: pending`；`integration.status: not_integrated`。
- 一致性检查：Manifest 的 root 与文件均指向实际存在的概念副本；未复制到 `assets/art/`，未增加 Godot 引用，未修改共享 Token、Theme、实现总览或 Roadmap。
- 实际截图／展示证据：本轮在对话展示了 `hero.png` 原图；该图片是概念阶段候选，不是 Godot 运行截图，也不作为接入验收证据。
- 资源台验证：`py -3 -m unittest discover -s tools/art/asset_manager/tests -v`，33 项测试全部通过；覆盖主 Manifest schema、对象发现、注册文件存在性及 `unselected + not_integrated` 不提升规则。直接首次运行 `run-server.ps1 -Port 8876 -NoOpen` 在仓库既有 Godot 导入阶段失败，日志显示缺失 Open Sans 导入缓存、编辑器设置写入限制及既有 `settings_menu.gd` 解析报错；本轮未修改工具链、Theme 或运行时代码。
- 专业边界与已知问题：生成图的理工图形细节在小尺寸可能退化为装饰噪声；正式资产阶段应简化细节、单独制作标题标识，并以实际菜单安全区和三种桌面分辨率重新验证。概念批准前不做这些下游工作。
- 本地提交：本轮概念候选、来源记录、任务档案与 Manifest 已在本分支提交；不推送远程。
