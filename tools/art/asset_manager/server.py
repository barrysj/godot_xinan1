"""Local-only web service for the Cyber Pop Campus art browser."""

from __future__ import unicode_literals

import argparse
import json
import mimetypes
import os
import re
import secrets
import shutil
import subprocess
import threading
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from catalog import AssetCatalog
from thumbnails import ThumbnailCache


APP_ID = "cyber-pop-art-manager-v4"
STATIC_ROOT = Path(__file__).resolve().parent / "static"


def pick_manifest_path(project_root, initial_path=""):
    """Open the native file dialog while keeping selection inside this project."""
    try:
        from tkinter import Tk, filedialog
    except ImportError:
        raise RuntimeError("当前 Python 缺少文件选择器支持")
    project_root = Path(project_root).resolve()
    initial = Path(initial_path).resolve() if initial_path else project_root / "assets" / "art" / "asset_manifest.yaml"
    try:
        initial.relative_to(project_root)
    except ValueError:
        initial = project_root / "assets" / "art" / "asset_manifest.yaml"
    try:
        window = Tk()
        window.withdraw()
        window.attributes("-topmost", True)
    except Exception as exc:
        raise RuntimeError("无法打开系统文件选择器：%s" % exc)
    try:
        try:
            selected = filedialog.askopenfilename(
                parent=window,
                title="选择主 Manifest",
                initialdir=str(initial.parent if initial.suffix else initial),
                initialfile=initial.name if initial.is_file() else "",
                filetypes=(("YAML Manifest", "*.yaml *.yml"), ("所有文件", "*.*")),
            )
        except Exception as exc:
            raise RuntimeError("无法打开系统文件选择器：%s" % exc)
    finally:
        window.destroy()
    if not selected:
        return None
    path = Path(selected).resolve()
    try:
        path.relative_to(project_root)
    except ValueError:
        raise RuntimeError("只能选择当前项目内的 Manifest")
    if path.suffix.lower() not in (".yaml", ".yml") or not path.is_file():
        raise RuntimeError("请选择当前项目内存在的 YAML Manifest")
    return str(path)


class PreviewManager(object):
    def __init__(self, project_root):
        self.project_root = Path(project_root).resolve()
        self._process = None
        self._lock = threading.Lock()
        self._last = {
            "state": "idle",
            "message": "尚未启动预览",
            "animation": None,
            "unit": None,
            "projectile": None,
            "started_at": None,
            "exit_code": None,
        }

    def default_engine(self):
        script = self.project_root / "run-motion-preview.ps1"
        try:
            text = script.read_text(encoding="utf-8-sig")
        except OSError:
            return ""
        match = re.search(r"\[string\]\$EnginePath\s*=\s*'([^']+)'", text)
        return match.group(1) if match else ""

    def status(self):
        with self._lock:
            if self._process is not None:
                code = self._process.poll()
                if code is None:
                    self._last["state"] = "running"
                    self._last["message"] = "预览进程运行中（含资源导入）；请查看 Godot 窗口"
                else:
                    self._last["exit_code"] = code
                    self._last["state"] = "finished" if code == 0 else "failed"
                    self._last["message"] = "预览已结束" if code == 0 else "预览启动失败（退出码 %s）" % code
                    self._process = None
            return dict(self._last)

    def start(self, resolved, engine_path=""):
        with self._lock:
            if self._process is not None and self._process.poll() is None:
                return False, "已有预览窗口正在运行"
            pwsh = shutil.which("pwsh.exe")
            if not pwsh:
                return False, "未找到 PowerShell 7（pwsh.exe）"
            engine = str(engine_path or self.default_engine()).strip().strip('"')
            if not engine or not Path(engine).is_file():
                return False, "Godot 路径无效，请在页面配置 EnginePath"
            script = Path(resolved["script"]).resolve()
            is_card = bool(resolved.get("card_uri"))
            expected_script = "run-holo-card.ps1" if is_card else "run-motion-preview.ps1"
            if script.parent != self.project_root or script.name != expected_script:
                return False, "预览入口不受信"
            args = [pwsh, "-NoProfile", "-File", str(script), "-Godot" if is_card else "-EnginePath", engine]
            if is_card:
                args.extend(["-Card", resolved["card_uri"]])
            else:
                args.append("-EnsureImport")
            if resolved.get("unit_uri"):
                args.extend(["-Unit", resolved["unit_uri"]])
            if resolved.get("animation_uri"):
                args.extend(["-Animation", resolved["animation_uri"]])
            if resolved.get("projectile_uri"):
                args.extend(["-Projectile", resolved["projectile_uri"]])
            flags = getattr(subprocess, "CREATE_NO_WINDOW", 0)
            try:
                self._process = subprocess.Popen(
                    args,
                    cwd=str(self.project_root),
                    stdin=subprocess.DEVNULL,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    creationflags=flags,
                    shell=False,
                )
            except OSError as exc:
                return False, "无法启动预览：%s" % exc
            self._last = {
                "state": "running",
                "message": "正在导入资源并准备预览",
                "card": resolved.get("card_uri"),
                "animation": resolved.get("animation_uri"),
                "unit": resolved.get("unit_uri"),
                "projectile": resolved.get("projectile_uri"),
                "started_at": int(time.time()),
                "exit_code": None,
            }
            return True, self._last["message"]


def browse_index(result):
    """Keep large file lists and resource graphs behind the object detail endpoint."""
    objects = []
    for obj in result['objects']:
        item = {key: obj[key] for key in ('id', 'name', 'category', 'has_generated_assets', 'counts', 'statuses')}
        item['thumbnail'] = next(({'id': asset['id'], 'name': asset['name']} for asset in obj['assets'] if asset['id'] == obj['thumbnail_id']), None)
        item['approval'] = next((v['approval'] for v in obj['variants'] if v['selection'] == 'selected' and v['stage'] == 'asset'), 'unknown')
        objects.append(item)
    return dict(result, objects=objects)


class CatalogLoader:
    def __init__(self, server):
        self.server = server
        self.lock = threading.Lock()
        self.job = None
        self.objects = {}
        self.revision = None

    def start(self, manifest, validate):
        with self.lock:
            if self.job and self.job['state'] == 'running':
                if self.job['manifest'] == manifest and self.job['validate'] == validate:
                    return dict(self.job)
                raise RuntimeError('已有目录任务正在加载，请稍后重试')
            self.job = {'id': secrets.token_hex(8), 'state': 'running', 'phase': '读取索引',
                        'completed': 0, 'total': 0, 'manifest': manifest, 'validate': validate}
            job_id = self.job['id']
            threading.Thread(target=self._run, args=(job_id, manifest, validate), daemon=True).start()
            return dict(self.job)

    def _run(self, job_id, manifest, validate):
        def progress(update):
            with self.lock:
                self.job.update(update)
        try:
            catalog = AssetCatalog(self.server.project_root)
            result = catalog.scan(manifest, validate=validate, progress=progress)
            index = browse_index(result)
            with self.lock:
                self.server.catalog = catalog
                self.objects = {obj['id']: obj for obj in result['objects']}
                self.revision = job_id
                self.job.update(state='ready', phase='目录就绪', result=index)
        except Exception as exc:
            with self.lock:
                self.job.update(state='failed', error='目录加载失败：%s' % exc)

    def status(self, job_id):
        with self.lock:
            return dict(self.job) if self.job and self.job['id'] == job_id else None


class ArtManagerServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address, handler, project_root):
        super(ArtManagerServer, self).__init__(address, handler)
        self.project_root = Path(project_root).resolve()
        self.catalog = AssetCatalog(self.project_root)
        self.preview = PreviewManager(self.project_root)
        self.token = secrets.token_urlsafe(32)
        self.default_manifest = str(self.project_root / "assets" / "art" / "asset_manifest.yaml")
        self.loader = CatalogLoader(self)
        self.thumbnails = ThumbnailCache(self.project_root)


class Handler(BaseHTTPRequestHandler):
    server_version = "CyberPopArtManager/2.0"

    def log_message(self, fmt, *args):
        message = re.sub(r"token=[^ &\"]+", "token=[redacted]", fmt % args)
        print("[%s] %s" % (self.log_date_time_string(), message), flush=True)

    def _security_headers(self, content_type="application/json; charset=utf-8"):
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")

    def _json(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self._security_headers()
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _allowed_origin(self):
        origin = self.headers.get("Origin")
        if not origin:
            return True
        parsed = urlparse(origin)
        return (
            parsed.scheme == "http"
            and parsed.hostname in ("127.0.0.1", "localhost")
            and parsed.port == self.server.server_address[1]
        )

    def _authorized(self):
        return (
            self.headers.get("X-Art-Token", "") == self.server.token
            and self._allowed_origin()
        )

    def _read_json(self):
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            raise ValueError("请求长度无效")
        if length <= 0 or length > 262144:
            raise ValueError("请求大小无效")
        try:
            return json.loads(self.rfile.read(length).decode("utf-8"))
        except (ValueError, UnicodeError):
            raise ValueError("JSON 请求无效")

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path in ('/api/load/status', '/api/object'):
            if not self._authorized():
                self._json(HTTPStatus.FORBIDDEN, {'error': '会话校验失败'})
                return
            query = parse_qs(parsed.query)
            if parsed.path == '/api/load/status':
                job = self.server.loader.status(query.get('id', [''])[0])
                self._json(HTTPStatus.OK if job else HTTPStatus.NOT_FOUND, job or {'error': '加载任务已过期，请刷新'})
            else:
                with self.server.loader.lock:
                    if query.get('revision', [''])[0] != self.server.loader.revision:
                        self._json(HTTPStatus.CONFLICT, {'error': '目录已刷新，请重新加载'})
                        return
                    obj = self.server.loader.objects.get(query.get('id', [''])[0])
                self._json(HTTPStatus.OK if obj else HTTPStatus.NOT_FOUND, obj or {'error': '对象不存在'})
            return
        if parsed.path == "/api/health":
            self._json(HTTPStatus.OK, {
                "app": APP_ID,
                "status": "ok",
                "process_id": os.getpid(),
                "project_root": str(self.server.project_root),
            })
            return
        if parsed.path == "/api/preview/status":
            if not self._authorized():
                self._json(HTTPStatus.FORBIDDEN, {"error": "会话校验失败"})
                return
            self._json(HTTPStatus.OK, self.server.preview.status())
            return
        if parsed.path == "/api/file":
            query = parse_qs(parsed.query)
            query_token = query.get("token", [""])[0]
            if query_token != self.server.token or not self._allowed_origin():
                self._json(HTTPStatus.FORBIDDEN, {"error": "会话校验失败"})
                return
            asset_id = query.get("id", [""])[0]
            path = self.server.catalog.resolve_file(asset_id)
            if path is None:
                self._json(HTTPStatus.NOT_FOUND, {"error": "资源不存在或未在 Manifest 登记"})
                return
            if query.get('size', [''])[0] == 'thumb':
                if path.suffix.lower() not in ('.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.svg'):
                    self._json(HTTPStatus.BAD_REQUEST, {'error': '该文件不是图片'})
                    return
                path = self.server.thumbnails.get(path)
            content_type = mimetypes.guess_type(str(path))[0] or "application/octet-stream"
            try:
                stat = path.stat()
                size = stat.st_size
                etag = '"%x-%x"' % (stat.st_mtime_ns, size)
                if self.headers.get('If-None-Match') == etag:
                    self.send_response(HTTPStatus.NOT_MODIFIED)
                    self.send_header('ETag', etag)
                    self.send_header('Cache-Control', 'private, max-age=0, must-revalidate')
                    self.end_headers()
                    return
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-Type', content_type)
                self.send_header('Cache-Control', 'private, max-age=0, must-revalidate')
                self.send_header('ETag', etag)
                self.send_header('X-Content-Type-Options', 'nosniff')
                self.send_header('Referrer-Policy', 'no-referrer')
                self.send_header('Cross-Origin-Resource-Policy', 'same-origin')
                if path.suffix.lower() == ".svg":
                    self.send_header("Content-Security-Policy", "sandbox")
                self.send_header("Content-Length", str(size))
                self.end_headers()
                with path.open("rb") as handle:
                    shutil.copyfileobj(handle, self.wfile)
            except OSError:
                return
            return
        if parsed.path in ("/", "/index.html"):
            template = (STATIC_ROOT / "index.html").read_text(encoding="utf-8")
            boot = {
                "token": self.server.token,
                "defaultManifest": self.server.default_manifest,
                "defaultEngine": self.server.preview.default_engine(),
            }
            body = template.replace("__ART_MANAGER_BOOT__", json.dumps(boot, ensure_ascii=False)).encode("utf-8")
            self.send_response(HTTPStatus.OK)
            self._security_headers("text/html; charset=utf-8")
            self.send_header(
                "Content-Security-Policy",
                "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'none'",
            )
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if parsed.path.startswith("/static/"):
            name = parsed.path[len("/static/") :]
            if name not in ("app.css", "app.js"):
                self._json(HTTPStatus.NOT_FOUND, {"error": "文件不存在"})
                return
            path = STATIC_ROOT / name
            body = path.read_bytes()
            content_type = "text/css; charset=utf-8" if name.endswith(".css") else "application/javascript; charset=utf-8"
            self.send_response(HTTPStatus.OK)
            self._security_headers(content_type)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self._json(HTTPStatus.NOT_FOUND, {"error": "入口不存在"})

    def do_POST(self):
        if not self._authorized():
            self._json(HTTPStatus.FORBIDDEN, {"error": "会话或来源校验失败"})
            return
        try:
            payload = self._read_json()
        except ValueError as exc:
            self._json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})
            return
        parsed = urlparse(self.path)
        if parsed.path == "/api/pick-manifest":
            initial = payload.get("initial", self.server.default_manifest)
            if not isinstance(initial, str) or len(initial) > 4096:
                self._json(HTTPStatus.BAD_REQUEST, {"error": "Manifest 路径无效"})
                return
            try:
                selected = pick_manifest_path(self.server.project_root, initial)
            except RuntimeError as exc:
                self._json(HTTPStatus.CONFLICT, {"error": str(exc)})
                return
            self._json(HTTPStatus.OK, {"selected": bool(selected), "path": selected})
            return
        if parsed.path in ('/api/load', '/api/scan'):
            manifest = payload.get("manifest", self.server.default_manifest)
            if not isinstance(manifest, str) or len(manifest) > 4096:
                self._json(HTTPStatus.BAD_REQUEST, {"error": "Manifest 路径无效"})
                return
            if parsed.path == '/api/load':
                validate = payload.get('validate', False)
                if not isinstance(validate, bool):
                    self._json(HTTPStatus.BAD_REQUEST, {'error': '校验选项无效'})
                    return
                try:
                    job = self.server.loader.start(manifest, validate)
                except RuntimeError as exc:
                    self._json(HTTPStatus.CONFLICT, {'error': str(exc)})
                    return
                self._json(HTTPStatus.ACCEPTED, job)
                return
            # Preserve the delivery-validation API used by existing tools/tests.
            catalog = AssetCatalog(self.server.project_root)
            result = catalog.scan(manifest)
            with self.server.loader.lock:
                if not self.server.loader.job or self.server.loader.job['state'] != 'running':
                    self.server.catalog = catalog
            self._json(HTTPStatus.OK, result)
            return
        if parsed.path == "/api/preview":
            asset_id = str(payload.get("asset_id", ""))
            resolved = self.server.catalog.resolve_animation(asset_id)
            if resolved is None:
                self._json(HTTPStatus.BAD_REQUEST, {"error": "资源不可预览；请刷新扫描结果并检查资源状态"})
                return
            ok, message = self.server.preview.start(resolved, payload.get("engine_path", ""))
            status = HTTPStatus.ACCEPTED if ok else HTTPStatus.CONFLICT
            self._json(status, {"ok": ok, "message": message, "status": self.server.preview.status()})
            return
        self._json(HTTPStatus.NOT_FOUND, {"error": "入口不存在"})


def build_parser():
    parser = argparse.ArgumentParser(description="Cyber Pop Campus local art manager")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--project-root", default=str(Path(__file__).resolve().parents[3]))
    return parser


def main():
    args = build_parser().parse_args()
    if args.port < 1 or args.port > 65535:
        raise SystemExit("Port must be between 1 and 65535")
    project_root = Path(args.project_root).resolve()
    server = ArtManagerServer(("127.0.0.1", args.port), Handler, project_root)
    print("%s listening on http://127.0.0.1:%s" % (APP_ID, args.port), flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
