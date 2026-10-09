# guard asset_002

2026-10-10：负责人批准最新整套动画及游戏接入；正式运行包使用 assets/art/characters/guard/。

最终文件来自 tmp_001，角色帧图逐文件SHA完全相同；只归一化路径、补齐运行元数据和源包依赖，没有生图或修改动作。

动作来源、文件SHA、当前尺寸和批准依据见 source/provenance.json。原配模型、动画组与CC0许可证保存在 design/references/animation/kaykit/；source/motion.blend保存当前模型，model.json保存动作与相机参数。model-frames、选中转绘源图及frame-map保存模型姿势与2D帧映射；历史生成调用中的旧输入路径只用于来源追踪，不是活动依赖。

本套守护者是历史混合来源：待机／近战／移动使用3D动作导向；最新受击、施法、濒危、退场含直接生成姿势。不能补称全套3D转绘；后续人形工作流必须先完成各自3D动作。

通用处理约束、QA及运行验证以 docs/art/WORKFLOW.md的人形动画生成为准。待机／原待机返回保持精确复用，退场停在末帧；源骨骼、动画和像素不因提升改变。中间候选与废稿按本次授权删除。
