# Visual Task Spec：关系网界面（示例）

## 目标
以网络拓扑展示主角与同学、老师、社团之间的关系。

## 页面
- Scene：`ui/relationship/relationship_screen.tscn`
- 入口：主菜单 > 关系网

## 资产
- `ui.relationship.node_normal`
- `ui.relationship.node_selected`
- 人物头像按 Manifest 读取

## 布局
主角节点中心；一级关系环绕；二级关系向外；顶部筛选栏；右侧人物详情区。

## 视觉
普通关系线=科技青；亲密/情绪=品红；当前可触发事件=亮黄；背景深灰蓝；不持续 glitch。

## 交互
Hover 节点轻微放大并显示标签；Selected 使用选中资产；点击更新右侧详情；滚轮缩放；拖拽移动网络。

## 动效
Hover 120ms；选中 180ms；新关系连线 220ms。

## 验收
- [ ] 节点不互相遮挡
- [ ] 连接线不盖住头像
- [ ] 三类关系颜色正确
- [ ] 右侧详情正常
- [ ] 缩放 80%～130% 可用
