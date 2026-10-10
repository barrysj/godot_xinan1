# 奖励、热点事件与终端回收子页

当前使用 asset_003（重绘纸面＋复用asset_002其余组件），分支art/event-choice-ui，背景修订基线abdfcad＋本轮工作树。技术接入已验证；具体视觉仍为review。既有asset_001／asset_002及原始实施记录保留。

## 授权与范围

用户本任务明确授权：“制作美术资源时可以无需等我的批准，而是直接生成ui ux的图并应用，直到实现功能”。因此本任务直接完成生成、图像检查、主线接入和技术验证，不把中途人工批准作为阻断；此授权不伪造具体版本的人工审美批准，也不授权合入main或推送。

布局依用户要求参考《杀戮尖塔》《怪物火车》的事件阅读体验：弹出子页，左侧插画，右侧描述与选择。使用自制图像与原生Godot文字、按钮，没有复制游戏截图或商业UI素材。官方Steam介绍页仅作产品参考，未用其截图作为图像来源。

## 版本与保留

- asset_001保留frame.png、reward.png、terminal.png、完整generation.json和quality-result.json。稳定副本位于assets/art/ui/event_choice，三张逐字节一致。
- frame为1586×992 RGB无字纸面；reward和terminal为1086×1448 RGB物件插画。生成方式为内置imagegen；来源、完整提示词、SHA、技术与视觉检查均在该版本记录。
- 图片检查：frame PASS；reward、terminal PASS_WITH_NOTES。印刷／电路细线不作为可读文案；档案室插画含风格化窗口，仅作为调查插画，不冒充真实校园照片。生成图不承载按钮、奖励数字或剧情文字。
- 人物肖像、装备图标与三色记忆终端继续复用当前项目资产；原照片查看／放大入口保留。
- 首次交付时仅生成并保留asset_001；2026-10-08视觉修订后改用asset_002，历史源及证据本次不删除。全局生成原件仍保留。必要实机证据归design/concepts/event-choice-ui/review，不混入运行资源。
- 登记表为assets/art/manifests/event_choice_ui.yaml：selected／review与authorized_active分别记录。程序检查或本地提交不把它升级为approved。

## 接入与交互

原campaign_hub与campaign_panel使用choice_page.gd共同组件；保留真实地点作为被遮暗的背景。Anchor、Container、ScrollContainer与CampusUi Theme负责布局，原生文字可换行。参考页在桌面窗口内等比例缩放并居中；长文和多对象可以滚动，焦点限制在当前子页内。

奖励使用紧凑卡，保留收益、类别、对象／生效方式、短按钮。对象选择显示当前候选肖像，不可用原因同时写在卡内。事件支持多轮、条件选项与跨地图线索；返回地点保留未结束节点。通关“核心”仍是现有三台记忆终端，先沿原结算事务保存，再展示已回收和下一步目标。

菜单层高于选择子页；奖励页的Esc打开既有菜单，对象页返回奖励，事件页按当前节点返回权限决定是否返回地点。遮罩阻挡底层点击，更新／关闭子页释放旧焦点与悬停所有权。图片轻微淡入，文字与选项没有持续闪烁。

## 实机验证

2026-10-08，PowerShell7／Godot4.7.2 Compatibility。choice_pages_check三桌面尺寸197／0，无头107／0；额外终端三尺寸54／0。覆盖真实鼠标多轮推进、Esc关闭、继续原节点、跨地图引用、固定训练对象的禁用／返回／一次领取、奖励冻结、菜单叠层、长文初始位置与键盘焦点滚动、失败事务回滚、坏状态拒绝、旧存档默认、原记忆收集与护盾编队、既有结算去重。

原战役全流程无头149／0、实机150／0（012顺序，序章→三区域→终局）；奖励道具69／0、奖励槽22／0、适配23／0、页面清理64／0、校园原交互61／0。精确命令和边界归verification.md及RUN-02／REWARD-01。截图为真实原战役实例上的隔离场景夹具，UI测试中的守卫完成与结算遍历不是自然战斗胜率证据；完整战役检查另行实际推进模拟战斗。

必要证据：event/reward/core三尺寸，linked/person 1920×1080与owner-disabled；asset-validation.json记录全库登记检查。手机、手柄、Web包与真人阅读体验尚未验收；本次只补齐事件JSON在各导出预设的include_filter。高层总览与Roadmap未改。


## asset_002：校园档案卡修订（2026-10-08）

负责人反馈“ui背景、按钮、框感觉都不够好看”，本轮在既有直接生成并应用授权内修改共用选择子页。采用深色插画侧栏、暖白轻纹理正文、克制切角、青色实心主操作，品红仅标识焦点；返回／菜单使用描边次操作。原全屏双描边纸框不再绘制。正文仍为原生可换行中文，保留左图右文及原交互。只修本任务的奖励、热点和终端页，不重定义全局日常界面。

整套asset_002有17份SVG和3份PNG，包含底纹、外壳、插画框、普通／高亮／不可用选项卡、主／次按钮的五态及箭头／保存提示图标；附chrome.json、generation.json和quality-result.json，源总计6,405,755字节（约6.11MiB）。paper.png由内置imagegen生成，实测1659×948 RGB；既有reward／terminal逐字节复用。矢量通过tools/art/ui/build_choice_chrome.py从data/visual/colors.json读取色板确定性生成。卡片16px、按钮12px、插画框20px NinePatch；1120×640逻辑画布，选择页局部线性采样，文字使用现有思源中文字体。生成图没有按钮和文案；纸纹叠48%白色层以压低对比。图片闸门PASS_WITH_NOTES：右下蓝图范围略大于提示词建议比例，不遮挡操作，原插画的既有备注继续有效。

choice_skin.gd为局部皮肤，choice_page.gd沿原Container布局接入；鼠标悬停和键盘焦点同时强调对应卡片，按下转深色，禁用退灰且保留原因。紧凑奖励卡调整内边距与辅助字号。人工审美批准未记录，Manifest保持selected／review、authorized_active。新源与必要实机证据留存；asset_001与已有截图本次不删除、不重复复制旧稿。旧frame.png保留作历史，活动背景改为paper＋shell。

验证基线b2a1e83＋本轮工作树，Godot4.7.2 Compatibility／PowerShell7：choice_pages_check --capture为205／0（三尺寸原流程、多轮、跨地图、奖励对象、长文滚动、焦点和结算）；--capture --skin-only为55／0（含共用图谱检查及真实指针悬停／按下、焦点对应卡片和禁用状态）；screen_cleanup为64／0。没有本轮脚本错误。AssetCatalog为54对象／1575登记文件，0缺失／0不一致，20张源图片与运行副本一致；chrome.json一致。原根证书和Kenney直接读图警告仍存在。

证据位于design/concepts/event-choice-ui/review/codex-workflow/asset-002/：事件／奖励／终端三尺寸，跨地图、训练对象不可用、按钮悬停／按下与test-results、asset-validation。精确复现命令归verification.md。尚未验证手机、实体手柄、Web导出或真人阅读；没有重跑无关战斗数值套件。视觉反馈仍由负责人决定。

## 字体层级与结果标记（2026-10-08）

基线1365e70＋本轮工作树。继续使用asset_002的纸面、插画和矢量框；本轮调整原生排版和组件，没有生成asset_003或修改已登记图片。当前仍为review／authorized_active，既有直接制作并应用授权继续有效，技术通过不代表人工审美批准。新代码与必要实机证据留存，原版本和旧证据不删除。

页面分为标题／事件记录或领取说明／可选行动或候选奖励／保存状态。故事使用常规正文、较舒展行距和轻底色左竖线；选项名独立加粗，说明与限制降低层级。字号只在choice_skin的TYPE_SIZES维护：标题30、正文18、选项20、说明16、后果13、辅助14、按钮17（逻辑像素），不在调用处再传重复字号。字重读取现有typography Token。NotoSansSC可变字体通过TextServer整数wght标签设置FontVariation，避免落到字体默认Thin轴；使用方式参照[Godot FontVariation文档](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html)。全局Theme和Token没有修改。

choice_outcomes.gd从真实奖励operation和CombatReward类别生成展示元数据：装备入库与直接训练区分；补给明确库存增加，招募、资源与构筑强化各有文字。热点读取既有set／command／to，显式outcomes数组可展示混合后果，未知类别回退未知结果，不从文案中的正负号猜测效果。此适配器不执行奖励或事件，也不保存第二份规则数值。

choice_outcome_chip.gd用原生矢量符号＋类别文字＋低对比底色表达结果：道具／资源为金色，属性提升为绿，属性损失为红，消耗为棕，线索／构筑为青，伙伴为品红，探索／未知为灰。混合结果逐项并列，说明保留中性色；单一属性类说明使用对应色。长标签和多个标签均在卡内换行。每类标签的实际文字／底色对比均经检查≥4.5:1，此结果不扩展为整个游戏的无障碍认证。

game-feel用于选项悬停／键盘聚焦时的结果图标轻弹回落，以及节点更新时正文淡入。时长读取animation.json的normal，使用QUAD ease-out；只有视觉节点变化，按钮热区保持稳定，动效期间仍可点击。切换／关闭取消内容Tween，没有持续闪烁、震屏或更改时间流速。

验证：choice_semantics_check三尺寸214／0；原choice_pages_check图形200／0、无头103／0；按钮状态55／0、退出清理64／0。涵盖真实补给点击一次领取、候选快照不变、原事件多轮及跨地图、对象禁用与返回、长文焦点、十类后果对比与换行、未知回退、静止热区及快速关闭。原流程断言数随随机奖励分支变化。损失、消耗与混合数值只在明确标注“界面展示检查”的夹具出现，当前M1未新增扣属性事件；此检查不证明自然战斗胜率或经济平衡。

必要截图与精简验证JSON：design/concepts/event-choice-ui/review/codex-workflow/semantics/，九张实机图（约16MiB；实际体积见test-results）。主线事件、终端、禁用对象、三尺寸真实候选、混合／长标记及悬停已查看；混合检查只为展示能力，不当作正式内容。活动21份源／运行文件仍逐字节一致，全库54对象／1575登记文件，0缺失／不一致／错误。原证书和Kenney警告保留。手机、实体手柄、Web导出、真人阅读仍未验证。精确入口归verification.md。

## 三选项同屏排版修订（2026-10-08）

基线97d4fa6＋工作树。分类与主标题共用头部，短按钮与选项标题同排，描述扩到全宽；后果与辅助说明合并一排，上下间距和按钮内边距收缩。复用asset_002，不修改图片或Token，不创建新资产版本；观感仍review／authorized_active。动效保持短暂，按钮热区不随动画移动。

三个真实补给／训练／装备候选在1920×1080、2560×1440、1920×1200均整卡同屏，无滚动条；choice_semantics_check GUI235／0，原choice_pages无头107／0，原按钮状态GUI55／0。截图已查看，三张必要实机证据与test-results留存于review/codex-workflow/compact；原证据不删除。长故事与较多对象仍允许滚动，未验移动／手柄／Web包；不把该夹具当作所有未来超长选项的保证。

## 事件返回状态修订（2026-10-08）

基线dbe4aa1＋工作树。原页头返回按钮可禁用，原因在按钮下常显，Esc只轻微强调提示；选项不再重复导航。复用asset_002与原Theme／字体／Container，未生成或修改图片，不创建新资产版本；当前review／authorized_active不变。空选项结束页省略行动分区，长文键盘阅读和短页首项焦点保留。

event_return_check三尺寸GUI111／0，choice_semantics235／0，原choice_pages GUI197／0／最终无头96／0，screen_cleanup64／0、原战役无头149／0。四张必要实机截图（禁止三尺寸＋允许1080）及精简验证JSON归review/codex-workflow/return-policy；原证据与源保留。配置与防重抽边界只归RUN-02／content-authoring，手机、实体手柄、Web包和真人体验仍未验。

## 纸面背景重绘与留存（2026-10-08）

用户反馈原背景只在右下角有不明显的花纹，要求保留线稿并增加元素。本轮使用内置image_gen编辑原背景，增加校园建筑、书页、银杏叶、芯片、键盘、网络节点和校园平面线稿，装饰分布于四周、右侧和底部；中央留出安静的阅读区。第二次仅清掉键盘细小符号，不绘制游戏文案。真实校园身份和布局没有在此图定案。

本轮过渡号已分配至tmp_004：tmp_003为首次重绘稿，tmp_004为无键盘标记的最终图。阶段留存决定来自用户答复“只保留最终版与必要证据（推荐）”：最终图、两次完整提示词／来源及必要实机截图留存为asset_003，首次重绘的项目tmp目录删除；既有asset_001／asset_002及已登记证据保留，生成工具的原始输出仍保留在默认目录。此答复只确定留存范围，不视为具体资产或接入效果的人工审美批准。已有直接生成并应用授权继续有效。

asset_003只新增paper.png、generation.json及quality-result.json：PNG实测1659×948 RGB、不透明，2,111,084字节（约2.01MiB），源与运行逐字节一致。Manifest该版本通过相对路径复用asset_002的其他20份运行依赖，不复制一整套旧素材；活动版本selected／review，integration仍authorized_active。原48%白色层、正文背景、字体、按钮、排版、事件返回开关和玩法均不改变。图像通用闸门PASS_WITH_NOTES：线稿为泛化校园／专业装饰；左三分之一在现有插画侧栏下不可见，右侧仍有充分元素，不将此画面当作真实校园空间资料。

PowerShell7／Godot4.7.2 Compatibility，choice_pages_check --capture为197／0，涵盖三桌面尺寸原事件、多轮／跨地图、奖励／对象、长文焦点和结算。实际已查看事件1080／1200、奖励16:10；全库54对象／1578文件，0缺失／不一致／错误，当前21份运行文件全部匹配。四张必要截图和精简test-results／asset-validation在review/codex-workflow/paper-redraw；命令与编辑器退出边界归verification。未扩大为手机、实体手柄、Web包或真人审美验收。
