import {clone, screenToMap} from './editor-core.mjs';
import {effectOptions, validateDispatch} from './dispatch-core.mjs';
const $ = id => document.getElementById(id), canvas = $('overlay'), ctx = canvas.getContext('2d');
const size = [1600,900]; let data, baseline, revision, saved, outside = true, selected = 'qingshuihe', taskId = '', scale = 1, drag = null, history = [], future = [];
const kindNames = {feature:'功能',preparation:'准备池',character:'人物',item:'物品池',buff:'规则效果'};
const valueNames = {preparation:'出发准备',shield:'应急护盾',revive:'复苏装置',inventor:'发明家',reward_refresh:'奖励刷新'};
const snap = () => JSON.stringify(data), place = () => data.places.find(p => p.id === selected), task = () => data.commissions.find(t => t.id === taskId);
function message(text, error=false){$('message').textContent=text;$('message').classList.toggle('error',error);}
function options(select, entries, value){select.replaceChildren(...entries.map(([id,name])=>{const o=document.createElement('option');o.value=id;o.textContent=name;return o;}));select.value=value;}
function changed(before){if(before!==snap()){history.push(before);future=[];} update();}
function update(){
 const choices=data.places.filter(p=>p.outside===outside);if(!choices.some(p=>p.id===selected))selected=choices[0]?.id||'';
 options($('place-select'),choices.map(p=>[p.id,p.name]),selected);
 const p=place();$('place-name').value=p?.name||'';$('place-x').value=p?.point[0]??'';$('place-y').value=p?.point[1]??'';
 $('delete-place').disabled=!p||['library','qingshuihe'].includes(selected)||data.commissions.some(t=>t.location===selected);
 const tasks=data.commissions.filter(t=>t.location===selected);if(!tasks.some(t=>t.id===taskId))taskId=tasks[0]?.id||'';
 options($('task-select'),tasks.map(t=>[t.id,t.name+(t.enabled===false?'（停用）':'')]),taskId);
 $('task-fields').hidden=!task();if(task()){
  const t=task();$('task-name').value=t.name;$('task-description').value=t.description;$('task-cost').value=t.cost;$('task-enabled').checked=t.enabled!==false;
  options($('task-location'),data.places.filter(p=>p.id!=='qingshuihe').map(p=>[p.id,p.name]),t.location);
  options($('task-requires'),[['','无'],...data.commissions.filter(v=>v.id!==t.id).map(v=>[v.id,v.name])],t.requires);
  for(const id of ['task-cost','task-location','task-requires','task-enabled'])$(id).disabled=t.id==='departure';
  $('task-effect').textContent=`${kindNames[t.kind]} · ${valueNames[t.value]} · ID: ${t.id}`;
 }
 $('dirty').textContent=snap()===saved?'已同步':'未保存';$('save').disabled=snap()===saved;$('undo').disabled=!history.length;$('redo').disabled=!future.length;
 $('campus').classList.toggle('active',!outside);$('city').classList.toggle('active',outside);draw();
}
function draw(){ctx.clearRect(0,0,...size);if(!data)return;
 for(const label of data.maps[outside?'city':'campus'].labels||[]){const [x,y]=label.point.map((n,i)=>n*size[i]);ctx.font=`${14/scale}px sans-serif`;ctx.lineWidth=4/scale;ctx.strokeStyle='#fff';ctx.strokeText(label.title,x,y);ctx.fillStyle='#304651';ctx.fillText(label.title,x,y);}
 for(const p of data.places.filter(p=>p.outside===outside)){
  const [x,y]=p.point.map((n,i)=>n*size[i]);ctx.beginPath();ctx.arc(x,y,9/scale,0,Math.PI*2);ctx.fillStyle=p.id===selected?'#ee9844':'#1b8b9d';ctx.fill();ctx.strokeStyle='#fff';ctx.lineWidth=2/scale;ctx.stroke();
  ctx.font=`${14/scale}px sans-serif`;const w=ctx.measureText(p.name).width+12/scale;const tx=Math.min(size[0]-w,Math.max(0,x+12/scale));ctx.fillStyle='#ffffffed';ctx.fillRect(tx,y-13/scale,w,24/scale);ctx.fillStyle='#163946';ctx.fillText(p.name,tx+6/scale,y+4/scale);
 }
}
function setScale(value){scale=Math.max(.15,Math.min(3,value));$('stage').style.width=`${size[0]*scale}px`;$('stage').style.height=`${size[1]*scale}px`;canvas.width=size[0];canvas.height=size[1];$('zoom-value').textContent=Math.round(scale*100)+'%';draw();}
function fit(){setScale(Math.min(($('viewport').clientWidth-30)/size[0],($('viewport').clientHeight-30)/size[1]));}
function setMap(city){outside=city;$('map-image').onload=()=>{size[1]=Math.round(size[0]*$('map-image').naturalHeight/$('map-image').naturalWidth);fit();};$('map-image').src='/api/dispatch-image?map='+(outside?'city':'campus');update();fit();}
function edit(fn){const before=snap();fn();changed(before);}
function validEdit(fn){const before=snap();fn();const errors=validateDispatch(data,baseline);if(errors.length){data=JSON.parse(before);message(errors.join('；'),true);update();return;}changed(before);message('修改尚未保存');}
for(const [id,key] of [['place-name','name'],['place-x',0],['place-y',1]])$(id).addEventListener('change',()=>validEdit(()=>{if(typeof key==='number')place().point[key]=Number($(id).value);else place()[key]=$(id).value.trim();}));
for(const [id,key] of [['task-name','name'],['task-description','description'],['task-cost','cost'],['task-location','location'],['task-requires','requires'],['task-enabled','enabled']])$(id).addEventListener('change',()=>validEdit(()=>{task()[key]=key==='cost'?Number($(id).value):key==='enabled'?$(id).checked:$(id).value;}));
$('place-select').onchange=()=>{selected=$('place-select').value;taskId='';update();};$('task-select').onchange=()=>{taskId=$('task-select').value;update();};
$('campus').onclick=()=>setMap(false);$('city').onclick=()=>setMap(true);$('fit').onclick=fit;$('plus').onclick=()=>setScale(scale*1.2);$('minus').onclick=()=>setScale(scale/1.2);
canvas.addEventListener('wheel',event=>{event.preventDefault();setScale(scale*(event.deltaY<0?1.1:1/1.1));},{passive:false});
const at = event=>screenToMap([event.clientX,event.clientY],canvas.getBoundingClientRect(),size);
canvas.onpointerdown=event=>{const point=at(event);const found=data.places.filter(p=>p.outside===outside).map(p=>({p,d:Math.hypot(p.point[0]*size[0]-point[0],p.point[1]*size[1]-point[1])})).sort((a,b)=>a.d-b.d)[0];if(found&&found.d<24/scale){selected=found.p.id;drag={before:snap(),id:selected};canvas.setPointerCapture(event.pointerId);update();}};
canvas.onpointermove=event=>{if(!drag)return;place().point=at(event).map((n,i)=>Math.round(n/size[i]*10000)/10000);draw();};
canvas.onpointerup=()=>{if(drag){const before=drag.before;drag=null;changed(before);}};canvas.onpointercancel=()=>{if(drag){data=JSON.parse(drag.before);drag=null;update();}};
$('add-place').onclick=()=>validEdit(()=>{const id=$('new-place-id').value.trim();data.places.push({id,name:$('new-place-name').value.trim(),point:[.5,.5],outside});selected=id;});
$('delete-place').onclick=()=>validEdit(()=>{data.places=data.places.filter(p=>p.id!==selected);selected='';});
options($('new-task-kind'),Object.entries(kindNames),'item');
function updateValues(){options($('new-task-value'),effectOptions[$('new-task-kind').value].map(v=>[v,valueNames[v]]),effectOptions[$('new-task-kind').value][0]);}
$('new-task-kind').onchange=updateValues;updateValues();
$('add-task').onclick=()=>validEdit(()=>{const id=$('new-task-id').value.trim();data.commissions.push({id,name:$('new-task-name').value.trim(),description:'请填写委托说明。',cost:1,location:selected,requires:'departure',kind:$('new-task-kind').value,value:$('new-task-value').value,enabled:true});taskId=id;});
$('undo').onclick=()=>{if(history.length){future.push(snap());data=JSON.parse(history.pop());update();}};$('redo').onclick=()=>{if(future.length){history.push(snap());data=JSON.parse(future.pop());update();}};
$('save').onclick=async()=>{try{const errors=validateDispatch(data,baseline);if(errors.length)throw Error(errors.join('；'));const body=snap();$('save').disabled=true;const response=await fetch('/api/dispatch',{method:'POST',headers:{'Content-Type':'application/json','If-Match':revision},body});if(!response.ok)throw Error((await response.json()).error);revision=response.headers.get('etag');saved=body;baseline=JSON.parse(body);message('已保存；重新打开游戏即可读取地点与委托');}catch(error){message(error.message,true);}finally{update();}};
$('export').onclick=()=>{const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([JSON.stringify(data,null,2)+'\n'],{type:'application/json'}));a.download='dispatch_map.json';a.click();setTimeout(()=>URL.revokeObjectURL(a.href),500);};
$('import').onclick=()=>$('file').click();$('file').onchange=async()=>{try{const candidate=JSON.parse(await $('file').files[0].text());const errors=validateDispatch(candidate,baseline);if(errors.length)throw Error(errors.join('；'));edit(()=>{data=clone(candidate);});setMap(outside);message('已导入；保存后才会写入游戏');}catch(error){message(error.message,true);}$('file').value='';};
window.addEventListener('beforeunload',event=>{if(data&&snap()!==saved){event.preventDefault();event.returnValue='';}});window.addEventListener('resize',fit);
try{const response=await fetch('/api/dispatch');if(!response.ok)throw Error((await response.json()).error);data=await response.json();const errors=validateDispatch(data);if(errors.length)throw Error(errors.join('；'));baseline=clone(data);revision=response.headers.get('etag');saved=snap();setMap(true);message('选择地点，拖动标记；右侧编辑委托。保存前可撤销。');}catch(error){message(error.message,true);}
