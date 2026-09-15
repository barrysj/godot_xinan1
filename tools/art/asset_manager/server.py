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


APP_ID = "cyber-pop-art-manager-v3"
STATIC_ROOT = Path(__file__).resolve().parent / "static"


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
                    self._last["message"] = "预览窗口正在运行"
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
            if script.parent != self.project_root or script.name != "run-motion-preview.ps1":
                return False, "预览入口不受信"
            args = [pwsh, "-NoProfile", "-File", str(script), "-EnginePath", engine]
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
                "animation": resolved.get("animation_uri"),
                "unit": resolved.get("unit_uri"),
                "projectile": resolved.get("projectile_uri"),
                "started_at": int(time.time()),
                "exit_code": None,
            }
            return True, self._last["message"]


class ArtManagerServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address, handler, project_root):
        super(ArtManagerServer, self).__init__(address, handler)
        self.project_root = Path(project_root).resolve()
        self.catalog = AssetCatalog(self.project_root)
        self.preview = PreviewManager(self.project_root)
        self.token = secrets.token_urlsafe(32)
        self.default_manifest = str(self.project_root / "assets" / "art" / "asset_manifest.yaml")


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
        if parsed.path == "/api/health":
            self._json(HTTPStatus.OK, {"app": APP_ID, "status": "ok"})
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
            content_type = mimetypes.guess_type(str(path))[0] or "application/octet-stream"
            try:
                size = path.stat().st_size
                self.send_response(HTTPStatus.OK)
                self._security_headers(content_type)
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
        if parsed.path == "/api/scan":
            manifest = payload.get("manifest", self.server.default_manifest)
            if not isinstance(manifest, str) or len(manifest) > 4096:
                self._json(HTTPStatus.BAD_REQUEST, {"error": "Manifest 路径无效"})
                return
            result = self.server.catalog.scan(manifest)
            self._json(HTTPStatus.OK, result)
            return
        if parsed.path == "/api/preview":
            asset_id = str(payload.get("asset_id", ""))
            resolved = self.server.catalog.resolve_animation(asset_id)
            if resolved is None:
                self._json(HTTPStatus.BAD_REQUEST, {"error": "动画不可预览；请刷新扫描结果并检查资源状态"})
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
