# 成都地形底图 · asset_004

2026-10-14，image_gen 生成并局部编辑，直接采用最终 1672×941 不透明 PNG，未做像素加工。完整原始提示词、参考顺序和编辑链见 [generation.json](../../../../../design/concepts/ui/dispatch/asset_004/generation.json)。模型版本、种子未由工具提供。

源包保留两张地理参考和局部编辑输入，归 design/concepts/ui/dispatch/asset_004/source；风格参考是 assets/art/ui/dispatch/asset_003/city.png。首张生成结果为 exec-42821dfc-234b-403d-8b78-2f07e917d0dd.png，删除多出的最内侧第五环后得到最终 exec-61a43a9d-4475-4c73-a370-3f75816a321a.png。旧 asset_003 为必要风格输入，不删除其来源链。

## 地理依据与来源

- [环路示意参考](https://p0.itc.cn/images01/20210829/bf2115ab164a415d83bc5c87bcdbd6d5.jpeg)：核对一环、二环、三环、绕城的嵌套与偏心形态，排除2.5环、规划3.5环及最内河流圈。第三方地图，署名“地图帝”，仅作地理参考，非项目可再分发美术，不进入运行资源。
- [道路地图参考](https://fcqimg.soufunimg.com/pc/fcq/2024/07/24/6462579e-3b0a-4123-b1fc-2bf814e125fe.jpg)：核对清水河紧邻西北侧绕城；忽略图上手绘红色路线。来源房天下新闻页，权利未另获许可，仅研究参考，不进入运行资源。
- [学校地址](https://zs.uestc.edu.cn/wap/article/view/id/832.html)：清水河校区为西源大道2006号；[学校报道](https://news.uestc.edu.cn/info/1069/28518.htm)用于交叉核对校园与绕城关系。
- 高德地点参考：[清水河](https://amap.com/place/B001C8UQ4H)、[沙河主楼](https://ditu.amap.com/place/B001C8WG1A)。只用于相对地理位置，运行时坐标不是经纬度。

## 自检与接入

QA PASS_WITH_NOTES：四条主要闭合道路可辨；最外绕城使用橙色边、灰色路面及车道标识，蓝色仅表示水系。无地点插画、缩略图、文字或图钉烘焙。道路和地点标签独立读取 game/meta/dispatch_map.json。清水河位于绕城西北侧外缘，沙河在春熙路东北侧；是据参考重绘的游戏示意，未作GIS投影配准，不能用于导航。沿用用户session美术自主授权，review／authorized_active，不冒充逐图人工批准。
