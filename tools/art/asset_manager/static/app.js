"use strict";

const boot = JSON.parse(document.getElementById("boot-data").textContent);
const state = { objects: [], filter: "全部", selected: null, detailView: null, history: [] };
const manifest = document.getElementById("manifest");
const manifestPicker = document.getElementById("pick-manifest");
const engine = document.getElementById("engine");
const scanButton = document.getElementById("scan");
const notice = document.getElementById("notice");
const grid = document.getElementById("grid");
const empty = document.getElementById("empty");
const filters = document.getElementById("filters");
const summary = document.getElementById("summary");
const detail = document.getElementById("detail");
const detailContent = document.getElementById("detail-content");
const detailBack = document.getElementById("detail-back");
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
const validationLabels = { matched: "校验通过", missing: "文件缺失", mismatch: "校验异常", unknown: "待校验" };

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

function godotPreviewPanel(variant) {
  const previews = variant.previews || [];
  const godot = previews.find(item => item.type === "godot");
  if (!godot) return null;
  const row = document.createElement("div"); row.className = "godot-preview";
  const button = document.createElement("button"); button.className = "preview"; button.textContent = "预览"; button.disabled = !godot.supported; button.title = godot.reason;
  button.addEventListener("click", () => startPreview(godot, button));
  const target = document.createElement("p"); target.className = `reason${godot.supported ? "" : " bad"}`;
  target.textContent = [godot.unit, godot.animation, godot.projectile].filter(Boolean).join(" · ") || godot.reason;
  row.append(button, target); return row;
}

function animationBrowser(variant) {
  const clips = variant.animation?.clips || [];
  if (!clips.length) return null;
  const gifPreviews = new Map((variant.previews || []).filter(item => item.type === "gif").map(item => [item.id, item]));
  const browser = document.createElement("div"); browser.className = "animation-browser";
  const list = document.createElement("div"); list.className = "animation-action-list";
  const stage = document.createElement("div"); stage.className = "animation-preview-stage";
  const buttons = [];
  const showClip = clip => {
    buttons.forEach(button => {
      const active = button.dataset.clipId === clip.id;
      button.classList.toggle("active", active); button.setAttribute("aria-pressed", String(active));
    });
    stage.replaceChildren();
    const preview = gifPreviews.get(clip.id);
    const asset = preview && variant.files.find(item => item.id === preview.file_id);
    const heading = document.createElement("strong"); heading.className = "animation-preview-name"; heading.textContent = clip.name || clip.id;
    stage.append(heading);
    if (asset && preview.supported) {
      const image = document.createElement("img"); image.src = fileUrl(asset); image.alt = `${clip.name || clip.id} GIF`; image.loading = "lazy"; stage.append(image);
    } else {
      const empty = document.createElement("p"); empty.className = "animation-preview-empty"; empty.textContent = "该动作暂无 GIF 预览。"; stage.append(empty);
    }
  };
  clips.forEach(clip => {
    const button = document.createElement("button"); button.type = "button"; button.className = "animation-action"; button.dataset.clipId = clip.id;
    const name = document.createElement("strong"); name.textContent = clip.name || clip.id;
    const facts = [];
    if (clip.frames !== undefined && clip.frames !== null) facts.push(`${clip.frames}帧`);
    if (clip.fps !== undefined && clip.fps !== null) facts.push(`${clip.fps} FPS`);
    if (clip.loop === true) facts.push("循环");
    const meta = document.createElement("span"); meta.textContent = facts.join(" · ") || "帧信息未记录";
    button.append(name, meta); button.addEventListener("click", () => showClip(clip)); buttons.push(button); list.append(button);
  });
  browser.append(list, stage);
  showClip(clips.find(clip => gifPreviews.get(clip.id)?.supported) || clips[0]);
  return browser;
}

function appendAssetList(panel, assets) {
  if (!assets.length) return false;
  const list = document.createElement("div"); list.className = "asset-list";
  assets.forEach(asset => list.append(assetCard(asset))); panel.append(list); return true;
}

function variantDetails(variant) {
  const details = document.createElement("div"); details.className = "variant-details";
  if (variant.approval_evidence?.source) {
    const evidence = document.createElement("p"); evidence.className = "evidence";
    evidence.textContent = `评审依据：${variant.approval_evidence.source}`;
    details.append(evidence);
  }

  const visibleFiles = variant.files.filter(item => item.role !== "preview_gif");
  const animationRoles = new Set(["animation_resource", "effect_resource", "projectile_resource"]);
  const pages = {
    atlas: visibleFiles.filter(item => item.role === "atlas"),
    animation: visibleFiles.filter(item => animationRoles.has(item.role)),
    other: visibleFiles.filter(item => item.role !== "atlas" && !animationRoles.has(item.role)),
  };
  const tabs = document.createElement("div"); tabs.className = "variant-tabs"; tabs.setAttribute("role", "tablist");
  const panel = document.createElement("div"); panel.className = "variant-panel";
  const showPage = page => {
    tabs.querySelectorAll("button").forEach(button => {
      const active = button.dataset.page === page;
      button.classList.toggle("active", active); button.setAttribute("aria-selected", String(active));
    });
    panel.replaceChildren(); let populated = false;
    if (page === "atlas") populated = appendAssetList(panel, pages.atlas);
    if (page === "animation") {
      populated = appendAssetList(panel, pages.animation);
      if (variant.animation) {
        const heading = document.createElement("h4"); heading.className = "subhead"; heading.textContent = variant.animation.label || "动作";
        panel.append(heading);
        const actionBrowser = animationBrowser(variant); if (actionBrowser) panel.append(actionBrowser);
        populated = true;
      }
      const preview = godotPreviewPanel(variant); if (preview) { panel.append(preview); populated = true; }
    }
    if (page === "other") {
      populated = appendAssetList(panel, pages.other);
      if (Object.keys(variant.metadata || {}).length) { panel.append(metadataList(variant.metadata)); populated = true; }
    }
    if (!populated) {
      const empty = document.createElement("p"); empty.className = "subpage-empty"; empty.textContent = `这个版本暂无${page === "atlas" ? "图集" : page === "animation" ? "动画" : "其他文件"}。`; panel.append(empty);
    }
  };
  [["atlas", "图集"], ["animation", "动画"], ["other", "其他"]].forEach(([page, label]) => {
    const button = document.createElement("button"); button.className = "variant-tab"; button.dataset.page = page; button.setAttribute("role", "tab"); button.textContent = label;
    button.addEventListener("click", () => showPage(page)); tabs.append(button);
  });
  details.append(tabs, panel);
  const preferred = pages.atlas.length ? "atlas" : (variant.animation || pages.animation.length || variant.previews.length ? "animation" : "other");
  showPage(preferred); return details;
}

function variantCard(object, variant, expanded = false) {
  const section = document.createElement("article"); section.className = "variant-card"; section.dataset.variantId = variant.id;
  const toggle = document.createElement("button"); toggle.className = "variant-summary"; toggle.type = "button"; toggle.setAttribute("aria-expanded", String(expanded));
  const thumb = document.createElement("div"); thumb.className = "variant-thumb";
  const thumbAsset = variant.files.find(item => item.id === variant.summary.thumbnail_id);
  if (thumbAsset) {
    const image = document.createElement("img"); image.src = fileUrl(thumbAsset); image.alt = `${object.name} ${variant.version} 缩略图`; image.loading = "lazy"; thumb.append(image);
  } else { const placeholder = document.createElement("span"); placeholder.textContent = "◇"; thumb.append(placeholder); }
  const copy = document.createElement("div"); copy.className = "variant-copy";
  const top = document.createElement("div"); top.className = "variant-summary-top";
  const title = document.createElement("h3"); title.textContent = object.name;
  const version = document.createElement("strong"); version.textContent = `版本 ${variant.version}`;
  const badges = document.createElement("div"); badges.className = "summary-badges";
  const selected = document.createElement("span"); selected.className = `state-badge state-${variant.selection}`; selected.textContent = selectionLabels[variant.selection] || variant.selection;
  selected.title = "选用状态：当前制作或接入流程选择的是哪一个版本。";
  const approved = document.createElement("span"); approved.className = `state-badge state-${variant.approval}`; approved.textContent = approvalLabels[variant.approval] || variant.approval;
  approved.title = "批准状态：负责人是否认可这个具体版本。选用不等于批准。";
  const validationStatus = variant.summary.validation_status;
  const validation = document.createElement("span"); validation.className = `validation-badge validation-${validationStatus}`; validation.textContent = variant.summary.validation_label || validationLabels[validationStatus] || validationStatus;
  validation.title = "校验状态：管理器根据登记文件与 Godot 引用实时计算，不是 Manifest 字段。";
  badges.append(selected, approved, validation); top.append(title, version, badges);
  const root = document.createElement("code"); root.className = "variant-root"; root.textContent = variant.root;
  const facts = document.createElement("div"); facts.className = "variant-facts";
  [`日期 ${variant.summary.date}`, `${variant.summary.images} 张图片`, `${variant.summary.animations} 个动画`].forEach(text => { const span = document.createElement("span"); span.textContent = text; facts.append(span); });
  copy.append(top, root, facts);
  const chevron = document.createElement("span"); chevron.className = "variant-chevron"; chevron.textContent = "展开";
  toggle.append(thumb, copy, chevron);
  const body = variantDetails(variant); body.hidden = !expanded;
  const setExpanded = value => { body.hidden = !value; section.classList.toggle("expanded", value); toggle.setAttribute("aria-expanded", String(value)); chevron.textContent = value ? "收起" : "展开"; if (value && state.detailView) state.detailView.variantId = variant.id; };
  toggle.addEventListener("click", () => setExpanded(toggle.getAttribute("aria-expanded") !== "true"));
  section.append(toggle, body); setExpanded(expanded); return section;
}

function integrationSection(object) {
  const integration = object.integration;
  const section = document.createElement("section"); section.className = "asset-section integration-section";
  const heading = document.createElement("h3"); heading.textContent = `实际生效 · ${integrationLabels[integration.verified_status] || integration.verified_status}`; section.append(heading);
  const lead = document.createElement("p"); lead.className = "evidence";
  lead.textContent = `声明：${integration.declared_status} · 所有者：${integration.owner_resource || "未登记"}`; section.append(lead);
  const active = object.variants.find(variant => variant.id === integration.active_variant);
  if (active) {
    const jump = document.createElement("button"); jump.className = "integration-jump"; jump.textContent = `${object.name} · 版本 ${active.version}`;
    jump.title = "前往资产版本"; jump.addEventListener("click", () => navigateDetail(object, { stage: "asset", variantId: active.id })); section.append(jump);
  }
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
    } else { const placeholder = document.createElement("span"); placeholder.textContent = "◇"; thumb.append(placeholder); }
    const copy = document.createElement("div");
    const kind = document.createElement("span"); kind.className = "relationship-kind"; kind.textContent = relation.kind === "projectile" ? "弹体" : relation.kind;
    const name = document.createElement("strong"); name.textContent = relation.target_name || relation.object_id;
    const status = document.createElement("small"); status.textContent = target ? "打开详情 →" : relation.status_label;
    copy.append(kind, name, status); card.append(thumb, copy);
    if (target) card.addEventListener("click", () => navigateDetail(target, { stage: target.variants.some(item => item.stage === "asset") ? "asset" : target.variants[0]?.stage }));
    list.append(card);
  });
  section.append(list); return section;
}

function filterControl(label, options, value, changed) {
  const field = document.createElement("label"); field.className = "variant-filter";
  const text = document.createElement("span"); text.textContent = label;
  const select = document.createElement("select"); select.setAttribute("aria-label", label);
  options.forEach(([key, name]) => { const option = document.createElement("option"); option.value = key; option.textContent = name; option.selected = key === value; select.append(option); });
  select.addEventListener("change", () => changed(select.value)); field.append(text, select); return field;
}

function stageBrowser(object, options = {}) {
  const stages = [...new Set(object.variants.map(variant => variant.stage))];
  if (object.integration.declared_status !== "not_integrated") stages.push("integration");
  const browser = document.createElement("section"); browser.className = "stage-browser";
  const tabs = document.createElement("div"); tabs.className = "stage-tabs"; tabs.setAttribute("role", "tablist");
  const panel = document.createElement("div"); panel.className = "stage-panel";
  const filtersByStage = { concept: { selection: "all", approval: "all" }, asset: { selection: "all", approval: "all" } };
  const renderVariants = (stage, focusVariantId = null) => {
    panel.replaceChildren(); const selectedFilters = filtersByStage[stage];
    let variants = object.variants.filter(variant => variant.stage === stage);
    if (selectedFilters) {
      const controls = document.createElement("div"); controls.className = "variant-filters";
      controls.append(
        filterControl("是否选用", [["all", "全部"], ["selected", "当前选用"], ["unselected", "未选用"], ["unknown", "未记录"]], selectedFilters.selection, value => { selectedFilters.selection = value; renderVariants(stage); }),
        filterControl("是否批准", [["all", "全部"], ["approved", "已批准"], ["review", "待评审"], ["rejected", "已否决"], ["unknown", "未记录"]], selectedFilters.approval, value => { selectedFilters.approval = value; renderVariants(stage); })
      ); panel.append(controls);
      variants = variants.filter(variant => selectedFilters.selection === "all" || variant.selection === selectedFilters.selection);
      variants = variants.filter(variant => selectedFilters.approval === "all" || (selectedFilters.approval === "review" ? ["review", "pending"].includes(variant.approval) : variant.approval === selectedFilters.approval));
    }
    const list = document.createElement("div"); list.className = "variant-list";
    variants.forEach(variant => list.append(variantCard(object, variant, variant.id === focusVariantId))); panel.append(list);
    if (!variants.length) { const empty = document.createElement("p"); empty.className = "subpage-empty"; empty.textContent = "没有符合条件的版本。"; panel.append(empty); }
    state.detailView = { objectId: object.id, stage, variantId: focusVariantId };
    if (focusVariantId) requestAnimationFrame(() => panel.querySelector(`[data-variant-id="${CSS.escape(focusVariantId)}"]`)?.scrollIntoView({ block: "start" }));
  };
  const show = (stage, focusVariantId = null) => {
    tabs.querySelectorAll("button").forEach(button => { const active = button.dataset.stage === stage; button.classList.toggle("active", active); button.setAttribute("aria-selected", String(active)); });
    panel.replaceChildren();
    if (stage === "integration") { state.detailView = { objectId: object.id, stage, variantId: null }; panel.append(integrationSection(object)); }
    else renderVariants(stage, focusVariantId);
  };
  stages.forEach(stage => {
    const button = document.createElement("button"); button.className = "stage-tab"; button.dataset.stage = stage; button.setAttribute("role", "tab");
    button.textContent = stage === "integration" ? "生效" : (stageLabels[stage] || stage);
    button.addEventListener("click", () => show(stage)); tabs.append(button);
  });
  browser.append(tabs, panel);
  const preferred = stages.includes(options.stage) ? options.stage : (stages.includes("asset") ? "asset" : stages[0]);
  show(preferred, options.variantId || null); return browser;
}

function openDetail(object, options = {}) {
  if (!options.preserveHistory) state.history = [];
  state.selected = object.id; detailContent.replaceChildren(); detailBack.hidden = state.history.length === 0;
  const kicker = document.createElement("p"); kicker.className = "detail-kicker"; kicker.textContent = `${object.category} · ${object.type}${object.subtype ? ` / ${object.subtype}` : ""}`;
  const title = document.createElement("h2"); title.id = "detail-title"; title.textContent = object.name;
  const lead = document.createElement("p"); lead.className = "detail-lead"; lead.textContent = `对象 ID：${object.id}。版本默认折叠，校验、选用与批准状态分别显示。`;
  const legend = document.createElement("div"); legend.className = "state-legend";
  legend.innerHTML = "<span><strong>校验</strong>：文件与 Godot 引用的实时结果（非 Manifest 字段）</span><span><strong>选用</strong>：当前流程选择的版本</span><span><strong>批准</strong>：负责人认可的版本</span>";
  detailContent.append(kicker, title, lead, legend);
  object.warnings.forEach(message => { const warning = document.createElement("div"); warning.className = "warning"; warning.textContent = message; detailContent.append(warning); });
  detailContent.append(stageBrowser(object, options));
  const relations = relationshipSection(object); if (relations) detailContent.append(relations);
  detail.classList.add("open"); detail.setAttribute("aria-hidden", "false"); document.body.style.overflow = "hidden";
  if (!options.variantId) detail.querySelector(".detail-sheet").scrollTop = 0;
}

function navigateDetail(object, options = {}) {
  if (state.detailView) state.history.push(Object.assign({}, state.detailView));
  openDetail(object, Object.assign({}, options, { preserveHistory: true }));
}

function returnDetail() {
  const previous = state.history.pop(); if (!previous) return;
  const object = state.objects.find(item => item.id === previous.objectId); if (!object) return;
  openDetail(object, { stage: previous.stage, variantId: previous.variantId, preserveHistory: true });
}

function closeDetail() { detail.classList.remove("open"); detail.setAttribute("aria-hidden", "true"); document.body.style.overflow = ""; state.selected = null; state.detailView = null; state.history = []; }
function showOriginal(asset) { lightboxImage.src = fileUrl(asset); lightboxCaption.textContent = asset.manifest_path || asset.path; lightbox.showModal(); }

async function startPreview(preview, button) {
  button.disabled = true; setNotice("正在导入资源并准备预览…");
  try {
    const payload = await api("/api/preview", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ asset_id: preview.asset_id, engine_path: engine.value.trim() }) });
    const target = payload.status.unit || payload.status.animation || "已登记目标";
    setNotice(`${payload.message} · ${target}`, "success");
  } catch (error) { setNotice(error.message, "error"); }
  finally { button.disabled = !preview.supported; }
}

async function chooseManifest() {
  manifestPicker.disabled = true; setNotice("正在打开文件选择器…");
  try {
    const payload = await api("/api/pick-manifest", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ initial: manifest.value.trim() }) });
    if (payload.selected && payload.path) { manifest.value = payload.path; await scan(); }
    else setNotice("未更改 Manifest。", "");
  } catch (error) { setNotice(error.message, "error"); }
  finally { manifestPicker.disabled = false; }
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
manifestPicker.addEventListener("click", chooseManifest);
scanButton.addEventListener("click", scan);
detailBack.addEventListener("click", returnDetail);
detail.querySelectorAll("[data-close]").forEach(node => node.addEventListener("click", closeDetail));
document.getElementById("lightbox-close").addEventListener("click", () => lightbox.close());
document.addEventListener("keydown", event => { if (event.key === "Escape" && detail.classList.contains("open") && !lightbox.open) closeDetail(); });
renderFilters(); scan();
