# 守护者战斗图集生成记录

来源：内置 image_gen，2026-09-13；独立生成，不是旧占位图的变形。

角色与动作的接入由本轮用户明确授权。视觉 QA 状态保留 review，不冒充负责人批准。

原始 PNG 保留真实 Alpha；AtlasTexture 裁切、统一画布及脚底偏移见 battle_sheet.frames.json。像素未由导入脚本重绘或抠图。

## 原始提示词

> Create a production-oriented 2D GAME SPRITE SHEET for ONE character. 4 columns by 4 rows = EXACTLY 16 separate full-body poses in a perfectly regular grid. Square PNG canvas, genuine transparent alpha background. NO checkerboard pixels, no labels, no text, no grid lines, no shadows, no scenery. All 16 cells are equal squares, each character entirely within its own cell with generous transparent margins and consistent scale. Character foot-contact baseline is at 88% down each cell; horizontal body pivot at 50% of each cell. No pose crosses cell boundaries.
> Character: the Guardian, a young adult male science-campus student, SHORT DARK NAVY HAIR, white athletic campus jacket with navy shoulders and cyan cuff piping, navy trousers, white/cyan sneakers, small cyan smartwatch and student ID. NO armor, NO fantasy knight, NO cape. Precisely FOUR HEADS TALL (full standing height equals four crown-to-chin head lengths), youthful but NOT toddler/baby chibi, natural readable arms and legs. Clean 2D cel-shaded animation drawing, defined navy outlines, consistent single soft top-left light, limited clean palette. Identity and clothing identical in every cell. Side-facing 3/4 game view, ALWAYS facing screen RIGHT. A normal contemporary campus student defending teammates.
> Reading order left-to-right, top-to-bottom:
> ROW 1: (1) neutral ready standing with fists relaxed; (2) soft breathing ready stance slightly lowered shoulders; (3) running stride left foot forward right arm forward; (4) running opposite stride right foot forward left arm forward.
> ROW 2: (5) close-range attack anticipation, twist shoulders and draw right fist back; (6) quick forward straight punch with right arm fully extended and front knee bent; (7) punch follow-through, torso leaning forward and arm beginning to recoil; (8) return from punch, hands recovering to guard.
> ROW 3: (9) skill preparation crouch, raise left wrist and right hand toward smartwatch; (10) protective skill cast: stand firm and extend open left palm toward screen right, wrist cyan indicator bright but no external effect; (11) hurt recoil with torso leaning back and arms recoiling; (12) hurt recovery regaining balance.
> ROW 4: (13) exhausted critical standing, bent knees and lowered head; (14) collapse begins, one knee on floor and one hand reaching down; (15) collapse continues leaning sideways, head visibly lower; (16) fully fallen on side on the ground, recognizable clothes and hairstyle, within own cell. For fallen poses keep ground level at 88% of cell.
> Priority: anatomically complete distinct action poses, exact 4x4 grid, perfectly consistent character identity, compact four-head proportions, ACTUAL transparent pixels outside characters. This is to be sliced directly into a Godot SpriteFrames animation, not a concept poster.

