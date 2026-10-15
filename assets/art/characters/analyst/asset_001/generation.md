# 分析员准备姿态 · 制作依据

2026-10-14，内置 image_gen 编辑；transparent_background=true。输入 reference-guard.png（原守护者 idle_00.png 的逐字节副本），仅参考四头身、站姿和渲染风格。输出 ready.png 1341×1173 RGBA；未处理像素。模型版本和随机种子未由工具提供。源调用文件名 exec-e6c0295c-301f-49dc-aa9d-4921c27f6aa0.png。

## 原始提示词

Edit the supplied game sprite into a NEW character, the data analyst, while using the input only for exact four-heads-tall body proportions, full-body framing, grounded stance and clean soft cel-shaded anime rendering. Do not preserve the boy's identity or weapons. The analyst is a youthful female engineering university student: amber-brown shoulder-length hair with tidy bangs, calm intelligent face, compact navy headset, ivory shirt under a muted lavender zip hoodie, dark navy practical trousers, white low-top sneakers, cyan student ID lanyard. She holds a slim tablet at her left forearm and a small digital stylus naturally in her right hand, ready to inspect data. Three-quarter view facing right. Replace the shield and sword entirely; no weapons, no big floating hologram. Crucially keep the input's short FOUR HEAD HEIGHT full body proportions, not seven-head fashion proportions and not a baby chibi. Maintain separated arms and legs and readable silhouette. One figure only. Full head and both soles visible, no cropping. Transparent background with clean alpha, no glow behind the person, no ground, no cast shadow, no text, no frame. This is a single neutral ready-pose sprite for the original battle renderer, not a scene or poster.

## 选用与边界

QA PASS_WITH_NOTES：头身、身份、服饰、平板与手部接触、轮廓、透明背景和完整脚底可读；单张准备姿态，不是完整动作序列。原始程序位移／伸缩／受击／倒下演出继续驱动它；角色数据与规则不变。display_size 174.33×152.49，anchor(0.52,0.905)，头像取(485,180,410,390)。来源为本次AI生成，风格参考为项目既有守护者；无新增第三方下载。按本session自主美术授权选用，不冒充逐图人工批准。
