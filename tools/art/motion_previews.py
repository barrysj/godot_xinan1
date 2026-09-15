"""Explicit preview production. The encoder only consumes a validated capture manifest."""
import argparse
import json
from pathlib import Path
import shutil
import uuid

from asset_manager.catalog import parse_simple_yaml

ROOT = Path(__file__).resolve().parents[2]
ACTIONS = ('idle', 'move', 'melee', 'ranged', 'cast', 'hurt', 'critical', 'death')


def inside(path, root):
    path, root = Path(path).resolve(), Path(root).resolve()
    if path == root or root not in path.parents:
        raise ValueError('Path must be below {}: {}'.format(root, path))
    return path


def write_yaml(path, data):
    # Same mapping/scalar-list subset as the catalog; JSON quoting preserves version strings.
    def lines(mapping, depth=0):
        result = []
        for key, value in mapping.items():
            prefix = ' ' * depth + str(key) + ':'
            if isinstance(value, dict) and value:
                result.append(prefix)
                result.extend(lines(value, depth + 2))
            elif isinstance(value, dict):
                result.append(prefix)
            else:
                result.append(prefix + ' ' + json.dumps(value, ensure_ascii=False))
        return result
    temporary = Path(str(path) + '.tmp')
    temporary.write_text('\n'.join(lines(data)) + '\n', encoding='utf-8')
    temporary.replace(path)


def prepare(animation, unit, action, root=ROOT):
    index = parse_simple_yaml(root / 'assets/art/asset_manifest.yaml')
    matches = []
    for relative in index['objects'].values():
        path = inside(root / 'assets/art' / relative, root / 'assets/art/manifests')
        manifest = parse_simple_yaml(path)
        for key, variant in manifest.get('variants', {}).items():
            if variant.get('stage') != 'asset' or 'animation' not in variant:
                continue
            preview = variant.get('previews', {}).get('godot', {})
            if animation:
                selected = variant.get('resource') == (animation[6:] if animation.startswith('res://') else animation)
            else:
                selected = (unit and preview.get('unit') == unit and
                            manifest.get('integration', {}).get('active_variant') == key)
            if selected:
                matches.append((path, manifest, key, variant, preview))
    if len(matches) != 1:
        raise ValueError('Export requires exactly one Manifest candidate. Specify -Animation or -Unit.')
    path, manifest, key, variant, preview = matches[0]
    candidate = inside(root / variant['root'], root / 'design/concepts')
    if not candidate.is_dir():
        raise ValueError('Candidate does not exist')
    review = inside(candidate / 'review', candidate)
    cache = inside(root / '.godot/motion-capture' / uuid.uuid4().hex, root / '.godot/motion-capture')
    cache.mkdir(parents=True)
    job = {'schema_version': 1, 'object': manifest['object']['id'], 'variant': key,
           'object_manifest': path.relative_to(root).as_posix(), 'candidate_root': variant['root'],
           'review_root': review.relative_to(root).as_posix(), 'cache': cache.relative_to(root).as_posix(),
           'unit': preview['unit'], 'animation': 'res://' + variant['resource'],
           'projectile': preview.get('projectile', ''), 'requested_action': action.lower(),
           'fps': 30, 'size': [352, 352], 'captures': []}
    output = cache / 'capture.json'
    output.write_text(json.dumps(job, ensure_ascii=False, indent=2), encoding='utf-8')
    return output


def encode(path, root=ROOT):
    from PIL import Image
    path = inside(path, root / '.godot/motion-capture')
    job = json.loads(path.read_text(encoding='utf-8'))
    cache = inside(root / job['cache'], root / '.godot/motion-capture')
    if path.parent != cache or job.get('schema_version') != 1:
        raise ValueError('Invalid capture manifest location/schema')
    object_path = inside(root / job['object_manifest'], root / 'assets/art/manifests')
    manifest = parse_simple_yaml(object_path)
    variant = manifest['variants'][job['variant']]
    if variant['root'] != job['candidate_root']:
        raise ValueError('Candidate changed during capture')
    candidate = inside(root / variant['root'], root / 'design/concepts')
    review = inside(root / job['review_root'], candidate)
    if review != candidate / 'review':
        raise ValueError('Output must be the registered candidate review directory')
    captures = job['captures']
    if not captures:
        raise ValueError('Godot produced no captures')
    expected = [job['requested_action']] if job['requested_action'] else job['supported_actions']
    if [item['action'] for item in captures] != expected:
        raise ValueError('Incomplete action capture')
    prepared = []
    for item in captures:
        action = item['action']
        if action not in ACTIONS or item['fps'] != job['fps']:
            raise ValueError('Invalid action/fps')
        images = []
        for relative in item['frames']:
            source = inside(cache / relative, cache)
            with Image.open(source) as image:
                if list(image.size) != job['size']:
                    raise ValueError('Unexpected frame dimensions')
                background = Image.new('RGBA', image.size, '#fff9ee')
                background.alpha_composite(image.convert('RGBA'))
                images.append(background.convert('RGB'))
        if not images:
            raise ValueError('Empty capture')
        prepared.append((item, images))
    review.mkdir(exist_ok=True)
    tour = []
    # Alternate 30/40 ms GIF ticks preserve 30 FPS without cumulative speed drift.
    def save(images, destination, loop):
        durations = [round((i + 1) * 100 / job['fps']) * 10 - round(i * 100 / job['fps']) * 10
                     for i in range(len(images))]
        options = {'loop': 0} if loop else {}
        images[0].save(destination, save_all=True, append_images=images[1:], duration=durations,
                       disposal=2, optimize=False, **options)
    for item, images in prepared:
        action = item['action']
        name = action + '-preview.gif'
        save(images, review / name, item['loop'])
        images[min(len(images) - 1, int(job['fps'] * 0.6))].save(cache / (action + '.png'))
        key = 'gif_' + action
        variant.setdefault('files', {})[key] = 'review/' + name
        # Legacy metadata still calls an attack clip 'attack'; consume its explicit mapping.
        clip = item.get('source_clip', action)
        variant.setdefault('previews', {}).setdefault('gifs', {})[clip] = key
        tour.extend(images)
    if not job['requested_action']:
        save(tour, review / 'all-actions.gif', False)
        variant['files']['gif_all_actions'] = 'review/all-actions.gif'
    write_yaml(object_path, manifest)
    # Only this job's PNGs, below its checked cache, are temporary. Keep the JSON audit.
    frames = inside(cache / 'frames', cache)
    if frames.exists():
        shutil.rmtree(frames)
    print('MOTION_PREVIEW_EXPORT actions={} size={} tour={}'.format(len(captures), job['size'], not job['requested_action']))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['prepare', 'encode'])
    parser.add_argument('--animation', default='')
    parser.add_argument('--unit', default='')
    parser.add_argument('--action', default='')
    parser.add_argument('--manifest')
    args = parser.parse_args()
    if args.command == 'prepare':
        print(prepare(args.animation, args.unit, args.action))
    else:
        encode(args.manifest)


if __name__ == '__main__':
    main()
