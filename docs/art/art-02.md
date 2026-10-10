# ART-02 · 当前资产与游戏接入

- 状态：部分实装；版本与批准由 Manifest 维护，整体视听验收未完成
- 统筹：2026-10-10，代码核对基线 `d99750b`；以下运行结果继承已登记验证，本次目录整理不重新宣称玩法通过。

## 当前能力

五名我方使用已批准asset_002正式帧包，旧守护者asset_001按明确决定留作对照。图书馆五敌人正式包与粉笔精灵混合包已复用主线播放；其余敌人概念／试接入和占位的状态分别查清单。人形首选3D动作导向→日系2D转绘→固定画布序列帧。

图书馆九张室内图、12处日常／异常外景、主菜单六图、记忆终端三图已具备正式资产或技术接入。校园全图asset_001桌面／Web三态继续review＋试接入授权，连续地面候选撤回。HUD和选择页纹理家族已试接入，最终效果状态不等同技术通过。

闪卡直接维护原图、card.tres和Godot review；图鉴自动发现活动集合。声音尚未形成完成的战斗／环境系统。

## 实现与契约

[主Manifest](../../assets/art/asset_manifest.yaml)是实际资源入口；各对象说明与当前状态分别在[人物](characters/player-cast.md)、[敌人](enemies/cast.md)、[校园图](environments/campus-map.md)、[地点](environments/campus-locations.md)、[图书馆](environments/library.md)、[菜单](environments/main-menu.md)、[终端](props/memory-terminal.md)、[UI](README.md)、[闪卡](holo-cards.md)。运行包契约见[战斗动画](../combat/animation.md)。不再单独维护过时的M1静态交付清单。

## 验证与边界

最近整合：2026-10-10、`ed4d275`＋`c3dc5c2`合并树，扫描54对象／2383文件、缺失／不一致／错误0，资源台40项通过；五包提升核验、正式静态与原战斗联合检查通过。入口与当前清理结果见[美术验证](verification.md)。

已有review及试接入授权保持，删除过程记录不补造批准。未提供的真实人物／照片内容、全量无占位、声音、真人观感和最新Web／移动导出仍未完成。
