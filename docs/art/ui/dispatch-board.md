# 派遣白板

沿用清爽理工校园、轻数字表达的项目方向。校内以真实校园布局为几何依据绘制派遣地图；校外采用成都一环、二环、三环与绕城示意，清水河在西北，沙河在春熙路东北。地名、委托、资源、按钮为原生控件，保证清晰度与交互。

现用整套 asset_007：校内图与四类奖励／资源图标使用 asset_005，城市图沿用 asset_004/city.png，白板材质沿用 asset_001。地理来源、完整提示词、编辑输入链与质量边界见[生成说明](../../../assets/art/ui/dispatch/asset_004/generation.md)。原基地背景继续使用，点击右侧白板进入派遣。

本 session 用户明确免除美术审批，Codex 已自检选用；Manifest 保留 review 表达无单张人工批准，接入授权为 authorized_active。校园地标必须与项目真实校内地图的相对位置对应；派遣委托不等于探索路线。地图保留插画精度，不用于导航。文字和按钮不烘焙进图片。

2026-10-14：Godot 实机展示地图、往返动画与结算窗口；运行证据随 META-02 / META-03 功能验证记录维护。新增asset_002三名后勤立绘，UI头像由原图AtlasTexture取区，地图头像移动、成果归队与人选共用。准备页复用同一白板材质、既有物资箱插画和新物品图标；途中招募复用既有AI事件卡。分析员像素占位替换为绘制立绘，详见[分析员](../characters/analyst.md)。这些素材已自检选用，未重绘全部既有战斗特效和原生控件。

## 城市底图与地点分层

2026-10-14，基线e9b34ce：按地理参考重新生成1672×941地形／道路底图，四条环路清晰可辨；最外绕城为橙色边灰色路面，避免与蓝色河流混淆。无烘焙地点缩略图、文字或图钉。QA PASS_WITH_NOTES，未做测绘投影配准，不用于导航。

清水河落点在绕城西北侧外缘，沙河在春熙路东北侧。地点按钮与落点引导线独立叠加，城市不显示道路名称，读取 game/meta/dispatch_map.json；清水河落点同时驱动校园缩放锚点与派遣出发点。派遣编辑器复用校园工具服务，使用独立页面与数据契约，见[派遣地图](../../progression/dispatch-map.md)。三尺寸游戏验证与浏览器保存验证见META-02。

asset_005 的真实布局参考、完整提示词和图标分区见[制作依据](../../../assets/art/ui/dispatch/asset_005/generation.md)。2026-10-15资源目录校验：19文件，missing/mismatch/errors均0。新版界面实机检查及触屏模拟边界见[META-02](../../progression/meta-02.md)。

人员空位现用asset_007/staff_slot.png：细青色轮廓、米白底、大面积深青人形与独立加号，1254×1254 RGBA透明边缘。取消厚金属外壳、星徽和圆形加号徽章；无原生按钮额外框体，保留84×84点击区及亮度反馈。选人后替换为后勤头像。

完整提示词及编辑参考链见design/concepts/ui/dispatch/asset_007/generation.json；asset_006仅作为编辑输入保留，原“厚框仍可用”的判定撤回。当前image-quality-check：技术、主体、任务符合、可读性及生成伪影检查PASS；解剖物理不适用。eligible_for_style_validation=true，next_step=accept；仅表示通用质量通过，不冒充独立风格验证或人工批准。

2026-10-15，基线479f6e3后，1920×1080实际84像素槽位核对人形／加号辨识，dispatch_framework_check为failures=0。Manifest 24文件matched，missing/mismatch/errors均0。session免审批接入仍标记review / authorized_active；可读性判断为Codex自检，未做玩家盲测。
