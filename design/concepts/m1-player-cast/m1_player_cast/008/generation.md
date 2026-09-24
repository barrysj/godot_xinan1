# M1 应援者可换脸头部接口 008 处理记录

处理日期：2026-09-21  
处理方式：从 007 已登记的无工具 RGBA 母版进行确定性逐像素拆分；未调用生成模型，未引入或处理真实人物照片。  
用途：把完整风格化头部从身体中独立出来，为以后在获得明确授权后制作真人身份参考的风格化替换头部预留稳定接口。本批仍为待人工评审的资产候选，不是游戏接入或真实人物内容批准。

## 拆分结果

| 文件 | 用途 | 尺寸／格式 | SHA-256 |
| --- | --- | --- | --- |
| `parts/m1_healer_head_complete_source_008.png` | 紧裁完整头部，供未来替换头生成／处理 | 620×505／RGBA | `a47a35a0ef68fa32308d902f3b1afcfb9354e746d579dfe57defd84ca18c8224` |
| `parts/m1_healer_head_on_source_canvas_008.png` | 保持 1086×1448 源画布坐标的头部层 | 1086×1448／RGBA | `782d027f6cfdae6f4a5201e7c03d6cb6f58e78bfc8ddf1a5831f6d3345d96668` |
| `parts/m1_healer_body_without_head_source_008.png` | 保持源画布坐标的无头身体层 | 1086×1448／RGBA | `81d36365e0c2d870dc7a1affeaa58edddb49823f1feb58955152b8c47f968931` |
| `parts/m1_healer_head_on_canvas_384_008.png` | 384×384 运行尺度头部层 | 384×384／RGBA | `b6b5f763e48a91c83d48e827171307b8f21616c3ca1669931edaa8246b9d963e` |
| `parts/m1_healer_body_without_head_384_008.png` | 384×384 运行尺度无头身体层 | 384×384／RGBA | `1ff26664c6a2c7c9a60830e61389f41bb93ddc328f87d80083bc694b5062c193` |
| `head_socket.json` | 画布、裁切、枢轴、绘制顺序与脸部参考窗 | JSON | 提交时由资源台动态校验 |
| `review/codex-workflow/m1_healer_head_socket_recomposed_384_008.png` | 两层重新叠合结果 | 384×384／RGBA | `0e1ad1910a9b581db0085040e8d3b125fa9c8d4735bbb74ebd1d79486cd2400c` |
| `review/codex-workflow/m1_healer_head_socket_008_contact.png` | 头部、无头身体与接口标记对照 | 1200×700／RGBA | `83470ca6ef553d758af1a5c50f8d5dda7884d4d39d054794b9245ac676cdef6f` |

## 接口规则

- 源画布在 `y=510` 分区；紧裁头部原点为 `(250,35)`，尺寸为 `620×505`。
- 头部源图枢轴为 `(555,510)`；映射到 384×384 画布后为 `(193,122)`。
- 运行时绘制顺序为无头身体在下、头部在上。替换头应透明，并让颈部对齐同一枢轴。
- 青色参考窗只标记脸部构图范围，不是硬裁切蒙版。真人照片应只作为身份参考，先转为与项目一致的完整风格化头部；不建议把原始照片直接贴进四头身战斗角色。
- 使用真实人物照片前，仍需负责人确认来源、使用授权与具体版本，并单独进行内容和接入评审。

## 无损重组验证

007 的 `processed/m1_healer_rig_master_384.png` 与 008 两层重新叠合图逐像素比较：

```text
different_pixels = 0
visible_different_pixels = 0
alpha_different_pixels = 0
max_channel_sum_difference = 0
```

重组图 SHA-256 与 007 归一化母版完全相同，均为 `0e1ad1910a9b581db0085040e8d3b125fa9c8d4735bbb74ebd1d79486cd2400c`。

## 图片质量闸门

```yaml
quality_result:
  schema_version: 1
  task_id: m1-player-cast-healer-head-socket-008
  status: PASS_WITH_NOTES
  eligible_for_asset_review: true
  checks:
    technical_integrity: PASS
    subject_and_identity: PASS
    anatomy_and_physics: PASS
    prompt_and_content: PASS
    composition_and_readability: PASS
    generation_artifacts: PASS
  failures: []
  notes:
    - "头部包含完整发型、脸、耳部与上段颈部；身体保留衣领和下段颈部，没有后脑发梢残留。"
    - "全部部件为真实透明 RGBA，头部与身体使用同一画布版本时可无损重组。"
    - "紧裁头部下缘是接口切线，不是最终独立头像构图；实际换头必须按枢轴对齐颈部。"
    - "当前只拆出完整头部，没有进一步分离前发、后发、面部、眼睛或嘴部，也没有真实人物照片。"
  repair_directives: []
  next_step: human_asset_review
```

