# M1 主菜单视觉样板 · 概念 002

## 来源与边界

- 生成工具：Codex 内置 `image_gen`，按项目美术技能的默认生成路径使用。
- 生成日期：2026-09-20。
- 项目副本：本目录下的 `library.png`、`pinxue-building.png`、`ginkgo-main-building.png`。
- 用户提供的本地参考图：
  - 图书馆：`E:/Pictures/素材/7b3d915a3cf7bc6c357fa1c2da737d03.jpg`
  - 品学楼：`E:/Pictures/素材/db213e7c-562f-46f6-95d0-f3c8ed97ac15.png`
  - 秋天的银杏主楼：`E:/Pictures/素材/u=17798006669753378389,10582299323802172423&fm=3008&app=3011&f=JPEG.jfif`
- 参考用途：只用于建筑身份、季节、构图和环境关系的视觉参考；没有把照片中的人物、黑天鹅、可读标语或偶然物件当作必须保留的资产内容。
- 权利记录：这些输入是用户提供的本地参考图。本记录不把“用户提供”推断为可公开发布或可商业再分发许可；正式资产阶段仍需负责人确认来源和发布边界。
- 共同生成约束：16:9 横向、2D 绘制概念感、校园优先、局部赛博增强、无可读文字、无菜单／按钮／HUD／水印；至少保留左侧或左下低信息区供原生导航使用。
- 视觉系统：深蓝／冷灰作为环境基底；青色 `#22B8D6`、亮青 `#22E0F0` 作为信号光；品红 `#E83E8C`、亮品红 `#FF2BA6` 作为少量强调；黄色 `#E8D72F` 只作小面积暖色提示。光源方向和画面透视以各自参考图为锚点，不要求三张共享同一时刻。

## 候选 A：图书馆湖畔

- 输入参考：`7b3d915a3cf7bc6c357fa1c2da737d03.jpg`。
- 输出：`library.png`。
- 原始输出：`C:\Users\SongJun\.codex\generated_images\01a0b583-eea1-7ca3-b787-57c5a36b3259\exec-b0c13ecd-a52c-4379-b8b6-0e3eb389ec02.png`。
- 设计意图：保留湖畔白色图书馆、树线、岸边栏杆和水面倒影；把左侧湖面与天空处理为低信息区，令菜单可以自然落在水面／天空之上；青／品红只出现在窗面、栏杆和倒影。
- 生成提示词：

```text
Create a 16:9 horizontal main-menu background concept for the Cyber Pop Campus game, using the attached campus photograph as a structural and identity reference. Theme: the campus library by the lake. Preserve the recognizable white modern library building beside the water, its broad horizontal mass, the tree line, the lake reflection, and the calm open-air campus feeling. Recompose it as a clean 2D painted game background with restrained cyber-campus accents: realistic architectural perspective, soft cel-painted edges, subtle cyan and magenta light traces integrated into railings or window reflections, and a small warm yellow accent, never overwhelming the real campus identity. Use late-afternoon clear light with a gently cool atmosphere. Keep the left third and lower-left lake area relatively low-detail and low-contrast for native game navigation and menu controls; keep a calmer upper sky area for title placement. Remove incidental black swans, close-up people, logos, watermarks, UI, HUD elements, readable signage, fake letters, and button text. Do not invent a different building or change the campus architecture. No character art. No photorealistic editing artifacts. This is a visual concept candidate only, not a finished production asset.
```

## 候选 B：品学楼蓝调前庭

- 输入参考：`db213e7c-562f-46f6-95d0-f3c8ed97ac15.png`。
- 输出：`pinxue-building.png`。
- 原始输出：`C:\Users\SongJun\.codex\generated_images\01a0b583-eea1-7ca3-b787-57c5a36b3259\exec-aec1da87-cb2b-4451-a3b9-8e8989767750.png`。
- 设计意图：保留品学楼的正面中轴、广场、喷泉、两侧树阵和自行车带来的校园尺度；用蓝调天空、暖窗光和局部霓虹水光建立迎宾感；楼体文字交给原生 UI，不在底图中生成。
- 生成提示词：

```text
Create a 16:9 horizontal main-menu background concept for the Cyber Pop Campus game, using the attached campus photograph as a structural and identity reference. Theme: the 品学楼 academic building. Preserve the recognizable broad symmetrical modern school building, its central entrance axis, front plaza, fountain, bicycles kept as small indistinct shapes, and the mature trees framing both sides. Recompose it as a clean 2D painted game background with restrained cyber-campus accents: realistic perspective, soft cel-painted edges, subtle cyan and magenta light traces in the fountain, window reflections, and pathway fixtures, plus a very small warm yellow accent. Use early evening blue-hour light with warm interior windows and a calm welcoming campus mood. Keep the left third and lower-left plaza relatively low-detail and low-contrast for native menu controls; keep a calmer upper area for title placement while preserving the building as the focal landmark. Remove people, logos, watermarks, readable Chinese signage, fake letters, UI, HUD elements, button text, and any invented text. Do not alter the building into a different style or location. No character art. No photorealistic editing artifacts. This is a visual concept candidate only, not a finished production asset.
```

## 候选 C：秋天的银杏主楼

- 输入参考：`u=17798006669753378389,10582299323802172423&fm=3008&app=3011&f=JPEG.jfif`。
- 输出：`ginkgo-main-building.png`。
- 原始输出：`C:\Users\SongJun\.codex\generated_images\01a0b583-eea1-7ca3-b787-57c5a36b3259\exec-700a02d2-22b7-4534-9fc4-6262fb1ee95f.png`。
- 设计意图：保留秋季银杏大道、道路中轴、主楼正立面和金黄色季节氛围；暖金是主导，青色只落在窗面和路径灯，形成三张中最鲜明的季节主题。
- 生成提示词：

```text
Create a 16:9 horizontal main-menu background concept for the Cyber Pop Campus game, using the attached campus photograph as a structural and identity reference. Theme: the campus main building in autumn, reached through a golden ginkgo avenue. Preserve the recognizable large pale symmetrical main building, its central approach, broad steps and formal façade, the long perspective of the road, and the dense yellow ginkgo trees lining both sides. Recompose it as a clean 2D painted game background with restrained cyber-campus accents: warm autumn gold as the dominant environmental color, cool cyan reflections in selected windows or path lights, a tiny magenta signal accent, soft cel-painted edges, and realistic campus scale. Use late-afternoon autumn light with a slightly nostalgic but hopeful atmosphere. Keep the left lower road edge and a small upper sky area relatively calm and low-detail for native menu navigation and title placement, while keeping the building and ginkgo canopy immediately readable. Remove people, cars, logos, watermarks, readable signage, fake letters, UI, HUD elements, button text, and any invented text. Do not change the main building into a different architecture or location. No character art. No photorealistic editing artifacts. This is a visual concept candidate only, not a finished production asset.
```

## 输出与质量闸门

```yaml
quality_result:
  schema_version: 1
  task_id: m1-main-menu
  variant: concept_002
  status: PASS_WITH_NOTES
  eligible_for_style_validation: true
  checks:
    technical_integrity: PASS
    subject_and_identity: PASS_WITH_NOTES
    anatomy_and_physics: NOT_APPLICABLE
    prompt_and_content: PASS
    composition_and_readability: PASS_WITH_NOTES
    generation_artifacts: PASS_WITH_NOTES
  failures: []
  notes:
    - "三张均为 1672x941、Format24bppRgb、非透明 PNG，可作为横向概念底图读取。"
    - "图书馆保留白色湖畔建筑、岸线和倒影；品学楼保留正面中轴、喷泉和树阵；银杏主楼保留秋季道路、金色树冠和主楼正立面。"
    - "没有发现菜单文字、水印或签名；正式标题、按钮和状态信息仍必须由 Godot 原生组件或独立可编辑资源承担。"
    - "真实建筑经生成重绘后存在细节和比例漂移风险；概念评审通过后应以负责人选定的单张主题作为正式资产基线。"
    - "照片来源的公开发布／商业使用许可尚未由本记录推断，正式资产阶段需要人工确认。"
  repair_directives: []
  next_step: accept
```

## 文件核验

| 文件 | 尺寸 | 像素格式 | 大小 | SHA-256 |
| --- | --- | --- | ---: | --- |
| `library.png` | 1672×941 | `Format24bppRgb` | 1,986,375 bytes | `9c5084963c20c93fea30edc9fbda1b3c4a591b83ec4b7a9cb3bb39254bb01842` |
| `pinxue-building.png` | 1672×941 | `Format24bppRgb` | 2,266,084 bytes | `8d71c520dd505ab3722504db03213444fc00be7f89ba6f894012bee220e0e3a4` |
| `ginkgo-main-building.png` | 1672×941 | `Format24bppRgb` | 2,664,200 bytes | `42608ccf87bd9cfc17323d37186fab55b7b6998fbf507912c98774b5e14bd444` |

结论：三个候选允许进入人工概念评审，不代表概念批准、正式资产批准或 Godot 接入授权。当前 Manifest 选择状态为 `unselected`，审批状态为 `pending`，集成状态为 `not_integrated`。
