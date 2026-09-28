import test from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp, mkdir, readFile, writeFile, readdir, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";

const url = "http://127.0.0.1:" + (process.env.CAMPUS_MAP_EDITOR_PORT || "8767") + "/api/layout";

test("health identifies the local map editor and worktree", async () => {
  const response = await fetch(url.replace("/api/layout", "/api/health"));
  const health = await response.json();
  assert.equal(response.status, 200);
  assert.equal(health.app, "cyber-pop-campus-map-editor-v1");
  assert.ok(health.process_id > 0);
  assert.equal(resolve(health.project_root), resolve(fileURLToPath(new URL("../..", import.meta.url))));
});

test("editor serves the current map and a revision token", async () => {
  const response = await fetch(url);
  assert.equal(response.status, 200);
  assert.ok(response.headers.get("etag"));
  assert.equal((await response.json()).routes.length, 3);
});

test("server rejects malformed geometry without writing", async () => {
  const current = await fetch(url);
  const layout = await current.json();
  layout.routes[0].area = [[0, 0], [10, 10]];
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json", "If-Match": current.headers.get("etag") },
    body: JSON.stringify(layout),
  });
  assert.equal(response.status, 400);
  assert.match((await response.json()).error, /area/);
});

test("server rejects an out-of-date save", async () => {
  const current = await fetch(url);
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json", "If-Match": '"outdated"' },
    body: await current.text(),
  });
  assert.equal(response.status, 409);
});

test("save writes validated layout and keeps a recoverable backup", async () => {
  const fixture = await mkdtemp(resolve(tmpdir(), "campus-map-editor-test-"));
  const fixtureLayout = resolve(fixture, "game/run/expanded_campus_layout.json");
  const original = await readFile(new URL("../../game/run/expanded_campus_layout.json", import.meta.url));
  await mkdir(dirname(fixtureLayout), { recursive: true });
  await writeFile(fixtureLayout, original);
  const child = spawn(process.execPath, [fileURLToPath(new URL("./server.mjs", import.meta.url))], {
    env: { ...process.env, NODE_ENV: "test", CAMPUS_MAP_EDITOR_ROOT: fixture, CAMPUS_MAP_EDITOR_PORT: "0" },
    stdio: ["ignore", "pipe", "pipe"],
  });
  try {
    const address = await new Promise((done, fail) => {
      const timer = setTimeout(() => fail(Error("test server did not start")), 5000);
      child.stdout.on("data", chunk => {
        const match = String(chunk).match(/http:\/\/127\.0\.0\.1:\d+\//);
        if (match) { clearTimeout(timer); done(match[0]); }
      });
      child.on("error", fail);
    });
    const loaded = await fetch(address + "api/layout");
    const candidate = await loaded.json();
    candidate.places.library.title = "图书馆测试";
    const originalRoutes = structuredClone(candidate.routes);
    candidate.light_boundary.points[0] = [580, 95];
    const saved = await fetch(address + "api/layout", {
      method: "POST",
      headers: { "Content-Type": "application/json", "If-Match": loaded.headers.get("etag") },
      body: JSON.stringify(candidate),
    });
    assert.equal(saved.status, 200);
    assert.equal(JSON.parse(await readFile(fixtureLayout, "utf8")).places.library.title, "图书馆测试");
    const savedLayout = JSON.parse(await readFile(fixtureLayout, "utf8"));
    assert.deepEqual(savedLayout.light_boundary.points[0], [580, 95]);
    assert.deepEqual(savedLayout.routes, originalRoutes);
    const backupDirectory = resolve(fixture, ".godot/campus-map-editor-backups");
    const backups = await readdir(backupDirectory);
    assert.equal(backups.length, 1);
    assert.deepEqual(await readFile(resolve(backupDirectory, backups[0])), original);
  } finally {
    child.kill();
    if (dirname(fixture) === resolve(tmpdir()) && basename(fixture).startsWith("campus-map-editor-test-")) {
      await rm(fixture, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 });
    }
  }
});
