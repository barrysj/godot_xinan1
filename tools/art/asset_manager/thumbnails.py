"""Disposable browse thumbnails. No writes to source packages or manifests."""
import ctypes
import hashlib
import os
import threading
import uuid
from pathlib import Path


def _windows_resize(source, target, edge):
    # Windows' bundled decoder keeps the existing Python 3.7 launcher usable.
    # API contract: https://learn.microsoft.com/windows/win32/gdiplus/-gdiplus-bitmap-flat
    class StartupInput(ctypes.Structure):
        _fields_ = [('version', ctypes.c_uint32), ('callback', ctypes.c_void_p),
                    ('suppress_thread', ctypes.c_int), ('suppress_codecs', ctypes.c_int)]
    dll = ctypes.WinDLL('gdiplus')
    pointer = ctypes.c_void_p
    signatures = {
        'GdiplusStartup': [ctypes.POINTER(ctypes.c_size_t), ctypes.POINTER(StartupInput), pointer],
        'GdipLoadImageFromFile': [ctypes.c_wchar_p, ctypes.POINTER(pointer)],
        'GdipGetImageWidth': [pointer, ctypes.POINTER(ctypes.c_uint)],
        'GdipGetImageHeight': [pointer, ctypes.POINTER(ctypes.c_uint)],
        'GdipCreateBitmapFromScan0': [ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, pointer, ctypes.POINTER(pointer)],
        'GdipGetImageGraphicsContext': [pointer, ctypes.POINTER(pointer)],
        'GdipSetInterpolationMode': [pointer, ctypes.c_int],
        'GdipDrawImageRectI': [pointer, pointer, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int],
        'GdipSaveImageToFile': [pointer, ctypes.c_wchar_p, pointer, pointer],
        'GdipDeleteGraphics': [pointer], 'GdipDisposeImage': [pointer],
        'GdiplusShutdown': [ctypes.c_size_t],
    }
    for name, args in signatures.items():
        getattr(dll, name).argtypes = args
    def checked(name, *args):
        status = getattr(dll, name)(*args)
        if status:
            raise OSError('%s failed (%s)' % (name, status))
    token = ctypes.c_size_t()
    checked('GdiplusStartup', ctypes.byref(token), ctypes.byref(StartupInput(1, None, 0, 0)), None)
    image, bitmap, graphics = pointer(), pointer(), pointer()
    try:
        checked('GdipLoadImageFromFile', str(source), ctypes.byref(image))
        width, height = ctypes.c_uint(), ctypes.c_uint()
        checked('GdipGetImageWidth', image, ctypes.byref(width))
        checked('GdipGetImageHeight', image, ctypes.byref(height))
        ratio = min(1.0, float(edge) / max(width.value, height.value, 1))
        w, h = max(1, round(width.value * ratio)), max(1, round(height.value * ratio))
        checked('GdipCreateBitmapFromScan0', w, h, 0, 0x26200A, None, ctypes.byref(bitmap))
        checked('GdipGetImageGraphicsContext', bitmap, ctypes.byref(graphics))
        checked('GdipSetInterpolationMode', graphics, 7)
        checked('GdipDrawImageRectI', graphics, image, 0, 0, w, h)
        png_encoder = ctypes.create_string_buffer(uuid.UUID('557cf406-1a04-11d3-9a73-0000f81ef32e').bytes_le)
        checked('GdipSaveImageToFile', bitmap, str(target), png_encoder, None)
    finally:
        if graphics:
            dll.GdipDeleteGraphics(graphics)
        for item in (bitmap, image):
            if item:
                dll.GdipDisposeImage(item)
        dll.GdiplusShutdown(token)


class ThumbnailCache:
    def __init__(self, project_root):
        self.root = Path(project_root) / '.godot/art-workflow/asset-manager/thumbnails'
        self._lock = threading.Lock()

    def get(self, source, edge=480):
        if source.suffix.lower() == '.svg':
            return source
        stat = source.stat()
        key = '%s:%s:%s:%s:v1' % (source, stat.st_mtime_ns, stat.st_size, edge)
        target = self.root / (hashlib.sha256(key.encode('utf-8')).hexdigest() + '.png')
        with self._lock:
            if target.is_file():
                return target
            self.root.mkdir(parents=True, exist_ok=True)
            temporary = target.with_suffix('.tmp.png')
            try:
                if os.name == 'nt' and source.suffix.lower() in ('.png', '.jpg', '.jpeg', '.gif', '.bmp'):
                    _windows_resize(source, temporary, edge)
                else:
                    from PIL import Image
                    with Image.open(str(source)) as image:
                        image.thumbnail((edge, edge))
                        image.convert('RGBA').save(str(temporary))
                temporary.replace(target)
            except (OSError, ImportError, ValueError):
                if temporary.exists():
                    temporary.unlink()
                # Decode failures remain visible; browsing never hides the original.
                return source
        return target
