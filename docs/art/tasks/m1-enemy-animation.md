# 美术任务：首批图书馆敌人混合动画

状态：负责人已批准仅保留五套最新 `tmp_002`，正式留存为 `asset_001` 并提升运行子集；旧首版按授权清理。主线单位尚未绑定，接入效果未批准。分支 `art/enemy-hybrid-animation`，来自本地 main `2eaa397`。独立工具已本地提交 `36fac21`、`4afdab9`、`90bbf7e`。

## 资产批准与留存决定（2026-10-07）

负责人原话：“‘已生成资产’用选择框筛选、而不是标签。只保留最新一版，并提升为正式资产”。该决定绑定刚展示的五套 `tmp_002` 完整动画包：七动作、施法光效、管理员攻击／施法修订及四轮印章修正。按决定删除被替代的五套 `tmp_001` 及其跨角色旧版评审证据；保留批准概念和最新包的源稿／生成追溯、动作卡、运行资源、GIF 与最低限度实机证据。

编号审计：五对象的 tmp 已分配上限均为 `002`，此上限在删除前记录，后续临时候选从 `tmp_003` 开始。目录、Git 中的对象登记历史和本任务均无已留存 asset 号，首次留存分配 `asset_001`；不重排历史概念编号。正式稳定目录为 `assets/art/characters/<对象ID>/`。批准资产与主线接入状态独立，本轮不新增敌人属性、技能规则或关卡编组。

## 已确认范围（2026-10-07）

负责人要求制作四种普通敌人与一种 Boss 的七种混合动画，并选择“图书馆这组”：键帽拳灵、投影独眼灵、归还印章怪、馆藏巨典，以及 Boss 图书管理员。概念批准依据与原图见 [敌人家族](m1-enemy-cast.md) 和各对象 Manifest。

负责人确认：“确认，按现有视角连续制作”。允许已批准概念板替代完整三视图，按现有战斗单视角连续制作动作卡、画稿、运行包与实机预览。不将本轮解释为八方向资产、正式资产批准、接入效果批准、留存或合并授权。

| 对象 | 批准概念 | 攻击意图 | 施法意图 |
| --- | --- | --- | --- |
| keycap_brawler | concept_002 | 收拳蓄力，双键拳面前冲 | 双拳压键蓄能，脉冲释放 |
| projector | concept_003 | 挡片聚焦，镜头出光 | 强化投射 |
| return_stamp | concept_002 | 柄沿套筒下压、抬升、垂直盖印 | 保持四轮形状，柄抬升、印记扩散 |
| great_volume_boss | concept_004 | 抬升后本体重砸 | 左右开书，纸飞机齐射 |
| cyber_librarian | concept_003 | 侧翼展开，归架书群发射 | 双翼定场，肃静区域 |

历史 ID `great_volume_boss` 保持稳定，其定位为普通敌人。公共动画为 idle、move、melee 或 ranged、cast、hurt、critical、death；各对象共七种。右向身份锚用于画稿，左向按现有引擎显示处理，不宣称背面或八方向验证。

## 当前交付与评审

| 阶段 | 版本 | 决定 | 依据 |
| --- | --- | --- | --- |
| 概念 | 上表五版 | 已批准，保留 | 原任务及 Manifest |
| 动作范围 | 单视角七动作 | 已确认 | 2026-10-07 当前对话 |
| 资产首版 | 五套 tmp_001 | 已被替代、按授权删除 | 管理员动作与印章轮数反馈 |
| 最新资产 | 五套 asset_001，原 tmp_002 | 当前选用、已批准、已正式提升 | 上述负责人原话 |
| 主线接入 | 尚未绑定新敌人单位 | not_integrated | 本轮为资产交付；接入效果未批准 |

每套包含九张统一 640×640 RGBA 姿势、刚性部件、AnimationLibrary、presentation.tscn、BattleAnimationSet、七张 character-action-design Schema v2 动作卡，以及七动作 GIF 和完整巡演。源稿与完整生成／编辑提示词留在 `design/concepts/enemy/<slug>/asset_001/`。源稿中的历史过程用语不代表当前审批状态。

五套使用共享 hybrid_presentation 与原战斗时钟，无敌人专用运行脚本。每敌人的施法都有原生 Line2D 双色亮边、短光线及显隐／缩放曲线，释放时最亮，跨状态复位。管理员攻击前倾、展开侧翼并发射三本装饰书；施法竖直抬升、双翼上举、青色光环和肃静框。归还印章当前九姿势均为四个日期轮，木柄沿连接套位移。

正式稳定目录分别为 `assets/art/characters/keycap_brawler/`、`projector/`、`return_stamp/`、`great_volume_boss/`、`cyber_librarian/`，供后续原主线单位引用。仅提升 rig_manifest 白名单运行子集：92 个文件、9,213,651 B（8.787 MiB），无源稿、动作卡、GIF、生产追溯或预览单位依赖。正式帧元数据剔除 source_processing，资源引用改写到正式路径。

预览使用 `tools/art/animation/enemy_cast/preview_units/<对象ID>.tres` 与正式 BattleAnimationSet；这些单位只服务既有开发预览，不代表敌人属性／技能设计，不进入正式包。资源台的 Godot 预览已启用。原主线目前只有 chalk、paper_guard 等既有定义，本批五对象尚无对应单位定义，因此没有把“正式资产”登记为主线已生效。

## 2026-10-07 阶段收尾验证

基线 `90bbf7e` + 当前批准资产工作树；Godot 4.7.2。可复用命令见 [生产入口](../../../tools/art/animation/enemy_cast/README.md)。

- 五次 `promote_animation.py <对象ID> --variant asset_001` 实际提升，随后 `--check` 逐文件一致性通过；正式目录无多余生产文件、候选依赖或角色专用运行扩展。
- 正式 PNG 常规 Godot 导入通过；`library_contract_check.tscn -- --production` 13,160 项、0 失败，覆盖七动作、真实曲线、光效峰值、出手姿态、跨状态切换、左右朝向、手动时钟、死亡冻结和轨道预算。未使用候选 PNG 加载器验证正式契约。
- 五套 `run-motion-preview.ps1 -Unit res://tools/art/animation/enemy_cast/preview_units/<ID>.tres -Animation res://assets/art/characters/<ID>/battle_animation.tres -Check` 全部 failures=0；暂停、单步、慢速及适用攻击模式通过。
- 五种施法与管理员远程攻击均从正式路径实拍 1920×1080、2560×1440、1920×1200，释放时刻采样；保留六张 1920×1080 原始截图及三尺寸日志。图已在对话展示。
- 改名后重新完整解码 35 单动作 GIF（352×352、各 3 秒）和 5 巡演（各 21 秒）；35 动作卡公开 Schema v2 全约束、PNG Alpha、安全边距、统一尺度与源图解码通过。源包和评审资料约 123.086 MiB，不含跨角色正式验证证据；PNG 编码体积不等于运行显存预算。
- 指定 image-quality-check 六类检查：馆藏巨典 PASS，其他四套 PASS_WITH_NOTES；无阻断缺陷。技术检查与人工批准分别登记，具体备注见 [质量结论](../../../design/concepts/enemy/review/codex-workflow/library-enemies-asset-001/quality-check.md)。正式提升后另复核[五种施法实拍](../../../design/concepts/enemy/review/codex-workflow/library-enemies-asset-001/formal-five-cast-release.jpg)，光效与四轮结构保留。
- 全库扫描 52 对象、1,381 文件，missing=0、mismatches=0、errors=[]。浏览器“敌人 + 已生成资产”显示 6 对象；本批各一动画版，asset_001 当前选用／已批准，七动作可切换，正式预览按钮可用。40 项资源台 Python 测试和 JS 语法通过，勾选框工具提交 `90bbf7e`。
- 五旧源包及旧跨角色评审目录已按明确授权删除；保留批准概念，最新整套源稿／生成过程与最少评审材料。删除路径、体积和编号上限见 [收尾审计](../../../design/concepts/enemy/review/codex-workflow/library-enemies-asset-001/promotion-audit.json)。未来 tmp 从 003 开始。

| 对象 | 留存 | 源包与评审 MiB | 运行白名单 MiB | 动画库 B / keys |
| --- | --- | ---: | ---: | ---: |
| 键帽拳灵 | asset_001 | 20.97 | 1.69 | 23,121 / 185 |
| 投影独眼灵 | asset_001 | 23.99 | 1.89 | 26,989 / 216 |
| 归还印章怪 | asset_001 | 22.38 | 1.46 | 30,966 / 224 |
| 馆藏巨典 | asset_001 | 25.81 | 1.86 | 33,969 / 241 |
| 图书管理员 | asset_001 | 29.94 | 1.92 | 38,536 / 277 |

所有库最长 1.8 秒，低于现有预算；原生光效不增加位图依赖。源包运行白名单约 8.817 MiB，实际正式包因帧元数据精简为 8.787 MiB。

证据：[七动作运行采样](../../../design/concepts/enemy/review/codex-workflow/library-enemies-asset-001/seven-actions-runtime.jpg)、[五施法释放帧](../../../design/concepts/enemy/review/codex-workflow/library-enemies-asset-001/five-cast-release.jpg)、[管理员攻击采样](../../../design/concepts/enemy/review/codex-workflow/library-enemies-asset-001/librarian-attack-samples.jpg)、[正式路径契约](../../../design/concepts/enemy/review/codex-workflow/library-enemies-asset-001/formal-contract-check.log)、[包校验](../../../design/concepts/enemy/review/codex-workflow/library-enemies-asset-001/package-check.json)、[提升审计](../../../design/concepts/enemy/review/codex-workflow/library-enemies-asset-001/promotion-audit.json)。各角色的 review/ 供资源台播放；跨角色静态证据只用于 Codex 工作流。

## 历史验证与已知边界

首版 tmp_001 的五套播放检查及 6,934 项契约检查通过；技术通过未识别印章三／四轮混用，旧质量结论已明确更正。首版源包和评审目录根据负责人只留新版的决定删除，不再提供活动文件链接。保留本节历史结论供追溯，不把旧技术检查作为当前视觉批准。

- 仅当前概念所示朝右单角度，朝左复用引擎变换。Esc 文字可能翻转，不用于方向识别；无背面或八方向验收。
- 刚性切片无蒙皮和被遮部件补画；出手、开书和退场按关键姿势换帧，骨骼连续插值不宣称全程手绘 16 帧。
- 投影四挡片有一片被该角度遮挡，只拆出三片可见挡片。印章木纹和管理员机身细线存在已记录的姿势细节变化；键帽退场仍有少量品红眼色，实际退场冻结后渐隐。
- 印记、纸飞机、书群与肃静框是动作提示，不增加沉默判定或额外伤害；新机制须接原战斗规则。
- 原引擎日志仍有根证书读取、编辑器配置保存与已有像素图直读提示；退出码和动作检查通过，无本批资源加载或脚本错误。未重新验证 Web 导出。

**待统筹**：五套敌人正式资产交付完成，主线单位定义／关卡编组与接入效果为后续范围；高层总览与 Roadmap 未改。

## 合入原主线（2026-10-07）

负责人明确要求与会话 01a1123f-c60a-7e01-a119-d8e9f900a6ef 协作，把敌人动画及资源台修改合入当前分支，冲突资产采用来源版本。来源确认 art/enemy-hybrid-animation 的 de3753be5f0b47e8dcfee0e0c3946c28cd01fec6 为清洁交付点。本次在 art/enemy-animation-assets 的 9a52d06 上合入四项源提交；没有合入 main、推送远程或生产新动作。

五套 asset_001 的源包与正式运行包均完整保留。键帽、投影、巨典旧运行图集由新包替代；归还印章和管理员新增主线绑定。映射：desk→keycap_brawler，board→projector，great_volume及兼容colossus→great_volume_boss，return_stamp→return_stamp，cyber_librarian→cyber_librarian。Manifest维持 selected／approved，并登记 authorized_active 与实际 owner；本次接入效果尚待负责人目视评审。

主线编组／数值与兼容边界统一见 docs/battle-demo.md；运行单位不引用美术 preview_units。具体校验见 ART-02：五包确定性提升通过、13,160项契约0失败、原主线三敌阵三尺寸108／0、起始流程133／0；资源台40项单测及52对象／1393文件扫描通过。状态层修正后的真实截图已展示。当前审批不扩展到新机制或其他人物，原动作的单角度、刚性切片等限制继续有效。

待统筹：此前“尚未接入”是源分支交付状态，本合并已完成当前主线接入；高层总览与 Roadmap 未改。
