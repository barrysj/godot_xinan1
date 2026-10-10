"""Assemble read-only pose review contact sheets; never alter source artwork."""
from PIL import Image, ImageDraw, ImageFont
from build_library_enemies import CONFIG, ROOT, POSES
import argparse
parser=argparse.ArgumentParser()
parser.add_argument('--version',default='asset_001')
version=parser.parse_args().version
stage_label='留存资产' if version.startswith('asset_') else '资产候选'
FONT='C:/Windows/Fonts/msyh.ttc'
labels=['待机','移动参考','蓄力','出手','收招','施法','濒危','失稳','退场']
font=ImageFont.truetype(FONT,23)
small=ImageFont.truetype(FONT,20)
for name,config in CONFIG.items():
    folder=ROOT/name/version
    board=Image.new('RGB',(1080,1160),'#e7e5de')
    d=ImageDraw.Draw(board);d.text((24,14),config['name']+' · '+version+' · '+stage_label,font=font,fill='#25344B')
    for index,pose in enumerate(POSES):
        image=Image.open(folder/'frames'/ (pose+'.png')).convert('RGBA');image.thumbnail((340,340))
        x=(index%3)*360+10;y=(index//3)*370+50
        board.paste(image,(x,y),image)
        d.text((x+130,y+334),labels[index],font=small,fill='#25344B')
    board.save(folder/'review/codex-workflow/poses.jpg',quality=92)
summary=Image.new('RGB',(1600,570),'#e7e5de');d=ImageDraw.Draw(summary)
for index,(name,config) in enumerate(CONFIG.items()):
    folder=ROOT/name/version;image=Image.open(folder/'frames/idle.png').convert('RGBA');image.thumbnail((310,390))
    summary.paste(image,(index*320+5,55),image)
    d.text((index*320+45,400),config['name'],font=font,fill='#25344B')
    d.text((index*320+45,440),'七动作 · '+stage_label,font=small,fill='#25344B')
target=ROOT/'review/codex-workflow'/('library-enemies-'+version.replace('_','-'));target.mkdir(parents=True,exist_ok=True)
summary.save(target/'lineup.jpg',quality=94)
print('ENEMY_REVIEW_SHEETS PASS 5 pose sheets + lineup')
