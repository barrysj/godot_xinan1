# 美术任务：M1 校园探索地点环境

状态：12张日常＋12张异常的3840×2160候选均已生成并登记。银桦＋清真食堂008的非实体异常类型与密度获负责人确认作为生产基准；其余11处已按此基准生成新版，西湖两处保留数字水面，图书馆窗侧提高密度。成电会堂＋商业街另有008建筑锚定裂隙单图试样待评。方向确认不等于具体版本资产获批；新候选仍待人工评审，未提升正式包或接入游戏，旧正式资产不变。

## 成电会堂＋商业街建筑裂隙单图校准（2026-09-24）

- 负责人指出其余11张未清楚呈现银桦＋清真食堂008那种沿建筑檐口、立面转角分叉的次元裂隙，要求先以一张图试验。选成电会堂＋商业街007作严格编辑源，银桦＋清真食堂008仅作裂隙形态参考。
- [008待审异常图](../../../design/concepts/m1-campus-locations/m1_chengdian_auditorium_commercial_street/008/anomaly.png)及[007／008对照（左旧右新）](../../../design/concepts/m1-campus-locations/review/codex-workflow/chengdian-007-008-rift-comparison.jpg)现有从成电会堂檐口贯至立面／入口转角的分叉紫色主裂隙，右侧商业建筑有较小次裂隙；建筑、墨蓝灰天空、青蓝平面板、短数据雨和地面光痕保留。主裂隙偏亮，可能接近闪电效果，需负责人判断。未把此方向批量推广至另10处。
- [来源、完整提示词与哈希](../../../design/concepts/m1-campus-locations/m1_chengdian_auditorium_commercial_street/008/generation.md)；008登记 `asset_anomaly_006 / unselected + pending`，007仍为待审历史候选。最终3840×2160 RGB不透明PNG为约1672×941生成源的高质量双三次重采样，非原生4K；无运行时改动。

## 目标与范围

- 用途、数量与本次要求：建立 M1 校园地点背景家族。南门 `gate` 概念已批准为日常视觉基准；后续按现实资料充分度逐项制作地点候选。用户本轮新增九处明确实景：学子食堂、学生活动中心、西湖中心、成电会堂+商业街、银桦食堂+清真食堂、基础实验大楼、西湖入口、操场、图书馆正面。
- 对应规范、已有身份参考：[场景视觉规范](../specs/ENVIRONMENT_SPEC.md)、[视觉方向](../STYLE_BIBLE.md)、[M1 静态资源清单](../m1-static-assets.md)、用户提供的校园平面图与南门／品学楼照片。
- 目标 Godot 场景、入口与依赖：未来对应 `scenes/expedition/exploration_board.gd` 的地点环境层；本轮不接入。现有 `game/run/campus_region.gd` 只作为地点 ID 与区域逻辑依据。
- 不在本次范围内的内容：区域地图底图、路线与建筑定位、运行时地点绑定、两个终点命名、照片卡、UI 贴图、人物、战斗代码和运行时代码。

### 现实身份资料审计

| 地点 ID | 当前运行时占位身份 | 当前参考状态 | 后续最低补充 |
| --- | --- | --- | --- |
| `gate` | 校门／旧校门 | 南门照片与校园平面图已提供 | 概念评审；正式制作前确认可使用范围 |
| `walk` | 步道 | 已生成湖畔步道概念候选；平面图有水系、绿地和道路关系，尚无指定步道照片 | 1 张能看出具体路径形态的照片，并在平面图上标注位置；当前候选不代表已确认现实路径 |
| `court` | 球场／当前 Resource 显示“篮球场” | 已生成篮球场概念候选；平面图可见运动场组团，尚无指定球场照片 | 1 张确定场地身份的宽景照片，并标注具体场地；当前候选不代表已确认现实球场 |
| `hall` | 走廊／教学走廊 | 仍缺走廊实景；品学楼两个明确地点另行登记为独立视觉身份，不冒充走廊 | 1 张走廊实景照片，并标注所属楼栋／区段 |
| `end_b` | 第二终端 | 尚未绑定现实地点；不以品学楼照片擅自命名 | 1 张候选地点照片与身份确认；系统名继续保留 |
| `end_c` | 第三终端 | 尚未绑定现实地点；不以品学楼照片擅自命名 | 1 张候选地点照片与身份确认；系统名继续保留 |

用户本轮明确提供并确认了两处独立现实地点：品学楼（教学楼）单区内部庭院、品学楼组团的中庭。它们现在分别登记为 `m1_pinxue_courtyard` 与 `m1_pinxue_atrium`；由于用户尚未指定它们对应 `hall`、`end_b` 或 `end_c` 哪个运行时占位，暂不强行绑定。

用户随后又明确提供并确认九处实景，分别登记为 `m1_xuezi_cafeteria`、`m1_student_activity_center`、`m1_west_lake_center`、`m1_chengdian_auditorium_commercial_street`、`m1_yinhua_halal_cafeterias`、`m1_basic_laboratory_building`、`m1_west_lake_entrance`、`m1_sports_field` 与 `m1_library_front`。这些对象保留现实地点身份，但同样不擅自绑定现有运行时占位；图书馆正面候选按用户要求移除了旗帜与旗杆。

## 008基准扩展至其余11处（2026-09-24）

- 负责人决定：“可以了，保留这种程度的异常元素+异常密度，继续生成其他11张图”；以银桦＋清真食堂008为普通地点的强度与非实体效果基准。此决定批准生产方向，不代替新11张的具体版本资产评审；银桦008保持原文件不重生。
- 新版分布：南门009；品学楼单区庭院／组团中庭、学子食堂、西湖中心、成电会堂＋商业街、基础实验大楼、西湖入口、操场各007；学生活动中心008；图书馆正面008。各地新增版本均为 `unselected + pending`，历史候选保持其原登记状态；12张日常和正式旧包不变。
- 普通地点沿用薄青蓝矩形面板、局部短数据雨、角状紫色裂隙与无体积的贴地光痕，清除先前铺地实物状发光碎块。西湖中心与西湖入口以既有双数字天鹅水面图为水面语言参考，保留断续青蓝／品红波纹、碎光与倒影，不复制天鹅或建筑；该参考文件实际位于主仓库 `E:/Documents/works/godot_xinan1/assets/art/backgrounds/m1_main_menu/anomaly/library-two-digital-swans.png`，当前工作树无副本。图书馆 Boss 区把更高密度集中在主体左右窗带与中央玻璃，广场则较疏，且不恢复旗帜／旗杆。
- [12张最新版异常评审拼图](../../../design/concepts/m1-campus-locations/review/codex-workflow/approved-density-12-anomaly-4k-review.jpg)和[批次索引](../../../design/concepts/m1-campus-locations/review/codex-workflow/paired-4k-generation.json)可逐项追到各版本 `generation.md` 的完整提示词、参考角色和SHA-256。逐张生成源和整组缩图已目检；11张新图均为3840×2160 RGB不透明PNG，从1671～1672×941原始输出高质量双三次重采样，非原生4K。`asset_report.py` 11张全部通过；资源台33项测试通过，AssetCatalog扫描26对象／426登记文件，缺失0、不一致0、错误0；批次索引可解析。通用质检为 `PASS_WITH_NOTES`：身份、地面物理逻辑、湖水与窗侧指令均可读，但多处地面偏湿亮、部分面板偏像灯具，需负责人审美复核。技术检查不代替批准，无运行时画面修改。

## 银桦＋清真食堂单图精修（2026-09-24）

- 负责人反馈：重复生成12张成本过高，先以银桦＋清真食堂为代表样图。006 中铺地上的立体晶体／实体碎块不符合数字异常设定；蓝色矩形平面光块、投影裂隙、窗内短数据雨及建筑裂缝方向认可。该反馈只否定本地点006的实体碎块，不自动否定或批准其他11张。
- 新候选 [007异常图](../../../design/concepts/m1-campus-locations/m1_yinhua_halal_cafeterias/007/anomaly.png)、[006／007并排对照（左旧右新）](../../../design/concepts/m1-campus-locations/review/codex-workflow/yinhua-006-007-comparison.jpg) 与 [完整提示词／来源](../../../design/concepts/m1-campus-locations/m1_yinhua_halal_cafeterias/007/generation.md)：两步精修，移除铺地实体并恢复地砖，再保留／补强无体积、沿透视投射在砖面上的断续青紫裂隙。006 保留历史并在 Manifest 记为 `unselected + rejected`，007 为 `unselected + pending`，不推及其他地点的批准状态。
- 负责人接着要求“再适当增多一些异常”。仅本地点生成 [008异常图](../../../design/concepts/m1-campus-locations/m1_yinhua_halal_cafeterias/008/anomaly.png)，[007／008并排对照（左旧右新）](../../../design/concepts/m1-campus-locations/review/codex-workflow/yinhua-007-008-comparison.jpg)，[完整提示词／来源](../../../design/concepts/m1-campus-locations/m1_yinhua_halal_cafeterias/008/generation.md)。增量集中在两侧立面的薄青蓝矩形面板、窗内短数据雨、铺地透视投影裂隙与微弱反光；不加入实体地面碎块、悬浮圆环或紫色天空。008 登记 `asset_anomaly_006 / unselected + pending`；007 仍为待评参照版本，不擅自标记拒绝或批准。
- 008 验证：生成源与并排缩图已目检，4K PNG 解码／尺寸／RGB不透明与全画幅检查通过；资源台33项测试通过，AssetCatalog扫描26对象／404登记文件、缺失0、不一致0、错误0，批次索引可解析。通用任务质检为 `PASS_WITH_NOTES`：增量可辨、地面无实体碎块；地面仍偏湿亮，多处面板的局部强度需负责人审美复核。技术验证不代替资产批准。
- 代表样图选择遵循 `create-game-assets` 的先确定单张视觉目标再扩展家族；“无实体地面碎块”已由负责人对008方向的确认推广到其余地点，具体新版本仍待评。最终图源与并排缩图已实际查看；007通过3840×2160、RGB不透明、无透明像素检查；资源台33项测试通过，AssetCatalog扫描26对象／402登记文件、缺失0、不一致0、错误0；批次索引可解析、git diff --check通过。通用结构与任务检查为PASS_WITH_NOTES：实体碎块消失且建筑保持可辨，铺地仍整体偏湿亮，后续需负责人审美复核。技术验证不替代批准。

## 去圆环、地面分布与 Boss 区修订（2026-09-24）

- 负责人指出上一批发光圆环在各地点重复、地面异常分布不足。该批12张异常旧候选保留历史文件，但相应 Manifest 版本标为 `unselected + rejected`；新12张另立版本，状态均为 `unselected + pending`。本次修订不影响12张日常候选或既有正式包。
- 新版目录：南门008；品学楼单区庭院、组团中庭、学子食堂、西湖中心、成电会堂＋商业街、银桦＋清真食堂、基础实验楼、西湖入口、操场各006；学生活动中心007；图书馆正面007。去除的是悬浮发光圆环，真实弧形建筑（食堂门厅、体育馆屋顶等）保持。
- 视觉方案：地点特有的角状霓虹裂缝和窗内短数据雨，配合前中景分散的青蓝／紫色碎片、透视正确的断续投影与弱倒影。西湖两张的水面仅参考 `E:/Documents/works/godot_xinan1/assets/art/backgrounds/m1_main_menu/anomaly/library-two-digital-swans.png` 的断续数字波纹与青蓝／品红碎光，不移植天鹅、图书馆建筑或天空。图书馆正面作为 Boss 区，立面裂缝、窗内数据雨和广场碎片显著增加，同时保留入口与建筑轮廓可读，且不恢复旗帜／旗杆。
- [新版12张评审拼图](../../../design/concepts/m1-campus-locations/review/codex-workflow/ring-free-ground-anomaly-4k-review.jpg)与[批次索引](../../../design/concepts/m1-campus-locations/review/codex-workflow/paired-4k-generation.json)；每张的两步编辑提示词、来源、交付哈希在对应 `generation.md`。生成源已逐张目检；最终图像为3840×2160 RGB不透明PNG，由1671～1672×941的模型输出高质量双三次重采样，不宣称原生4K。12张解码、尺寸、RGB与不透明检查通过；资源台33项测试通过；AssetCatalog扫描26对象／400登记文件，缺失0、不一致0、错误0；批次索引可解析，git diff --check通过。通用图像质量闸门判为 `PASS_WITH_NOTES`：画面核心任务、地点身份、地面接触与构图可读性通过；广场表面整体偏湿亮、个别投影近似几何线框，需负责人审美复核。技术与通用质检不替代风格或正式资产批准。

## 其余11处异常扩展（2026-09-24）

- 人工决定：“可以了，继续其它地点的生成”视为学生活动中心006天空与局部异常密度可作为扩展基准；仅批准生产方向，不替代本批12张异常的逐张或整批资产批准。
- 新候选：南门007、品学楼单区庭院／组团中庭、学子食堂、西湖中心、成电会堂＋商业街、银桦＋清真食堂、基础实验楼、西湖入口和操场各005的 `anomaly.png`，分别登记 `asset_anomaly_003 / unselected + pending`。图书馆正面005因主题性不足保留为rejected，006加入少量档案残页，登记 `asset_anomaly_004 / unselected + pending`；活动中心006维持 `asset_anomaly_005 / unselected + pending`。12张新版日常均维持 `asset_daily_002 / unselected + pending`。
- [11张4K评审拼图](../../../design/concepts/m1-campus-locations/review/codex-workflow/remaining-anomaly-4k-review.jpg)、[完整批次索引](../../../design/concepts/m1-campus-locations/review/codex-workflow/paired-4k-generation.json)。拼图按对象ID字母顺序排列，仅用于审图；各地点正式候选路径、完整提示词、来源与哈希见各自 `generation.md`。
- 视觉检查：所有天空为低饱和墨蓝灰；青蓝碎光与淡倒影集中在门柱、塔芯／廊桥、食堂入口、湖岸廊架、假山、远处看台等各自地标。图书馆006在玻璃中轴及相邻窗格加入略多碎光和少量档案残页，前广场留空，旗帜和旗杆没有恢复。逐张生成源与整组缩小图已查看；水面与地面反光、窗格局部效果仍需负责人审美复核。
- 技术处理：内置imagegen逐地点编辑，原生生成源均为1672×941；交付为3840×2160、RGB不透明PNG。源上下各裁0.25像素后使用高质量双三次重采样，属于非原生4K。11张均通过解码、尺寸、格式及透明度检查。无Godot运行画面改动；运行时地点绑定仍待定。
- 验证：最新版12日常＋12异常共24张全部通过3840×2160解码、RGB与不透明检查；资源台33项测试通过；AssetCatalog扫描26对象／376登记文件，缺失0、不一致0、错误0；批次索引可解析、11张最新异常路径齐全；git diff --check通过。此技术验证不替代正式资产审批。

## 当前样图微调（2026-09-23）

- 人工决定：004的天空比例已确认，只批准天空色调与比例，不是整张资产批准；负责人要求“再适当加一些异常元素（只加一点）”。Manifest在asset_anomaly_003的metadata中记录有限范围的sky_approval，不把整张改为approved。
- 追加反馈：005与上一版差异不明显，asset_anomaly_004改为rejected并保留。新候选006/anomaly.png（asset_anomaly_005 / unselected + pending）在入口增加可辨认的青蓝光块、碎光与柔和地面倒影；保持墨蓝灰天空与双光弧，不增加天空异象。
- [新候选与完整提示词](../../../design/concepts/m1-campus-locations/m1_student_activity_center/006/generation.md)、[前后对照（左005、右006）](../../../design/concepts/m1-campus-locations/review/codex-workflow/activity-anomaly-visible-comparison.jpg)。沿用create-game-assets先校准代表资产再扩展家族，本次仅微调样图，不将批准天空理解为批准新异常密度或完成24张。
- 生成方式：内置imagegen局部编辑；实际源1672×941，最终3840×2160 RGB不透明PNG，高质量双三次重采样、非原生4K。逐图解码与尺寸检查通过；原图及最终文件前后对照已实际查看，天空没有恢复高饱和紫色，主要建筑和道路保持可读。
- 验证基线：c1ea04a加本轮工作树；不改Godot或正式运行目录。原12张日常保持不变，其余11张异常尚未按最终样图扩展。
- 验证结果：资源台33项测试通过；AssetCatalog扫描26对象／352登记文件，缺失0、不一致0、错误0；git diff --check通过。

## 配对4K重制与天空校准记录（2026-09-22）

- 用户明确纠正：异常需要第一版类似的黑紫氛围，但削减异常元素数量；不是维持白天只叠加少量异常。第二轮 `asset_anomaly_002` 因日光方向不符改为 `unselected + rejected`。
- 第三轮已生成12张日常、9张黑紫异常中间稿；负责人随后指出“天空过于紫色了”。这9张紫天中间稿不作为最终交付；生成路径、完整提示词及参考用途保存在 [批次生成索引](../../../design/concepts/m1-campus-locations/review/codex-workflow/paired-4k-generation.json)，不宣称已完成12张新版异常。
- 按负责人指定的 `create-game-assets`，先以天空占比大的学生活动中心做代表样图，确认后才扩展家族。天空改为低饱和墨蓝／蓝黑、灰蓝云层，紫色留在建筑暗部和局部異象；保留双光弧，不新增异常，不改机位与建筑结构。本任务不重定义全局Token或风格规范。
- 12张日常新版为 `asset_daily_002 / unselected + pending`：南门目录006，其余地点004，文件名 `daily.png`。活动中心同目录的 `anomaly.png` 登记 `asset_anomaly_003 / unselected + pending`，用途仅为天空校准样图。
- 已落盘13张均为3840×2160、RGB、不透明PNG。原始生成尺寸全部1672×941，采用System.Drawing HighQualityBicubic，源上下各裁0.25像素以适配16:9再放大；属于重采样4K，不是原生4K或AI超分，不能增加真实细节。
- 当前待决只是一项：活动中心样图的“墨蓝灰天空＋建筑暗紫＋局部紫色异象”比例是否合适。确认后修订其余11张异常，包括图书馆（书页／记忆异常较多但集中，继续去除旗帜／旗杆），再做最终24张配对验收。
- 技术与QA：`create-game-assets/scripts/asset_report.py --expect-size 3840x2160 --json` 13张通过；按 `image-quality-check` 的技术、身份、物理、提示词、可读性、伪影顺序检查，结果 `PASS_WITH_NOTES`。详见 [技术属性与哈希](../../../design/concepts/m1-campus-locations/review/codex-workflow/paired-4k-technical.json)、[质量报告](../../../design/concepts/m1-campus-locations/review/codex-workflow/paired-4k-quality.json)、[前后对照（左修订、右紫天中间稿）](../../../design/concepts/m1-campus-locations/review/codex-workflow/sky-calibration-comparison.jpg)。
- 来源：Codex内置imagegen，未回报可核实模型版本；原生输出和来源路径保留，不推定为“image 2.5”。公开／商业再分发许可仍未单独核验。
- 修正南门Manifest历史登记错误：首轮异常拒绝意见此前误写到了 `concept_001`；现按既有阶段表恢复其 `pending`，将拒绝证据归还 `asset_anomaly_001`，不改变已批准 `concept_003` 和日常001。
- 验证基线：`art/m1-campus-locations` 的 `70105e7` 加本轮工作树；不改变运行时代码、正式生效路径或接入状态。
- 资源校验：33项资源台测试通过；`AssetCatalog.scan()` 为26对象／348文件，缺失0、哈希不一致0、错误0；`git diff --check` 通过。仅保存和登记本轮候选，不修改旧正式资产。

## 既有版本与方案（截至2026-09-21，现行修订见上节）

- 当前正式资产：十二处日常背景已按批准概念逐字节提升到 `assets/art/backgrounds/m1_campus_locations/<地点>/daily.png`。首轮异常态（南门 `004`、其余地点 `002`）因全景赛博化与异常覆盖过强，登记为 `asset_anomaly_001 / unselected + rejected` 并保留作反例。收敛版异常态为南门 `005`、其余地点 `003`，登记为 `asset_anomaly_002 / unselected + pending`，均为 3840×2160 候选，尚未提升到正式运行目录。
- 当前概念基准：`concept_003`；[南门远景修订概念](../../design/concepts/m1-campus-locations/m1_campus_locations/003/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_campus_locations/003/generation.md)。原始 `concept_001`、`concept_002` 保留用于回溯与对比。
- 当前已确认部分与后续待决事项：负责人确认南门概念可以，`concept_003` 作为已选概念基准；其远景主楼通过缩小门窗、降低细节和空气透视表达距离，南门近景结构、右上补全及四个热点锚点保持不变。十二张日常态已获得正式资产提升授权；首轮异常态已因“过于夸张”被否决。收敛版除图书馆外以保留 75%–85% 日常画面、单一局部异常为目标，图书馆保留全组最高但局部化的异常密度；这些新版仍需逐张或整批确认，且任何资产批准均不等同于 Godot 接入授权。
- 新增地点候选：`m1_campus_walk/concept_001`；[校园湖畔步道概念](../../design/concepts/m1-campus-locations/m1_campus_walk/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_campus_walk/001/generation.md)。该候选使用校园平面图的大关系，不宣称具体现实步道身份，状态为 `unselected + pending`。
- 新增地点候选：`m1_campus_court/concept_001`；[校园篮球场概念](../../design/concepts/m1-campus-locations/m1_campus_court/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_campus_court/001/generation.md)。该候选使用校园平面图的运动场组团大关系，不宣称具体现实球场身份，状态为 `unselected + pending`。
- 已批准明确地点概念：`m1_pinxue_courtyard/concept_001`；[品学楼单区内部庭院概念](../../design/concepts/m1-campus-locations/m1_pinxue_courtyard/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_pinxue_courtyard/001/generation.md)。该版本基于用户提供的庭院实景、校园平面图和已批准日常方向，状态为 `selected + approved`，运行时地点绑定待确认。
- 已批准明确地点概念：`m1_pinxue_atrium/concept_001`；[品学楼组团中庭概念](../../design/concepts/m1-campus-locations/m1_pinxue_atrium/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_pinxue_atrium/001/generation.md)。该版本基于用户提供的中庭实景、校园平面图和已批准日常方向，状态为 `selected + approved`，运行时地点绑定待确认。
- 已批准九处明确实景概念：`m1_xuezi_cafeteria`、`m1_student_activity_center`、`m1_west_lake_center`、`m1_chengdian_auditorium_commercial_street`、`m1_yinhua_halal_cafeterias`、`m1_basic_laboratory_building`、`m1_west_lake_entrance`、`m1_sports_field`、`m1_library_front` 的 `concept_001`。每处均使用对应用户实景作为身份参考、南门 `concept_003` 作为画风参考；全部为 `selected + approved`，运行时地点绑定待确认，图书馆版本额外记录 `remove_flags_and_flagpoles`。
- 复用的批准方向／资产及原评审记录：沿用 v0.3 清爽理工校园 × 轻数字美术 × 局部赛博强化方向，以及已批准图书馆环境的日常层渲染纪律；不复制图书馆几何，不修改图书馆任务。
- 技术依据：已批准日常资产为 1672×941、不透明 RGB PNG；收敛版异常候选由 1672×941 生成源以高质量双三次插值交付为 3840×2160、24bpp RGB、不透明 PNG，属于重采样 4K 而非原生 4K。日常状态使用 `data/visual/colors.json` 的日常层；间距与安全区按 `data/visual/spacing.json` 的 4px 倍数原则在后续原生 UI 接入中处理。本轮不生成 Godot 资源、不改运行时代码。
- 接入要求：未来背景不烘焙文字、按钮、侧栏、热点图标或路线线条；需在 1920×1080、2560×1440、1920×1200 三种桌面视口验证四角与底部操作区不压关键建筑。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `concept_001/concept.png` · `586D7711B6BF19FEFF5C53149152D76F366F35F54B7482B205CD62DE0FFEDA11` | 待评审 | 请确认南门身份、2D 表现方向、构图安全区与四个热点锚点。 | 待负责人决定 |
| 概念 | `concept_002/concept.png` · `AEFC64205550A9C384A2967623AF4F2826A186A36C48E15419ECFB5313F3B367` | 待评审 | 用户要求移除右上选定区域；请确认修补边界、连续天空／树冠效果，以及其余南门构图是否保持。 | 2026-09-20，用户修订请求；待负责人决定 |
| 概念 | `concept_003/concept.png` · `5CB280638B9B29A1CCF7DDCC8334E2E0E12A4826ABD5C746D03BC2033454386A` | 已批准，选为概念基准 | 用户确认可以；保留远景主楼的门窗缩小、细节降低与空气透视，作为其他地点概念的日常层参考。 | 2026-09-20，负责人确认“可以了，继续生成其他的地点” |
| 概念 | `m1_campus_walk/concept_001/concept.png` · `5F63B9DB3A36FC67A93F1DE3855E7796B9FCCA52639938A1221B680EE1FB652A` | 待评审 | 湖畔步道候选；请确认步道的场景价值与湖岸构图，并注意现实路径身份仍待照片和地图标记确认。 | 2026-09-20，基于负责人继续制作授权；待负责人决定 |
| 概念 | `m1_campus_court/concept_001/concept.png` · `01B872F85D9FE3B18C925A8D712533A53EC8CF8DDF46FD1DF8F2B1FACE45AB50` | 待评审 | 篮球场候选；请确认球场的场景价值与运动场组团构图，并注意现实场地身份仍待照片和地图标记确认。 | 2026-09-20，基于负责人继续制作授权；待负责人决定 |
| 概念 | `m1_pinxue_courtyard/concept_001/concept.png` · `865D67C5B82D3225165F179845CA976C33340F51D83CBCC91E9497051AA9AA5B` | 已批准 | 品学楼单区内部庭院；中央窄塔、连廊、坡道与庭院尺度通过概念验收。运行时 ID 暂不绑定。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_pinxue_atrium/concept_001/concept.png` · `A854A0FD6FA39026356E4384139A35B8661D615EFEA2A0456C1A89DB70EAB25F` | 已批准 | 品学楼组团中庭；台阶、左右翼楼、中央廊桥、柱列与轴线开口通过概念验收。运行时 ID 暂不绑定。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_xuezi_cafeteria/concept_001/concept.png` · `1520A31F7E4CD5DB2EDCB1201C9C82D097CD1097350B0AAF6E6AA3193AB8DC39` | 已批准 | 学子食堂；红米色体块、玻璃中轴、道路与宿舍背景通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_student_activity_center/concept_001/concept.png` · `A146B8A8CF1C279F19CA8B2B7B7AD3111C1613CBFF7F417FAED26C73F67D3D64` | 已批准 | 学生活动中心；弧形立面、广场与右侧道路通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_west_lake_center/concept_001/concept.png` · `81B7847073EC16833EF4FFDD418A2613031738CD115924396A8FC254C2AA9540` | 已批准 | 西湖中心；木栈道、亭廊、树列与湖岸关系通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_chengdian_auditorium_commercial_street/concept_001/concept.png` · `E9A348D0F759C7057DAF717ABA7495D635C51DB67E8EE7E3CCC5C85977A9A646` | 已批准 | 成电会堂+商业街；会堂主量体与右后商业街双主体关系通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_yinhua_halal_cafeterias/concept_001/concept.png` · `1C0ED5D24E680B93D623EA29B6F3F03488C1D19DA524C3788D3B6681B45EA671` | 已批准 | 银桦食堂+清真食堂；左侧直线体块与右侧弧形门厅通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_basic_laboratory_building/concept_001/concept.png` · `4D006B4E732211A1BBE5E4C42ED6EFF9EE69E0ED2CE4F6DF12A34F4565033C91` | 已批准 | 基础实验大楼；右侧实验楼、玻璃中轴及左侧草地小桥通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_west_lake_entrance/concept_001/concept.png` · `A7B3AF56903EA047EEDCF7C4A271FD4EADCE32A4FB684D72707514DF1410BC7B` | 已批准 | 西湖入口；前广场、湖面与右侧假山喷泉通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_sports_field/concept_001/concept.png` · `7C09249556773ED8DDA0C390E14B3CDDABE274BCE3958CDE18AC4D0E67688A2E` | 已批准 | 操场；球场尺度、球门、树列与远处拱形看台通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_library_front/concept_001/concept.png` · `9A1149B2E7071D13AC43F0BC6452085AA23F9C97E76EBF04DB5908C2D09D2C1C` | 已批准 | 图书馆正面；旗帜与旗杆移除、正立面对称、玻璃中轴与前广场通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 资产 | 十二处 `asset_daily_001`；对应 `assets/art/backgrounds/m1_campus_locations/*/daily.png` | 已批准并提升 | 完全复用已批准概念像素，不重绘；候选与正式文件 SHA-256 逐项一致。仅为日常态正式资产，尚未接入。 | 2026-09-21，负责人要求“将这12张都提升为资产” |
| 资产 | 十二处异常态 `asset_anomaly_001`；南门 `004`、其余地点 `002` | 已拒绝 | 异常覆盖与霓虹／数据元素密度过高，削弱现实校园识别和地点差异；保留文件与记录作反例，不提升、不接入。 | 2026-09-21，负责人反馈“过于夸张”，并要求按质量建议重新生成 |
| 资产 | 十二处收敛版异常态 `asset_anomaly_002`；南门 `005`、其余地点 `003` | 已拒绝（日光方向不符） | 普通地点只保留一种局部异常，维持白天、自然材质和大部分日常画面；图书馆仍为全组最高异常密度，但将书页、档案框与知识图谱集中在中央玻璃中轴和内圈广场，继续保持无旗帜／旗杆。最终文件均为 3840×2160 重采样交付。 | 2026-09-21，按负责人要求重新生成并提升交付分辨率；等待资产批准 |
| 资产 | 十二处 `asset_daily_002`；南门006、其余004的daily.png | 待评审 | 新生成日常4K候选，未沿用旧资产批准；来源与哈希见各目录generation.md。 | 2026-09-22，负责人要求重制12日常＋12异常 |
| 资产 | 活动中心 `asset_anomaly_003`；004/anomaly.png | 待天空校准评审 | 墨蓝灰天空、局部紫色异象；其余11张异常待此样图确认后制作。 | 2026-09-22，负责人反馈“天空过于紫色了” |
| 接入效果 | 未接入 | 不适用 | 正式资产批准并提升后才接入 Godot。 | 待负责人决定 |

## 历史验证与结果（截至2026-09-21）

- 本任务验收条件：用户参考副本与概念候选均可追溯；对象 Manifest 能发现实际文件；南门 `concept_003`、两个品学楼 `concept_001` 与本轮九处实景 `concept_001` 均为 `selected + approved`；旧步道与篮球场仍为 `unselected + pending`；所有对象集成状态保持 `not_integrated`；未获得身份资料的地点不被虚构为已确认现实地点。
- 技术检查结果：PowerShell 7 使用 `System.Drawing.Image` 核对十二张收敛版异常态均为 3840×2160、24bpp RGB、不透明且可解码；生成源为 1672×941，交付文件使用高质量双三次重采样，不宣称原生 4K。十二张生成源均经实际画面检查与通用图片质量闸门检查为 `PASS_WITH_NOTES`：地点身份、主要建筑／景观和底部可用区域保持可读，异常集中于地点专属区域，未使用全景夜化、霓虹铺地、数据雨或泛滥悬浮面板；图书馆异常密度高于其余地点且未恢复旗帜或旗杆。由于 4K PNG 体积较大，`view_image` 对最终文件返回 Base64 解码限制；最终文件以 `System.Drawing.Image` 完成逐张可解码、尺寸、格式与透明度技术核验，视觉内容则以同源生成输出逐张检查。
- Manifest 回写：十二个 `asset_daily_001` 保持 `selected + approved`；十二个 `asset_anomaly_001` 改为 `unselected + rejected` 并记录强度过高的拒绝证据；新增十二个 `asset_anomaly_002`，均为 `unselected + pending`，来源指向对应日常资产并记录地点专属局部异常、生成源尺寸和重采样交付方式。图书馆登记 `anomaly_intensity: medium_high_localized`、日常保留目标 55%–65% 与保持移除旗帜／旗杆要求。旧步道与篮球场不在本次批准范围，继续保持 `unselected + pending`。不填写正式生效文件，全部对象集成均为 `not_integrated`。
- 一致性检查：十二张日常正式资产与批准概念逐项 SHA-256 一致；正式目录只保存运行 PNG，概念、参考图与 generation.md 继续留在 `design/concepts/`。当前没有 Godot 引用或生效文件。
- 资源目录扫描：`AssetCatalog.scan()` 通过；全局 26 个对象、323 个文件，缺失 0、哈希不一致 0。十二个日常资产为 `matched + selected + approved`，首轮异常态为 `matched + unselected + rejected`，收敛版异常态为 `matched + unselected + pending`；运行时地点绑定仍为 `pending_runtime_location_binding`，集成均为 `not_integrated`。`git diff --check` 与资源台 33 项测试通过。
- 适用的布局／动画验证结果：本轮为静态资产候选，不执行 Godot 接入、动画或运行截图；十二张异常态原图已在对话展示。
- 实际截图／动作预览证据：南门、两个品学楼地点、学子食堂、学生活动中心、西湖中心、成电会堂+商业街、银桦食堂+清真食堂、基础实验大楼、西湖入口、操场、图书馆正面共十二张异常态均已在对话展示；无运行时截图。
- 未解决问题：十二处收敛版异常态资产仍待人工资产批准与正式提升；旧步道候选仍缺具体路径照片和地图标记；旧篮球场候选仍缺指定场地照片和地图标记；教学走廊仍缺走廊实景；十二处正式日常资产的运行时 ID 映射尚未确认；两个终点仍未获得独立身份资料；用户提供原图的公开／商业再分发许可未单独核验；全部尚未接入 Godot。
- 本地提交：资源台、差异检查与图像检查通过后按项目规则提交；不自动推送远程。
