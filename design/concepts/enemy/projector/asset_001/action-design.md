# 投影独眼灵动作设计清单

身份依据：concept_003；单视角替代三视图经负责人2026-10-07确认。
游戏：现有自动战斗，沿用战棋动作包。预算：七种动作，骨骼连续运动与序列帧混合。
动作签名：轻悬浮、挡片收拢聚焦，镜头释放时机身小幅后坐

| 动作 | 循环 | 设计采样 | 出手点 | 后续衔接 |
| --- | --- | --- | --- | --- |
| idle | loop | 16 | — | 原表现层返回idle／move／critical |
| move | loop | 16 | — | 原表现层返回idle／move／critical |
| ranged | one-shot | 16 | 8（运行释放0.45） | 原表现层返回idle／move／critical |
| cast | one-shot | 16 | 8（运行释放0.45） | 原表现层返回idle／move／critical |
| hurt | one-shot | 16 | — | 原表现层返回idle／move／critical |
| critical | loop | 16 | — | 原表现层返回idle／move／critical |
| death | one-shot-freeze-last | 16 | — | 末姿冻结，恢复生命由原表现层重置 |

## 动作卡

### idle

```json
{
  "action_card_v2": {
    "action_id": "idle",
    "module": "idle",
    "priority": "P0",
    "loop_policy": "loop",
    "frame_count": 16,
    "frame_rate": 12,
    "canvas_size": [
      640,
      640
    ],
    "view_angle": "side-2.5d",
    "key_poses": [
      {
        "frame": 1,
        "height": "mid",
        "pose": "常态姿势"
      },
      {
        "frame": 4,
        "height": "low",
        "pose": "重心微升"
      },
      {
        "frame": 8,
        "height": "high",
        "pose": "状态平稳"
      },
      {
        "frame": 12,
        "height": "mid",
        "pose": "重心微落"
      },
      {
        "frame": 16,
        "height": "mid",
        "pose": "回到首姿"
      }
    ],
    "consistency_locks": {
      "identity_anchor": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆",
      "asymmetry_lock": "保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点",
      "weapon_hand_lock": "一枚镜头与四块挡片；一套顶部支架；无手持武器",
      "palette_lock": "#F6F8FA / #252B33 / #22E0F0 / #E83E8C",
      "direction_hint": {
        "E": "固定概念板的朝右三分之四视角；不生成背向"
      }
    },
    "transitions": {
      "can_cancel_to": [],
      "interruptible": true,
      "blend_time": 0,
      "hit_frame": 0
    },
    "motion_trail": null,
    "prompt": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆；保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点；一枚镜头与四块挡片；一套顶部支架；无手持武器；#F6F8FA / #252B33 / #22E0F0 / #E83E8C；常态姿势→重心微升→状态平稳→重心微落→回到首姿；固定朝右三分之四视角，干净赛博校园2D赛璐璐与透明背景。",
    "runtime_sampling": "16帧为关键姿势设计网格；骨骼连续插值，出手映射impact_ratio=0.45；远程第8帧表示释放而非抵达伤害"
  }
}
```

### move

```json
{
  "action_card_v2": {
    "action_id": "move",
    "module": "locomotion",
    "priority": "P0",
    "loop_policy": "loop",
    "frame_count": 16,
    "frame_rate": 12,
    "canvas_size": [
      640,
      640
    ],
    "view_angle": "side-2.5d",
    "key_poses": [
      {
        "frame": 1,
        "height": "mid",
        "pose": "开始移动"
      },
      {
        "frame": 4,
        "height": "low",
        "pose": "重心抬升或步态迈出"
      },
      {
        "frame": 8,
        "height": "high",
        "pose": "推进中心"
      },
      {
        "frame": 12,
        "height": "mid",
        "pose": "回摆或换步"
      },
      {
        "frame": 16,
        "height": "mid",
        "pose": "返回循环首姿"
      }
    ],
    "consistency_locks": {
      "identity_anchor": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆",
      "asymmetry_lock": "保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点",
      "weapon_hand_lock": "一枚镜头与四块挡片；一套顶部支架；无手持武器",
      "palette_lock": "#F6F8FA / #252B33 / #22E0F0 / #E83E8C",
      "direction_hint": {
        "E": "固定概念板的朝右三分之四视角；不生成背向"
      }
    },
    "transitions": {
      "can_cancel_to": [],
      "interruptible": true,
      "blend_time": 0,
      "hit_frame": 0
    },
    "motion_trail": null,
    "prompt": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆；保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点；一枚镜头与四块挡片；一套顶部支架；无手持武器；#F6F8FA / #252B33 / #22E0F0 / #E83E8C；开始移动→重心抬升或步态迈出→推进中心→回摆或换步→返回循环首姿；固定朝右三分之四视角，干净赛博校园2D赛璐璐与透明背景。",
    "runtime_sampling": "16帧为关键姿势设计网格；骨骼连续插值，出手映射impact_ratio=0.45；远程第8帧表示释放而非抵达伤害"
  }
}
```

### ranged

```json
{
  "action_card_v2": {
    "action_id": "ranged",
    "module": "attack",
    "priority": "P0",
    "loop_policy": "one-shot",
    "frame_count": 16,
    "frame_rate": 12,
    "canvas_size": [
      640,
      640
    ],
    "view_angle": "side-2.5d",
    "key_poses": [
      {
        "frame": 1,
        "height": "mid",
        "pose": "悬浮值守"
      },
      {
        "frame": 4,
        "height": "low",
        "pose": "四挡片收拢聚焦"
      },
      {
        "frame": 8,
        "height": "high",
        "pose": "镜头出光、机身后坐"
      },
      {
        "frame": 12,
        "height": "mid",
        "pose": "挡片回收"
      },
      {
        "frame": 16,
        "height": "mid",
        "pose": "回到悬浮"
      }
    ],
    "consistency_locks": {
      "identity_anchor": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆",
      "asymmetry_lock": "保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点",
      "weapon_hand_lock": "一枚镜头与四块挡片；一套顶部支架；无手持武器",
      "palette_lock": "#F6F8FA / #252B33 / #22E0F0 / #E83E8C",
      "direction_hint": {
        "E": "固定概念板的朝右三分之四视角；不生成背向"
      }
    },
    "transitions": {
      "can_cancel_to": [
        "death"
      ],
      "interruptible": false,
      "blend_time": 0,
      "hit_frame": 8
    },
    "motion_trail": null,
    "prompt": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆；保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点；一枚镜头与四块挡片；一套顶部支架；无手持武器；#F6F8FA / #252B33 / #22E0F0 / #E83E8C；悬浮值守→四挡片收拢聚焦→镜头出光、机身后坐→挡片回收→回到悬浮；固定朝右三分之四视角，干净赛博校园2D赛璐璐与透明背景。",
    "runtime_sampling": "16帧为关键姿势设计网格；骨骼连续插值，出手映射impact_ratio=0.45；远程第8帧表示释放而非抵达伤害"
  }
}
```

### cast

```json
{
  "action_card_v2": {
    "action_id": "cast",
    "module": "skill",
    "priority": "P0",
    "loop_policy": "one-shot",
    "frame_count": 16,
    "frame_rate": 12,
    "canvas_size": [
      640,
      640
    ],
    "view_angle": "side-2.5d",
    "key_poses": [
      {
        "frame": 1,
        "height": "mid",
        "pose": "镜头平稳"
      },
      {
        "frame": 4,
        "height": "low",
        "pose": "支架伸展、挡片准备，光效由弱转强"
      },
      {
        "frame": 8,
        "height": "high",
        "pose": "聚焦强化投射，青色镜头聚光在释放帧达到峰值"
      },
      {
        "frame": 12,
        "height": "mid",
        "pose": "降低光强，光环扩散后消退"
      },
      {
        "frame": 16,
        "height": "mid",
        "pose": "回到悬浮"
      }
    ],
    "consistency_locks": {
      "identity_anchor": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆",
      "asymmetry_lock": "保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点",
      "weapon_hand_lock": "一枚镜头与四块挡片；一套顶部支架；无手持武器",
      "palette_lock": "#F6F8FA / #252B33 / #22E0F0 / #E83E8C",
      "direction_hint": {
        "E": "固定概念板的朝右三分之四视角；不生成背向"
      }
    },
    "transitions": {
      "can_cancel_to": [
        "death"
      ],
      "interruptible": false,
      "blend_time": 0,
      "hit_frame": 8
    },
    "motion_trail": null,
    "prompt": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆；保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点；一枚镜头与四块挡片；一套顶部支架；无手持武器；#F6F8FA / #252B33 / #22E0F0 / #E83E8C；镜头平稳→支架伸展、挡片准备，光效由弱转强→聚焦强化投射，青色镜头聚光在释放帧达到峰值→降低光强，光环扩散后消退→回到悬浮；固定朝右三分之四视角，干净赛博校园2D赛璐璐与透明背景。",
    "runtime_sampling": "16帧为关键姿势设计网格；骨骼连续插值，出手映射impact_ratio=0.45；远程第8帧表示释放而非抵达伤害"
  }
}
```

### hurt

```json
{
  "action_card_v2": {
    "action_id": "hurt",
    "module": "hit",
    "priority": "P0",
    "loop_policy": "one-shot",
    "frame_count": 16,
    "frame_rate": 12,
    "canvas_size": [
      640,
      640
    ],
    "view_angle": "side-2.5d",
    "key_poses": [
      {
        "frame": 1,
        "height": "mid",
        "pose": "维持原姿"
      },
      {
        "frame": 4,
        "height": "low",
        "pose": "短促后仰"
      },
      {
        "frame": 8,
        "height": "high",
        "pose": "承受冲击"
      },
      {
        "frame": 12,
        "height": "mid",
        "pose": "重心回收"
      },
      {
        "frame": 16,
        "height": "mid",
        "pose": "恢复原状态"
      }
    ],
    "consistency_locks": {
      "identity_anchor": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆",
      "asymmetry_lock": "保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点",
      "weapon_hand_lock": "一枚镜头与四块挡片；一套顶部支架；无手持武器",
      "palette_lock": "#F6F8FA / #252B33 / #22E0F0 / #E83E8C",
      "direction_hint": {
        "E": "固定概念板的朝右三分之四视角；不生成背向"
      }
    },
    "transitions": {
      "can_cancel_to": [],
      "interruptible": true,
      "blend_time": 0,
      "hit_frame": 0
    },
    "motion_trail": null,
    "prompt": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆；保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点；一枚镜头与四块挡片；一套顶部支架；无手持武器；#F6F8FA / #252B33 / #22E0F0 / #E83E8C；维持原姿→短促后仰→承受冲击→重心回收→恢复原状态；固定朝右三分之四视角，干净赛博校园2D赛璐璐与透明背景。",
    "runtime_sampling": "16帧为关键姿势设计网格；骨骼连续插值，出手映射impact_ratio=0.45；远程第8帧表示释放而非抵达伤害"
  }
}
```

### critical

```json
{
  "action_card_v2": {
    "action_id": "critical",
    "module": "status",
    "priority": "P0",
    "loop_policy": "loop",
    "frame_count": 16,
    "frame_rate": 12,
    "canvas_size": [
      640,
      640
    ],
    "view_angle": "side-2.5d",
    "key_poses": [
      {
        "frame": 1,
        "height": "mid",
        "pose": "保持濒危姿态"
      },
      {
        "frame": 4,
        "height": "low",
        "pose": "弱幅摇摆"
      },
      {
        "frame": 8,
        "height": "high",
        "pose": "光强低落"
      },
      {
        "frame": 12,
        "height": "mid",
        "pose": "弱幅回摆"
      },
      {
        "frame": 16,
        "height": "mid",
        "pose": "回到首姿"
      }
    ],
    "consistency_locks": {
      "identity_anchor": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆",
      "asymmetry_lock": "保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点",
      "weapon_hand_lock": "一枚镜头与四块挡片；一套顶部支架；无手持武器",
      "palette_lock": "#F6F8FA / #252B33 / #22E0F0 / #E83E8C",
      "direction_hint": {
        "E": "固定概念板的朝右三分之四视角；不生成背向"
      }
    },
    "transitions": {
      "can_cancel_to": [],
      "interruptible": true,
      "blend_time": 0,
      "hit_frame": 0
    },
    "motion_trail": null,
    "prompt": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆；保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点；一枚镜头与四块挡片；一套顶部支架；无手持武器；#F6F8FA / #252B33 / #22E0F0 / #E83E8C；保持濒危姿态→弱幅摇摆→光强低落→弱幅回摆→回到首姿；固定朝右三分之四视角，干净赛博校园2D赛璐璐与透明背景。",
    "runtime_sampling": "16帧为关键姿势设计网格；骨骼连续插值，出手映射impact_ratio=0.45；远程第8帧表示释放而非抵达伤害"
  }
}
```

### death

```json
{
  "action_card_v2": {
    "action_id": "death",
    "module": "death",
    "priority": "P0",
    "loop_policy": "one-shot-freeze-last",
    "frame_count": 16,
    "frame_rate": 12,
    "canvas_size": [
      640,
      640
    ],
    "view_angle": "side-2.5d",
    "key_poses": [
      {
        "frame": 1,
        "height": "mid",
        "pose": "濒危姿态"
      },
      {
        "frame": 4,
        "height": "low",
        "pose": "核心熄灭开始失稳"
      },
      {
        "frame": 8,
        "height": "high",
        "pose": "落地或坍下"
      },
      {
        "frame": 12,
        "height": "mid",
        "pose": "惯性停稳"
      },
      {
        "frame": 16,
        "height": "mid",
        "pose": "末姿冻结"
      }
    ],
    "consistency_locks": {
      "identity_anchor": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆",
      "asymmetry_lock": "保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点",
      "weapon_hand_lock": "一枚镜头与四块挡片；一套顶部支架；无手持武器",
      "palette_lock": "#F6F8FA / #252B33 / #22E0F0 / #E83E8C",
      "direction_hint": {
        "E": "固定概念板的朝右三分之四视角；不生成背向"
      }
    },
    "transitions": {
      "can_cancel_to": [],
      "interruptible": false,
      "blend_time": 0,
      "hit_frame": 0
    },
    "motion_trail": null,
    "prompt": "无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆；保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点；一枚镜头与四块挡片；一套顶部支架；无手持武器；#F6F8FA / #252B33 / #22E0F0 / #E83E8C；濒危姿态→核心熄灭开始失稳→落地或坍下→惯性停稳→末姿冻结；固定朝右三分之四视角，干净赛博校园2D赛璐璐与透明背景。",
    "runtime_sampling": "16帧为关键姿势设计网格；骨骼连续插值，出手映射impact_ratio=0.45；远程第8帧表示释放而非抵达伤害"
  }
}
```

## 下游与衔接

本轮仅朝右概念视角；朝左由已有引擎显示变换处理，未生产背面或八方向。
F1/F4/F8/F12/F16用于约束动作节奏，连续骨骼不等于16张PNG。16→1闭环检查以实际Godot GIF为依据。
攻击和施法由模拟动作锁定，受击不抢占；死亡打断，末帧停留；恢复生命回到现有静止状态。
远程F8表示发射，命中由模拟弹道抵达时决定；没有另建战斗状态机。
