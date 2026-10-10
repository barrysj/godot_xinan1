from pathlib import Path
import json
d=Path(__file__).resolve().parent
(d/'frames').mkdir(parents=True,exist_ok=True)
items=[]
def svg(name,w,h,body,usage,margins=None):
    content=f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n'
    (d/'frames'/f'{name}.svg').write_text(content,encoding='utf-8')
    items.append(dict(id=name,path=f'frames/{name}.svg',size=[w,h],usage=usage,nine_slice=margins,filter='linear',mipmaps=False,pivot='top_left',text_baked=False))
def panel(name,w,h,cut,usage,margins):
    pts=f'{cut},1 {w-1},1 {w-1},{h-cut} {w-cut},{h-1} 1,{h-1} 1,{cut}'
    svg(name,w,h,f'<defs><linearGradient id="ink" x2="0.9" y2="1"><stop stop-color="#1D2D3B"/><stop offset="1" stop-color="#11151C"/></linearGradient></defs><polygon points="{pts}" fill="url(#ink)" stroke="#476371" stroke-width="1"/><path d="M{cut+2} 3H{w-4}" stroke="#85B4C6" stroke-opacity="0.22"/><path d="M2 {cut+2}V{h-4}" stroke="#11151C" stroke-width="2"/>',usage,margins)
panel('stock_frame',174,52,7,'team_stock',[10,8,10,8])
panel('counter_frame',96,26,5,'personal_code_progress',[7,7,7,7])
panel('absorb_frame',174,52,7,'team_shield_absorption',[10,8,10,8])
panel('intent_plate',32,32,5,'enemy_intent',[7,7,7,7])
panel('tooltip_frame',64,64,7,'skill_details',[10,10,10,10])
panel('shield_plate',44,18,4,'shield_amount',[6,6,6,6])
svg('intent_focus',32,32,'<path d="M6 1H31V26L26 31H1V6Z" fill="none" stroke="#F4F8FC" stroke-width="2"/>','hover_and_focus_overlay')
svg('stock_focus',174,52,'<path d="M7 1H173V45L167 51H1V7Z" fill="none" stroke="#F4F8FC" stroke-width="2"/>','gain_pulse_overlay',[10,8,10,8])
svg('bar_frame',104,14,'<path d="M4 1H103V10L100 13H1V4Z" fill="#11151C" stroke="#476371"/><path d="M4 3H101V9L99 11H3V4Z" fill="#293747"/>','hp_or_single_action_track',[5,5,5,5])
svg('bar_fill',98,8,'<defs><linearGradient id="fill" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#FFFFFF"/><stop offset="1" stop-color="#C7D8E5"/></linearGradient></defs><path d="M2 0H98V6L96 8H0V2Z" fill="url(#fill)"/><path d="M3 1H97" stroke="#FFFFFF" stroke-opacity="0.6"/>','modulate_and_clip_to_actual_ratio')
svg('action_tip',12,8,'<path d="M4 0H6L2 8H0ZM10 0H12L8 8H6Z" fill="#F4F8FC"/>','optional_action_release_edge')
svg('slot_empty',12,12,'<path d="M3 1H11V9L9 11H1V3Z" fill="#0D1623" stroke="#6B7F90"/>','empty_code_node')
svg('slot_filled',12,12,'<path d="M3 1H11V9L9 11H1V3Z" fill="#F4F8FC"/><path d="M3 2H10" stroke="#FFFFFF"/>','filled_code_node_modulate')
svg('code_tile',30,30,'<path d="M5 1H29V25L25 29H1V5Z" fill="#F4F8FC"/><path d="M6 2H28" stroke="#FFFFFF"/>','typed_code_icon_tile_modulate')
svg('tooltip_tail',10,18,'<path d="M9 1L1 9L9 17" fill="#172431" stroke="#476371"/><path d="M9 1V17" stroke="#172431" stroke-width="2"/>','optional_detached_detail_pointer')
(d/'frames.json').write_text(json.dumps(dict(version='asset_001',assets=items),ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Authored {len(items)} SVG frame assets')
