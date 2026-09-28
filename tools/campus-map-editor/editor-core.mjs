export const clone = value => JSON.parse(JSON.stringify(value));

export function clampPoint(point, size) {
  return [0, 1].map(axis => Math.round(Math.min(size[axis], Math.max(0, point[axis])) * 10) / 10);
}

export function screenToMap(client, rect, size) {
  return clampPoint([
    (client[0] - rect.left) * size[0] / rect.width,
    (client[1] - rect.top) * size[1] / rect.height,
  ], size);
}

export function distanceToSegment(point, a, b) {
  const dx = b[0] - a[0], dy = b[1] - a[1];
  const lengthSquared = dx * dx + dy * dy;
  const t = lengthSquared ? Math.max(0, Math.min(1, ((point[0] - a[0]) * dx + (point[1] - a[1]) * dy) / lengthSquared)) : 0;
  return Math.hypot(point[0] - a[0] - t * dx, point[1] - a[1] - t * dy);
}

export function nearestVertex(points, point, radius) {
  let best = { index: -1, distance: radius };
  points.forEach((vertex, index) => {
    const distance = Math.hypot(vertex[0] - point[0], vertex[1] - point[1]);
    if (distance < best.distance) best = { index, distance };
  });
  return best.index;
}

export function nearestEdge(points, point, closed, radius) {
  let best = { index: -1, distance: radius };
  const count = closed ? points.length : points.length - 1;
  for (let index = 0; index < count; index++) {
    const distance = distanceToSegment(point, points[index], points[(index + 1) % points.length]);
    if (distance < best.distance) best = { index, distance };
  }
  return best.index;
}

function intersects(a, b, c, d) {
  const turn = (p, q, r) => (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0]);
  const abC = turn(a, b, c), abD = turn(a, b, d), cdA = turn(c, d, a), cdB = turn(c, d, b);
  return ((abC > 0 && abD < 0) || (abC < 0 && abD > 0)) &&
    ((cdA > 0 && cdB < 0) || (cdA < 0 && cdB > 0));
}

export function polygonSelfIntersects(points) {
  for (let i = 0; i < points.length; i++) {
    for (let j = i + 1; j < points.length; j++) {
      if (j === i + 1 || (i === 0 && j === points.length - 1)) continue;
      if (intersects(points[i], points[(i + 1) % points.length], points[j], points[(j + 1) % points.length])) return true;
    }
  }
  return false;
}

export function validate(layout) {
  const errors = [];
  const pair = (point, size) => Array.isArray(point) && point.length === 2 &&
    point.every((value, axis) => Number.isFinite(value) && value >= 0 && value <= size[axis]);
  if (!Array.isArray(layout?.size) || layout.size.length !== 2 || !layout.size.every(n => Number.isFinite(n) && n > 0)) {
    return ["地图尺寸无效"];
  }
  if (!layout.places || typeof layout.places !== "object" || Array.isArray(layout.places)) return ["地点数据无效"];
  if (!Array.isArray(layout.routes) || !layout.routes.length) return ["路线数据无效"];
  const boundary = layout.light_boundary;
  if (!boundary || !Array.isArray(boundary.points) || boundary.points.length < 3 || boundary.points.length > 32 ||
      boundary.points.some(point => !pair(point, layout.size))) errors.push("亮区边界顶点无效");
  else if (polygonSelfIntersects(boundary.points)) errors.push("亮区边界自交");
  if (!Number.isFinite(boundary?.feather) || boundary.feather < 0 || boundary.feather > 80) errors.push("亮区过渡宽度无效");
  for (const state of ["day", "night", "anomaly"]) {
    const value = boundary?.outside_brightness?.[state];
    if (!Number.isFinite(value) || value < 0 || value > 1) errors.push(`${state} 校外亮度无效`);
  }
  for (const [id, place] of Object.entries(layout.places)) {
    if (!id || !place?.title?.trim()) errors.push(`地点 ${id} 缺少名称`);
    if (!pair(place?.point, layout.size)) errors.push(`地点 ${id} 坐标越界`);
  }
  const ids = new Set();
  for (const route of layout.routes) {
    if (!route || typeof route !== "object") { errors.push("路线数据无效"); continue; }
    if (!route?.id || ids.has(route.id)) errors.push("路线 ID 缺失或重复");
    ids.add(route.id);
    if (!route?.title?.trim()) errors.push(`路线 ${route?.id} 缺少名称`);
    if (!Array.isArray(route?.places) || !route.places.length || route.places.some(id => !layout.places[id])) errors.push(`路线 ${route?.id} 的地点引用无效`);
    for (const [kind, minimum] of [["path", 2], ["area", 3]]) {
      if (!Array.isArray(route[kind]) || route[kind].length < minimum || route[kind].length > 32 ||
          route[kind].some(point => !pair(point, layout.size))) errors.push(`路线 ${route.id} 的 ${kind} 顶点无效`);
    }
    if (Array.isArray(route.area) && route.area.length >= 3 && route.area.every(point => pair(point, layout.size)) && polygonSelfIntersects(route.area)) errors.push(`路线 ${route.id} 的区域边界自交`);
    if (!/^[0-9a-f]{6}$/i.test(route.color || "")) errors.push(`路线 ${route.id} 的颜色无效`);
    if (!["library", "region_b", "region_c"].includes(route.campaign_region)) errors.push(`路线 ${route.id} 的战役区域无效`);
  }
  return errors;
}
