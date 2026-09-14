# GitHub Pages 发布

目标地址：https://barrysj.github.io/godot_xinan1/

## 首次启用

1. 打开 https://github.com/barrysj/godot_xinan1/settings/pages ，将 Build and deployment → Source 设为 **GitHub Actions**。
2. 将本地代码提交并推送到 `main`。按项目约定，推送由仓库主人手动执行。
3. 在仓库 Actions 中查看 **Publish Web to GitHub Pages**：build 和 deploy 都成功后访问目标地址。
4. 首次发布后验证：Play → 校园基地 → 开始探索 → 编队 → 开战 → 结算，以及暂停/返回菜单。

后续推送 `main` 自动更新网站，也可在 Actions 页面选择 Run workflow。旧的通用模板工作流已由这条专用流程替代，避免同时向 gh-pages 分支部署。无需 PAT 或自建部署密钥。

## 构建约定

- 固定 Godot **4.7.2 标准版**。当前项目使用 GDScript；Mono 编辑器会拒绝 Web 导出。
- CI 从 Godot 官方发布下载引擎与模板并验证 SHA-512，只安装 Web 单线程模板，随后缓存。
- 使用 Compatibility 渲染器、单线程 Web 导出、默认相对资源路径；PWA 未启用。
- 中文字体随游戏打包：Google Fonts Noto Sans SC，许可证见 `assets/fonts/OFL.txt`。
- 上传 `builds/web` 为官方 Pages artifact，再通过 `actions/deploy-pages` 发布。
- `builds` 和 `.godot` 不提交。首次 CI 下载完整模板较大，后续命中缓存会更快。

## 本地复现

PowerShell 7：

```powershell
pwsh.exe -File .\build-web.ps1
```

本机默认使用 `.godot/web-tools/engine` 下的标准版。其他机器通过 `-Godot '完整可执行文件路径'` 指定标准版，并先安装 4.7.2 导出模板。

用 HTTP 服务提供 `builds` 目录，再打开 `/web/`。不要双击 HTML，也不要只上传 HTML；WASM、PCK、JS 等全部文件必须一起部署。

## 线上验收

- 确认在仓库子路径下加载成功、中文与像素素材正常。
- 桌面浏览器能完成一场战斗，暂停和返回菜单正常。
- 手机浏览器横屏验证加载与点击；电脑缩小窗口不能替代 Android/iOS 真机验收。
- 网页存档属于当前浏览器与站点，清理网站数据会清除存档。刷新后从最近一次节点检查点恢复；若在战斗中刷新，则从该场战前阵容重开，不恢复逐帧生命与位置。

如果 deploy 提示找不到 Pages 站点，优先检查首次启用的 Source 设置。如果 build 失败，查看 Import and export 日志；不要把未成功构建的产物当作已发布。

## 本次本地验证（2026-09-07）

Godot 4.7.2 标准版实际 release Web 导出成功；本地 `/web/` 子路径加载、主菜单进入、中文/像素资源、开始探索、进入编队和战斗暂停已通过浏览器检查。原生完整路线 smoke 通过。844×390 浏览器视口能进入游戏，但文字偏小；尚未完成 Android/iOS 真机验收。GitHub Actions 与线上地址须在手动推送、启用 Pages 后验证，不能用本地结果代替线上验收。

## 当前本地验证（2026-09-14）

当前提交使用 Godot 4.7.2 标准版重新导出 release Web 包，并在 Codex 应用内浏览器的默认桌面视口通过完整流程：模板主菜单 → 基地 → 新探索 → 首战部署 → 战斗／暂停／恢复 → 战报与奖励 → 路线事件 → Boss → 结算 → 返回基地与主菜单。中文字体、两名绘制角色、像素角色与三张战斗背景均从实际导出包加载；控制台没有游戏脚本错误。

在 Boss 前地图检查点刷新后，“继续”准确恢复到第 5/5 层。另复现了原子替换后立刻刷新可能读到旧 IndexedDB 检查点的问题；现于 Web 成功写入后强制同步持久文件系统。修复包已验证奖励后立刻刷新仍恢复到最新第 2/5 地图，战斗开始后立刻刷新则恢复同一场的 4/4 战前阵容。

844×390 仅作为小屏风险探针：页面可加载，地图与部署点选可触达，但中文、卡片和勾叉确认控件明显偏小，因此不判定为手机可用。Android／iOS 真机触控、浏览器后台切页、存储配额、音频以及线上 Pages 仍未验收；当前支持边界只到本地桌面浏览器流程。
