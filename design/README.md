# 美术源资料

设计方向、具体对象方案与实施说明集中在[美术文档](../docs/art/README.md)，当前状态由[Manifest](../assets/art/asset_manifest.yaml)登记。此目录只保存参考和必要生产源，不承载审批流水账。

- references/：负责人提供的照片、地图、DXF／GLB、上游资料及许可。
- concepts/characters/：我方人物身份参考与当前动画源包。
- concepts/enemy/：敌人、弹体与当前混合动画源包。
- concepts/environments/：校园大地图、地点、图书馆和菜单背景。
- concepts/ui/：基地、探索、战斗与选择页的源组件。
- concepts/props/：记忆终端、闪卡样本与必要制作源。

concept_###与asset_###只表示资料阶段；批准状态看Manifest。当前资产保留足够的原图、模型、参数和处理入口；仍被预览脚本引用的旧源包属于必要依赖。未知未跟踪文件不自动清理。运行交付在assets/art，Token在data/visual；这些目录各有职责，不复制成文档附件。

原始提示词、实际生成调用、参考图及用途、生产参数和处理脚本是制作配方，随保留版本维护；不是审批流水，不因记录精简而删除。`generation*.md`／`generation*.json`保存原文或指向本包的调用文件，原记录只有摘要时明确标注摘要；种子、模型版本未记录时不得补造。机器参数继续以本包JSON／资源为准。

资源浏览器使用的缩略图、动作GIF和交付预览随源包保存在`review/`或Manifest指定位置并进入Git；清理前核对全部保留版本的files、previews和资源依赖，不删除仍用于浏览的文件。已有三个正式演示GIF沿用原路径，由Git忽略规则显式豁免。

Codex工作流的临时截图、试渲染、接触表、审核报告、日志和临时脚本统一输出到`.godot/art-workflow/`，不进入Git。旧`review/codex-workflow/`目录也默认忽略；新交付预览使用`review/`，不再混入工作流临时目录。历史废稿和逐次审核从Git查阅，不在活动目录重建历史图库。校园三态源包入口见[校园图](concepts/environments/campus-map/campus-map/asset_001/README.md)。
