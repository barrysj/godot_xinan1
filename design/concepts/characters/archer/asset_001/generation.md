# Archer 001 generation

- Identity reference: `design/concepts/characters/archer/concept_006/m1_archer_short_sleeve_concept_006.png`.
- Tool: built-in imagegen; both outputs have genuine transparent alpha. `ranged-keypose.png` is an edit of `idle-master.png`.
- Candidate only. The source poses have not been approved as final game art.

## Idle master prompt

> Create a SINGLE standalone full-body 2D anime game character sprite on a genuinely transparent background. The supplied concept image is the identity and costume reference, especially its left full-body figure and central virtual pistol. Same young woman: dark high ponytail with tiny cyan X hair clip, gray-blue short-sleeve T-shirt, black cargo pants, white canvas sneakers, black small crossbody bag with gamepad charm, teal student ID lanyard. RIGHT-FACING THREE-QUARTER SIDE VIEW, both feet fully visible on one level baseline, stable relaxed combat idle, 5 to 6 head heights, clean crisp cel shading, compact readable silhouette. Exactly ONE futuristic cyan-and-white virtual pistol held in her RIGHT hand down by her hip, muzzle entirely within the canvas; LEFT hand relaxed and empty. Preserve identity, asymmetry, weapon hand and outfit palette. Neutral expression. Entire person including ponytail, shoes and gun inside generous empty margins. No duplicated character, no portrait, no inset panels, no text, no background, no shadow floor, no scenery, no extra hands, no extra weapons, no motion blur. This is a placeholder master for a reusable bone rig, so favor clear separation between head, torso and weapon.

## Ranged key pose prompt

> EDIT this exact transparent Archer game sprite into ONE right-facing ranged ATTACK KEY POSE, retaining the same person and game art style. Keep the dark high ponytail and cyan X clip, same facial features, gray-blue short sleeve shirt, teal ID, crossbody gamepad bag, dark cargo trousers and white sneakers. Keep the feet anchored to the same baseline and the same total body scale and frame center. RIGHT hand extends forward to the RIGHT at chest height and securely aims the same single complete cyan-white virtual pistol horizontally right; LEFT hand supports the right wrist, with no second weapon. Slight forward lean and focused expression. Full body, ponytail, both shoes, entire pistol muzzle within the transparent canvas with safe margins. Strict three-quarter side view facing right, fixed camera. Identity, asymmetry, weapon hand, and palette must remain consistent with the input. No muzzle flash, projectile, beam, motion blur, extra limbs, scene, floor, text, second person or duplicate pose. Clean sharp cel-shaded 2D game sprite.

The deterministic processing steps and placement data are in `build_placeholder_hybrid.py` and `battle_animation.frames.json`. The script adds a compact cyan muzzle flash to a copy of the key pose; this is a procedural placeholder, not an imagegen output.
