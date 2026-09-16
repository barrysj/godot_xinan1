# 美术任务：M1 图书馆静态环境

状态：概念候选已生成，等待人工概念评审；尚未批准、未制作正式资产、未接入 Godot。

## 当前推荐：concept_002（2026-09-16）

用户已提供正门航拍与入口内固定点四向环视，现实参考阻塞解除。参考原件保存于 `design/concepts/m1-library-environment/references/`；均为用户提供的设计参考，未用于照片卡。下方 001 内容仅保留历史，不再作为当前方案。

- 推荐版本：`m1_library_environment/concept_002`；文件 `design/concepts/m1-library-environment/m1_library_environment/002/concept.png`；生成过程见同目录 `generation.md`。
- 以第二张参考的入口内侧望中庭为机位，保留多层环廊、木栏杆、玻璃采光顶、侧楼梯与挑空。第四张的入口闸机在机位背后，不擅自移入画面；不沿用虚构阅读桌布置。
- 001 保留 `unselected + pending` 作为未批准历史；002 同为 `unselected + pending`，对象保持 `not_integrated`。推荐不代表流程选用或人工批准。
- 待人工审核：建筑辨识度、楼层与楼梯关系、日常配色与赛璐璐程度。002 SHA-256：`81BE939055B23A1B16C6BA0A4189051C270B5438FD9D20AF2A12CB10FC77EA0B`。
- 未解决边界：热点和侧栏需按中庭画面重新排布，现有归一化坐标不能直接视为验收通过；阅读区和借阅设备细部无清晰参考，不补造。异常／恢复仍等日常批准后制作。
- 验证基线：`10dfbcd`；日期 2026-09-16。前轮资源台 33 测试通过；本轮运行 AssetCatalog.scan 核验两版实际文件与 pending/unselected/not_integrated 状态，PNG 头与 SHA-256 核验，`git diff --check`。结果见本次提交与聊天回报。
- 未改运行画面，按工作流仅展示概念原图；本地提交涵盖本任务候选、参考和登记，不包含统筹临时 AGENTS.md 更改。待统筹：概念已具真实参考，尚未取得人工批准，不代表图书馆精制完成。

## 目标与范围

- 用途、数量与本次要求：为 M1 图书馆地点制作一张日常静态环境的推荐概念候选。它服务于现有原生地点示意的未来替换，但本次不修改游戏。
- 对应规范、已有身份参考：[场景规范](../specs/ENVIRONMENT_SPEC.md#8-图书馆)、[视觉方向](../STYLE_BIBLE.md#3-核心视觉支柱)、[M1 静态清单](../m1-static-assets.md)。当前没有真实图书馆原照或环境参考；候选是明确虚构的风格概念，不能冒充真实地点或照片。
- 目标 Godot 场景、入口与依赖：`scenes/expedition/campaign_board.gd` 的图书馆地点示意。当前四热点按位置为左下守卫、左上回忆档案、中右下发明家、右上借阅终端；中央阅读桌与侧边详情覆盖区须保持可读。
- 不在本次范围内的内容：正式背景、Godot 接入、运行截图、人物／守卫、照片内容、异常／恢复衍生状态、动画、其他六地点、两个尚未确定身份的终点。

## 当前版本与方案

- 当前使用版：无；`m1_library_environment` 未接入。
- 本轮候选：`concept_001`，概念阶段；[原图](../../../design/concepts/m1-library-environment/m1_library_environment/001/concept.png)，生成记录见同目录 [generation.md](../../../design/concepts/m1-library-environment/m1_library_environment/001/generation.md)。
- 本轮取舍：白天自然光、学习区、书架和电子借阅共同确立图书馆身份；以低饱和浅色为主，少量青蓝作为数字提示。画面没有 UI 或交互标记，保留热点覆盖空间。
- 复用的批准方向／资产及原评审记录：仅沿用 v0.3 日常校园方向与 `colors.json` 日常层；没有复用可视化环境资产，也没有可继承的图书馆批准记录。
- 技术依据：实际输出 1672 × 941 PNG、非透明；主 Manifest 与对象 Manifest 已登记。`campaign_board.gd` 仍使用原生几何绘制，故没有 selected-to-effective binding。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `concept_001/concept.png` · `A9D75DCCB6AD4DD7AA0C522FF08403DA12494CF648A483B17236A3ACB715646A` | 待评审 | 需确认日常机位、空间布局与偏细腻的 2D 表现是否可作为正式资产方向。 | 待负责人决定 |
| 资产 | 未制作 | 不适用 | 概念批准后才制作。 | 待负责人决定 |
| 接入效果 | 未接入 | 不适用 | 正式资产批准后才接入并三尺寸截图。 | 待负责人决定 |

## 验证与结果

- 本任务验收条件：真实候选文件存在、主／对象 Manifest 能发现该对象、概念保持 `unselected + pending`，`integration.status` 为 `not_integrated`。
- 技术检查：`[System.Drawing.Image]::FromFile(...)` 核对 1672 × 941；`Get-FileHash -Algorithm SHA256` 核对表内哈希。资源台目录契约见 `tools/art/asset_manager/README.md`。
- Manifest 回写：`m1_library_environment/concept_001` 已登记实际文件；无 `approval_evidence`、无 Godot 预览、无生效文件或对象关系，避免暗示批准或接入。
- 一致性检查：不适用；没有 active variant 或运行时引用。
- 实际截图／动作预览证据：概念原图已在本次对话展示。未改变运行画面，依工作流不启动游戏或伪造运行截图。
- 未解决问题：缺真实图书馆原照、来源与短回忆；概念尚待人工决定。批准日常样板后，异常／恢复衍生必须同机位再单独审核。
- 本地提交：待 Manifest 校验与 Git 复核通过后填写。
