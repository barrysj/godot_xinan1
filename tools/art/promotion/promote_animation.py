"""Deterministically promote an approved Manifest candidate's allowlisted runtime package."""
import argparse
import json
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from asset_manager.catalog import parse_simple_yaml
from animation.motion_previews import inside, write_yaml, ROOT, ACTIONS

CORE = {'presentation.tscn', 'animations.tres', 'battle_animation.tres',
        'battle_animation.frames.json', 'rig_manifest.json'}
SHARED = 'res://scenes/battle_demo/presentations/hybrid_presentation.gd'
REFERENCES = re.compile(r'path="(res://[^"]+)"')


def production_extras(destination, names):
    return [p.relative_to(destination).as_posix() for p in destination.rglob('*')
            if p.is_file() and p.relative_to(destination).as_posix() not in names
            and not (p.name.endswith('.png.import') and p.relative_to(destination).as_posix()[:-7] in names)]


def validate_external(path, root, visited):
    path = inside(path, root)
    if path in visited:
        return
    visited.add(path)
    if not path.is_file():
        raise ValueError('Missing dependency: ' + str(path))
    if path.suffix not in ('.tres', '.tscn'):
        return
    text = path.read_text(encoding='utf-8-sig')
    for reference in REFERENCES.findall(text):
        if 'design/concepts/' in reference:
            raise ValueError('External runtime dependency points into candidates: ' + reference)
        validate_external(root / reference[6:], root, visited)


def runtime_name(name):
    path = Path(name)
    if path.is_absolute() or '..' in path.parts or '\\' in name:
        raise ValueError('Runtime path escapes package: ' + name)
    return name in CORE or (path.suffix == '.png' and
                           (len(path.parts) == 1 or (len(path.parts) == 2 and path.parts[0] == 'parts')))


def plan(object_id, variant_id=None, root=ROOT):
    index = parse_simple_yaml(root / 'assets/art/asset_manifest.yaml')
    manifest_path = inside(root / 'assets/art' / index['objects'][object_id], root / 'assets/art/manifests')
    manifest = parse_simple_yaml(manifest_path)
    integration = manifest['integration']
    key = variant_id or integration['active_variant']
    variant = manifest['variants'][key]
    if variant.get('approval') != 'approved' or variant.get('selection') != 'selected':
        raise ValueError('Promotion requires an explicitly approved and selected candidate')
    candidate = inside(root / variant['root'], root / 'design/concepts')
    destination = inside(root / integration['root'], root / 'assets/art')
    if any(re.fullmatch(r'\d+|review', part) for part in destination.relative_to(root / 'assets/art').parts):
        raise ValueError('Production path must be stable and unversioned')
    rig = json.loads((candidate / 'rig_manifest.json').read_text(encoding='utf-8'))
    names = rig['runtime_files']
    if len(names) != len(set(names)) or not CORE.issubset(names) or not all(runtime_name(n) for n in names):
        raise ValueError('Invalid runtime allowlist')
    extras = production_extras(destination, names)
    if extras:
        raise ValueError('Remove non-runtime files before promotion: ' + ', '.join(extras))
    metadata = json.loads((candidate / 'battle_animation.frames.json').read_text(encoding='utf-8'))
    frame_actions = set(metadata['clips'])
    skeleton_actions = set(rig['skeleton_actions'])
    if frame_actions != set(rig['frame_actions']) or not skeleton_actions.issubset(frame_actions):
        raise ValueError('Metadata action sets disagree')
    if not frame_actions.issubset(ACTIONS) or not {'idle', 'death'}.issubset(frame_actions):
        raise ValueError('Invalid canonical action contract')
    library = (candidate / 'animations.tres').read_text(encoding='utf-8')
    budget = rig.get('animation_budget', {})
    key_count = sum(len(values.split(',')) for values in
                    re.findall(r'"times": PackedFloat32Array\(([^)]*)\)', library) if values.strip())
    if budget and (len(library.encode('utf-8')) > budget['max_bytes'] or key_count > budget['max_keys']):
        raise ValueError('Animation resource exceeds registered byte/key budget')
    lengths = [float(value) for value in re.findall(r'^length = ([\d.eE+-]+)', library, re.M)]
    if budget and any(value > budget['max_cycle_seconds'] for value in lengths):
        raise ValueError('Animation resource exceeds registered duration budget')
    library_actions = {name for name in re.findall(r'^&"([^"]+)": SubResource', library, re.M)
                       if name != 'RESET' and not name.startswith('_cycle_')}
    if library_actions != skeleton_actions:
        raise ValueError('AnimationLibrary action set disagrees with rig manifest')
    battle = (candidate / 'battle_animation.tres').read_text(encoding='utf-8')
    if set(re.findall(r'"name": &"([^"]+)"', battle)) != frame_actions:
        raise ValueError('SpriteFrames actions disagree with metadata')
    for action in ('melee', 'ranged'):
        if (action in frame_actions) != (action in rig['attack_modes']):
            raise ValueError('Attack capabilities disagree with actions')
    old_prefix = 'res://' + candidate.relative_to(root).as_posix() + '/'
    new_prefix = 'res://' + destination.relative_to(root).as_posix() + '/'
    payload = {}
    for name in sorted(names):
        source = inside(candidate / name, candidate)
        if not source.is_file():
            raise ValueError('Missing allowlisted file: ' + name)
        data = source.read_bytes()
        if source.suffix in ('.tres', '.tscn', '.json'):
            text = data.decode('utf-8-sig').replace(old_prefix, new_prefix)
            # Resource UIDs are checkout caches; paths are portable and authoritative.
            text = re.sub(r' uid="uid://[^"]+"', '', text)
            if 'design/concepts/' in text:
                raise ValueError('Runtime package contains candidate dependency: ' + name)
            for reference in REFERENCES.findall(text):
                target = inside(root / reference[6:], root)
                if reference.startswith(new_prefix):
                    if reference[len(new_prefix):] not in names:
                        raise ValueError('Dependency is absent from allowlist: ' + reference)
                elif not target.is_file():
                    raise ValueError('External dependency missing: ' + reference)
                elif reference.endswith('.gd') and name == 'presentation.tscn' and reference != SHARED:
                    extension = rig.get('extension') or {}
                    if extension.get('script') != reference or not extension.get('reason'):
                        raise ValueError('Unregistered special presentation extension')
                    if 'presentation_extension = ' not in battle or 'extension_reason = ' not in battle:
                        raise ValueError('Extension must also be declared by BattleAnimationSet')
                if not reference.startswith(new_prefix):
                    validate_external(target, root, set())
            data = text.replace('\r\n', '\n').encode('utf-8')
        payload[name] = data
    # Resolve all owner rewrites before any mutation.
    owners = integration.get('owners', [integration['owner']] if 'owner' in integration else [])
    if not owners:
        raise ValueError('No registered runtime owner')
    old_resource = 'res://' + integration['resource']
    new_resource = new_prefix + 'battle_animation.tres'
    owner_updates = {}
    for owner in owners:
        path = inside(root / owner, root / 'resources')
        text = path.read_text(encoding='utf-8-sig')
        if old_resource not in text:
            raise ValueError('Registered owner does not reference the active resource')
        owner_updates[path] = text.replace(old_resource, new_resource).replace('\r\n', '\n').encode('utf-8')
    return manifest_path, manifest, variant, integration, destination, payload, owner_updates


def promote(object_id, variant_id=None, check=False, root=ROOT):
    path, manifest, variant, integration, destination, payload, owners = plan(object_id, variant_id, root)
    if check:
        for name, data in payload.items():
            target = inside(destination / name, destination)
            if not target.is_file() or target.read_bytes() != data:
                raise ValueError('Production differs from deterministic promotion: ' + name)
        for owner, data in owners.items():
            if owner.read_bytes() != data:
                raise ValueError('Owner needs promotion: ' + str(owner))
        extras = production_extras(destination, set(payload))
        if extras:
            raise ValueError('Non-runtime files in production: ' + ', '.join(extras))
        print('ANIMATION_PROMOTION_CHECK PASS files={}'.format(len(payload)))
        return
    destination.mkdir(parents=True, exist_ok=True)
    # Payload and owner writes are deterministic; review/provenance are never copied.
    for name, data in payload.items():
        target = inside(destination / name, destination)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    for owner, data in owners.items():
        owner.write_bytes(data)
    runtime_keys = {name: key for key, name in variant['files'].items() if name in payload}
    for name in sorted(payload):
        runtime_keys.setdefault(name, 'battle_animation' if name == 'battle_animation.tres' else Path(name).stem)
    integration['files'] = {runtime_keys[name]: name for name in sorted(payload)}
    integration['resource'] = (destination / 'battle_animation.tres').relative_to(root).as_posix()
    write_yaml(path, manifest)
    print('ANIMATION_PROMOTION files={} destination={}'.format(len(payload), destination.relative_to(root)))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('object')
    parser.add_argument('--variant')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    promote(args.object, args.variant, args.check)


if __name__ == '__main__':
    main()
