"use strict";

const boot = JSON.parse(document.getElementById("boot-data").textContent);
const state = { objects: [], filter: "全部", selected: null };
const manifest = document.getElementById("manifest");
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

manifest.value = boot.defaultManifest;
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

const integrationLabels = {
  matched: "生效一致", mismatch: "生效异常", missing: "文件缺失",
  unknown: "待核验", not_integrated: "未接入"
};
const stageLabels = { concept: "概念", asset: "资产", animation: "动画" };
const selectionLabels = { selected: "当前选用", unselected: "未选用", unknown: "选用未记录" };
const approvalLabels = { approved: "已批准", rejected: "已否决", review: "待评审", pending: "待评审", deprecated: "已停用", unknown: "批准未记录" };

function countLabel(object) {
  const bits = [];
  if (object.counts.concepts) bits.push(`${object.counts.concepts} 概念版`);
  if (object.counts.atlases) bits.push(`${object.counts.atlases} 图集`);
  if (object.counts.animations) bits.push(`${object.counts.animations} 动画版`);
  if (!bits.length) bits.push(`${object.variants.length} 版本`);
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
    const badge = document.createElement("em"); badge.textContent = String(count); button.append(badge);
    button.addEventListener("click", () => { state.filter = category; renderFilters(); renderGrid(); });
    filters.append(button);
  });
}

function renderGrid() {
  const visible = state.filter === "全部" ? state.objects : state.objects.filter(item => item.category === state.filter);
  grid.replaceChildren(); empty.hidden = visible.length > 0;
  if (!visible.length) {
    empty.querySelector("h3").textContent = state.objects.length ? "这个分类还是空的" : "Manifest 没有对象";
    empty.querySelector("p").textContent = state.objects.length ? "换个分类看看吧。" : "先登记对象，再重新校验。";
  }
  visible.forEach(object => {
    const card = document.createElement("button"); card.className = "object-card"; card.dataset.objectId = object.id;
    const thumb = document.createElement("div"); thumb.className = "thumb";
    const thumbAsset = object.assets.find(item => item.id === object.thumbnail_id);
    if (thumbAsset) {
      const image = document.createElement("img"); image.src = fileUrl(thumbAsset); image.alt = `${object.name}缩略图`; image.loading = "lazy"; thumb.append(image);
    } else {
      const placeholder = document.createElement("div"); placeholder.className = "thumb-placeholder"; placeholder.textContent = "◇"; thumb.append(placeholder);
    }
    const body = document.createElement("div"); body.className = "card-body";
    const top = document.createElement("div"); top.className = "card-top";
    const category = document.createElement("span"); category.className = "category"; category.textContent = object.category;
    const verified = object.integration.verified_status;
    const status = document.createElement("span"); status.className = `status integrity-${verified}`; status.textContent = integrationLabels[verified] || verified;
    top.append(category, status);
    const title = document.createElement("h3"); title.textContent = object.name;
    const counts = document.createElement("div"); counts.className = "counts";
    countLabel(object).forEach(label => { const tag = document.createElement("span"); tag.textContent = label; counts.append(tag); });
    body.append(top, title, counts); card.append(thumb, body);
    card.addEventListener("click", () => openDetail(object)); grid.append(card);
  });
}

function metadataList(metadata) {
  const keys = ["resolution", "grid", "portrait_region", "normalized_canvas", "display_size", "anchor", "style_layer"];
  const dl = document.createElement("dl"); dl.className = "meta";
  keys.forEach(key => {
    if (metadata[key] === undefined || metadata[key] === null) return;
    const dt = document.createElement("dt"); dt.textContent = key;
    const dd = document.createElement("dd"); dd.textContent = Array.isArray(metadata[key]) ? metadata[key].join(" × ") : String(metadata[key]);
    dl.append(dt, dd);
  });
  return dl;
}

function assetCard(asset, compact = false) {
  const card = document.createElement("article"); card.className = `asset-card${compact ? " compact" : ""}`;
  if (asset.is_image && !compact) {
    const image = document.createElement("img"); image.className = "asset-preview"; image.src = fileUrl(asset); image.alt = asset.name; image.loading = "lazy"; card.append(image);
  }
  const info = document.createElement("div"); info.className = "asset-info";
  const heading = document.createElement("div"); heading.className = "asset-title";
  const title = document.createElement("h4"); title.textContent = asset.name;
  const kind = document.createElement("span"); kind.className = "asset-kind"; kind.textContent = asset.kind_label;
  heading.append(title, kind);
  const path = document.createElement("p"); path.className = "asset-path"; path.textContent = asset.manifest_path || asset.path;
  const integrity = document.createElement("p"); integrity.className = `integrity integrity-${asset.integrity.status}`;
  integrity.textContent = `${asset.integrity.label} · 实时 SHA-256 ${asset.integrity.actual ? asset.integrity.actual.slice(0, 12) : "—"}`;
  info.append(heading, path, integrity);
  const actions = document.createElement("div"); actions.className = "asset-actions";
  if (asset.is_image) {
    const original = document.createElement("button"); original.className = "original"; original.textContent = "原图";
    original.addEventListener("click", () => showOriginal(asset)); actions.append(original);
  }
  if (actions.childElementCount) info.append(actions);
  card.append(info); return card;
}

function clipList(animation) {
  const box = document.createElement("div"); box.className = "clips";
  (animation?.clips || []).forEach(clip => {
    const tag = document.createElement("span"); tag.className = "clip";
    const parts = [clip.name];
    if (clip.frames !== undefined && clip.frames !== null) parts.push(`${clip.frames}帧`);
    if (clip.fps !== undefined && clip.fps !== null) parts.push(`${clip.fps} FPS`);
    if (clip.loop === true) parts.push("循环");
    tag.textContent = parts.join(" · "); box.append(tag);
  });
  return box;
}

function previewPanel(variant) {
  const previews = variant.previews || [];
  if (!previews.length) return null;
  const panel = document.createElement("div"); panel.className = "preview-panel";
  previews.filter(item => item.type === "gif").forEach(preview => {
    const asset = variant.files.find(item => item.id === preview.file_id);
    if (!asset) return;
    const wrap = document.createElement("div"); wrap.className = "gif-preview";
    const label = document.createElement("strong"); label.textContent = variant.animation?.clips.find(item => item.id === preview.id)?.name || preview.id;
    const image = document.createElement("img"); image.src = fileUrl(asset); image.alt = `${label.textContent} GIF`; image.loading = "lazy";
    wrap.append(label, image); panel.append(wrap);
  });
  const godot = previews.find(item => item.type === "godot");
  if (godot) {
    const row = document.createElement("div"); row.className = "godot-preview";
    const button = document.createElement("button"); button.className = "preview"; button.textContent = "预览"; button.disabled = !godot.supported; button.title = godot.reason;
    button.addEventListener("click", () => startPreview(godot, button));
    const target = document.createElement("p"); target.className = `reason${godot.supported ? "" : " bad"}`;
    target.textContent = [godot.unit, godot.animation, godot.projectile].filter(Boolean).join(" · ") || godot.reason;
    row.append(button, target); panel.append(row);
  }
  return panel;
}

function variantCard(variant) {
  const section = document.createElement("section"); section.className = "variant-card";
  const head = document.createElement("div"); head.className = "variant-head";
  const title = document.createElement("h3"); title.textContent = `版本 ${variant.version}`;
  const states = document.createElement("div"); states.className = "variant-states";
  const selected = document.createElement("span"); selected.textContent = selectionLabels[variant.selection] || variant.selection;
  selected.title = "选用状态：当前制作或接入流程选择的是哪一个版本。";
  const approved = document.createElement("span"); approved.textContent = approvalLabels[variant.approval] || variant.approval;
  approved.title = "批准状态：负责人是否认可这个具体版本。选用不等于批准。";
  states.append(selected, approved);
  head.append(title, states); section.append(head);
  if (variant.approval_evidence?.source) {
    const evidence = document.createElement("p"); evidence.className = "evidence";
    evidence.textContent = `决定：${variant.approval_evidence.decision || "未记录"} · ${variant.approval_evidence.date || "日期未知"} · ${variant.approval_evidence.source}`;
    section.append(evidence);
  }
  const visibleFiles = variant.files.filter(item => item.role !== "preview_gif");
  if (visibleFiles.length) {
    const list = document.createElement("div"); list.className = "asset-list"; visibleFiles.forEach(asset => list.append(assetCard(asset))); section.append(list);
  }
  if (variant.animation) {
    const animationTitle = document.createElement("h4"); animationTitle.className = "subhead"; animationTitle.textContent = variant.animation.label || "动作";
    section.append(animationTitle, clipList(variant.animation));
  }
  const previews = previewPanel(variant); if (previews) section.append(previews);
  if (Object.keys(variant.metadata || {}).length) section.append(metadataList(variant.metadata));
  return section;
}

function integrationSection(object) {
  const integration = object.integration;
  const section = document.createElement("section"); section.className = "asset-section integration-section";
  const heading = document.createElement("h3"); heading.textContent = `实际生效 · ${integrationLabels[integration.verified_status] || integration.verified_status}`; section.append(heading);
  const lead = document.createElement("p"); lead.className = "evidence";
  lead.textContent = `声明：${integration.declared_status} · 生效版本：${integration.active_variant || "未登记"} · 所有者：${integration.owner_resource || "未登记"}`; section.append(lead);
  if (integration.effective_files.length) {
    const list = document.createElement("div"); list.className = "asset-list compact-list";
    integration.effective_files.forEach(asset => list.append(assetCard(asset, true))); section.append(list);
  }
  if (integration.bindings.length) {
    const bindings = document.createElement("div"); bindings.className = "binding-list";
    integration.bindings.forEach(binding => {
      const item = document.createElement("div"); item.className = `binding integrity-${binding.status}`;
      item.textContent = `${binding.kind || "运行校验"} · ${binding.label}`; bindings.append(item);
    });
    section.append(bindings);
  }
  return section;
}

function relationshipSection(object) {
  if (!object.relationships.length) return null;
  const section = document.createElement("section"); section.className = "relationship-section";
  const heading = document.createElement("h3"); heading.textContent = "关联素材"; section.append(heading);
  const list = document.createElement("div"); list.className = "relationship-grid";
  object.relationships.forEach(relation => {
    const target = state.objects.find(item => item.id === relation.object_id);
    const card = document.createElement("button"); card.className = `relationship-card integrity-${relation.status}`; card.disabled = !target;
    const thumb = document.createElement("div"); thumb.className = "relationship-thumb";
    const asset = target?.assets.find(item => item.id === relation.thumbnail_id);
    if (asset) {
      const image = document.createElement("img"); image.src = fileUrl(asset); image.alt = `${relation.target_name}缩略图`; image.loading = "lazy"; thumb.append(image);
    } else {
      const placeholder = document.createElement("span"); placeholder.textContent = "◇"; thumb.append(placeholder);
    }
    const copy = document.createElement("div");
    const kind = document.createElement("span"); kind.className = "relationship-kind"; kind.textContent = relation.kind === "projectile" ? "弹体" : relation.kind;
    const name = document.createElement("strong"); name.textContent = relation.target_name || relation.object_id;
    const status = document.createElement("small"); status.textContent = target ? "打开详情 →" : relation.status_label;
    copy.append(kind, name, status); card.append(thumb, copy);
    if (target) card.addEventListener("click", () => openDetail(target));
    list.append(card);
  });
  section.append(list); return section;
}

function stageBrowser(object) {
  const stages = [...new Set(object.variants.map(variant => variant.stage))];
  if (object.integration.declared_status !== "not_integrated") stages.push("integration");
  const browser = document.createElement("section"); browser.className = "stage-browser";
  const tabs = document.createElement("div"); tabs.className = "stage-tabs"; tabs.setAttribute("role", "tablist");
  const panel = document.createElement("div"); panel.className = "stage-panel";
  const preferred = stages.includes("asset") ? "asset" : stages[0];
  const show = stage => {
    tabs.querySelectorAll("button").forEach(button => {
      const active = button.dataset.stage === stage;
      button.classList.toggle("active", active); button.setAttribute("aria-selected", String(active));
    });
    panel.replaceChildren();
    if (stage === "integration") panel.append(integrationSection(object));
    else {
      const grid = document.createElement("div"); grid.className = "variant-grid";
      object.variants.filter(variant => variant.stage === stage).forEach(variant => grid.append(variantCard(variant)));
      panel.append(grid);
    }
  };
  stages.forEach(stage => {
    const button = document.createElement("button"); button.className = "stage-tab"; button.dataset.stage = stage; button.setAttribute("role", "tab");
    button.textContent = stage === "integration" ? "生效" : (stageLabels[stage] || stage);
    button.addEventListener("click", () => show(stage)); tabs.append(button);
  });
  browser.append(tabs, panel); show(preferred); return browser;
}

function openDetail(object) {
  state.selected = object.id; detailContent.replaceChildren();
  const kicker = document.createElement("p"); kicker.className = "detail-kicker"; kicker.textContent = `${object.category} · ${object.type}${object.subtype ? ` / ${object.subtype}` : ""}`;
  const title = document.createElement("h2"); title.id = "detail-title"; title.textContent = object.name;
  const lead = document.createElement("p"); lead.className = "detail-lead"; lead.textContent = `对象 ID：${object.id}。按阶段查看版本；文件类型由路径、.frames.json 与 Godot 资源自动识别。`;
  const legend = document.createElement("div"); legend.className = "state-legend";
  legend.innerHTML = "<span><strong>当前选用</strong>：当前流程选择的版本</span><span><strong>已批准</strong>：负责人认可的版本；选用不等于批准</span>";
  detailContent.append(kicker, title, lead, legend);
  object.warnings.forEach(message => { const warning = document.createElement("div"); warning.className = "warning"; warning.textContent = message; detailContent.append(warning); });
  detailContent.append(stageBrowser(object));
  const relations = relationshipSection(object); if (relations) detailContent.append(relations);
  detail.classList.add("open"); detail.setAttribute("aria-hidden", "false"); document.body.style.overflow = "hidden";
  detail.querySelector(".detail-sheet").scrollTop = 0;
}

function closeDetail() { detail.classList.remove("open"); detail.setAttribute("aria-hidden", "true"); document.body.style.overflow = ""; state.selected = null; }
function showOriginal(asset) { lightboxImage.src = fileUrl(asset); lightboxCaption.textContent = asset.manifest_path || asset.path; lightbox.showModal(); }

async function startPreview(preview, button) {
  button.disabled = true; setNotice("正在启动预览…");
  try {
    const payload = await api("/api/preview", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ asset_id: preview.asset_id, engine_path: engine.value.trim() }) });
    const target = payload.status.unit || payload.status.animation || "已登记目标";
    setNotice(`${payload.message} · ${target}`, "success");
  } catch (error) { setNotice(error.message, "error"); }
  finally { button.disabled = !preview.supported; }
}

async function scan() {
  scanButton.disabled = true; setNotice("正在读取 Manifest，并实时核对文件与 Godot 引用…");
  try {
    const payload = await api("/api/scan", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ manifest: manifest.value.trim() }) });
    state.objects = payload.objects; state.filter = "全部";
    summary.textContent = `${payload.summary.objects} 个对象 · ${payload.summary.files} 个登记文件 · ${payload.summary.mismatches} 处不一致`;
    renderFilters(); renderGrid();
    if (payload.errors.length || payload.summary.mismatches || payload.summary.missing) {
      const issues = [`${payload.summary.mismatches} 处不一致`, `${payload.summary.missing} 个缺失`];
      if (payload.errors.length) issues.push(payload.errors.map(item => `${item.path}：${item.message}`).join("；"));
      setNotice(`校验完成；${issues.join("；")}`, "error");
    } else setNotice(`校验完成：${payload.summary.objects} 个对象，文件与引用均有效。`, "success");
  } catch (error) { state.objects = []; renderFilters(); renderGrid(); setNotice(error.message, "error"); }
  finally { scanButton.disabled = false; }
}

document.getElementById("defaults").addEventListener("click", () => { manifest.value = boot.defaultManifest; });
scanButton.addEventListener("click", scan);
detail.querySelectorAll("[data-close]").forEach(node => node.addEventListener("click", closeDetail));
document.getElementById("lightbox-close").addEventListener("click", () => lightbox.close());
document.addEventListener("keydown", event => { if (event.key === "Escape" && detail.classList.contains("open") && !lightbox.open) closeDetail(); });
renderFilters(); scan();
