"""Explicit temporary catalog registration for reviewed library enemy candidates."""
from pathlib import Path
import argparse
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from asset_manager.catalog import AssetCatalog, parse_simple_yaml
from animation.motion_previews import write_yaml
from animation.enemy_cast.build_library_enemies import CONFIG, PROJECT, ROOT

def register(version):
    for name,config in CONFIG.items():
        folder=ROOT/name/version
        path=PROJECT/'assets/art/manifests/enemy'/ (config['id']+'.yaml')
        manifest=parse_simple_yaml(path)
        relative=folder.relative_to(PROJECT).as_posix()
        files={p.relative_to(folder).as_posix().replace('/','_').replace('.','_'):p.relative_to(folder).as_posix()
               for p in folder.rglob('*') if p.is_file() and not p.name.endswith(('.import','.uid')) and not p.relative_to(folder).as_posix().startswith('review/')}
        files['frame_metadata']='battle_animation.frames.json'
        # Keep an existing export mapping when only regenerating the rig.
        previous=manifest.get('variants',{}).get(version,{})
        previews=previous.get('previews',{})
        previews['godot']={'unit':'res://'+relative+'/preview_unit.tres','animation':'res://'+relative+'/battle_animation.tres'}
        manifest['variants'][version]={'stage':'asset','version':version[-3:],'selection':'unselected','approval':'pending',
            'root':relative,'files':{**previous.get('files',{}),**files},'resource':relative+'/battle_animation.tres',
            'animation':{'frames':'frame_metadata','scene':relative+'/presentation.tscn','library':relative+'/animations.tres'},
            'previews':previews,'metadata':{'method':'rigid_parts_and_authored_pose_frames','attack_modes':[config['mode']],
            'usage':['asset_review','motion_preview'],'temporary_registration':True,'review_note':'临时预览登记；未确认留存、未批准或接入正式玩家流程。'}}
        write_yaml(path,manifest)
    scan=AssetCatalog(PROJECT).scan()
    print('ENEMY_PREVIEW_REGISTER',scan.get('summary',{}),'errors=',scan.get('errors',[]))
    if scan.get('errors'): raise SystemExit(1)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--version',default='tmp_003');register(parser.parse_args().version)
