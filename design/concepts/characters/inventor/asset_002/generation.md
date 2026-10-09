# inventor asset_002

2026-10-10：负责人批准最新整套动画及游戏接入；正式运行包使用 assets/art/characters/inventor/。

最终文件来自 tmp_005，角色帧图逐文件SHA完全相同；只归一化路径、补齐运行元数据和源包依赖，没有生图或修改动作。

动作来源、文件SHA、当前尺寸和批准依据见 source/provenance.json。原配模型、动画组与CC0许可证保存在 design/references/animation/kaykit/；source/base-motion.blend保存普通动作模型，source/motion.blend保存最终派生施法模型，model.json保存动作与相机参数。model-frames、选中转绘源图及frame-map保存模型姿势与2D帧映射；历史生成调用中的旧输入路径只用于来源追踪，不是活动依赖。

优先复用角色原配开源动作；施法在原动作上进行时间重映射、原生待机返回和自制科技道具动画。全身转绘可能演绎关节与武器透视，不是把静态图贴到模型上直接渲染。

通用处理约束、QA及运行验证以 docs/art/WORKFLOW.md的人形动画生成为准。待机／原待机返回保持精确复用，退场停在末帧；源骨骼、动画和像素不因提升改变。中间候选与废稿按本次授权删除。
