const sharp=require(process.env.SHARP_MODULE||'C:/Users/SongJun/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const path=require('path');
(async()=>{for(const s of ['default','focus','detail','complete']){
const overlay=await sharp(path.join(__dirname,'overlay-'+s+'.svg')).png().toBuffer();
await sharp(path.join(__dirname,'../003/background-study.png')).resize(1600,900).composite([{input:overlay}]).png().toFile(path.join(__dirname,'review-'+s+'.png'));
}})().catch(e=>{console.error(e);process.exit(1)});
