# 守护者 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/characters/guard.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

生成方式：Codex 内置 `image_gen`，无外部图片来源、无在世艺术家风格指令。
- 角色身份基准：虚构中国理工科学生，棕色短发、圆框眼镜、深灰外套、浅蓝衬衫、青色学生证挂绳、斜挎包和像素键帽挂件。
- 排除食物饮料、重型装备、黑客连帽衫和真人身份暗示。
- 以身份基准定向编辑；保留脸、发型、服装与配饰，只加入右手单手霓虹剑、青白剑刃、少量品红权限纹与像素碎片。
- 独立生成巨型半透明防火墙盾；青色分层玻璃盾面、分段硬表面边框、中心锁钥负形与少量品红权限节点。
- 使用以上三图作为身份、剑与盾参考，组合为右手剑、左手盾的角色概念稿，并保留同源头像。
- 从组合稿定向编辑；移除头像、背景、地面与展示框，只保留一个完整战斗角色；目标为约四头身轻卡通比例、右手单手剑、左前臂操作盾牌、真实透明背景与完整安全边距。

## 原始生成提示词

原记录中标为摘要的文本仍是摘要，未补写为完整调用。

### 1 · 最终资产候选提示词摘要

```text
Use case: identity-preserve.
Asset type: isolated 2D battle-character formal candidate for Godot.
Preserve the same fictional student's identity, ordinary campus clothing, messenger bag,
glasses, ID lanyard, cyan/magenta virtual sword and firewall shield.
Redraw as a four-head-tall light-cartoon battle unit facing screen-right; right hand holds
one neon sword, left forearm visibly operates one translucent firewall shield.
Centered full-body cutout, genuine transparent background, no floor shadow, readable at 128x128.
Exactly one character, one sword and one shield; no portrait, text, UI, food, drinks,
guns, medieval ornament, tactical gear, heavy armor or scenery.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
