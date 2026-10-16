# 界面验证

战斗状态、播放、产码、层级与页面清理的最新2026-10-10联合结果统一引用[战斗验证](../combat/verification.md#人物与战斗表现)，不复制表格。

## 选择子页

原场景scenes/expedition/choice_pages_check.tscn、choice_semantics_check.tscn；页面清理另用scenes/expedition/screen_cleanup_check.tscn。上述选择页场景使用GUI -- --capture，覆盖多轮节点、禁用原因、回退、真实奖励归属与原存档恢复。最新主线choice_pages197／0、清理52／0；语义专项曾214／0。隔离夹具支持损失等显示类型，不证明这些效果已经新增进主线。

## 菜单、图鉴与暂停

tools/development/tests/menu_runtime_check.tscn参数-- --test-size=1920x1080（另2560x1440、1920x1200）验证六背景和恢复状态；窗口显示名取“校园异闻”，工程元数据仍保留原身份。scenes/menu/menu.tscn -- --codex-check验证暂停图鉴与恢复；闪卡集合与详情另见[美术验证](../art/verification.md)。

三桌面尺寸实际截图有既有证据；手机、实体手柄、任意极端拥挤和当前Web仍待验证。美术接入状态见对应对象说明和Manifest，不由断言升级。

## 地图与下一站导览

2026-10-13，基线`d042663`＋完整地点节点修正，Godot4.7.2 Compatibility原生窗口。导航专项511／0、地图专项220／0、原Campaign149／0、流程资源120／0、地图编辑器几何／布局6／0。页面清理52／0继承本分支已有结果，本次退出由导航专项覆盖。分支art/campus-navigation-ui从main `2d7cda7`创建，负责人授权调整后squash合入main。

隔离profile的原Campaign控制器通过实际鼠标、方向键、Enter操作，覆盖1920×1080、2560×1440、1920×1200、1280×720。先选择区域，再展开5／5／6个地理地点节点；逐个点击验证边框、名称、图片，校验实验大楼(925,740)以及会堂hall／商业街shopping。三态外观不改选区，悬停不替换点击信息，滚轮／拖动不误选择，拖动后键盘仍可用。展开和返回交接焦点，主要动作／圆形节点／卡片在视口内。

“开始探索”进入原开局策略，策略后才启动Journey；下一站显示完整路线，当前候选可前往，后续地点可查看但禁用前往，原快照保持不变。会堂与商业街分别显示详情，但两个按钮共用enter:0并进入原end_c，不新增故事站次。确认进入地点／返回基地移除旧导航；日间地图、节点与详情使用正式daily素材。守卫／奖励标记与复合终点站次是UI夹具，不证明实际打赢战斗；原战斗、保存与恢复由Campaign回归覆盖。另核验精确旧占位快照使用实时校正，而手工自定义偏移继续有效。

在项目根使用PowerShell7，$godot指向Godot4.7.2 console.exe；日志使用.godot/art-workflow/navigation-ui下绝对路径：

```powershell
& $godot --path . --rendering-method gl_compatibility res://scenes/expedition/campus_navigation_check.tscn -- --capture
& $godot --path . --rendering-method gl_compatibility res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check
& $godot --headless --path . res://scenes/expedition/expedition.tscn -- --campaign-flow-check
& $godot --headless --path . res://scenes/content/campus_flow_preview.tscn -- --flow-preview-check
node --test tools/campus-map-editor/editor-core.test.mjs
```

截图位于.godot/art-workflow/navigation-ui：region-{0,1,2}-*、map-selection-*、next-station-*、next-station-day-*以及compound-next-station-1280x720.png，不入Git。已查看真实全路线图、实验大楼、拆分会堂商业街、深浅地图和四尺寸画面；节点使用深色隔离边／白环／选中暖黄双环与勾号，密集节点上方名称避让，透明按钮边距不挡邻居。位置只随地图移动或控件尺寸事件更新，不每帧轮询Journey。原地图专项仍覆盖三态宽底图、亮区、缩放平滑／拖动／复位和投影；三态底图与亮区参数不变，只调整地标和地点资源。

已知边界：未确认微地点仍为原暂定偏移，不能把正确绑定配置当作全部实地定位；会堂和商业街共用既有复合地点背景，不伪造两套独立素材。根证书／shader缓存权限和旧Kenney读图告警为已有环境边界，无Script／Parse错误；Web、移动端、实体手柄、任意拥挤长内容和色觉障碍用户体验未验。既有美术资产审批状态不因本轮原生UI修改升级。


2026-10-15地图数据校正及校验，基线742de3d：三区各六个地理节点与编辑器关联地标、名称和坐标一致，教学南门不再进入正式路线；旧固定出发／复合地点文案改读真实配置，内部gate和背景类型不决定地点。原四尺寸真实交互检查555／0，图已展示；当前格式存读档、旧格式拒绝、完整原战役及入口见[战役验证](../campaign/verification.md#地图路线一致性)。两个编辑入口仍分离，本次为一次数据对齐；旧坐标不纠偏。同站多地标交互仍复用原组件，资产批准状态不变；部分新对应的地点暂复用已有环境背景。

## Web 战斗中文字体

2026-10-16，基线 `c7184c6`＋本次修复，分支 `codex/fix-web-battle-fonts`，Godot 4.7.2 标准版、PowerShell 7。共用 Theme 默认改用随包的 `SourceHanSansSC-Medium.otf`，使战斗物品、破解预览、代码栏和下拉菜单不再依赖桌面系统字体回退。

在项目根执行，`$godot` 指向 `.godot/web-tools/engine/Godot_v4.7.2-stable_win64_console.exe`：

```powershell
& $godot --headless --path . --quit-after 500 --log-file .godot/art-workflow/battle-font-check/font.log res://scenes/battle_demo/battle_font_check.tscn
& $godot --path . --rendering-method gl_compatibility --quit-after 3000 --log-file .godot/art-workflow/battle-font-check/feedback.log res://scenes/battle_demo/battle_feedback_check.tscn -- --capture
pwsh.exe -File ./build-web.ps1
```

字体检查实例化原 Campaign 战斗，读取真实物品／程序说明、四类代码、按钮、下拉菜单和人物详情的实际解析字体，关闭测试字体的系统回退后逐字检查。旧字体112项中89项缺字；修复后112／0。原战斗反馈图形专项81／0，覆盖1920×1080、2560×1440和1920×1200的详情、键盘／鼠标操作与暂停。

本地 release Web 导出成功，正式 `/web/` 菜单→基地→继续探索→原战斗流程人工检查1280×720浏览器画面：四类代码名称、追踪破解／反冲护盾和代码补给说明正常，物品实际消耗成功；本次正式页面无脚本错误。浏览器截图保留在 `.godot/art-workflow/battle-font-check/web-after-program.jpg` 和 `web-after-item.jpg`，不入Git。Web release模板禁用场景路径覆写，浏览器验证使用正式入口；独立字体检查场景仅通过原生命令启动。

此证据仅覆盖本地桌面浏览器的文字与上述交互；线上Pages、手机真机与全流程平台验收仍沿用既有边界。

### 2026-10-16 单字体复测

`battle_font_check.tscn` 扩展至事件页 FontVariation 与教学标签，关闭 FontFile 及 FontVariation 基础字库的系统回退，115 项／0 失败。正式 Web 包仅保留思源字体，实际菜单、事件奖励页、教学卡、物品说明、破解目标与派遣／地图中文字形正常。发布包范围、截图与命令见 RELEASE-01 的单字体瘦身记录。
