export const effectOptions = {
  feature: ["preparation"], preparation: ["shield", "revive"],
  character: ["inventor"], item: ["shield"], buff: ["reward_refresh"],
};
export function validateDispatch(data, previous = null) {
  const errors = [];
  const idOk = id => typeof id === "string" && /^[a-z][a-z0-9_]{0,47}$/.test(id);
  const textOk = (text, limit) => typeof text === "string" && text.trim().length > 0 && text.length <= limit;
  if (data?.schema !== 1 || !Array.isArray(data.places) || !Array.isArray(data.commissions)) return ["派遣数据格式无效"];
  if ([...data.places, ...data.commissions].some(value => !value || typeof value !== "object" || Array.isArray(value))) return ["地点或委托对象无效"];
  if (data.places.length > 100 || data.commissions.length > 200) errors.push("地点或委托数量超限");
  for (const key of ["campus", "city"]) {
    if (!/^res:\/\/assets\/art\/[a-zA-Z0-9_/-]+\.png$/.test(data.maps?.[key]?.texture || "")) errors.push("底图路径无效");
  }
  for (const map of Object.values(data.maps || {})) {
    const labels = map.labels ?? [];
    if (!Array.isArray(labels) || labels.length > 16 || labels.some(l => !l || !textOk(l.title,32) || !Array.isArray(l.point) || l.point.length !== 2 || !l.point.every(n => Number.isFinite(n) && n >= 0 && n <= 1))) errors.push("道路标注无效");
  }
  const places = new Map(), tasks = new Map();
  for (const place of data.places) {
    if (!idOk(place?.id) || places.has(place.id)) errors.push("地点 ID 无效或重复");
    if (!textOk(place?.name, 32) || typeof place.outside !== "boolean") errors.push("地点名称或地图无效");
    if (!Array.isArray(place.point) || place.point.length !== 2 || !place.point.every(n => Number.isFinite(n) && n >= 0 && n <= 1)) errors.push("地点坐标越界");
    places.set(place.id, place);
  }
  if (!places.get("qingshuihe")?.outside || places.get("library")?.outside !== false) errors.push("必须保留清水河校区和校内图书馆入口");
  for (const task of data.commissions) {
    if (!idOk(task?.id) || tasks.has(task.id)) errors.push("委托 ID 无效或重复");
    if (!textOk(task?.name, 32) || !textOk(task?.description, 1200)) errors.push("委托名称或说明无效");
    if (!Number.isInteger(task.cost) || task.cost < 0 || task.cost > 999) errors.push("消耗必须为 0～999 的整数");
    if (!places.has(task.location) || task.location === "qingshuihe") errors.push("委托地点无效，清水河标记仅用于进入校园");
    if (!effectOptions[task.kind]?.includes(task.value)) errors.push("委托效果不受游戏支持");
    if (typeof task.requires !== "string" || (task.requires && !idOk(task.requires))) errors.push("前置委托格式无效");
    if (task.enabled !== undefined && typeof task.enabled !== "boolean") errors.push("启用状态无效");
    tasks.set(task.id, task);
  }
  const departure = tasks.get("departure");
  if (!departure || departure.cost !== 0 || departure.requires !== "" || departure.kind !== "feature" || departure.value !== "preparation" || departure.location !== "library" || departure.enabled === false) errors.push("教学出发准备必须免费、启用并保留在图书馆");
  for (const task of data.commissions) {
    const seen = new Set([task.id]); let current = task;
    while (current?.requires) {
      if (!tasks.has(current.requires)) { errors.push("前置委托不存在"); break; }
      if (seen.has(current.requires)) { errors.push("前置委托形成循环"); break; }
      seen.add(current.requires); current = tasks.get(current.requires);
    }
    if (task.id !== "departure" && !seen.has("departure")) errors.push("委托必须依赖教学出发准备");
  }
  if (previous) {
    for (const old of previous.commissions) {
      const next = tasks.get(old.id);
      if (!next) errors.push("已登记委托不能删除；请停用以兼容存档");
      else if (next.kind !== old.kind || next.value !== old.value) errors.push("已登记委托的奖励身份不能修改；请新增委托");
    }
  }
  return [...new Set(errors)];
}
