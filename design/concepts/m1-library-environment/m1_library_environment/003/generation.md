# concept_003 · 径向布局修订 · 三个视角

2026-09-17，基线 a5e9786。此版本为同一空间方案修订，不按视角递增版本。002 保留原四视角；本版三张均未选用、待人工批准、未接入。

## 用户空间依据

用户草图与最新文字明确：书桌和书架长轴都从中庭圆心向外窗径向发散，不是绕中庭的同心环。上层每条径向序列含内侧短桌、中部约六桌长的书架、外侧短桌，桌位半深隔断上有横板及内嵌日光灯管。底层中庭中央为画展，周边水吧与休闲沙发。外观保持原照多边形结构，示意圆不是建筑测绘。展板、绘画、沙发和水吧款式是概念推演，不代表真实历史展品。

## 内建 imagegen 提示词

Create a polished 2D cel shaded daytime architectural game concept, fine outlines, cream polygonal balcony bands, warm brown timber railings, pale stone, same university library atrium as photographic reference. No people, UI, legible text or logos. CRITICAL corrected plan: on upper floors ALL LONG AXES of study tables AND very long shelving runs point RADIALLY from central atrium toward outer facade like wheel SPOKES. They do NOT follow the circumference, do NOT run tangentially alongside the railing or windows. Each ray contains short inner desk section, long middle bookcase section about six desk modules long, short outer desk section ending toward exterior windows. Adjacent rays form aisles. Desktops continuous with HALF-depth dividers between seats, top horizontal board resting on dividers with fluorescent tube RECESSED FLUSH into underside. Inner balustrade and outer windows can remain polygonal rings, but furniture crosses these rings at right angles. Bottom atrium floor completely DIFFERENT: CENTRAL temporary ART EXHIBITION of freestanding display panels with modest generic abstract pictures, perimeter water/beverage bar counter and lounge sofa clusters, no bookshelves or study desks at bottom. Retain actual polygonal atrium shape, side stairs and glass lattice roof from reference; plan diagram circle was schematic. Exact furniture models and art are concept proposals.

- atrium-down.png：参考 reference-2.png，从上层栏杆向下看，中央画展清楚可见，周边沙发和水吧；上层应见径向桌架短端面。
- window-corridor.png：参考 reference-2.png，从外窗看向内侧，强调桌架短端面朝窗，长轴朝中庭，横向通道分隔短桌与长架，不沿窗布置长桌。
- shelf-to-atrium.png：参考 reference-2.png，沿径向一消点透视；左右书架长侧沿视线延伸，端部短桌同向接续，中心通道通到栏杆，不横桌封路。
- 最后一张首输出出现楼板断接，经 imagegen 编辑修复：保持镜头及径向方向，地面完整连接栏杆，增加桌位隔断顶板与嵌灯。仅修复后图作为候选落盘；不保留失败图为另一个版本。

## 自检与评审边界

三张原图已在聊天展示；均为日常静态概念、无人物与游戏 UI。俯视图已呈现画展、沙发、水吧；走廊图桌架同向关系仍不够清楚，书架长度比例待用户审核；径向通道图已修楼板断接，仍残留书架顶灯等模型自行添加细节。不将生成结果描述为准确测绘或完成资产验收。

验证：AssetCatalog.scan 核验 001 一图、002 四图、003 三图与 pending/unselected/not_integrated；PNG 头与 SHA-256 实测；git diff --check。未修改游戏，不需运行截图。
