# 项目文档导航

[实现总览](implementation-status.md)说明当前玩家能力与断点；[Roadmap](roadmap.md)维护里程碑、范围和验收。进入M2前先核对它们，再进入对应领域。

## 按领域阅读与维护

- [战役与地图](campaign/README.md)
- [战斗与构筑](combat/README.md)
- [成长、派遣与存档](progression/README.md)
- [内容录入](content/README.md)
- [开发与集成](development/README.md)
- [构建与发布](release/README.md)
- [美术](art/README.md)
- [玩家界面](ui/README.md)
- [音频](audio/README.md)

## 维护规则

同一功能的设计、实现、录入说明和验证留在同一领域目录。功能ID只对应一份当前档案（现有41项），就地更新能力、入口、最近验证日期／基线／命令／覆盖／边界；数值只在规则事实源和运行Resource维护。跨领域接口归development/integration.md，共用验证方式归development/verification.md，具体结果归领域验证页。

新功能只在确有独立边界时建档，不预建空任务或按日期建session文件。功能完成后标记影响和待统筹；统筹核对代码再更新总览，仅范围或优先级改变时调整Roadmap。设计与实装有差异时明确说明，不用旧PASS覆盖当前失败。

单人开发只保留关键方向、现用版本最终状态与可复现契约。小改动决策、逐次审批、失败生成流水、已被替代的提案和截图清单不另存档；Git承担追溯。美术状态仍区分批准／试接入，不因删除历史意见而自动批准。

代码、运行资产、Token和Manifest分别留在game／scenes、assets、data，不搬进docs。美术源资料按领域归design/concepts，原始参考归design/references；许可和当前必要源包保留。调研结论在本领域research，诊断脚本回工具目录，截图回资料目录或缓存。旧implementation与research横切目录已撤销，不留重定向副本。
