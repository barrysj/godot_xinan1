"""Build the reviewed library enemy poses into the existing hybrid resource contract.

Source artwork is never repainted. Polygon masks partition the idle into rigid
parts, and all pose normalization uses one isotropic scale per enemy.
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
import re
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PROJECT = Path(__file__).resolve().parents[4]
ROOT = PROJECT / 'design/concepts/enemy'
CANVAS, BASELINE, HEIGHT = 640, 560, 400
POSES = ['idle', 'stride', 'anticipation', 'impact', 'recover', 'cast', 'critical', 'fall', 'death']
CONFIG = {
    'keycap-brawler': {
        'id': 'keycap_brawler', 'name': '键帽拳灵', 'concept': 'concept_002', 'mode': 'melee',
        'personality': ['急躁', '好斗'], 'weapon': '双拳，每拳固定两枚键帽；无独立持握武器',
        'identity': 'Esc键帽头、双键拳面、两臂两腿、青色胸核、品红眼的机械拳灵',
        'palette': '#F6F8FA / #252B33 / #22E0F0 / #FF2BA6',
        'signature': '蓄力收拳，蹬地向前，双键拳面撞击后迅速回防',
        'attack': ['双拳警戒', '出拳臂后收、膝部下沉', '拳面向右前冲', '肘部回收', '恢复双拳警戒'],
        'cast': ['双拳警戒', '双拳并拢胸前', '压键释放胸核脉冲', '双拳分开', '回到警戒'],
        'bounds': [(15,10,405,430),(440,10,817,435),(830,20,1240,430),(5,440,455,842),(455,435,815,842),(850,442,1240,842),(15,872,402,1218),(438,890,809,1218),(795,1000,1239,1218)],
        'axes': [210,650,1060,195,650,1070,222,646,1030],
        'parts': {
            'Head': ([(150,24),(290,24),(305,142),(225,160),(151,145)],(219,154)),
            'NearLeg': ([(242,272),(287,278),(337,348),(359,399),(338,420),(272,416),(267,366),(232,319)],(246,283)),
            'FarLeg': ([(156,269),(212,273),(193,330),(157,384),(142,417),(50,420),(43,399),(106,350)],(185,283)),
        },
    },
    'projector': {
        'id': 'projector', 'name': '投影独眼灵', 'concept': 'concept_003', 'mode': 'ranged',
        'personality': ['警觉', '专注'], 'weapon': '一枚镜头与四块挡片；一套顶部支架；无手持武器',
        'identity': '无脚悬浮投影机、单青色镜头、四挡片、顶部折叠支架与品红线缆',
        'palette': '#F6F8FA / #252B33 / #22E0F0 / #E83E8C',
        'signature': '轻悬浮、挡片收拢聚焦，镜头释放时机身小幅后坐',
        'attack': ['悬浮值守', '四挡片收拢聚焦', '镜头出光、机身后坐', '挡片回收', '回到悬浮'],
        'cast': ['镜头平稳', '支架伸展、挡片准备', '聚焦强化投射', '降低光强', '回到悬浮'],
        'bounds': [(15,10,413,414),(466,46,846,422),(864,69,1222,414),(19,458,445,816),(463,455,839,822),(870,390,1244,844),(21,855,423,1232),(449,890,806,1226),(828,987,1237,1227)],
        'axes': [210,667,1053,233,655,1060,225,637,1039],
        'projectile': 'optical_pulse', 'launch': [27,-27],
        'parts': {
            'Bracket': ([(45,24),(339,24),(339,190),(290,218),(227,225),(125,227),(65,208)],(209,221)),
            'ShutterTop': ([(212,182),(330,177),(326,215),(278,249),(201,254)],(247,248)),
            'ShutterBottom': ([(246,324),(306,335),(351,374),(338,397),(279,386),(235,351)],(276,337)),
            'ShutterFront': ([(330,241),(396,270),(394,297),(353,292),(316,266)],(329,267)),
        },
    },
    'return-stamp': {
        'id': 'return_stamp', 'name': '归还印章怪', 'concept': 'concept_002', 'mode': 'melee',
        'personality': ['执拗', '刻板'], 'weapon': '刚性梨形木柄、四日期轮、双纸条、红色印底；无手持武器',
        'identity': '木柄品红眼、黄铜四日期轮、两张纸条臂与矩形红印底的印章怪',
        'palette': '#9B542B / #B58A40 / #F6F8FA / #B8203C / #FF2BA6',
        'signature': '木柄沿伸缩套直上直下，印底平行落地，回弹利落',
        'attack': ['印底平稳', '木柄沿套筒下压', '垂直盖印接触', '印底抬起回弹', '柄回原位'],
        'cast': ['四日期轮静止', '柄抬升、双纸条展开', '印记脉冲释放', '紙条回收', '回到值守'],
        'bounds': [(35,8,402,454),(425,24,809,451),(837,102,1238,455),(32,550,414,869),(438,459,808,860),(840,440,1244,859),(36,872,407,1240),(428,915,824,1240),(831,947,1244,1238)],
        'axes': [225,641,1048,232,641,1048,213,626,1038],
        'parts': {
            'Handle': ([(148,23),(315,23),(318,180),(281,210),(275,226),(176,226),(167,179)],(225,226)),
            'ReceiptLeft': ([(41,241),(150,227),(166,258),(145,299),(100,355),(61,369),(33,332)],(151,257)),
            'ReceiptRight': ([(287,258),(319,275),(385,324),(392,371),(347,370),(309,322)],(298,274)),
        },
    },
    'great-volume-boss': {
        'id': 'great_volume_boss', 'name': '馆藏巨典', 'concept': 'concept_004', 'mode': 'melee',
        'personality': ['沉重', '顽固'], 'weapon': '一册厚书、两条红书签；开书发射纸飞机；无手持武器',
        'identity': '无脚悬浮深蓝黄铜厚书、品红双眼、两条红书签、左右展开的巨典',
        'palette': '#25344B / #B58A40 / #FFF9EE / #B8203C / #FF2BA6',
        'signature': '沉重抬升后下砸，书签延迟回摆，开页释放纸飞机',
        'attack': ['闭书悬浮', '整书抬升、重心后压', '书角向前下砸', '书体回弹', '恢复闭书悬浮'],
        'cast': ['闭书值守', '封面从书缝展开', '左右两页展开释放纸飞机', '书页回拢', '回到闭书'],
        'bounds': [(5,51,372,397),(394,49,818,410),(822,42,1233,403),(28,450,422,810),(398,449,757,793),(775,466,1244,770),(22,852,392,1169),(408,891,800,1188),(783,969,1244,1175)],
        'axes': [243,666,1080,257,653,1040,242,622,1040],
        'parts': {}, 'projectile': 'paper_airplane', 'height': 360,
    },
    'cyber-librarian': {
        'id': 'cyber_librarian', 'name': '图书管理员', 'concept': 'concept_003', 'mode': 'ranged',
        'personality': ['沉稳', '古板'], 'weapon': '非类人机身、双书挡翼、两侧馆藏、一个归还口；无手持武器',
        'identity': '无脚悬浮奶白深蓝胶囊机身、黑屏双青眼、双书挡翼的图书馆Boss',
        'palette': '#F6F8FA / #25344B / #B58A40 / #22E0F0',
        'signature': '平稳值守，两翼按秩序展开，归架书群集中指向目标',
        'attack': ['平稳值守', '书翼回摆、归还口蓄光', '书翼展开、归架发射', '书翼收拢', '回到值守'],
        'cast': ['书翼静止', '双翼分开定场', '肃静区域释放', '书翼收回', '回到值守'],
        'bounds': [(23,9,382,425),(424,18,809,423),(837,23,1229,426),(18,429,425,830),(441,427,807,835),(817,418,1244,832),(17,842,419,1220),(434,848,812,1224),(807,936,1244,1216)],
        'axes': [232,650,1044,225,643,1048,223,637,1039],
        'parts': {
            'WingLeft': ([(40,118),(102,110),(107,318),(83,356),(37,335)],(109,227)),
            'WingRight': ([(303,116),(370,106),(372,337),(318,354),(304,302)],(300,227)),
        }, 'projectile': 'library_book', 'launch': [0,-22],
    },
}


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def isolate_primary(cell):
    """Retain the primary connected sprite, excluding adjacent atlas fragments.

    Run-length components keep the original pixels and antialiased edge. This
    is sprite extraction, not painting or per-pose color/shape correction.
    """
    pixels=np.asarray(cell).copy(); mask=pixels[:,:,3]>32
    parents=[]; counts=[]; runs=[]; previous=[]
    def find(i):
        while parents[i]!=i:
            parents[i]=parents[parents[i]]; i=parents[i]
        return i
    for y,row in enumerate(mask):
        changes=np.flatnonzero(np.diff(np.r_[False,row,False].astype(np.int8)))
        current=[]
        for start,end in zip(changes[::2],changes[1::2]):
            index=len(parents);parents.append(index);counts.append(int(end-start))
            for a,b,j in previous:
                if a<=end and b>=start:
                    p,q=find(index),find(j)
                    if p!=q: parents[q]=p;counts[p]+=counts[q]
            current.append((int(start),int(end),index));runs.append((y,int(start),int(end),index))
        previous=current
    if not parents: raise ValueError('No visible sprite')
    largest=max((i for i in range(len(parents)) if find(i)==i),key=lambda i:counts[i])
    retained=np.zeros_like(mask)
    for y,start,end,index in runs:
        if find(index)==largest: retained[y,start:end]=True
    # Retain a two-pixel AA envelope from the actual source, not invented pixels.
    envelope=Image.fromarray(retained.astype('uint8')*255).filter(ImageFilter.MaxFilter(5))
    keep=np.asarray(envelope)>0
    removed=int(np.count_nonzero((pixels[:,:,3]>32)&~keep))
    pixels[~keep]=0
    return Image.fromarray(pixels), removed


def pose_source(folder):
    corrected = folder/'source/poses-four-wheels.png'
    return corrected if corrected.exists() else folder/'source/poses.png'


def normalize_poses(folder, config):
    source = Image.open(pose_source(folder)).convert('RGBA')
    if source.getchannel('A').getextrema() != (0, 255):
        raise ValueError('Source must contain real transparent and opaque pixels')
    # Crop bounds are authored against the 1280px review display, never inferred
    # from an ideal grid: generated sprites can extend beyond nominal cells.
    ratio = source.width / 1280
    bounds = [tuple(round(v * ratio) for v in box) for box in config['bounds']]
    bounds = [(max(0,l-28),max(0,t-28),min(source.width,r+28),min(source.height,b+28)) for l,t,r,b in bounds]
    idle, _ = isolate_primary(source.crop(bounds[0]))
    idle_box = Image.fromarray((np.asarray(idle.getchannel('A')) > 100).astype('uint8') * 255).getbbox()
    scale = config.get('height', HEIGHT) / (idle_box[3] - idle_box[1])
    frames, records = {}, {}
    for index, pose in enumerate(POSES):
        box = bounds[index]
        cell, removed = isolate_primary(source.crop(box))
        visible = Image.fromarray((np.asarray(cell.getchannel('A')) > 100).astype('uint8') * 255).getbbox()
        if not visible:
            raise ValueError('Empty pose: ' + pose)
        axis = config['axes'][index] * ratio - box[0]
        resized = cell.resize((round(cell.width * scale), round(cell.height * scale)), Image.Resampling.LANCZOS)
        left, top = round(CANVAS / 2 - axis * scale), round(BASELINE - visible[3] * scale)
        result = Image.new('RGBA', (CANVAS, CANVAS))
        result.alpha_composite(resized, (left, top))
        final_box = Image.fromarray((np.asarray(result.getchannel('A')) > 100).astype('uint8') * 255).getbbox()
        if not final_box or min(final_box[:2]) < 6 or max(final_box[2:]) > CANVAS - 6:
            raise ValueError('Pose clipped; enlarge common canvas rather than squash: ' + pose)
        result.save(folder / 'frames' / (pose + '.png'))
        frames[pose] = result
        records[pose] = {'crop': box, 'source_bbox': visible, 'axis_x': axis, 'scale_xy': [scale, scale],
                         'placement': [left, top], 'visible_bbox': final_box,'adjacent_fragment_pixels_removed':removed}
    return frames, records, ratio


def revised_boss_poses(folder, frames, records):
    path = folder/'source/action-poses-clean.png'
    if not path.exists(): return
    source=Image.open(path).convert('RGBA')
    cells=[isolate_primary(source.crop((i*source.width//2,0,(i+1)*source.width//2,source.height)))[0] for i in range(2)]
    boxes=[Image.fromarray((np.asarray(c.getchannel('A'))>100).astype('uint8')*255).getbbox() for c in cells]
    scale=HEIGHT/max(b[3]-b[1] for b in boxes)
    for pose,cell,box,axis in zip(['impact','cast'],cells,boxes,[434,372]):
        resized=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.LANCZOS)
        placement=(round(CANVAS/2-axis*scale),round(BASELINE-box[3]*scale))
        result=Image.new('RGBA',(CANVAS,CANVAS));result.alpha_composite(resized,placement)
        visible=Image.fromarray((np.asarray(result.getchannel('A'))>100).astype('uint8')*255).getbbox()
        if not visible or min(visible[:2])<6 or max(visible[2:])>CANVAS-6:
            raise ValueError('Revised boss pose clipped: '+pose)
        result.save(folder/'frames'/ (pose+'.png'));frames[pose]=result
        records[pose]={'source':'source/action-poses-clean.png','scale_xy':[scale,scale],'placement':placement,'axis_x':axis}


def revised_stamp_poses(folder, frames, records):
    fall_source=folder/'source/poses-death-wheel-attempt.png'
    death_source=folder/'source/death-four-wheels.png'
    if not fall_source.exists() or not death_source.exists(): return
    source=Image.open(fall_source).convert('RGBA')
    ratio=source.width/Image.open(pose_source(folder)).width
    record=records['fall']
    crop=tuple(round(v*ratio) for v in record['crop'])
    cell=isolate_primary(source.crop(crop))[0]
    scale=record['scale_xy'][0]/ratio
    resized=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.LANCZOS)
    result=Image.new('RGBA',(CANVAS,CANVAS));result.alpha_composite(resized,tuple(record['placement']))
    result.save(folder/'frames/fall.png');frames['fall']=result
    records['fall']={**record,'source':fall_source.relative_to(folder).as_posix()}
    cell=isolate_primary(Image.open(death_source).convert('RGBA'))[0]
    box=Image.fromarray((np.asarray(cell.getchannel('A'))>100).astype('uint8')*255).getbbox()
    old=Image.fromarray((np.asarray(frames['death'].getchannel('A'))>100).astype('uint8')*255).getbbox()
    scale=(old[2]-old[0])/(box[2]-box[0])
    resized=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.LANCZOS)
    placement=(round(old[0]-box[0]*scale),round(BASELINE-box[3]*scale))
    result=Image.new('RGBA',(CANVAS,CANVAS));result.alpha_composite(resized,placement)
    result.save(folder/'frames/death.png');frames['death']=result
    records['death']={'source':death_source.relative_to(folder).as_posix(),'scale_xy':[scale,scale],
        'placement':placement,'alignment':'match existing complete silhouette width and ground anchor'}
    for pose in ['fall','death']:
        visible=Image.fromarray((np.asarray(frames[pose].getchannel('A'))>100).astype('uint8')*255).getbbox()
        if not visible or min(visible[:2])<6 or max(visible[2:])>CANVAS-6:
            raise ValueError('Revised stamp pose clipped: '+pose)


def partition(folder, idle, config, record, ratio):
    data = np.asarray(idle).copy()
    parts, pivots = {}, {}
    occupied = np.zeros((CANVAS, CANVAS), dtype=bool)
    def transform(point):
        return (round((point[0]*ratio-record['crop'][0])*record['scale_xy'][0]+record['placement'][0]),
                round((point[1]*ratio-record['crop'][1])*record['scale_xy'][1]+record['placement'][1]))
    for name, (polygon, pivot) in config['parts'].items():
        mask = Image.new('1', idle.size)
        ImageDraw.Draw(mask).polygon([transform(p) for p in polygon], fill=1)
        chosen = np.asarray(mask, dtype=bool) & ~occupied
        occupied |= chosen
        layer = np.zeros_like(data)
        layer[chosen] = data[chosen]
        parts[name] = Image.fromarray(layer)
        pivots[name] = transform(pivot)
    if config['id'] == 'great_volume_boss':
        red = (data[:,:,0].astype(int)>data[:,:,1].astype(int)*1.7) & (data[:,:,0]>75) & (data[:,:,0].astype(int)>data[:,:,2].astype(int)*1.25)
        xx, yy = np.meshgrid(np.arange(CANVAS), np.arange(CANVAS))
        for name, selection in [('RibbonBack', red & (xx < 190)), ('RibbonFront', red & (xx >= 190))]:
            layer = np.zeros_like(data); layer[selection] = data[selection]
            parts[name] = Image.fromarray(layer); occupied |= selection
            pivots[name] = (220, 248)
    core = np.zeros_like(data); core[~occupied] = data[~occupied]
    parts['Body'] = Image.fromarray(core)
    reconstructed = np.zeros_like(data)
    for name, part in parts.items():
        part.save(folder / 'parts' / (name + '.png'))
        reconstructed += np.asarray(part)
    if not np.array_equal(reconstructed, data):
        raise ValueError('Rigid parts do not exactly reconstruct idle')
    return parts, pivots


def godot_value(value):
    if isinstance(value, bool): return str(value).lower()
    if isinstance(value, (list, tuple)): return 'Vector2({}, {})'.format(*value)
    return str(value)


def track(index, path, times, values, discrete=False):
    if all(value==values[0] for value in values):
        times,values=[0],[values[0]]
    return '\n'.join([f'tracks/{index}/type = "value"', f'tracks/{index}/path = NodePath("{path}")',
        f'tracks/{index}/interp = 1', f'tracks/{index}/loop_wrap = true', f'tracks/{index}/keys = {{',
        '"times": PackedFloat32Array('+', '.join(map(str,times))+'),',
        '"transitions": PackedFloat32Array('+', '.join(['1']*len(times))+'),',
        '"update": '+('1' if discrete else '0')+',',
        '"values": ['+', '.join(godot_value(v) for v in values)+']', '}'])


def write_rig(folder, config, pivots, revised=False):
    base = 'res://' + folder.relative_to(PROJECT).as_posix()
    root = 'Rig/Skeleton2D/RootBone'
    scene = ['[gd_scene format=3]', '[ext_resource type="Script" path="res://scenes/battle_demo/presentations/hybrid_presentation.gd" id="script"]',
             f'[ext_resource type="AnimationLibrary" path="{base}/animations.tres" id="library"]']
    for name in ['Body'] + list(pivots):
        scene.append(f'[ext_resource type="Texture2D" path="{base}/parts/{name}.png" id="{name}"]')
    scene.append(f'[ext_resource type="Texture2D" path="{base}/frames/critical.png" id="critical_pose"]')
    volume=config['id']=='great_volume_boss'
    boss=config['id']=='cyber_librarian'
    pose_cast=revised and not volume
    if pose_cast: scene.append(f'[ext_resource type="Texture2D" path="{base}/frames/cast.png" id="cast_pose"]')
    if revised and boss:
        scene += [f'[ext_resource type="Texture2D" path="{base}/frames/impact.png" id="attack_pose"]',f'[ext_resource type="Texture2D" path="{base}/parts/projectile.png" id="book"]']
    if volume:
        scene += [f'[ext_resource type="Texture2D" path="{base}/frames/cast.png" id="cast_pose"]',
                  f'[ext_resource type="Texture2D" path="{base}/parts/projectile.png" id="plane"]']
    if revised:
        rgb='1, 0.16, 0.42' if config['id']=='return_stamp' else ('1, 0.82, 0.4' if volume else '0.13, 0.88, 0.94')
    scene += ['[node name="Presentation" type="Node2D"]', 'visible = false', 'script = ExtResource("script")',
              'canvas_size = Vector2(640, 640)', '[node name="Rig" type="Node2D" parent="."]',
              '[node name="Skeleton2D" type="Skeleton2D" parent="Rig"]',
              '[node name="RootBone" type="Bone2D" parent="Rig/Skeleton2D"]',
              'rest = Transform2D(1, 0, 0, 1, 0, 0)', 'auto_calculate_length_and_angle = false', 'length = 1.0', 'bone_angle = 0.0',
              '[node name="Body" type="Sprite2D" parent="'+root+'"]',
              'position = Vector2(0, -240)', 'texture = ExtResource("Body")']
    for name, (x,y) in pivots.items():
        px,py=x-CANVAS/2,y-BASELINE
        scene += [f'[node name="{name}Bone" type="Bone2D" parent="{root}"]',
                  f'position = Vector2({px}, {py})', f'rest = Transform2D(1, 0, 0, 1, {px}, {py})',
                  'auto_calculate_length_and_angle = false', 'length = 1.0', 'bone_angle = 0.0',
                  f'[node name="{name}" type="Sprite2D" parent="{root}/{name}Bone"]',
                  f'position = Vector2({-px}, {-240-py})', f'texture = ExtResource("{name}")']
    scene += [f'[node name="CriticalPose" type="Sprite2D" parent="{root}"]', 'visible = false',
              'position = Vector2(0, -240)', 'texture = ExtResource("critical_pose")']
    if pose_cast:
        scene += [f'[node name="CastPose" type="Sprite2D" parent="{root}"]','visible = false','position = Vector2(0, -240)','texture = ExtResource("cast_pose")']
    if revised and boss:
        scene += [f'[node name="AttackPose" type="Sprite2D" parent="{root}"]','visible = false','position = Vector2(0, -240)','texture = ExtResource("attack_pose")']
    if volume:
        scene += [f'[node name="OpenBook" type="Sprite2D" parent="{root}"]', 'visible = false',
                  'position = Vector2(0, -240)', 'texture = ExtResource("cast_pose")']
        for index in range(3):
            scene += [f'[node name="Plane{index}" type="Sprite2D" parent="Rig"]',
                      'visible = false',f'position = Vector2(110, {-190+index*26})',
                      'scale = Vector2(0.18, 0.18)','texture = ExtResource("plane")']
    if config['id'] in ['return_stamp','cyber_librarian']:
        scene += ['[node name="CastCue" type="Node2D" parent="Rig"]','modulate = Color(1, 1, 1, 0)']
        if config['id']=='return_stamp':
            for index,inset in enumerate([0,16]):
                scene += [f'[node name="Seal{index}" type="Line2D" parent="Rig/CastCue"]',
                          f'points = PackedVector2Array({-130+inset}, -18, {80-inset}, -32, {130-inset}, 16, {-80+inset}, 30, {-130+inset}, -18)',
                          'width = 4.0','default_color = Color(1, 0.18, 0.42, 0.9)']
        else:
            scene += ['position = Vector2(135, -115)' if revised else 'position = Vector2(160, -94)',
                      '[node name="SilenceBounds" type="Line2D" parent="Rig/CastCue"]',
                      'points = PackedVector2Array(-52, -40, 52, -40, 52, 40, -52, 40, -52, -40)',
                      'width = 3.0','default_color = Color(0.13, 0.88, 0.94, 0.8)']
            for index,x in enumerate([-20,20]):
                scene += [f'[node name="Grid{index}" type="Line2D" parent="Rig/CastCue"]',
                          f'points = PackedVector2Array({x}, -40, {x}, 40)','width = 1.5',
                          'default_color = Color(0.13, 0.88, 0.94, 0.45)']
            scene += ['[node name="MuteMark" type="Line2D" parent="Rig/CastCue"]',
                      'points = PackedVector2Array(-18, -8, -7, -8, 6, -20, 6, 20, -7, 8, -18, 8, -18, -8)',
                      'width = 3.0','default_color = Color(0.85, 1, 1, 0.95)',
                      '[node name="MuteSlash" type="Line2D" parent="Rig/CastCue"]',
                      'points = PackedVector2Array(14, -12, 30, 12)','width = 3.0',
                      'default_color = Color(0.85, 1, 1, 0.95)']
    if revised:
        center={'keycap_brawler':(0,-240),'projector':(100,-150),'return_stamp':(0,-25),'great_volume_boss':(0,-200),'cyber_librarian':(0,-230)}[config['id']]
        scene += ['[node name="CastLight" type="Node2D" parent="Rig"]','modulate = Color(1, 1, 1, 0)',
                  f'position = Vector2({center[0]}, {center[1]})',
                  ]
        points=[]
        for i in range(49):
            angle=math.tau*i/48;points += [round(math.cos(angle)*150,3),round(math.sin(angle)* (38 if config['id']=='return_stamp' else 105),3)]
        scene += ['[node name="Ring" type="Line2D" parent="Rig/CastLight"]',
                  'points = PackedVector2Array('+', '.join(map(str,points))+')','width = 9.0',f'default_color = Color({rgb}, 1)','antialiased = true',
                  '[node name="RingCore" type="Line2D" parent="Rig/CastLight"]',
                  'points = PackedVector2Array('+', '.join(map(str,points))+')','width = 2.5','default_color = Color(0.9, 1, 1, 0.9)','antialiased = true']
        for i in range(6):
            angle=math.tau*i/6
            scene += [f'[node name="Ray{i}" type="Line2D" parent="Rig/CastLight"]',
                      'points = PackedVector2Array('+', '.join(str(round(v,3)) for v in [math.cos(angle)*165,math.sin(angle)*110,math.cos(angle)*195,math.sin(angle)*135])+')',
                      'width = 5.0',f'default_color = Color({rgb}, 0.9)','antialiased = true']
        if boss:
            scene += ['[node name="AttackCue" type="Node2D" parent="Rig"]','modulate = Color(1, 1, 1, 0)',
                      '[node name="Beam" type="Line2D" parent="Rig/AttackCue"]','points = PackedVector2Array(15, -85, 315, -120)','width = 9.0','default_color = Color(0.13, 0.88, 0.94, 1)',
                      '[node name="BeamCore" type="Line2D" parent="Rig/AttackCue"]','points = PackedVector2Array(15, -85, 315, -120)','width = 2.5','default_color = Color(0.9, 1, 1, 1)']
            for i in range(3):
                scene += [f'[node name="Book{i}" type="Sprite2D" parent="Rig/AttackCue"]','texture = ExtResource("book")','scale = Vector2(0.32, 0.32)',f'position = Vector2({100+i*95}, {-75-i*22})']
    scene += ['[node name="AnimationPlayer" type="AnimationPlayer" parent="."]',
              'callback_mode_process = 2', 'libraries/ = ExtResource("library")']
    (folder/'presentation.tscn').write_text('\n'.join(scene)+'\n',encoding='utf-8')
    skeleton_actions = ['idle','move','hurt','critical']
    if config['id'] in ['return_stamp','great_volume_boss']:
        skeleton_actions.append('melee')
    if config['id'] == 'return_stamp': skeleton_actions.append('cast')
    if config['id'] == 'cyber_librarian': skeleton_actions += ['ranged','cast']
    if volume: skeleton_actions.append('cast')
    if revised and 'cast' not in skeleton_actions: skeleton_actions.append('cast')
    library=['[gd_resource type="AnimationLibrary" format=3]']
    actions=['RESET']+skeleton_actions
    for action in actions:
        length = {'RESET':0.01,'idle':1.6,'move':0.72,'hurt':0.5,'critical':1.8}.get(action,1.0)
        times=[0, length*.25, length*.45, length*.7, length]
        loop=action in ['idle','move','critical']
        library += [f'[sub_resource type="Animation" id="{action}"]',f'resource_name = "{action}"',f'length = {length}', 'loop_mode = 1' if loop else 'loop_mode = 0']
        pos = [(0,0),(0,-3),(0,-6),(0,-3),(0,0)]
        rot = [0,-.012,0,.012,0]
        if action=='RESET': pos=[(0,0)]*5; rot=[0]*5
        if action=='move': pos=[(0,0),(0,-8),(0,-3),(0,-8),(0,0)]; rot=[0,.04,.01,-.025,0]
        if action=='hurt': pos=[(0,0),(-9,2),(-15,4),(-6,1),(0,0)]; rot=[0,-.055,-.075,-.025,0]
        if action=='critical': pos=[(0,0),(-2,-1),(1,0),(-1,1),(0,0)]; rot=[0,-.012,.008,-.008,0]
        if action=='melee':
            if config['id']=='return_stamp': pos=[(0,0),(0,-45),(0,0),(0,-18),(0,0)]; rot=[0]*5
            else: pos=[(0,0),(-15,-65),(34,6),(14,-23),(0,0)]; rot=[0,-.14,.33,.11,0]
        if action=='ranged': pos=[(0,0),(-6,-4),(-12,0),(-4,-2),(0,0)]; rot=[0,-.025,-.04,-.012,0]
        if action=='cast': pos=[(0,0),(0,-10),(0,-16),(0,-7),(0,0)]; rot=[0]*5
        if revised and boss and action=='ranged': pos=[(0,0),(-20,-10),(12,-6),(3,-2),(0,0)];rot=[0,-.10,0,.035,0]
        if revised and boss and action=='cast': pos=[(0,0),(0,-24),(0,-38),(0,-18),(0,0)]
        library += [track(0,root+':position',times,pos),track(1,root+':rotation',times,rot)]
        for i,(name,(x,y)) in enumerate(pivots.items(),2):
            angles=[0,-.018,0,.018,0]
            if action in ['RESET','critical']: angles=[0]*5
            if action=='move':
                amplitude=.10 if 'Leg' in name else .04
                sign=-1 if name in ['NearLeg','WingRight','ReceiptRight','RibbonFront'] else 1
                angles=[0,amplitude*sign,0,-amplitude*sign,0]
            if action=='hurt': angles=[0,.02,.035,.015,0]
            if action in ['ranged','cast'] and 'Wing' in name:
                sign=-1 if name=='WingLeft' else 1
                angles=[0,.06*sign,.16*sign,.065*sign,0]
                if revised: angles=[0,.10*sign,.36*sign,.13*sign,0]
            if action=='melee' and 'Ribbon' in name: angles=[0,-.06,-.13,.08,0]
            if name=='Handle':
                px,py=x-CANVAS/2,y-BASELINE
                shifts=([0,18,28,10,0] if action=='melee' else [0,-10,-18,-8,0]) if action in ['melee','cast'] else [0]*5
                library.append(track(i,root+'/'+name+'Bone:position',times,[(px,py+s) for s in shifts]))
            else: library.append(track(i,root+'/'+name+'Bone:rotation',times,angles))
        index=2+len(pivots)
        library.append(track(index,root+'/CriticalPose:visible',[0],[action=='critical'],True));index+=1
        pose_times=[0,.20,.82,1.0]
        cast_open=[False,True,False,False] if action=='cast' and pose_cast else [False]*4
        attack_open=[False,True,False,False] if revised and boss and action=='ranged' else [False]*4
        if pose_cast:
            library.append(track(index,root+'/CastPose:visible',pose_times,cast_open,True));index+=1
        if revised and boss:
            library.append(track(index,root+'/AttackPose:visible',pose_times,attack_open,True));index+=1
        if not volume:
            for part in ['Body']+list(pivots):
                path=root+'/Body:visible' if part=='Body' else root+'/'+part+'Bone/'+part+':visible'
                visible=[action!='critical' and not c and not a for c,a in zip(cast_open,attack_open)]
                library.append(track(index,path,pose_times,visible,True));index+=1
        if config['id'] in ['return_stamp','cyber_librarian']:
            alpha=[0,0.12,0.95,0.38,0] if action=='cast' else [0]*5
            library.append(track(index,'Rig/CastCue:modulate',times,[f'Color(1, 1, 1, {a})' for a in alpha]));index+=1
            sizes=[(.4,.4),(.65,.65),(1,1),(1.12,1.12),(.4,.4)] if action=='cast' else [(1,1)]*5
            library.append(track(index,'Rig/CastCue:scale',times,sizes));index+=1
            if revised and boss:
                library.append(track(index,'Rig/CastCue:position',times,[(60,-85),(95,-105),(135,-115),(145,-115),(60,-85)] if action=='cast' else [(135,-115)]*5));index+=1
        if revised:
            alpha=[0,.32,1,.62,0] if action=='cast' else [0]*5
            library.append(track(index,'Rig/CastLight:modulate',times,[f'Color(1, 1, 1, {a})' for a in alpha]));index+=1
            library.append(track(index,'Rig/CastLight:scale',times,[(.45,.45),(.65,.65),(1,1),(1.12,1.12),(.45,.45)] if action=='cast' else [(1,1)]*5));index+=1
            if boss:
                alpha=[0,.1,1,.55,0] if action=='ranged' else [0]*5
                library.append(track(index,'Rig/AttackCue:modulate',times,[f'Color(1, 1, 1, {a})' for a in alpha]));index+=1
                for i in range(3):
                    library.append(track(index,f'Rig/AttackCue/Book{i}:position',times,[(15,-85),(25,-85),(100+i*95,-75-i*22),(150+i*95,-85-i*22),(15,-85)] if action=='ranged' else [(100+i*95,-75-i*22)]*5));index+=1
        if volume:
            pose_times=[0,.30,.78,1.0]
            opened=[False,True,False,False] if action=='cast' else [False]*4
            library.append(track(index,root+'/OpenBook:visible',pose_times,opened,True));index+=1
            for part in ['Body']+list(pivots):
                path=root+'/Body:visible' if part=='Body' else root+'/'+part+'Bone/'+part+':visible'
                library.append(track(index,path,pose_times,[not v and action!='critical' for v in opened],True));index+=1
            for plane in range(3):
                library.append(track(index,f'Rig/Plane{plane}:visible',[0,.45+plane*.02,.75+plane*.02,1],
                                     [False,True,False,False] if action=='cast' else [False]*4,True));index+=1
                y=-190+plane*26
                library.append(track(index,f'Rig/Plane{plane}:position',[0,.45+plane*.02,.75+plane*.02,1],
                                     [(110,y),(110,y),(225,y+15),(110,y)] if action=='cast' else [(110,y)]*4));index+=1
    library += ['[resource]','_data = {']+[f'&"{a}": SubResource("{a}")'+(',' if i<len(actions)-1 else '') for i,a in enumerate(actions)]+['}']
    (folder/'animations.tres').write_text('\n'.join(library)+'\n',encoding='utf-8')
    return skeleton_actions


def clips(config):
    return {
        'idle': (['idle'],True,8), 'move': (['idle','stride','idle','stride'],True,8),
        config['mode']: (['idle','anticipation','anticipation','impact','recover','idle'],False,12),
        'cast': (['idle','anticipation','cast','cast','recover','idle'],False,12),
        'hurt': (['idle','recover','idle'],False,12),
        'critical': (['critical'],True,8), 'death': (['critical','fall','death'],False,6),
    }


def write_frames(folder,config):
    base='res://'+folder.relative_to(PROJECT).as_posix()
    text=['[gd_resource type="Resource" format=3]',
          '[ext_resource type="Script" path="res://game/content/battle_animation_set.gd" id="script"]',
          f'[ext_resource type="PackedScene" path="{base}/presentation.tscn" id="scene"]',
          f'[ext_resource type="AnimationLibrary" path="{base}/animations.tres" id="library"]']
    text += [f'[ext_resource type="Texture2D" path="{base}/frames/{p}.png" id="{p}"]' for p in POSES]
    if config.get('projectile'):
        image=Image.open(folder/'source/projectile.png').convert('RGBA')
        # alpha bbox uses the drawn object, avoiding diffuse generated halos.
        bbox=Image.fromarray((np.asarray(image.getchannel('A'))>220).astype('uint8')*255).getbbox()
        crop=image.crop(bbox)
        crop.thumbnail((256,160),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(288,192)); canvas.alpha_composite(crop,((288-crop.width)//2,(192-crop.height)//2))
        canvas.save(folder/'parts/projectile.png')
        text += [f'[ext_resource type="Texture2D" path="{base}/parts/projectile.png" id="projectile_texture"]',
                 '[ext_resource type="Script" path="res://game/content/battle_projectile_style.gd" id="projectile_script"]',
                 '[sub_resource type="Resource" id="projectile"]','script = ExtResource("projectile_script")',
                 'texture = ExtResource("projectile_texture")','display_size = Vector2(28, 18)','trail_gap = 3.0']
    text += ['[sub_resource type="SpriteFrames" id="frames"]','animations = [']
    entries=[]
    for action,(poses,loop,fps) in clips(config).items():
        durations=([.9]*3+[1.1]*3) if action in [config['mode'],'cast'] else [1.0]*len(poses)
        entries.append('{"frames": ['+', '.join('{"duration": '+str(d)+', "texture": ExtResource("'+p+'")}' for p,d in zip(poses,durations))+'], "loop": '+str(loop).lower()+', "name": &"'+action+'", "speed": '+str(fps)+'}')
    text += [',\n'.join(entries),']','[resource]','script = ExtResource("script")','frames = SubResource("frames")',
             'presentation_scene = ExtResource("scene")','animation_library = ExtResource("library")',
             'display_size = Vector2(200, 200)' if config['id']=='cyber_librarian' else 'display_size = Vector2(160, 160)',
             'anchor = Vector2(0.5, 0.875)','impact_ratio = 0.45','flip_with_facing = true',
             'launch_offset = Vector2({}, {})'.format(*config.get('launch',[25,-42])),'hit_offset = Vector2(0, -38)']
    if config.get('projectile'): text.append('projectile_style = SubResource("projectile")')
    (folder/'battle_animation.tres').write_text('\n'.join(text)+'\n',encoding='utf-8')
    # Harness-only unit; uses a stock skill solely to exercise cast timing.
    unit=['[gd_resource type="Resource" format=3]', '[ext_resource type="Script" path="res://game/content/unit_def.gd" id="unit"]',
          '[ext_resource type="Resource" path="res://resources/content/skills/inventor.tres" id="skill"]',
          '[resource]','script = ExtResource("unit")',f'id = "{config["id"]}_art_preview"',f'display_name = "{config["name"]}"',
          'description = "动作评审样本，属性与技能不代表正式敌人规则。"','health = 400','attack = 24','interval = 1.5',
          'attack_range = 3.2' if config['mode']=='ranged' else 'attack_range = 1.45',
          'attack_modes = 2' if config['mode']=='ranged' else 'attack_modes = 1','skill = ExtResource("skill")']
    (folder/'preview_unit.tres').write_text('\n'.join(unit)+'\n',encoding='utf-8')


def write_cards(folder,config):
    locks={'identity_anchor':config['identity'],'asymmetry_lock':'保持概念板所示部件归属及镜头／书脊朝向，不交换部件；原生文字不作为左右识别点',
           'weapon_hand_lock':config['weapon'],'palette_lock':config['palette'],'direction_hint':{'E':'固定概念板的朝右三分之四视角；不生成背向'}}
    cards=[]
    descriptions={
        'idle':['常态姿势','重心微升','状态平稳','重心微落','回到首姿'],
        'move':['开始移动','重心抬升或步态迈出','推进中心','回摆或换步','返回循环首姿'],
        config['mode']:config['attack'], 'cast':config['cast'],
        'hurt':['维持原姿','短促后仰','承受冲击','重心回收','恢复原状态'],
        'critical':['保持濒危姿态','弱幅摇摆','光强低落','弱幅回摆','回到首姿'],
        'death':['濒危姿态','核心熄灭开始失稳','落地或坍下','惯性停稳','末姿冻结'],
    }
    if (folder/'source/revision.json').exists():
        light = {'keycap_brawler':'青色胸核脉冲', 'projector':'青色镜头聚光',
                 'return_stamp':'品红印底光环', 'great_volume_boss':'暖金书页光环',
                 'cyber_librarian':'青色双翼光环与肃静框'}[config['id']]
        descriptions['cast'] = list(descriptions['cast'])
        descriptions['cast'][1] += '，光效由弱转强'
        descriptions['cast'][2] += '，'+light+'在释放帧达到峰值'
        descriptions['cast'][3] += '，光环扩散后消退'
        if config['id']=='cyber_librarian':
            descriptions['ranged'] = ['平稳值守','机身后压、书翼回摆、归还口蓄光',
                '机身前倾、双翼明显展开、三本馆藏随青光向右发射',
                '书群离开、书翼收拢、枪口光消退','回到值守']
    for action in clips(config):
        module={'idle':'idle','move':'locomotion','cast':'skill','hurt':'hit','critical':'status','death':'death'}.get(action,'attack')
        poses=[{'frame':f,'height':h,'pose':p} for f,h,p in zip([1,4,8,12,16],['mid','low','high','mid','mid'],descriptions[action])]
        card={'action_id':action,'module':module,'priority':'P0','loop_policy':'loop' if action in ['idle','move','critical'] else ('one-shot-freeze-last' if action=='death' else 'one-shot'),
              'frame_count':16,'frame_rate':12,'canvas_size':[CANVAS,CANVAS],'view_angle':'side-2.5d','key_poses':poses,'consistency_locks':locks,
              'transitions':{'can_cancel_to':['death'] if action in [config['mode'],'cast'] else [],'interruptible':action not in [config['mode'],'cast','death'],'blend_time':0,'hit_frame':8 if action in [config['mode'],'cast'] else 0},
              'motion_trail':None,'prompt':'；'.join([locks[k] for k in ['identity_anchor','asymmetry_lock','weapon_hand_lock','palette_lock']])+ '；'+ '→'.join(descriptions[action])+'；固定朝右三分之四视角，干净赛博校园2D赛璐璐与透明背景。',
              'runtime_sampling':'16帧为关键姿势设计网格；骨骼连续插值，出手映射impact_ratio=0.45；远程第8帧表示释放而非抵达伤害'}
        cards.append({'action_card_v2':card})
    dump(folder/'action-cards.json',{'schema_version':2,'direction_scope':'E artwork; W engine facing','actions':cards})
    inputs={'character':{'name':config['name'],'identity':config['identity'],'personality':config['personality'],'body_type':'非人校园器物，比例沿用批准概念',
                        'weapon_main':config['weapon'],'combat_style':config['signature'],'faction_vibe':'校园异常敌人','asymmetry':locks['asymmetry_lock']},
            'game':{'genre':'SLG战棋','camera':'2.5D侧视','exaggeration':3},'tech':{'directions':['E'],'frames_per_dir':16,'frame_rate':12},
            'approved_reference_exception':'2026-10-07负责人允许已批准概念板替代三视图，单视角连续制作'}
    dump(folder/'action-input.json',inputs)
    markdown=['# '+config['name']+'动作设计清单','',
              '身份依据：'+config['concept']+'；单视角替代三视图经负责人2026-10-07确认。',
              '游戏：现有自动战斗，沿用战棋动作包。预算：七种动作，骨骼连续运动与序列帧混合。',
              '动作签名：'+config['signature'],'',
              '| 动作 | 循环 | 设计采样 | 出手点 | 后续衔接 |',
              '| --- | --- | --- | --- | --- |']
    for wrapper in cards:
        card=wrapper['action_card_v2'];action=card['action_id']
        markdown.append('| '+action+' | '+card['loop_policy']+' | 16 | '+('8（运行释放0.45）' if action in [config['mode'],'cast'] else '—')+' | '+('末姿冻结，恢复生命由原表现层重置' if action=='death' else '原表现层返回idle／move／critical')+' |')
    markdown += ['', '## 动作卡','']
    for wrapper in cards:
        markdown += ['### '+wrapper['action_card_v2']['action_id'],'','```json',json.dumps(wrapper,ensure_ascii=False,indent=2),'```','']
    markdown += ['## 下游与衔接','',
                '本轮仅朝右概念视角；朝左由已有引擎显示变换处理，未生产背面或八方向。',
                'F1/F4/F8/F12/F16用于约束动作节奏，连续骨骼不等于16张PNG。16→1闭环检查以实际Godot GIF为依据。',
                '攻击和施法由模拟动作锁定，受击不抢占；死亡打断，末帧停留；恢复生命回到现有静止状态。',
                '远程F8表示发射，命中由模拟弹道抵达时决定；没有另建战斗状态机。','']
    (folder/'action-design.md').write_text('\n'.join(markdown),encoding='utf-8')
    # Execute the skill's original validate(data) and constants without its
    # optional YAML file front-end: inputs are already structured JSON.
    source=Path('C:/Users/SongJun/.codex/skills/character-action-design/scripts/validate_input.py')
    parsed=ast.parse(source.read_text(encoding='utf-8-sig'))
    body=[n for n in parsed.body if isinstance(n,(ast.Assign,ast.FunctionDef)) and (not isinstance(n,ast.FunctionDef) or n.name in ['_norm','validate'])]
    namespace={'re':re}; exec(compile(ast.Module(body=body,type_ignores=[]),str(source),'exec'),namespace)
    ok,errors=namespace['validate'](inputs)
    if not ok: raise ValueError('Skill input validation: '+str(errors))
    for wrapper in cards:
        card=wrapper['action_card_v2']
        assert [p['frame'] for p in card['key_poses']]==[1,4,8,12,16]
        assert all(card['consistency_locks'][k] in card['prompt'] for k in ['identity_anchor','asymmetry_lock','weapon_hand_lock','palette_lock'])
    return {'skill_input_validator':'original validate(data) executed against JSON input','input_pass':True,'cards':7,'key_poses_per_card':5,'four_locks_in_prompt':True}


def build(name,version):
    config=CONFIG[name]; folder=ROOT/name/version
    for directory in ['frames','parts','review/codex-workflow']: (folder/directory).mkdir(parents=True,exist_ok=True)
    frames,records,ratio=normalize_poses(folder,config)
    revised=(folder/'source/revision.json').exists()
    revised_boss_poses(folder,frames,records)
    revised_stamp_poses(folder,frames,records)
    parts,pivots=partition(folder,frames['idle'],config,records['idle'],ratio)
    skeleton=write_rig(folder,config,pivots,revised); write_frames(folder,config); card_result=write_cards(folder,config)
    dump(folder/'battle_animation.frames.json',{'canvas':[CANVAS,CANVAS],'anchor':[.5,.875],'display_size':[200,200] if config['id']=='cyber_librarian' else [160,160],
            'impact_ratio':.45,'flip_with_facing':True,'clips':{a:{'poses':p,'loop':l,'fps':f} for a,(p,l,f) in clips(config).items()},
            'source_processing':records,'method':'rigid-part skeleton continuous loops/reactions; authored key poses for deformation and death',
            'frame_release_ratio':.45,'attack_frame_durations':[.9,.9,.9,1.1,1.1,1.1]})
    runtime=['battle_animation.tres','battle_animation.frames.json','rig_manifest.json','presentation.tscn','animations.tres']
    runtime += ['frames/'+p+'.png' for p in POSES]+['parts/'+p+'.png' for p in parts]
    if config.get('projectile'): runtime.append('parts/projectile.png')
    dump(folder/'rig_manifest.json',{'schema_version':2,'self_contained':True,'canvas':[CANVAS,CANVAS],'anchor':[320,BASELINE],
             'skeleton_actions':skeleton,'frame_actions':list(clips(config)),'attack_modes':[config['mode']],'extension':None,
             'parts':{p:{'file':'parts/'+p+'.png','pivot':pivots.get(p,[320,BASELINE])} for p in parts},
             'runtime_files':runtime,'playback_metadata_only':True,'animation_budget':{'max_bytes':65536,'max_keys':1200,'max_cycle_seconds':2}})
    visible={p:list(Image.fromarray((np.asarray(img.getchannel('A'))>100).astype('uint8')*255).getbbox()) for p,img in frames.items()}
    source_path=pose_source(folder)
    dump(folder/'review/codex-workflow/build-check.json',{'object':config['id'],'source_file':source_path.relative_to(folder).as_posix(),'source_size':list(Image.open(source_path).size),
             'true_alpha':True,'single_isotropic_scale':True,'idle_parts_exact_reconstruction':True,'pose_bboxes':visible,'skeleton_actions':skeleton,
             'frame_actions':list(clips(config)),'action_cards':card_result,'runtime_files':len(runtime),
             'source_sha256':hashlib.sha256(source_path.read_bytes()).hexdigest()})
    dump(folder/'build-config.json',config)
    print('ENEMY_BUILD PASS',config['id'],'actions=7','skeleton='+','.join(skeleton),'runtime_files='+str(len(runtime)))


if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--enemy',choices=list(CONFIG)+['all'],default='all'); parser.add_argument('--version',default='tmp_003')
    args=parser.parse_args()
    for name in CONFIG if args.enemy=='all' else [args.enemy]: build(name,args.version)
