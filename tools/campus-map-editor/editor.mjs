import { clone, clampPoint, nearestVertex, nearestEdge, screenToMap, validate } from "./editor-core.mjs";

const $ = id => document.getElementById(id);
const canvas = $("overlay"), context = canvas.getContext("2d");
let layout, revision, routeIndex = 0, mode = "area", selectedVertex = -1, selectedPlace = "";
let scale = 1, fitScale = 1, drag = null, history = [], future = [], savedSnapshot = "";
const image = $("map-image");
let pickingCoordinates = false, pickedCoordinate = null;

function updateCoordinate() {
  $("picked-coordinate").value = pickedCoordinate ? `x=${pickedCoordinate[0]}, y=${pickedCoordinate[1]}` : "";
  $("copy-coordinate").disabled = $("clear-coordinate").disabled = !pickedCoordinate;
}

function route() { return layout.routes[routeIndex]; }
function points() { return mode === "boundary" ? layout.light_boundary.points : route()[mode]; }
function snapshot() { return JSON.stringify(layout); }
function message(value, error = false) { $("message").textContent = value; $("message").classList.toggle("error", error); }
function commit(before) {
  if (before === snapshot()) return;
  history.push(before);
  future = [];
  updateUi();
}
function isDirty() { return snapshot() !== savedSnapshot; }
function updateDirty() {
  const dirty = isDirty();
  $("dirty").textContent = dirty ? "未保存" : "已同步";
  $("dirty").classList.toggle("dirty", dirty);
  $("save").disabled = !dirty;
}

function fit() {
  const viewport = $("viewport");
  fitScale = Math.min((viewport.clientWidth - 28) / layout.size[0], (viewport.clientHeight - 28) / layout.size[1]);
  setScale(fitScale);
}
function setScale(value) {
  scale = Math.max(0.2, Math.min(2.5, value));
  $("stage").style.width = `${layout.size[0] * scale}px`;
  $("stage").style.height = `${layout.size[1] * scale}px`;
  canvas.width = layout.size[0];
  canvas.height = layout.size[1];
  $("zoom-value").textContent = `${Math.round(scale * 100)}%`;
  draw();
}
function atEvent(event) { return screenToMap([event.clientX, event.clientY], canvas.getBoundingClientRect(), layout.size); }
function color(hex, alpha = 1) {
  const n = parseInt(hex, 16);
  return `rgba(${n >> 16 & 255},${n >> 8 & 255},${n & 255},${alpha})`;
}
function line(points, closed, stroke, fill = null, width = 3) {
  if (points.length < 2) return;
  context.beginPath();
  context.moveTo(...points[0]);
  for (const point of points.slice(1)) context.lineTo(...point);
  if (closed) context.closePath();
  if (fill) { context.fillStyle = fill; context.fill(); }
  context.strokeStyle = stroke;
  context.lineWidth = width / scale;
  context.stroke();
}
function dot(point, fill, selected = false, radius = 7) {
  context.beginPath();
  context.arc(point[0], point[1], (selected ? radius + 3 : radius) / scale, 0, Math.PI * 2);
  context.fillStyle = fill;
  context.fill();
  context.lineWidth = 2 / scale;
  context.strokeStyle = "#112635";
  context.stroke();
}
function draw() {
  if (!layout) return;
  context.clearRect(0, 0, canvas.width, canvas.height);
  const boundary = layout.light_boundary.points;
  context.beginPath();
  context.rect(0, 0, layout.size[0], layout.size[1]);
  context.moveTo(...boundary[0]);
  for (const point of boundary.slice(1)) context.lineTo(...point);
  context.closePath();
  context.fillStyle = `rgba(0,0,0,${1 - layout.light_boundary.outside_brightness.day})`;
  context.fill("evenodd");
  if (mode === "boundary") line(boundary, true, "#ffdb87", null, 4);
  for (let index = 0; index < layout.routes.length; index++) {
    const r = layout.routes[index], active = index === routeIndex;
    if (mode !== "boundary") {
      line(r.area, true, color(r.color, active ? .92 : .36), active ? color(r.color, .17) : null, active ? 3 : 2);
      line(r.path, false, active ? "#fff5cf" : color(r.color, .65), null, active ? 4 : 2);
    }
  }
  if (mode !== "place") {
    points().forEach((point, index) => dot(point, mode === "area" ? "#89e6e9" : "#fce58a", index === selectedVertex));
  }
  for (const [id, place] of Object.entries(layout.places)) {
    const active = id === selectedPlace;
    dot(place.point, active ? "#ffdc83" : "#d9fcff", active, 6);
    context.font = `${15 / scale}px "Microsoft YaHei UI", sans-serif`;
    const width = context.measureText(place.title).width + 14 / scale;
    const x = place.point[0] + 9 / scale, y = place.point[1] - 26 / scale;
    context.fillStyle = "#102636e8";
    context.fillRect(x, y, width, 24 / scale);
    context.strokeStyle = active ? "#ffdc83" : "#75cad6";
    context.lineWidth = 1 / scale;
    context.strokeRect(x, y, width, 24 / scale);
    context.fillStyle = "#fff";
    context.fillText(place.title, x + 7 / scale, y + 17 / scale);
  }
  if (pickedCoordinate) {
    const [x, y] = pickedCoordinate, r = 15 / scale;
    context.beginPath();
    context.arc(x, y, 9 / scale, 0, Math.PI * 2);
    context.moveTo(x - r, y); context.lineTo(x + r, y);
    context.moveTo(x, y - r); context.lineTo(x, y + r);
    context.strokeStyle = "#14202b"; context.lineWidth = 6 / scale; context.stroke();
    context.strokeStyle = "#ffda75"; context.lineWidth = 3 / scale; context.stroke();
  }
}

function updateUi() {
  const editingBoundary = mode === "boundary";
  document.querySelectorAll(".route-only").forEach(section => section.hidden = editingBoundary);
  $("boundary-settings").hidden = !editingBoundary;
  $("boundary-feather").value = layout.light_boundary.feather;
  for (const state of ["day", "night", "anomaly"]) {
    const value = layout.light_boundary.outside_brightness[state];
    $(`boundary-${state}`).value = value;
    $(`boundary-${state}-value`).textContent = `${Math.round(value * 100)}%`;
  }
  $("route-count").textContent = `${routeIndex + 1} / ${layout.routes.length}`;
  $("route-select").replaceChildren(...layout.routes.map((item, index) => new Option(item.title, index)));
  $("route-select").value = String(routeIndex);
  $("route-title").value = route().title;
  $("route-color").value = "#" + route().color;
  $("campaign-region").value = route().campaign_region;
  $("point-heading").textContent = mode === "boundary" ? "亮区顶点" : mode === "area" ? "区域顶点" : mode === "path" ? "路线节点" : "地点位置";
  $("point-count").textContent = mode === "place" ? `${Object.keys(layout.places).length} 个` : `${points().length} 个`;
  $("point-help").textContent = mode === "boundary" ? "边界内保持亮度，外侧变暗。拖动圆点或按 Shift 点击边线加点；保存后重启游戏查看三态。" : mode === "place" ? "点击地点圆点选中，再拖动改变落点。" : "拖动圆点调整位置；Shift＋点击边线插入顶点。";
  $("add-point").disabled = $("remove-point").disabled = mode === "place" || pickingCoordinates;
  $("remove-point").disabled ||= selectedVertex < 0 || points().length <= (mode === "path" ? 2 : 3);
  $("place-select").replaceChildren(new Option("选择地点", ""), ...Object.entries(layout.places).map(([id, place]) => new Option(`${place.title} · ${id}`, id)));
  $("place-select").value = selectedPlace;
  const place = layout.places[selectedPlace];
  for (const id of ["place-title", "place-x", "place-y"]) $(id).disabled = !place;
  $("place-title").value = place?.title ?? "";
  $("place-x").value = place?.point[0] ?? "";
  $("place-y").value = place?.point[1] ?? "";
  $("route-places").replaceChildren(...Object.entries(layout.places).map(([id, item]) => {
    const row = document.createElement("div"); row.className = "place-row";
    const box = document.createElement("input"); box.type = "checkbox"; box.checked = route().places.includes(id); box.ariaLabel = `路线包含${item.title}`;
    box.addEventListener("change", () => {
      const before = snapshot();
      if (box.checked) route().places.push(id);
      else if (route().places.length > 1) route().places.splice(route().places.indexOf(id), 1);
      else { box.checked = true; message("路线至少保留一个地点", true); return; }
      commit(before);
    });
    const name = document.createElement("span"); name.textContent = item.title; name.title = id;
    const up = document.createElement("button"); up.textContent = "↑"; up.title = "前移"; up.disabled = route().places.indexOf(id) <= 0;
    const down = document.createElement("button"); down.textContent = "↓"; down.title = "后移";
    const swap = step => { const from = route().places.indexOf(id), to = from + step; if (from < 0 || to < 0 || to >= route().places.length) return; const before = snapshot(); [route().places[from], route().places[to]] = [route().places[to], route().places[from]]; commit(before); };
    up.addEventListener("click", () => swap(-1)); down.addEventListener("click", () => swap(1));
    down.disabled = route().places.indexOf(id) < 0 || route().places.indexOf(id) >= route().places.length - 1;
    row.append(box, name, up, down); return row;
  }));
  document.querySelectorAll("[data-mode]").forEach(button => button.classList.toggle("active", !pickingCoordinates && button.dataset.mode === mode));
  $("pick-coordinate").classList.toggle("active", pickingCoordinates);
  $("pick-coordinate").setAttribute("aria-pressed", String(pickingCoordinates));
  $("hint").textContent = pickingCoordinates ? "点击地图固定坐标；取坐标不会拖动或增删地点与边界。" : "拖动圆点调整位置；Shift＋点击边线添加顶点。";
  updateCoordinate();
  $("undo").disabled = !history.length;
  $("redo").disabled = !future.length;
  updateDirty();
  draw();
}

canvas.addEventListener("pointerdown", event => {
  if (event.button !== 0 || !layout) return;
  const point = atEvent(event);
  if (pickingCoordinates) {
    pickedCoordinate = point;
    updateCoordinate(); draw();
    $("coordinate-status").textContent = `已固定原图位置（${layout.size.join("×")}），可以复制发给我。`;
    return;
  }
  if (mode === "place") {
    let best = "", distance = 18 / scale;
    for (const [id, place] of Object.entries(layout.places)) {
      const d = Math.hypot(point[0] - place.point[0], point[1] - place.point[1]);
      if (d < distance) { best = id; distance = d; }
    }
    selectedPlace = best;
    if (best) drag = { kind: "place", id: best, before: snapshot() };
  } else {
    const vertices = points(), radius = 16 / scale;
    selectedVertex = nearestVertex(vertices, point, radius);
    if (selectedVertex < 0 && event.shiftKey) {
      const edge = nearestEdge(vertices, point, mode !== "path", 18 / scale);
      if (edge >= 0 && vertices.length < 32) {
        const before = snapshot();
        vertices.splice(edge + 1, 0, point);
        selectedVertex = edge + 1;
        commit(before);
      }
    }
    if (selectedVertex >= 0) drag = { kind: "vertex", index: selectedVertex, before: snapshot() };
  }
  if (drag) canvas.setPointerCapture(event.pointerId);
  updateUi();
});
canvas.addEventListener("pointermove", event => {
  const point = atEvent(event);
  $("coordinates").textContent = `x ${point[0]}　y ${point[1]}`;
  if (!drag) return;
  if (drag.kind === "place") layout.places[drag.id].point = point;
  else points()[drag.index] = point;
  $("place-x").value = selectedPlace ? layout.places[selectedPlace].point[0] : "";
  $("place-y").value = selectedPlace ? layout.places[selectedPlace].point[1] : "";
  draw();
});
function finishDrag() { if (!drag) return; commit(drag.before); drag = null; }
canvas.addEventListener("pointerup", finishDrag);
canvas.addEventListener("pointercancel", finishDrag);

function applyEdit(control, callback) {
  control.addEventListener("change", () => { const before = snapshot(); callback(); commit(before); });
}
applyEdit($("route-title"), () => { route().title = $("route-title").value.trim() || route().title; });
applyEdit($("route-color"), () => { route().color = $("route-color").value.slice(1); });
applyEdit($("campaign-region"), () => { route().campaign_region = $("campaign-region").value; });
applyEdit($("boundary-feather"), () => {
  layout.light_boundary.feather = Math.min(80, Math.max(0, Number($("boundary-feather").value)));
});
for (const state of ["day", "night", "anomaly"]) {
  const slider = $(`boundary-${state}`);
  let start = null;
  slider.addEventListener("input", () => {
    if (start === null) start = snapshot();
    layout.light_boundary.outside_brightness[state] = Number(slider.value);
    $(`boundary-${state}-value`).textContent = `${Math.round(Number(slider.value) * 100)}%`;
    draw(); updateDirty();
  });
  slider.addEventListener("change", () => { if (start !== null) commit(start); start = null; });
}
applyEdit($("place-title"), () => { if (selectedPlace) layout.places[selectedPlace].title = $("place-title").value.trim() || layout.places[selectedPlace].title; });
for (const axis of [0, 1]) applyEdit($(axis ? "place-y" : "place-x"), () => {
  if (!selectedPlace) return;
  const inputs = [Number($("place-x").value), Number($("place-y").value)];
  layout.places[selectedPlace].point = clampPoint(inputs, layout.size);
});
$("route-select").addEventListener("change", () => { routeIndex = Number($("route-select").value); selectedVertex = -1; updateUi(); });
$("place-select").addEventListener("change", () => { pickingCoordinates = false; selectedPlace = $("place-select").value; mode = "place"; updateUi(); });
document.querySelectorAll("[data-mode]").forEach(button => button.addEventListener("click", () => { pickingCoordinates = false; mode = button.dataset.mode; selectedVertex = -1; updateUi(); }));
$("pick-coordinate").addEventListener("click", () => {
  if (!layout) return;
  finishDrag(); pickingCoordinates = !pickingCoordinates; updateUi();
});
$("clear-coordinate").addEventListener("click", () => {
  pickedCoordinate = null; updateCoordinate(); draw();
  $("coordinate-status").textContent = "标记已清除，地图数据未修改。";
});
$("copy-coordinate").addEventListener("click", async () => {
  if (!pickedCoordinate) return;
  try {
    await navigator.clipboard.writeText($("picked-coordinate").value);
    $("coordinate-status").textContent = "坐标已复制，直接粘贴到聊天即可。";
  } catch {
    $("picked-coordinate").focus(); $("picked-coordinate").select();
    $("coordinate-status").textContent = "自动复制不可用，已选中文字，请按 Ctrl+C 复制。";
  }
});
$("add-point").addEventListener("click", () => {
  if (pickingCoordinates || mode === "place" || points().length >= 32) return;
  const vertices = points(), index = selectedVertex >= 0 ? selectedVertex : vertices.length - 1;
  const next = vertices[(index + 1) % vertices.length];
  const candidate = mode === "path" && index === vertices.length - 1
    ? [vertices[index][0] + (vertices[index][0] - vertices[index - 1][0]) / 2, vertices[index][1] + (vertices[index][1] - vertices[index - 1][1]) / 2]
    : [(vertices[index][0] + next[0]) / 2, (vertices[index][1] + next[1]) / 2];
  const before = snapshot();
  vertices.splice(index + 1, 0, clampPoint(candidate, layout.size));
  selectedVertex = index + 1;
  commit(before);
});
$("remove-point").addEventListener("click", () => {
  if (pickingCoordinates || mode === "place" || selectedVertex < 0 || points().length <= (mode === "path" ? 2 : 3)) return;
  const before = snapshot(); points().splice(selectedVertex, 1); selectedVertex = -1; commit(before);
});
$("add-place").addEventListener("click", () => {
  const id = $("new-id").value.trim(), title = $("new-title").value.trim();
  if (!/^[a-z][a-z0-9_]*$/.test(id) || layout.places[id] || !title) { message("请填写未使用的英文 ID（小写字母、数字、下划线）和地点名称", true); return; }
  const viewport = $("viewport"), rect = canvas.getBoundingClientRect();
  const center = screenToMap([viewport.getBoundingClientRect().left + viewport.clientWidth / 2, viewport.getBoundingClientRect().top + viewport.clientHeight / 2], rect, layout.size);
  const before = snapshot(); layout.places[id] = { title, point: center }; route().places.push(id);
  selectedPlace = id; mode = "place"; $("new-id").value = ""; $("new-title").value = ""; commit(before); message("地点已添加，拖动地图圆点调整位置");
});
function restore(serialized) { layout = JSON.parse(serialized); selectedVertex = -1; if (!layout.places[selectedPlace]) selectedPlace = ""; routeIndex = Math.min(routeIndex, layout.routes.length - 1); updateUi(); }
$("undo").addEventListener("click", () => { if (!history.length) return; future.push(snapshot()); restore(history.pop()); });
$("redo").addEventListener("click", () => { if (!future.length) return; history.push(snapshot()); restore(future.pop()); });
document.addEventListener("keydown", event => {
  if (event.target.matches("input,select,textarea")) return;
  if (event.ctrlKey && event.key.toLowerCase() === "z") { event.preventDefault(); $("undo").click(); }
  if (event.ctrlKey && event.key.toLowerCase() === "y") { event.preventDefault(); $("redo").click(); }
  if (event.key === "Delete") $("remove-point").click();
});
$("fit").addEventListener("click", fit);
$("zoom-in").addEventListener("click", () => setScale(scale * 1.25));
$("zoom-out").addEventListener("click", () => setScale(scale / 1.25));
$("viewport").addEventListener("wheel", event => { if (!event.ctrlKey) return; event.preventDefault(); setScale(scale * (event.deltaY < 0 ? 1.1 : 1 / 1.1)); }, { passive: false });
window.addEventListener("resize", () => { if (Math.abs(scale - fitScale) < .001) fit(); });

async function loadLayout() {
  const response = await fetch("/api/layout");
  if (!response.ok) throw Error("无法读取地图数据");
  revision = response.headers.get("etag");
  const candidate = await response.json();
  const errors = validate(candidate);
  if (errors.length) throw Error(errors.join("；"));
  layout = candidate; savedSnapshot = snapshot(); history = []; future = []; routeIndex = 0; selectedPlace = ""; selectedVertex = -1;
  updateUi(); requestAnimationFrame(fit); message("拖动圆点即可编辑；保存会先备份原文件");
}
$("save").addEventListener("click", async () => {
  const errors = validate(layout);
  if (errors.length) { message(errors.join("；"), true); return; }
  try {
    const response = await fetch("/api/layout", { method: "POST", headers: { "Content-Type": "application/json", "If-Match": revision }, body: JSON.stringify(layout, null, 2) + "\n" });
    if (!response.ok) throw Error((await response.json()).error || "保存失败");
    revision = response.headers.get("etag"); savedSnapshot = snapshot(); updateDirty(); message("已保存到游戏布局文件；重启游戏预览即可看到新位置");
  } catch (error) { message(error.message, true); }
});
$("export").addEventListener("click", () => {
  const errors = validate(layout);
  if (errors.length) { message(errors.join("；"), true); return; }
  const link = document.createElement("a");
  link.href = URL.createObjectURL(new Blob([JSON.stringify(layout, null, 2) + "\n"], { type: "application/json" }));
  link.download = "expanded_campus_layout.json"; link.click(); setTimeout(() => URL.revokeObjectURL(link.href), 500);
  message("已导出副本；不会覆盖游戏布局");
});
$("import").addEventListener("click", () => $("file").click());
$("file").addEventListener("change", async () => {
  const file = $("file").files[0]; if (!file) return;
  try {
    const candidate = JSON.parse(await file.text()), errors = validate(candidate);
    if (errors.length) throw Error(errors.join("；"));
    const before = snapshot(); layout = clone(candidate); pickedCoordinate = null; updateCoordinate(); selectedPlace = ""; routeIndex = 0; selectedVertex = -1; commit(before); fit(); message("已导入；点击「保存地图」才会写入游戏文件");
  } catch (error) { message(error.message, true); }
  $("file").value = "";
});
window.addEventListener("beforeunload", event => { if (layout && isDirty()) { event.preventDefault(); event.returnValue = ""; } });
loadLayout().catch(error => message(error.message, true));
