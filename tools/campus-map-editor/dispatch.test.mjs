import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir,mkdtemp,readdir,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
import {validateDispatch} from './dispatch-core.mjs';
const source=JSON.parse(await readFile(new URL('../../game/meta/dispatch_map.json',import.meta.url),'utf8'));
test('current dispatch catalog validates',()=>assert.deepEqual(validateDispatch(source),[]));
test('invalid coordinates, references, cycles and unsupported effects are rejected',()=>{
 for(const change of [d=>d.places[0].point=[2,0],d=>d.places.push({...d.places[0]}),d=>d.commissions[1].location='missing',d=>d.commissions[1].requires=d.commissions[1].id,d=>d.commissions[1].value='unknown',d=>d.commissions[0].cost=1,d=>d.commissions[0].enabled=false,d=>d.maps.city.labels=[null],d=>d.places.push(null)]){const d=structuredClone(source);change(d);assert.ok(validateDispatch(d).length);}
});
test('saved IDs and effects survive edits; disabling and relocating are allowed',()=>{
 let d=structuredClone(source);d.commissions.pop();assert.ok(validateDispatch(d,source).length);
 d=structuredClone(source);d.commissions[1].value='revive';assert.ok(validateDispatch(d,source).length);
 d=structuredClone(source);d.commissions[1].enabled=false;d.commissions[1].location='chunxi';assert.deepEqual(validateDispatch(d,source),[]);
});
test('new supported content validates without changing registered rewards',()=>{
 const d=structuredClone(source);d.places.push({id:'museum',name:'博物馆',outside:true,point:[.5,.5]});d.commissions.push({id:'museum_supply',name:'物资联络',description:'测试',location:'museum',cost:2,requires:'departure',kind:'item',value:'shield'});assert.deepEqual(validateDispatch(d,source),[]);
});
test('API persists dispatch content, backs up, rejects concurrent overwrite and missing textures',async()=>{
 const root=await mkdtemp(resolve(tmpdir(),'dispatch-editor-test-'));const path=resolve(root,'game/meta/dispatch_map.json');await mkdir(dirname(path),{recursive:true});await writeFile(path,JSON.stringify(source));
 for(const map of Object.values(source.maps)){const image=resolve(root,map.texture.slice(6));await mkdir(dirname(image),{recursive:true});await writeFile(image,'fixture');}
 const child=spawn(process.execPath,[fileURLToPath(new URL('./server.mjs',import.meta.url))],{env:{...process.env,NODE_ENV:'test',CAMPUS_MAP_EDITOR_ROOT:root,CAMPUS_MAP_EDITOR_PORT:'0'},stdio:['ignore','pipe','pipe']});
 try{
  const address=await new Promise((done,fail)=>{const timer=setTimeout(()=>fail(Error('server startup timeout')),5000);child.stdout.on('data',c=>{const m=String(c).match(/http:\/\/127\.0\.0\.1:\d+\//);if(m){clearTimeout(timer);done(m[0]);}});child.on('error',fail);});
  const url=address+'api/dispatch', loaded=await fetch(url),data=await loaded.json(),tag=loaded.headers.get('etag');
  const post=(d,t)=>fetch(url,{method:'POST',headers:{'Content-Type':'application/json','If-Match':t},body:JSON.stringify(d)});
  data.places[2].point=[.24,.20];data.commissions[1].name='器材联络';
  const replies=await Promise.all([post(data,tag),post(data,tag)]);assert.deepEqual(replies.map(r=>r.status).sort(),[200,409]);assert.deepEqual(JSON.parse(await readFile(path,'utf8')),data);
  assert.equal((await readdir(resolve(root,'.godot/campus-map-editor-backups'))).length,1);
  const current=await fetch(url);data.maps.city.texture='res://assets/art/missing.png';assert.equal((await post(data,current.headers.get('etag'))).status,400);
  assert.equal((await fetch(address+'dispatch')).status,200);assert.equal((await fetch(address+'api/dispatch-image?map=city')).status,200);
 }finally{child.kill();await new Promise(resolve=>child.once('exit',resolve));await rm(root,{recursive:true,force:true,maxRetries:5,retryDelay:100});}
});
