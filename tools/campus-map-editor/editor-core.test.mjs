import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { clampPoint, nearestEdge, nearestVertex, polygonSelfIntersects, screenToMap, validate } from "./editor-core.mjs";

const layout = JSON.parse(await readFile(new URL("../../game/run/expanded_campus_layout.json", import.meta.url), "utf8"));

test("current campus data passes editor validation", () => assert.deepEqual(validate(layout), []));
test("viewport coordinates stay in source image pixels", () => {
  assert.deepEqual(screenToMap([600, 400], { left: 100, top: 100, width: 900, height: 750 }, layout.size), [1000, 600]);
  assert.deepEqual(clampPoint([-40, 1600], layout.size), [0, 1500]);
});
test("vertex and edge selection use source coordinates", () => {
  const points = [[0, 0], [100, 0], [100, 100], [0, 100]];
  assert.equal(nearestVertex(points, [105, 2], 10), 1);
  assert.equal(nearestEdge(points, [40, 3], true, 10), 0);
  assert.equal(nearestEdge(points, [-3, 40], true, 10), 3);
});
test("invalid polygon and broken place reference prevent save", () => {
  assert.equal(polygonSelfIntersects([[0, 0], [100, 100], [100, 0], [0, 100]]), true);
  const candidate = structuredClone(layout);
  candidate.routes[0].area = [[0, 0], [100, 100], [100, 0], [0, 100]];
  candidate.routes[0].places.push("missing");
  assert.ok(validate(candidate).some(error => error.includes("自交")));
  assert.ok(validate(candidate).some(error => error.includes("地点引用")));
});
test("area vertex limit matches Godot shader", () => {
  const candidate = structuredClone(layout);
  candidate.routes[0].area = Array.from({ length: 33 }, (_, index) => [index, 20]);
  assert.ok(validate(candidate).some(error => error.includes("area 顶点")));
});
test("editable light boundary is separate and validated", () => {
  const candidate = structuredClone(layout);
  candidate.light_boundary.points[0] = [-1, 85];
  assert.ok(validate(candidate).some(error => error.includes("亮区边界顶点")));
  candidate.light_boundary.points = [[0,0],[100,100],[100,0],[0,100]];
  assert.ok(validate(candidate).some(error => error.includes("亮区边界自交")));
  candidate.light_boundary.points = [[0,0],[100,0],[100,100],[0,100]];
  candidate.light_boundary.outside_brightness.day = 1.5;
  assert.ok(validate(candidate).some(error => error.includes("校外亮度")));
  candidate.light_boundary.outside_brightness.day = .82;
  assert.deepEqual(validate(candidate), []);
});

test("each campaign region has a unique editor selection", () => {
  const candidate = structuredClone(layout);
  candidate.routes[1].campaign_region = candidate.routes[0].campaign_region;
  assert.ok(validate(candidate).some(error => error.includes("只能对应一个地图选区")));
});
