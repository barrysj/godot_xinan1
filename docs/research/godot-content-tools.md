# Godot 内容录入工具调研

核实日期：2026-09-09。下列是在线文档与作者发布记录核实，尚未安装插件或进行本项目运行验证。

## 结论与采用顺序

有现成工具可以复用。针对当前以独立 `.tres` 文件、类型化 Resource、显式 manifest 和运行时校验组成的系统，优先试用 **Edit Resources as Table 2** 来改善批量录入；暂时保留现有数据模型和结算逻辑。若中文界面是主要需求，可比较 YARD 和 Resource table Database；未来多轮剧情优先评估 Dialogue Manager。此排序是结合下列作者资料与[本项目录入规则](../content-authoring.md)作出的工程判断，不是实际插件测试结果。

官方提供 Resource 数据容器、Inspector 和自定义编辑器接口；社区工具在这些能力上提供表格、资源数据库和剧情编辑界面。当前 Resource 路线与官方数据组织方式一致，无需为使用录入工具先迁移整个游戏模型。[官方 Resource 文档](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html)、[Inspector 扩展文档](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/inspector_plugins.html)

## 通用内容录入工具

### Edit Resources as Table 2：当前首选

- 资源库实查版本 **2.17.4，2026-01-27，MIT**，分类标注 Godot 4.0。Godot 4 应使用仓库的 `Godot-4` 分支；资源库的版本分类不等于已经验证本项目 Godot 4.7 兼容。[资源库](https://godotengine.org/asset-library/asset/1479)、[作者仓库](https://github.com/don-tnowe/godot-resources-as-sheets-plugin/tree/Godot-4)
- 直接将目录内 Resource 展示为表格，支持筛选、排序、批量修改、撤销/重做和 CSV 导入导出。基本值直接编辑，资源引用等可交给 Inspector；Resource 数组及内嵌子资源可以展开为独立表格。[功能说明](https://github.com/don-tnowe/godot-resources-as-sheets-plugin/tree/Godot-4)
- 项目已有多年公开维护历史，是本次候选中较有积累的通用表格工具。适合批量录入角色/敌人数值、装备、技能和地点，接入成本预计最低：已有 `.tres` 可以继续使用。但新增资源仍须进入本项目 manifest，插件不会自动实现游戏注册或语义校验。

### YARD：带中文的资源注册表与表格

- 实查 **v1.2.0，2026-05-19，MIT**，资源库分类 Godot 4.5；v1.1 已加入简体中文及 Godot 4.6 相关修复。[资源库](https://godotengine.org/asset-library/asset/4837)、[发布记录](https://github.com/elliotfontaine/yard-godot/releases)
- 提供 Resource 表格、目录同步、类型限制、嵌套属性索引和查询、资源加载接口。Registry 保存 UID 与稳定字符串 ID，而非复制全部 Resource 数据。v1.2 扩展了内联单元格与资源创建体验。[作者仓库](https://github.com/elliotfontaine/yard-godot)
- 适配判断：需要“表格 + 自动收集 + 检索”时值得评估，但它的注册表与当前 manifest/资源 `id` 存在职责重叠。采用前应明确唯一的注册与身份来源，或添加显式适配，避免维护两套名单。公开 1.x 发布历史较新，不能只凭功能丰富认定比前者更稳定。

### Resource table Database（ziqi-rgb）：中文与长文本候选

- 实查 **1.1.0，2026-08-11，MIT**，资源库分类 Godot 4.6。注意它与 Iffy 的 Godot Resource Database 是不同项目。[资源库](https://godotengine.org/asset-library/asset/4909)
- 支持目录扫描 `.tres`、同类 Resource 表格、长文本换行编辑、数组弹窗及中英文界面；可用字段 `##` 注释定义显示名称和提示。另有导出字段/分组生成向导。[作者仓库](https://github.com/ziqi-rgb/Godot-Resource-Database-Visual-Database-Editor-)
- 适配判断：对中文事件正文录入有吸引力，但公开历史较短，优先小规模试用。字段生成只是修改数据声明，不能自动生成战斗效果或校验规则；现有复杂类型引用和数组仍需实际验证。

### Pandora：全面，但尚未达到本次“成熟优先”的要求

- 为 RPG 提供实体、分类继承、属性编辑和运行时访问，可组织角色、物品、法术等；MIT。作者 README 仍明确标注 Alpha、尚未适合生产使用。[作者仓库与开发状态](https://github.com/bitbrain/pandora)
- 适配判断：它比表格编辑器更接近完整数据框架，但会引入 Pandora 实体和 API。当前系统已经具有稳定 ID、运行时校验与存档快照，为改善录入而迁移的成本偏高，因此不推荐当前整体替换。

另查到 Iffy 的 **Godot Resource Database v0.2.0**（2026-07-05，MIT，最低 Godot 4.4），提供 schema、表格与 ID 校验，但发布者明确标记该版本不稳定，且需接入其数据库/表结构，暂不作为首选。[作者商店页](https://store.godotengine.org/asset/iffy/godot-resource-database/)

## 建议的试用验收

本轮仅调研，不安装插件。后续若试用首选工具，应在独立分支按以下实际操作验收：

1. 批量修改角色与敌人数值，验证范围约束、保存及撤销。
2. 编辑中文事件长文本、技能/奖励引用、类型化数组和内嵌子资源，确认没有丢失类型或内容。
3. 新增一份资源并加入 manifest，运行现有内容校验与预览，确认工具没有绕开注册流程。
4. 重启编辑器并运行游戏，检查引用、AtlasTexture、存档快照和导出兼容性；检查 Git 差异是否只含预期资源修改。

表格编辑器负责录入效率，本项目继续负责字段的玩法含义、跨资源规则、事件支付与奖励防重、存档兼容。现阶段不必自行开发完整表格 UI；以后只有通用工具确实无法满足的字段，才考虑用官方 Inspector 扩展接口补充专用编辑器。

## 事件与对话工具

### Dialogue Manager：复杂分支剧情的优先候选

- 定位是分支对话编辑器与运行时，采用类似剧本的文本录入，提供语法高亮、补全、即时语法错误提示。作者明确说明游戏负责状态和对话外观；它不是角色、装备、敌人、奖励池的通用 RPG 数据库。[作者官网](https://dialogue.nathanhoad.net/)
- 支持 `if/elif/else`、带条件的回答、变量与函数结果判断，以及调用游戏方法/信号；条件与效果可以接到项目现有逻辑。[条件与状态修改文档](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Conditions_Mutations.md)
- 本地化走 Godot 的 `tr`，支持 CSV、PO 和静态文本 ID。[翻译文档](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Translations.md)
- 最新发布实查为 **v4.1.0，2026-09-04**，发布标题标注 Godot 4.7；当前 README 标注插件 v4 面向 Godot 4.6+。项目 `project.godot` 声明 4.7，因此版本声明吻合。发布页没有 Alpha/Beta 标识，且近期仍有功能和修复；这是维护活跃的证据，不等于已经证明本项目零兼容问题。[v4.1.0 发布](https://github.com/nathanhoad/godot_dialogue_manager/releases/tag/v4.1.0)、[README](https://github.com/nathanhoad/godot_dialogue_manager)
- 许可证为 MIT。[许可证](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/LICENSE)

适配判断：如果将来事件扩展到多轮对白、复杂条件分支、逐字显示和多语言，优先评估它。通过一层项目方法读取条件、提交事件结果；支付、装备/招募奖励、失败回滚、重复领取防护仍归现有探索逻辑管理。插件能够调用方法，不代表能够自动提供这些游戏语义。特别不能在对白中分别直接扣款与发奖，绕开项目已有的整组验证。这是根据其无状态设计和本项目事件约束得出的工程建议。[作者定位](https://dialogue.nathanhoad.net/)、[调用游戏方法](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Conditions_Mutations.md)、[本项目录入规则](../content-authoring.md)

### Dialogic 2：可视化剧情演出的候选，但当前仍为 Alpha

- 提供可移动事件块组成的可视化时间线，也能切换纯文本录入；包含文本、条件、动画、信号、人物编辑与变量系统，可扩展自定义事件，并支持 CSV 翻译。[官方概览](https://docs.dialogic.pro/)
- 最新发布实查为 **2.0-alpha-20，2026-07-21**。该版本要求 Godot 4.5+，推荐 4.6+，明确修复了 Godot 4.7 问题。旧搜索摘要中“最低 4.3”属于旧信息，不能拿来判断 Alpha 20。[Alpha 20 发布](https://github.com/dialogic-godot/dialogic/releases/tag/2.0-alpha-20)
- 官方文档仍明确标记 Alpha；Alpha 20 发布说明明确说明状态/子系统改造会破坏旧存档，部分自定义子系统要重写。存在维护活动，但不能描述为已经稳定的正式 2.0。[开发状态](https://docs.dialogic.pro/)、[破坏性变更说明](https://github.com/dialogic-godot/dialogic/releases/tag/2.0-alpha-20)
- 许可证为 MIT。[版本许可证](https://github.com/dialogic-godot/dialogic/blob/2.0-alpha-20/LICENSE)

适配判断：当主要需求是让非程序作者用可视化块编排人物立绘、背景、动画与对白时更有吸引力。我们目前的 1～3 个选择事件，增加它的独立时间线与运行时系统收益有限；也无法自动替代人物战斗数值、装备、奖励池配置。若采用，应固定版本并编写自定义事件桥接现有结算；不要把其内部保存状态当作本项目完整快照替代物。此处是工程判断，依据为插件功能边界、真实存档破坏记录及项目保存约束。[官方功能](https://docs.dialogic.pro/)、[发布变更](https://github.com/dialogic-godot/dialogic/releases/tag/2.0-alpha-20)、[本项目存档约束](../content-authoring.md)

### 事件工具采用边界

当前已有事件模板包含资源门槛、实际支付、角色/装备条件、多个奖励结果、单次执行标记，并把事件正文/选项/结果纳入已生成探索快照。继续使用现有 Resource 模板适合当前短事件；两种剧情插件都是将来的叙事扩展选项，不能仅因“有事件编辑器”便整体替换内容系统。[项目事件与存档文档](../content-authoring.md)

未验证项：两插件在本项目 Windows Godot 4.7 编辑器的实际导入、中文长文本录入体验、当前 UI 接入成本、导出构建，以及中途存读档/内容更新后的对话续接。上文没有承诺插件自带项目需要的支付原子性、奖励防重或快照迁移能力；这些必须通过适配实现并验证。
