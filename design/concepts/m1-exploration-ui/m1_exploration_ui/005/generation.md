# 原生组件候选 005

依据已批准的 concept_004；用户“继续吧”后进入资产制作，未获主游戏试接入授权。采用 Godot Control / Button / Container 与原生矢量绘制，复用项目 Theme、中文字体和异常层 Token；未调用图像生成。003/background-study.png 只供独立预览，不复制、提升或批准背景资产。

入口 preview.tscn，可点击四热点；一次仅展开一个详情。鼠标空白点击、关闭按钮和 Esc 返回；Tab 在弹窗内循环，关闭恢复热点焦点。热点和弹窗采用独立可点击范围。action_requested 与 set_guard_result 是预览交互接口，不连接战斗、存档或奖励系统。普通热点“已查看”仅为样例状态。

运行同一场景并附加 `-- --ui-capture` 可重建三尺寸默认、详情、完成截图；证据保存至 ../../review/codex-workflow/asset-005。测试通过视口输入事件驱动鼠标与焦点，不是仅发射 pressed 信号。背景按 cover 变换，HUD 角落锚定，弹窗边缘翻转并夹紧。Windows 三尺寸验证不代表手机、超宽屏或实体手柄认证。

仍待人工评审；主游戏未接入。尚未制作信号动态干扰、过渡动画或文本大小设置。模板编辑器 settings_menu.gd 存在无关解析报错，本候选独立运行日志无报错。
