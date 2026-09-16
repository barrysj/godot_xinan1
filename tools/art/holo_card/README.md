# RuiC 离线适配器

upstream 下 build_card.py、export_web.py、validate_assets.py、LICENSE 原样取自 https://github.com/HRuiCcc/RuiC-card-skill ，固定提交 ae25b5d02996eb5f5eb2540b91c26fe20f484d55。没有安装完整技能或下载执行其他依赖。

包装器调整卡比例、照片中性材质、输出尺寸、静态三视角，使用独立 BLENDER_USER_CONFIG。上游脚本未修改。许可见 upstream/LICENSE。

运行说明、差异和边界见 ../../../docs/art/holo-cards.md。GLB 不包含 Web 全息 shader，游戏不使用它。Blender 只在离线制作时需要。
