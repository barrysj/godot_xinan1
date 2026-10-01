# Striker 001 generation

- Identity reference: `design/concepts/characters/striker/concept_006/m1_striker_hoodie_concept_006.png`.
- Tool: built-in imagegen. `idle-master.png` is the transparent master; `melee-keypose.png` is an image edit of that master.
- Candidate only; source art and animation need human review before promotion.

## Attack key pose prompt

> Edit the supplied transparent full-body 2D game sprite into ONE clear melee attack key pose for the SAME young woman. Keep exactly the same identity: short dark bob with magenta tips, small white-magenta hair clip, charcoal hoodie and backpack, student ID, black cargo pants, white sneakers, and EXACTLY TWO cyan-magenta holographic short daggers, one securely held in EACH hand. Right-facing three-quarter side view throughout, no front view. Lunge a modest step toward the RIGHT with left foot planted behind and right foot in front on the same baseline. RIGHT hand extends the complete right dagger forward in a decisive horizontal slash toward screen right; LEFT hand holds the complete second dagger close to her torso as a guard. Keep both complete blades, tips, handles, hands, both shoes, hair and entire body well inside the transparent canvas. Compact readable game sprite, crisp cel shading, same body size and character identity as input. Fixed camera, no background, no floor shadow, no scenery, no motion blur, no extra blades, no extra hands, no detached weapon, no blade merging, no giant light trail or projectile. Preserve weapon count, which hand holds each blade, dark clothing and cyan-magenta palette.

The source idle prompt followed the approved 006 concept with the same identity, full body, two separately held blades, right-facing three-quarter stance and transparent background. `build_placeholder_hybrid.py` records normalization in `battle_animation.frames.json` and adds a small procedural tip spark; it does not generate a third blade.
