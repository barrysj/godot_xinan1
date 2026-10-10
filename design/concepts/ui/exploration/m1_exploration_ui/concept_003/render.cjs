const sharp = require(process.env.SHARP_MODULE || 'C:/Users/SongJun/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const path = require('path');
(async () => {
 for (const state of ['default','detail']) {
  const overlay = await sharp(path.join(__dirname,'overlay-'+state+'.svg')).png().toBuffer();
  await sharp(path.join(__dirname,'background-study.png')).resize(1600,900,{fit:'cover'}).composite([{input:overlay}]).png().toFile(path.join(__dirname,'review-'+state+'.png'));
 }
})().catch(e=>{console.error(e);process.exit(1);});
