# 分析员

现用 assets/art/characters/analyst/asset_001：四头身校园分析员准备姿态，替换原像素占位。头像、出发人员选择、招募与战场共用同一来源；白衬衣、浅紫外套、耳机和平板形成身份识别。

原始提示词、输入图、参数与QA见源包generation.md。用户本session给予自主美术授权，Codex选用并接入；Manifest为review / authorized_active，不声明单图人工批准。

战斗沿用原动作时序与程序位移、受击、伸缩及倒下演出，未制作逐帧动画。BattleAnimationSet.fallback_texture仅在没有有效动作贴图时使用，已有角色帧序列优先。战斗数值未改动。2026-10-14在准备／招募／两人开局战场实机验收，验证入口party_progression_check、preparation_check和animation_check。
