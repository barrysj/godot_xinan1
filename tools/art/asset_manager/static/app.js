"use strict";

const boot = JSON.parse(document.getElementById("boot-data").textContent);
const state = { objects: [], filter: "全部", selected: null };
const roots = document.getElementById("roots");
const engine = document.getElementById("engine");
const scanButton = document.getElementById("scan");
const notice = document.getElementById("notice");
const grid = document.getElementById("grid");
const empty = document.getElementById("empty");
const filters = document.getElementById("filters");
const summary = document.getElementById("summary");
const detail = document.getElementById("detail");
const detailContent = document.getElementById("detail-content");
const lightbox = document.getElementById("lightbox");
const lightboxImage = document.getElementById("lightbox-image");
const lightboxCaption = document.getElementById("lightbox-caption");

roots.value = boot.defaultRoots.join("\n");
engine.value = boot.defaultEngine || "";

function api(path, options = {}) {
  const headers = Object.assign({ "X-Art-Token": boot.token }, options.headers || {});
  return fetch(path, Object.assign({}, options, { headers })).then(async response => {
    const payload = await response.json();
    if (!response.ok) throw new Error(payload.error || payload.message || "请求失败");
    return payload;
  });
}

function fileUrl(asset) {
  return `/api/file?id=${encodeURIComponent(asset.id)}&token=${encodeURIComponent(boot.token)}`;
}

function setNotice(message, tone = "") {
  notice.textContent = message;
  notice.className = `notice ${tone}`.trim();
}

function countLabel(object) {
  const bits = [];
  if (object.counts.concepts) bits.push(`${object.counts.concepts} 概念`);
  if (object.counts.atlases) bits.push(`${object.counts.atlases} 图集`);
  if (object.counts.animations) bits.push(`${object.counts.animations} 动画`);
  if (!bits.length) bits.push(`${object.counts.files} 文件`);
  return bits;
}

function renderFilters() {
  const categories = ["全部", "场景", "人物", "UI", "特效", "未归类"];
  filters.replaceChildren();
  categories.forEach(category => {
    const count = category === "全部" ? state.objects.length : state.objects.filter(item => item.category === category).length;
    const button = document.createElement("button");
    button.className = `filter${state.filter === category ? " active" : ""}`;
    button.textContent = category;
    const badge = document.createElement("em");
    badge.textContent = String(count);
    button.append(badge);
    button.addEventListener("click", () => { state.filter = category; renderFilters(); renderGrid(); });
    filters.append(button);
  });
}

function renderGrid() {
  const visible = state.filter === "全部" ? state.objects : state.objects.filter(item => item.category === state.filter);
  grid.replaceChildren();
  empty.hidden = visible.length > 0;
  if (!visible.length) {
    empty.querySelector("h3").textContent = state.objects.length ? "这个分类还是空的" : "没有发现资源";
    empty.querySelector("p").textContent = state.objects.length ? "换个分类看看吧。" : "检查目录后再扫描一次。";
  }
  visible.forEach(object => {
    const card = document.createElement("button");
    card.className = "object-card";
    card.dataset.objectId = object.id;
    const thumb = document.createElement("div");
    thumb.className = "thumb";
    const thumbAsset = object.assets.find(item => item.id === object.thumbnail_id);
    if (thumbAsset) {
      const image = document.createElement("img");
      image.src = fileUrl(thumbAsset);
      image.alt = `${object.name}缩略图`;
      image.loading = "lazy";
      thumb.append(image);
    } else {
      const placeholder = document.createElement("div");
      placeholder.className = "thumb-placeholder";
      placeholder.textContent = "◇";
      thumb.append(placeholder);
    }
    const body = document.createElement("div");
    body.className = "card-body";
    const top = document.createElement("div"); top.className = "card-top";
    const category = document.createElement("span"); category.className = "category"; category.textContent = object.category;
    const status = document.createElement("span"); status.className = "status"; status.textContent = object.statuses.join(" · ");
    top.append(category, status);
    const title = document.createElement("h3"); title.textContent = object.name;
    const counts = document.createElement("div"); counts.className = "counts";
    countLabel(object).forEach(label => { const tag = document.createElement("span"); tag.textContent = label; counts.append(tag); });
    body.append(top, title, counts);
    card.append(thumb, body);
    card.addEventListener("click", () => openDetail(object));
    grid.append(card);
  });
}

function metadataList(metadata) {
  const keys = ["status", "resolution", "grid", "portrait_region", "normalized_canvas", "display_size", "anchor", "animation_resource", "style_layer"];
  const dl = document.createElement("dl"); dl.className = "meta";
  keys.forEach(key => {
    if (metadata[key] === undefined || metadata[key] === null) return;
    const dt = document.createElement("dt"); dt.textContent = key;
    const dd = document.createElement("dd"); dd.textContent = Array.isArray(metadata[key]) ? metadata[key].join(" × ") : String(metadata[key]);
    dl.append(dt, dd);
  });
  return dl;
}

function assetCard(asset) {
  const card = document.createElement("article"); card.className = "asset-card";
  if (asset.is_image) {
    const image = document.createElement("img"); image.className = "asset-preview"; image.src = fileUrl(asset); image.alt = asset.name; image.loading = "lazy";
    card.append(image);
  }
  const info = document.createElement("div"); info.className = "asset-info";
  const heading = document.createElement("div"); heading.className = "asset-title";
  const title = document.createElement("h4"); title.textContent = asset.name;
  const kind = document.createElement("span"); kind.className = "asset-kind"; kind.textContent = asset.kind_label;
  heading.append(title, kind);
  const path = document.createElement("p"); path.className = "asset-path"; path.textContent = asset.path;
  info.append(heading, path);
  if (asset.clips && asset.clips.length) {
    const clips = document.createElement("div"); clips.className = "clips";
    asset.clips.forEach(clip => {
      const tag = document.createElement("span"); tag.className = "clip";
      tag.textContent = `${clip.name}${clip.frames ? ` · ${clip.frames}帧` : ""}`;
      clips.append(tag);
    });
    info.append(clips);
  }
  const actions = document.createElement("div"); actions.className = "asset-actions";
  if (asset.is_image) {
    const original = document.createElement("button"); original.className = "original"; original.textContent = "原图";
    original.addEventListener("click", () => showOriginal(asset)); actions.append(original);
  }
  if (asset.kind === "animation" || asset.kind === "effect_animation") {
    const preview = document.createElement("button"); preview.className = "preview"; preview.textContent = "预览";
    preview.disabled = !asset.preview_supported;
    preview.title = asset.preview_reason;
    preview.addEventListener("click", () => startPreview(asset, preview)); actions.append(preview);
  }
  if (actions.childElementCount) info.append(actions);
  if ((asset.kind === "animation" || asset.kind === "effect_animation") && asset.preview_reason) {
    const reason = document.createElement("p"); reason.className = `reason${asset.preview_supported ? "" : " bad"}`; reason.textContent = asset.preview_reason; info.append(reason);
  }
  if (Object.keys(asset.metadata || {}).length) info.append(metadataList(asset.metadata));
  card.append(info);
  return card;
}

function openDetail(object) {
  state.selected = object.id;
  detailContent.replaceChildren();
  const kicker = document.createElement("p"); kicker.className = "detail-kicker"; kicker.textContent = `${object.category} · ${object.counts.files} 个文件`;
  const title = document.createElement("h2"); title.id = "detail-title"; title.textContent = object.name;
  const lead = document.createElement("p"); lead.className = "detail-lead"; lead.textContent = `对象 ID：${object.id}。多个版本在这里并列保留，不互相覆盖。`;
  detailContent.append(kicker, title, lead);
  object.warnings.forEach(message => { const warning = document.createElement("div"); warning.className = "warning"; warning.textContent = message; detailContent.append(warning); });
  const groups = [
    ["概念图", item => item.kind === "concept"],
    ["图集与图片", item => ["atlas", "image"].includes(item.kind)],
    ["动画资源", item => ["animation", "effect_animation", "resource"].includes(item.kind)],
  ];
  groups.forEach(([label, predicate]) => {
    const assets = object.assets.filter(predicate);
    if (!assets.length) return;
    const section = document.createElement("section"); section.className = "asset-section";
    const heading = document.createElement("h3"); heading.textContent = `${label} · ${assets.length}`;
    const list = document.createElement("div"); list.className = "asset-list";
    assets.forEach(asset => list.append(assetCard(asset)));
    section.append(heading, list); detailContent.append(section);
  });
  detail.classList.add("open"); detail.setAttribute("aria-hidden", "false"); document.body.style.overflow = "hidden";
}

function closeDetail() {
  detail.classList.remove("open"); detail.setAttribute("aria-hidden", "true"); document.body.style.overflow = ""; state.selected = null;
}

function showOriginal(asset) {
  lightboxImage.src = fileUrl(asset); lightboxCaption.textContent = asset.path; lightbox.showModal();
}

async function startPreview(asset, button) {
  button.disabled = true; setNotice(`正在启动 ${asset.name}…`);
  try {
    const payload = await api("/api/preview", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ asset_id: asset.id, engine_path: engine.value.trim() })
    });
    setNotice(`${payload.message} · ${payload.status.animation}`, "success");
  } catch (error) {
    setNotice(error.message, "error");
  } finally {
    button.disabled = !asset.preview_supported;
  }
}

async function scan() {
  scanButton.disabled = true; setNotice("正在读取实际文件与关联元数据…");
  try {
    const payload = await api("/api/scan", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ roots: roots.value.split(/\r?\n/).map(item => item.trim()).filter(Boolean) })
    });
    state.objects = payload.objects; state.filter = "全部";
    summary.textContent = `${payload.summary.objects} 个对象 · ${payload.summary.files} 个文件`;
    renderFilters(); renderGrid();
    if (payload.errors.length) {
      setNotice(`扫描完成；${payload.errors.map(item => `${item.path}：${item.message}`).join("；")}`, "error");
    } else {
      setNotice(`扫描完成：${payload.summary.objects} 个对象，${payload.summary.files} 个文件。`, "success");
    }
  } catch (error) {
    state.objects = []; renderFilters(); renderGrid(); setNotice(error.message, "error");
  } finally { scanButton.disabled = false; }
}

document.getElementById("defaults").addEventListener("click", () => { roots.value = boot.defaultRoots.join("\n"); });
scanButton.addEventListener("click", scan);
detail.querySelectorAll("[data-close]").forEach(node => node.addEventListener("click", closeDetail));
document.getElementById("lightbox-close").addEventListener("click", () => lightbox.close());
document.addEventListener("keydown", event => { if (event.key === "Escape" && detail.classList.contains("open") && !lightbox.open) closeDetail(); });

renderFilters();
scan();
