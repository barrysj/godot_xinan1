"""Deterministic, palette-backed scalable choice-page chrome. No raster text."""
from pathlib import Path
import json, argparse
ROOT=Path(__file__).resolve().parents[3]
def build(destination):
    destination=Path(destination)
    destination.mkdir(parents=True,exist_ok=True)
    colors=json.loads((ROOT/'data/visual/colors.json').read_text(encoding='utf-8'))
    d,n,b=colors['daily'],colors['night'],colors['brand']
    def svg(name,w,h,contents):
        (destination/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{contents}</svg>\n',encoding='utf-8',newline='\n')
    navy=n['surface']; cyan=d['accent_primary']; white=d['surface']; muted=d['text_secondary']
    svg('shell',1120,640,f'<path fill="{navy}" d="M0 0H412V640H0Z"/><path fill="{cyan}" d="M0 0H412V5H0Z"/><path fill="{navy}" d="M412 0H1120V5H412ZM412 637H1120V640H412Z"/><path fill="{b["magenta"]}" d="M1090 637H1120V640H1090Z"/><path stroke="{navy}" stroke-width="2" fill="none" d="M1 1H1119V639H1Z"/>')
    for name,fill,stroke,opacity in [('card',white,muted,'.28'),('card_active',d['surface_blue'],cyan,'1'),('card_disabled',d['background'],muted,'.20')]:
        svg(name,320,112,f'<path fill="{fill}" stroke="{stroke}" stroke-opacity="{opacity}" d="M1 1H305L319 15V111H15L1 97Z"/><path fill="{stroke if name=="card_disabled" else cyan}" fill-opacity="{opacity if name=="card_disabled" else "1"}" d="M1 14H4V84H1Z"/><path stroke="{stroke}" stroke-opacity="{opacity}" fill="none" d="M305 6L314 15"/>')
    for family in ['button','secondary']:
        for state in ['normal','hover','pressed','disabled','focus']:
            if family=='button':
                fill={'normal':cyan,'hover':b['cyan_bright'],'pressed':navy,'disabled':d['surface_blue'],'focus':'none'}[state]
            else:
                fill={'normal':white,'hover':navy,'pressed':navy,'disabled':d['surface_blue'],'focus':'none'}[state]
            stroke= b['magenta'] if state=='focus' else (muted if state=='disabled' else navy)
            opacity='.25' if state=='disabled' else '1'
            width='2.5' if state=='focus' else '1'
            svg(f'{family}_{state}',160,48,f'<path fill="{fill}" stroke="{stroke}" stroke-opacity="{opacity}" stroke-width="{width}" d="M2 2H147L158 13V46H13L2 35Z"/>'+(f'<path fill="{stroke}" d="M146 2H158V14Z"/>' if state=='focus' else ''))
    svg('illustration',160,160,f'<path fill="none" stroke="{cyan}" stroke-opacity=".6" d="M1 1H159V159H1Z"/><path stroke="{b["white"]}" stroke-width="2" fill="none" d="M2 18V2H18M142 158H158V142"/>')
    svg('arrow',12,12,f'<path fill="none" stroke="{b["white"]}" stroke-width="1.8" d="M1 6H10M6 2L10 6L6 10"/>')
    svg('status',16,16,f'<path fill="none" stroke="{cyan}" stroke-width="1.7" d="M3 8L7 12L13 4"/><path fill="none" stroke="{muted}" stroke-opacity=".45" d="M13 10V14H2V2H9"/>')
    (destination/'chrome.json').write_text(json.dumps({'schema_version':1,'palette_source':'data/visual/colors.json','native_sheet':[1120,640],'texture_filter':'linear','nine_patch':{'card':16,'button':12,'secondary':12,'illustration':20},'native_text':True,'generator':'tools/art/ui/build_choice_chrome.py'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('destination'); build(parser.parse_args().destination)
