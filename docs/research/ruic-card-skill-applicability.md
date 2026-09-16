# RuiC Card Skill 对本项目的适用性调研

> 调研日期：2026-09-16  
> 外部仓库快照：[`ae25b5d02996eb5f5eb2540b91c26fe20f484d55`](https://github.com/HRuiCcc/RuiC-card-skill/commit/ae25b5d02996eb5f5eb2540b91c26fe20f484d55)  
> 资料范围：仅使用目标仓库 README、`SKILL.md`、源码、许可证和官方依赖文档，并只读对照当前项目代码与文档。未安装该 Skill，未运行其资产生成流水线，也没有把其代码或产物接入本项目。因此，本文确认的是源码可证明的能力与适配方案，不把仓库演示等同于本项目的运行验收。

## 结论

**可以应用，但应把它定位为“纪念收藏卡的离线美术生产工具／独立分享页生成器”，不能当作现成的 Godot 卡牌系统。**

最值得采用的方向是：区域 Boss 后获得的记忆终端收藏、毕业纪念册或结尾回看页。Skill 生成的分层 PNG、静态渲染和卡片元数据可成为候选美术资产；若要在游戏内保留视差与流光，推荐以后将核心效果重写为 Godot 原生 2D `CanvasItem` shader，并复用现有详情弹窗与 Resource 数据。**不建议**把 Three.js 页面嵌入游戏，不建议直接把 `card.glb` 当成完成品导入，也不建议替换当前部署卡。

当前 M1 有 9 月 27 日硬截止，且只允许空占位或静态资源；现在引入 Blender、Node、Three.js 和新的运行时表现链路，范围与风险都不合算。[Roadmap](../roadmap.md#当前里程碑-m1虚拟校园修复战役骨架2026-09-16) 与 [M1 静态美术资源清单](../art/m1-static-assets.md) 已明确这些限制。建议 M1 只保留这一方向为后续候选；若确有收尾画面需求，最多使用经审批的静态渲染，不接入交互式全息运行时。

## 1. 它实际是什么

RuiC Card Skill 是一套 **Codex 驱动的资产生产流程**，输入一句描述或参考图，组织外部图像工具生成同画布分层图，再由 Python、Blender 和 Three.js 产出可编辑工程、静态渲染与独立网页。它不是卡牌玩法框架，也不生成战斗规则、牌组逻辑或 Godot Resource。

仓库定义的标准层为：

| 层 | 默认文件 | 作用 | 关键限制 |
| --- | --- | --- | --- |
| 主体 | `assets/subject.png` | 角色或主体 | 真实 RGBA，默认前向视差 |
| 特效 | `assets/effects.png`，可选 | 花瓣、火星等装饰 | 真实 RGBA，保持稀疏 |
| 背景 | `assets/background.png` | 环境与底纹 | 必须不透明，默认后向视差 |
| 线稿 | `assets/lineart.png` | 扫光轮廓遮罩 | 应从主体同源派生，避免错位 |
| 文字／卡框 | `assets/text.png` | 名称、编号、边框 | 不做视差，固定在卡边 |

标准画布通常为 1024×1536 竖版；各层共用尺寸和坐标。该约束来自 [`SKILL.md`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/SKILL.md#L7-L24) 与[分层美术说明](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/references/art-direction.md)。仓库本身不包含图像生成模型或付费 API；`SKILL.md` 要求 Codex 调用当时可用的图像工具，因此最终画质、身份一致性、参考图合规与成本并不是该仓库代码自身能保证的能力。

### 产物清单

完整流水线会产生：

- 分层 PNG 与 `asset-validation.json`；
- `card-config.json`，包含标题、说明、编号、图片路径、景深、缩放和光泽等展示参数；
- `card.blend` 可编辑 Blender 工程；
- Blender 静态渲染；
- `web/assets/card.glb`；
- 独立 Three.js 网页及本地服务；
- `verification/report.json` 和桌面／窄屏／不同视角截图。

来源见[仓库 README 的交付列表](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/README.md#L167-L180)、[`card-config.json` 示例](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/references/config.example.json)及[`run_pipeline.py`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/run_pipeline.py)。

一个必须记住的边界是：**`card.glb` 不是完整视觉成品。** 导出脚本把网格材质替换成 `web_front`、`web_edge`、`web_back`、`web_gold` 等“角色名”；Three.js 再根据这些名字挂上自定义 shader，并重新加载分层 PNG。[`export_web.py`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/export_web.py)与[`app.js`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/assets/web-template/app.js#L368-L411)都直接证明了这一点。仓库自己的验收说明也明确写着 glTF 不携带自定义 Blender 节点图，浏览器版本是 GLSL 重建，不能宣称与 Blender 像素一致。[验证说明](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/references/verification.md#L21-L24)

## 2. 工作流、依赖与可维护性

### 工作流

1. 先确定主体、标题、稀有度、色板、用途等卡片规格。
2. 通过外部图像工具生成同画布的主体、背景、线稿、文字和可选特效层。
3. `validate_assets.py` 检查 PNG、统一尺寸、最低 256 像素、透明度、空层和线稿明暗；遇到“画出来的棋盘格”时可尝试转成真实 Alpha。[源码](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/validate_assets.py)
4. `run_pipeline.py` 查找 Blender；缺失时下载 Blender 4.5 官方便携版与官方 SHA-256，并解压到输出项目的 `tools/`。[流水线](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/run_pipeline.py#L7-L29)、[Blender 安装器](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/ensure_blender.py)
5. Blender 脚本创建几何、视差节点、镭射、线稿发光、星点、灯光与 1–96 帧预览，保存 `.blend` 并渲染；再导出只承担几何／材质角色契约的 GLB。[`build_card.py`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/build_card.py)、[`export_web.py`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/export_web.py)
6. 复制网页模板、安装 `three@0.180.0`，再用 Bun 或 `npx esbuild@0.25.0` 尝试生成单文件 bundle；失败时保留仓库预构建 bundle。[`package.json`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/assets/web-template/package.json)、[`run_pipeline.py`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/run_pipeline.py#L26-L56)
7. `verify_web.mjs` 启动本地服务与 Chromium，通过 DevTools Protocol 检查拖转、翻面、缩放、键盘、五个滑杆、材质、截图、约 390 px 窄屏和减动效，并比较实际截图帧。[源码](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/verify_web.mjs)

自动化检查覆盖得比普通演示项目认真，但它只证明查看器交互和画面发生变化，不判断人物身份、审美、中文排版、移动端触控手感或本项目适配；仓库的 `SKILL.md` 也要求最后人工看正面和双向倾斜图。[`SKILL.md`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/SKILL.md#L23-L30)

### 依赖与边界

| 依赖 | 用途 | 是否进入游戏运行时 | 维护判断 |
| --- | --- | --- | --- |
| Codex + 外部图像工具 | 生成分层图 | 否 | 结果依赖当时可用模型，仓库不能独立复现美术 |
| Python 3 + Pillow | 校验、排字、流水线调度 | 否 | README 未锁 Pillow 版本；字体与字形覆盖需显式配置 |
| Blender 4.5.x | `.blend`、渲染、GLB | 不应进入 | 安装器动态选择最高 4.5 补丁版，虽校验 SHA-256，但同一命令未来可能取得不同版本 |
| Node.js + npm | 安装 Three.js、启动网页 | 仅独立网页需要 | `three` 锁为 0.180.0；首次安装需要网络 |
| Bun 或 esbuild | 重新打 bundle | 否 | Bun 可选；否则 `npx --yes esbuild@0.25.0` 仍会产生额外网络依赖 |
| Chromium 系浏览器 | E2E 验证 | 否 | 检查脚本直接寻找 Edge／Chrome／Chromium |
| Three.js + WebGL | 独立网页主渲染 | 若嵌页则会进入 | WebGL 不可用时降级到 CSS 3D；与 Godot 是第二套运行时 |

仓库目前没有稳定 Release 或版本化迁移约定；本次快照前的提交集中在 2026-09-07 至 2026-09-11，功能仍在快速调整。[提交历史](https://github.com/HRuiCcc/RuiC-card-skill/commits/main) 若采用，必须固定到具体 commit，不可直接追随 `main`。

从可维护性看，离线使用分层 PNG 风险最低；复用网页是中等风险；把 Three.js 或 Blender 工程变成本项目运行时依赖是高风险。尤其流水线默认把 Blender 下载到每个输出项目的 `tools/`，正式归档时应排除该目录、`node_modules`、缓存和临时验证产物，只保留批准的源图、必要配置、渲染与来源记录。

## 3. 与当前 Godot 项目的真实接口差异

### 数据模型不同

本项目的技能是 `CampusSkill` Resource，真正可执行的字段包括 `attacks_to_trigger` 与 `CampusEffect[]`；图标只是可选 `Texture2D`。[`skill_def.gd`](../../game/content/skill_def.gd) 与[内容录入指南](../content-authoring.md#人物敌人与技能)还明确规定：描述文字不会执行效果，新机制必须先写代码。

RuiC 的 `card-config.json` 只有标题、标语、版次、图片路径和视觉参数，没有伤害、治疗、目标、触发次数、角色引用或稳定游戏内容 ID。因此：

- 分层图可做视觉输入；
- `title`、`description` 可辅助人工录入；
- **不能**从该配置直接生成可玩的技能，也不能把自然语言卡面当成规则事实源；
- 若批量生产收藏卡，应由现有 Resource 提供名称和说明，再生成展示配置，避免两份文本漂移。

### 当前“卡牌”是轻量部署控件

战前部署卡由 [`deployment_panel.gd`](../../scenes/battle_demo/deployment_panel.gd#L28) 直接用 `CanvasItem._draw()` 绘制头像、姓名和部署状态；单张上限约 126×84，横向排列，承担点击、拖放、交换与撤回。它需要一眼可读和低输入延迟，不是收藏展示页。

把默认 1024×1536 竖版高信息卡缩进这个位置，会造成：

- 文字与镭射细节不可读；
- 动态倾斜与玩家拖拽部署争夺同一手势；
- 多张卡同时加载分层纹理和 shader，增加移动端显存与填充压力；
- 华丽收藏表现压过阵位、生命和部署状态，违反“核心操作必须可读”的 [UI 规范](../art/specs/UI_SPEC.md)。

所以替换部署卡属于**不可／不建议使用**，不是简单换皮。

### 渲染栈不同

项目为 Godot 4.7、2D `canvas_items` 伸缩，并在桌面和移动端都使用 Compatibility 渲染器。[`project.godot`](../../project.godot) 同时配置 Windows、Web 与 Android 导出，[`export_presets.cfg`](../../export_presets.cfg)；现有手机探针仍是“可操作但不可读”，真机触控未验收。[RELEASE-02](../implementation/release-02.md)

Godot 可以导入 GLB，官方也推荐 glTF 2.0；但官方文档同时提醒程序化 Blender 材质未必正确导入。[Godot 3D 格式文档](https://docs.godotengine.org/en/latest/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)、[导入配置](https://docs.godotengine.org/en/latest/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html) 对本 Skill 来说问题更明确：它的导出脚本本来就主动丢掉 Blender 节点材质，让网页自行重建。因此，直接导入 GLB 只会得到可用几何，不会得到仓库演示中的全息效果。

若游戏内确实需要视差，Godot 原生 2D shader 更符合当前架构。官方说明 `CanvasItem` shader 可用于所有 2D 节点和 GUI 元素，并提供 UV、纹理、时间和混合模式等所需能力。[Godot CanvasItem shader 文档](https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/canvas_item_shader.html) 需要移植的是视觉公式，不是把 Three.js 原样塞进项目。

### 美术流程不能跳过

RuiC 的资产校验能补充透明度、统一画布和网页交互检查，但不能替代本项目的三阶段人工批准。候选仍须按“概念 → 正式资产 → Godot 接入”分别评审，并登记对象版本、来源、批准与真实生效状态。[美术工作流](../art/WORKFLOW.md#2-三阶段生产)

若采用，其输出目录需要额外适配：

- 候选放入 `design/concepts/<任务>/<资产>/<版本>/`；
- 正式批准的 PNG／渲染才进入 `assets/art/`；
- 在对象 Manifest 中登记版本、文件、批准与接入，不让游戏运行时读取 `card-config.json` 取代现有 Resource；
- `generation.md` 记录提示词、参考图角色、生成工具、RuiC commit、字体与人工修改；
- Blender、Node 依赖、下载包、`node_modules` 与自动化截图不进入正式资产 Manifest。

## 4. 分级判断

| 产物／能力 | 判断 | 适用方式 | 主要条件或原因 |
| --- | --- | --- | --- |
| 分层 PNG | **可直接使用** | 作为候选美术源图、纪念卡详情页纹理、静态合成输入 | 必须完成权利核对、项目美术审批、裁切与尺寸检查；“直接”不代表免审批 |
| 静态 Blender／网页渲染图 | **可直接使用** | 结尾画面、图鉴大图、分享截图 | 需改品牌、字体并验证 Android 横屏可读性；M1 只允许此类静态结果 |
| 独立 Three.js 查看页 | **需改造后使用** | 游戏外的纪念卡分享页或展览彩蛋 | 换掉“白相”模板身份，补许可证与部署验证；它应独立托管，不嵌入游戏 |
| `card-config.json` | **需改造后使用** | 美术展示配置或构建中间格式 | 不可替代 `CampusSkill`／`CampusUnit`；应从现有 Resource 单向生成共享字段 |
| `card.blend` | **需改造后使用** | 美术人员继续调材质、灯光、出静帧 | 只作为生产源文件；体积、Blender 版本和资产打包策略需控制 |
| `card.glb` | **需改造后使用** | 极少量专用 3D 收藏展台 | 必须在 Godot 重建材质、交互和性能降级；单独导入不保留效果 |
| 视差／镭射公式 | **需改造后使用** | 后续 Godot 2D 收藏卡 shader | 用项目 Token 控制强度，支持触控、减动效与 Compatibility renderer |
| 分层、透明度检查与双向倾斜 QA 思路 | **只适合作为灵感** | 补强项目静态卡资产验收 | 可吸收检查方法，不必引入整个工具链 |
| 四种材质、翻面和景深滑杆 | **只适合作为灵感** | 开发预览或收藏详情页调参 | 玩家版不宜暴露全部制作参数，以免像工具页而非游戏界面 |
| 当前部署卡替换 | **不可／不建议使用** | — | 尺寸、信息密度、手势、性能和战术可读性均不匹配 |
| 把描述／卡面当战斗规则 | **不可／不建议使用** | — | 仓库没有玩法数据模型；会形成不可校验的第二事实源 |
| 游戏内嵌 Three.js／Node 服务 | **不可／不建议使用** | — | 多一套渲染、输入、依赖和平台验证；Android 原生也没有现成等价入口 |
| 把便携 Blender、`node_modules` 随游戏交付 | **不可／不建议使用** | — | 无运行价值、体积巨大，并扩大许可证与供应链范围 |

## 5. 推荐使用场景

### A. 区域 Boss 后的记忆终端收藏卡——最推荐

每个区域通关后解锁一张静态纪念卡；玩家在“回忆”或终端详情页点开大图，再通过轻微指针／陀螺视差查看。它能把“终端收集”变成情感奖励，而不是再加一条战斗数值。三张区域卡共享框架，仅更换主体、背景和区域标识，内容成本可控。

建议 M1 先用静态图；M1 之后如真人反馈证明收藏页值得停留，再做单卡 Godot shader 原型。不要让这一效果阻塞主线、存档或 Android 验收。

### B. 毕业纪念册／结尾回看——推荐

把角色、地点或真实照片做成可翻看的纪念条目，能服务项目“校园记忆”目标。这里玩家主动进入详情，允许比战斗 UI 更强的仪式感，也更容易提供减动效与静态回退。

涉及真实同学、姓名和照片时，必须先取得素材与公开展示授权；无资料时保持显式占位，不能让生成图冒充真实纪念记录。该原则与 [M1 静态清单](../art/m1-static-assets.md#待制作与输入清单)一致。

### C. 独立分享页——条件推荐

如果将来需要“通关后扫码打开一张会闪的毕业卡”，仓库原生网页就是成本最低的利用方式。它与游戏发布包分离，失败也不影响主流程。需要重新设计品牌、补第三方许可证、部署到 HTTPS、验证手机触控和资源加载，并明确页面与游戏存档不互通。

### D. 技能卡／装备卡——不推荐优先做

本项目目前不是手牌构筑游戏，技能固定随人物，装备也通过图标和详情操作。给每项技能或装备生产全息卡会扩大资产量，却不会增加战术选择；还会把视觉预算花在高频功能页，违背“功能页耐看，高潮页出拳”。除非未来玩法真的改成可收集／可编组卡牌，否则只保留统一图标和详情即可。

## 6. 价值、成本与玩家体验

| 维度 | 评估 |
| --- | --- |
| 玩法价值 | 对战斗规则几乎没有直接价值；对通关奖励、区域记忆收集和结尾仪式感有中高价值。必须把它绑定“获得了什么记忆”，而不是只做会闪的装饰。 |
| 范围成本 | 单张静态卡为小到中；独立网页为中；Godot 原生交互卡为中；直接复刻 3D／网页全功能为中到大；批量人物卡会迅速放大美术审批成本。 |
| 技术维护 | 分层 PNG 最稳；Godot 2D shader 次之；GLB + Godot 3D 材质再次；嵌入 Three.js 最差。应坚持一个运行时，不维护 Three.js 与 Godot 两套表现实现。 |
| 玩家体验 | 大图详情中，轻微视差能提升“拿到纪念物”的触感；高频战斗和小屏列表中，流光、自动旋转和密集文字会干扰读取。需提供静态回退、减动效和触摸操作。 |
| 视觉一致性 | 默认模板偏“私人全息典藏／白相画廊”，需改成“清爽理工校园 × 轻数字美术 × 局部赛博强化”。日常页降低镭射，高潮和结尾才提高强度。 |
| 交付风险 | 外部工具、字体、参考图权利、快速变动的上游和多平台性能都需独立验证；不适合卡在当前 M1 主路径。 |

## 7. 许可证与使用边界

这部分是工程风险判断，不是法律意见。

### 仓库代码

仓库根许可证为 MIT，允许使用、修改、分发和商业使用，但分发软件或其重要部分时必须保留版权与许可文本，并且不提供担保。[RuiC `LICENSE`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/LICENSE)

如果只把自己有权使用的最终 PNG／渲染带入游戏，而不复制 RuiC 源码或网页模板，MIT 代码通知通常不会跟着美术输出进入游戏；如果复制 shader、脚本或网页模板，则应在项目第三方通知中保留 RuiC MIT 文本。

### 生成图与参考图

RuiC 许可证第 7 行明确说，生成美术和用户上传参考图不由仓库的软件许可证覆盖。也就是说，“代码是 MIT”不能证明生成图可商用，更不能授权真实人物照片、角色形象、校徽、摄影作品或风格参考。[RuiC `LICENSE`](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/LICENSE#L7)

本项目若用于真实同学／校园纪念，应逐项记录：素材提供者、肖像／照片／商标授权范围、生成工具条款、是否允许公开分享、是否允许模型编辑与衍生。公开分享页的风险高于只在本地游戏中展示。

### Blender、Three.js、Pillow 与图标

- Blender 为 GPL 软件；Blender 官方同时明确，使用 Blender 产生的图片、影片、`.blend` 和其它数据文件属于创作者，可自由使用。[Blender 官方许可证说明](https://www.blender.org/about/license/) 因此用 Blender 生产卡片不会把游戏变成 GPL；但若把便携 Blender 二进制随项目或下载包再分发，则需要履行 Blender 的 GPL 分发义务。最安全的做法是把 Blender 保持为本机构建依赖，不纳入游戏交付。
- Three.js 使用 MIT；如果分发含 Three.js 的网页 bundle，应保留其 MIT 通知。[Three.js `LICENSE`](https://github.com/mrdoob/three.js/blob/dev/LICENSE)
- Pillow 使用开源 MIT-CMU 许可证。[Pillow 官方说明](https://pillow.readthedocs.io/en/stable/about.html#license)
- 网页模板的源码注释表明图标来自 Lucide；Lucide 当前根许可证包含 ISC，以及部分 Feather 图标的 MIT 条款。[Lucide `LICENSE`](https://github.com/lucide-icons/lucide/blob/main/LICENSE) 若分发网页模板或其内联图标，第三方通知应一并保留 Lucide 完整许可证。

仓库自己的根 `LICENSE` 不能替代这些第三方许可证。若采用完整网页模板，建议建立 `THIRD_PARTY_NOTICES` 或等价许可证目录，并基于实际锁定版本核对最终 bundle，而不是只复制 RuiC 的 MIT。

### 字体

`generate_typography.py` 默认依次尝试配置字体、Windows `simkai.ttf` 和若干系统字体，并把字形栅格化进 `text.png`。[源码](https://github.com/HRuiCcc/RuiC-card-skill/blob/ae25b5d02996eb5f5eb2540b91c26fe20f484d55/scripts/generate_typography.py) 系统里“能找到”不等于允许随项目使用或公开分发渲染结果。

本项目已有 `assets/fonts/SourceHanSansSC-Medium.otf` 及 [SIL OFL 1.1 许可证](../../assets/fonts/SourceHanSans-LICENSE.txt)。如做原型，应在 `card-config.json` 显式指定该字体，记录许可证，并检查中文排版；不要依赖机器上的楷体回退。

## 8. 建议实施路线

### 当前 M1

- 不安装 Skill，不引入 Blender／Node／Three.js 依赖，不修改战斗部署卡。
- 若结尾急需一张纪念视觉，先按现有美术工作流制作一张静态候选；即使借用 RuiC 的分层思路，也只交付批准后的静态 PNG／渲染。
- 在真实人物、照片与校园标识授权未明确前，不制作可公开传播的卡片。

### M1 后的一卡原型

1. 选一个低权利风险对象，例如虚构的“图书馆记忆终端”，而不是真人。
2. 固定 RuiC commit；在仓库外临时工作目录运行，显式使用项目已有 Source Han Sans。
3. 只产出并评审主体、背景、线稿、文字、可选特效、静态渲染与配置；不把 `tools/`、`node_modules` 或 Blender 下载包复制进项目。
4. 概念和资产批准后，再做一个 Godot 详情页：先静态，后加入强度受控的 2D shader；名字、说明和解锁状态仍来自现有 Resource。
5. 用项目既有三分辨率视觉检查，并补 Windows、桌面 Web、Android 横屏真机、减动效、触摸拖动、纹理内存和低端 Compatibility renderer 验证。
6. 只有当玩家愿意在收藏页停留、能说出这张卡代表哪段记忆，才批量扩展到三张区域卡；否则保留静态卡，不为“闪”而制造资产流水线。

### 原型验收线

- 收藏页不影响主线加载、部署拖放、暂停和存档；
- 文字、解锁状态和返回操作在 Android 横屏清楚可点；
- 减动效时关闭自动摆动与时间动画，仍能查看全部信息；
- 单张卡按需加载，离开页面可释放大纹理；
- Godot 与静态渲染允许有风格差异，但不得把未验证结果宣称为 Blender／网页像素一致；
- 资产版本、授权、字体、RuiC commit、人工批准和 Godot 接入截图可追溯。

## 最终建议

**采纳“分层卡片资产 + 收藏仪式感”的思想，暂不采纳它的网页运行时和 GLB 交付作为游戏实现。**

对当前项目，最佳性价比是：

1. M1 保持静态、按期完成完整战役骨架；
2. M1 后用一张虚构记忆终端卡验证收藏价值；
3. 若验证通过，移植为 Godot 原生 2D shader，并扩展到区域终端／毕业纪念收藏；
4. 独立 Three.js 网页只作为可选的游戏外分享彩蛋。

这样能拿到 RuiC 最有魅力的“把记忆拿在手里转一转”，又不会把现有 2D Godot 项目变成一艘同时拖着 Blender、Node 和浏览器的小船。
