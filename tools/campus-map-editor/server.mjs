import http from "node:http";
import { readFile, writeFile, mkdir, copyFile, rename, rm } from "node:fs/promises";
import { createHash } from "node:crypto";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { validate } from "./editor-core.mjs";

const editorDirectory = dirname(fileURLToPath(import.meta.url));
const projectRoot = process.env.NODE_ENV === "test" && process.env.CAMPUS_MAP_EDITOR_ROOT
  ? resolve(process.env.CAMPUS_MAP_EDITOR_ROOT) : resolve(editorDirectory, "../..");
const layoutPath = resolve(projectRoot, "game/run/expanded_campus_layout.json");
const backupDirectory = resolve(projectRoot, ".godot/campus-map-editor-backups");
const portFlag = process.argv.indexOf("--port");
const port = Number(portFlag >= 0 ? process.argv[portFlag + 1] : process.env.CAMPUS_MAP_EDITOR_PORT ?? 8767);
const appId = "cyber-pop-campus-map-editor-v1";
const resources = {
  "/": [resolve(editorDirectory, "index.html"), "text/html; charset=utf-8"],
  "/editor.css": [resolve(editorDirectory, "editor.css"), "text/css; charset=utf-8"],
  "/editor.mjs": [resolve(editorDirectory, "editor.mjs"), "text/javascript; charset=utf-8"],
  "/editor-core.mjs": [resolve(editorDirectory, "editor-core.mjs"), "text/javascript; charset=utf-8"],
  "/api/map-image": [resolve(projectRoot, "assets/art/campus_map/expanded_neutral/day.png"), "image/png"],
};
const etag = bytes => '"' + createHash("sha256").update(bytes).digest("hex") + '"';
const sendJson = (response, status, data) => {
  response.writeHead(status, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" });
  response.end(JSON.stringify(data));
};

async function saveLayout(request, response) {
  const current = await readFile(layoutPath);
  if (request.headers["if-match"] !== etag(current)) return sendJson(response, 409, { error: "地图文件已被其他程序修改；请先导出当前编辑，再刷新页面核对" });
  let chunks = [], length = 0;
  for await (const chunk of request) {
    length += chunk.length;
    if (length > 1024 * 1024) return sendJson(response, 413, { error: "布局数据过大" });
    chunks.push(chunk);
  }
  let parsed;
  try { parsed = JSON.parse(Buffer.concat(chunks).toString("utf8")); }
  catch { return sendJson(response, 400, { error: "JSON 格式无效" }); }
  const errors = validate(parsed);
  if (errors.length) return sendJson(response, 400, { error: errors.join("；") });
  const content = Buffer.from(JSON.stringify(parsed, null, 2) + "\n");
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  await mkdir(backupDirectory, { recursive: true });
  await copyFile(layoutPath, resolve(backupDirectory, `layout-${timestamp}.json`));
  const temporary = layoutPath + ".editor-tmp";
  try {
    await writeFile(temporary, content);
    await rename(temporary, layoutPath);
  } finally { await rm(temporary, { force: true }); }
  response.writeHead(200, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store", ETag: etag(content) });
  response.end(JSON.stringify({ ok: true }));
}

const server = http.createServer(async (request, response) => {
  try {
    const url = new URL(request.url, "http://127.0.0.1");
    if (request.method === "GET" && url.pathname === "/api/health") {
      return sendJson(response, 200, { app: appId, process_id: process.pid, project_root: projectRoot });
    }
    if (request.method === "GET" && url.pathname === "/api/layout") {
      const bytes = await readFile(layoutPath);
      response.writeHead(200, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store", ETag: etag(bytes) });
      return response.end(bytes);
    }
    if (request.method === "POST" && url.pathname === "/api/layout") return await saveLayout(request, response);
    if (request.method === "GET" && resources[url.pathname]) {
      const [file, type] = resources[url.pathname];
      response.writeHead(200, { "Content-Type": type, "Cache-Control": "no-store" });
      return response.end(await readFile(file));
    }
    sendJson(response, 404, { error: "未找到资源" });
  } catch (error) {
    sendJson(response, 500, { error: error.message });
  }
});
server.listen(port, "127.0.0.1", () => console.log(`校园地图编辑器：http://127.0.0.1:${server.address().port}/`));
server.on("error", error => {
  if (error.code === "EADDRINUSE") console.error(`端口 ${port} 已被占用；若编辑器已打开，请直接使用。否则设置 CAMPUS_MAP_EDITOR_PORT 为其他端口。`);
  else console.error(error);
  process.exitCode = 1;
});
