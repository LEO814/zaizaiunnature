-- Native whitebox acceptance Demo. Assembly belongs to program; object logic stays in packages.
local Config=require('gameplay.core.config')
local Registry=require('gameplay.registry')
local Factories=require('gameplay.package_factories')
local Adapter=require('gameplay.adapters.zaizai.adapter')
local Bootstrap=require('gameplay.bootstrap')
local Map=require('gameplay.packages.environment.map_demo.definition')
local Match=require('gameplay.systems.match.controller')
local Setup=require('gameplay.systems.round_setup.controller')
local Settlement=require('gameplay.systems.settlement.controller')
local Bag=require('gameplay.systems.inventory_meta.controller')
local UI=require('gameplay.packages.ui.ui_main.controller')
local Spatial=require('gameplay.core.spatial')
local Demo={};Demo.__index=Demo
local function copy(t)local out={};for k,v in pairs(t or{})do out[k]=type(v)=='table'and copy(v)or v end;return out end
local function profile(go,name)
 local ok,value=pcall(function()
  if not go then error('model not loaded: '..name)end
  local s=go:GetDouyinScript(name)
  if not s or not s.script or not s.script.GetProfile then error('profile script not ready: '..name)end
  return s.script.GetProfile()
 end)
 if ok and type(value)=='table'then return value end
 return nil,ok and('profile returned '..type(value))or tostring(value)
end
local function atan2(y,x)
 if x>0 then return math.atan(y/x)elseif x<0 then return math.atan(y/x)+(y>=0 and math.pi or -math.pi)elseif y>0 then return math.pi/2 elseif y<0 then return -math.pi/2 else return 0 end
end
local function number(value,default,min,max)
 local n=tonumber(value);if not n or n~=n or n<min or n>max then return default end;return n
end
local function merge_numbers(target,source,limits)
 for key,limit in pairs(limits)do if source and source[key]~=nil then target[key]=number(source[key],target[key],limit[1],limit[2])end end
end
function Demo.new(host)return setmetatable({host=host,started=false,sequence=0,objects={},qa_results={}},Demo)end
function Demo:log(message)CS.UnityEngine.Debug.Log('[ZZ_DEMO] '..message)end
function Demo:start()
 if self.started then return true end
 local U=CS.UnityEngine
 if not CS.DouyinActorService.GetLocalActor()then self.pending=true;return false end
 local p,pe=profile(U.GameObject.Find('player_default'),'player_attributes.lua')
 local m,me=profile(U.GameObject.Find('monster_inkwave_actor'),'monster_attributes.lua')
 local session,se=profile(self.host,'match_attributes.lua')
 if not p or not m or not session then
  self.pending=true;self.profile_attempts=(self.profile_attempts or 0)+1
  if self.profile_attempts>=120 then error('Inspector profile loading failed: '..tostring(pe)..' / '..tostring(me)..' / '..tostring(se))end
  return false
 end
 self.inspector_profiles_ready=true
 local config=copy(Config);config.projectName='仔仔搜打撤1.0';config.state='inkwave_monster_demo'
 local definitions={};for id,factory in pairs(Factories)do definitions[id]=copy(factory.definition)end
 merge_numbers(config.player,p.player,{maxHp={1,500},startHp={1,500},walkSpeedMps={.1,12},sprintSpeedMps={.1,15},crouchSpeedMps={.1,8},jumpHeightM={0,3},colliderRadiusM={.1,1},colliderHeightM={.5,3},colliderCenterY_M={0,2},spawnProtectionSec={0,15},hitInvulnerabilitySec={0,3}})
 config.player.startHp=math.min(config.player.maxHp,config.player.startHp)
 config.player.colliderHeightM=math.max(config.player.colliderHeightM,2*config.player.colliderRadiusM)
 merge_numbers(config.inventory,p.inventory,{bagSlots={1,48}});config.inventory.bagSlots=math.floor(config.inventory.bagSlots)
 merge_numbers(config.interaction,p.interaction,{maxDistanceM={.5,5}})
 local d=definitions.monster_inkwave
 merge_numbers(d,m,{maxHp={1,10000},patrolSpeedMps={.1,15},chaseSpeedMps={.1,20},patrolWaitSec={0,10},arriveDistanceM={.05,2},pathRefreshSec={.05,5},pathFailureRetrySec={.05,10},patrolUnreachableSkipSec={.1,30},leashRadiusM={1,100},hurtPauseSec={0,5}})
 merge_numbers(d.sense,m.sense,{rangeM={.1,50},fullAngleDeg={1,360},loseSightGraceSec={0,10},searchSec={0,30}})
 merge_numbers(d.attacks[1],m.attacks and m.attacks[1],{damageHp={0,1000},windupSec={0,10},activeSec={.05,5},recoverySec={0,10},cooldownSec={.05,30},rangeM={.1,15},arcDeg={1,360}})
 local attack=d.attacks[1];attack.cooldownSec=math.max(attack.cooldownSec,attack.windupSec+attack.activeSec+attack.recoverySec)
 merge_numbers(config.session,session,{roundDurationSec={30,3600},extractionHoldSec={.5,15}})
 self.config=config;self.definitions=definitions
 self.adapter=Adapter.new({host=self.host,config=config,definitions=definitions,map=Map,registry=Registry})
 local ctx=Bootstrap.create(self.adapter);ctx.config=config;ctx.definitions=definitions;ctx.state=self.adapter.state;ctx.demo=self;ctx.map_entity_id='map_demo'
 function ctx:next_request_id(prefix)self.request_sequence=(self.request_sequence or 0)+1;return self.state.run_id..':'..prefix..':'..self.request_sequence end
 ctx.monster_instance_id='monster_inkwave_1';ctx.monster_entity_id='monster_inkwave'
 self.context=ctx;self.match=Match.new(ctx);self.settlement=Settlement.new(ctx)
 local proxy=U.GameObject.Find('player_default');if proxy then
  local renderer=proxy:GetComponent(typeof(U.Renderer));if renderer then renderer.enabled=false end
  local collider=proxy:GetComponent(typeof(U.Collider));if collider then collider.enabled=false end
 end
 self.started=true;self.pending=false;self:begin_round();self:make_vision();self:log('READY config=0.2.0 roles=0.3.0 map=4rooms local_single_player');return true
end
function Demo:begin_round()
 if self.setup then self.setup:dispose()end
 if self.bag then self.bag:dispose()end
 if self.ui then self.ui:dispose()end
 self.adapter.state.ui_view=nil;self.next_vision_at=0
 local result=self.match:start();if not result.ok then error('match_start:'..tostring(result.reason))end
 self.setup=Setup.new(self.context);self.objects=self.setup:start(Map)
 self.bag=Bag.new(self.context,{heal=self.objects.heal});assert(self.bag:start())
 self.ui=UI.new(self.context,function(action,item)return self:dispatch(action,item)end);self.adapter.ui=self.ui;self.ui:start()
 self.adapter.services.Assets:play_clip(self:request('reset_chest',{instance_id='chest_demo',native_action='chest_close',clip_id='native_idle'}))
 self.context.state.toast='Demo 已就绪 · 前往黄色宝箱，绿色区域为撤离点'
end
function Demo:request(prefix,fields)fields=fields or{};fields.run_id=self.context.state.run_id;fields.request_id=self.context:next_request_id(prefix);return fields end
function Demo:message(result)
 local messages={FULL_HEALTH='当前满血，无需用药',CAST_STARTED='开始用药，请保持静止',OUT_OF_RANGE_OR_BLOCKED='距离过远或有墙体遮挡',COOLDOWN='动作冷却中',ITEM_NOT_OWNED='背包中没有这个道具',NO_USE_HANDLER='该物品是藏品 / 武器',EXTRACTION_STARTED='开始撤离读条',INVALID_PHASE='当前阶段不能执行',USE_IN_PROGRESS='正在使用道具'}
 self.context.state.toast=messages[result and result.reason]or(result and result.ok and'操作成功'or'操作失败：'..tostring(result and result.reason));return result
end
function Demo:close_view()
 self.objects.chest:close();self.adapter.services.UI:close_view(self:request('ui_close'))
end
function Demo:dispatch(action,item)
 if not self.started then return end
 local s=self.context.state;local svc=self.context.services
 if action=='qa'then return self:start_qa()end
 if action=='restart'then self.qa=nil;self.qa_summary=nil;self:begin_round();return end
 if action=='close'then self:close_view();return end
 if action=='attributes'then svc.UI:open_view(self:request('attributes',{view_id='attributes'}));return end
 if action=='bag'then if s.ui_view then self:close_view()else svc.UI:open_view(self:request('bag',{view_id='bag'}))end;return end
 if s.phase=='FINISHED'then return end
 if action=='pickup'then local result=self.objects.chest:pickup(item,1);self:message(result);self.ui:refresh_modal();return result end
 if action=='take_all'then
  local contents=self.objects.chest:read_contents();for _,entry in ipairs(contents.data.bag.items or{})do self:message(self.objects.chest:pickup(entry.id,entry.count))end
  self.ui:refresh_modal();return
 end
 if action=='use_item'then local result=self.bag:use_item(item);self:message(result);if result.ok then self:close_view()end;return result end
 if s.ui_view then s.toast='请先关闭面板';return end
 if action=='attack'then return self:message(self.objects.shovel:use({target_instance_id='monster_inkwave_1'}))end
 if action=='heal'then
  local bag=self.bag:read_bag().data.bag
  for _,entry in ipairs(bag.items)do if entry.entity_id=='item_heal_small'then return self:message(self.bag:use_item(entry.id))end end
  s.toast='先从宝箱取得药品';return
 end
 if action=='interact'then
  local pos=self.adapter:position('player_local');local chestdist=Spatial.distance(pos,Map.chest);local exitdist=Spatial.distance(pos,Map.exit)
  if exitdist<=self.config.interaction.maxDistanceM and exitdist<chestdist then return self:message(svc.Session:try_extract(self:request('extract',{user_instance_id='player_local',exit_instance_id='exit_demo'})))end
  local r=self.objects.chest:open('player_local');if r.ok then svc.UI:open_view(self:request('chest_view',{view_id='chest',container_id='chest_demo'}))end;return self:message(r)
 end
end
function Demo:make_vision()
 local U=self.adapter.U;local go=U.GameObject('demo_monster_vision');go.transform:SetParent(self.adapter.runtime_root.transform,false)
 self.vision=go:AddComponent(typeof(U.LineRenderer));self.vision.material=U.Material(U.Shader.Find('Sprites/Default'));self.vision.startWidth=.045;self.vision.endWidth=.045;self.vision.useWorldSpace=true
 self.vision.positionCount=39;self.next_vision_at=0
end
function Demo:update_vision()
 local s=self.context.state;if s.clock<(self.next_vision_at or 0)then return end;self.next_vision_at=s.clock+.12;local monster=s.entities.monster_inkwave_1
 self.vision.enabled=monster and monster.alive and self.definitions.monster_inkwave.sense.showDebugCone
 if not self.vision.enabled then return end
 local p=self.adapter:position('monster_inkwave_1');local f=self.adapter:forward('monster_inkwave_1');local sense=self.definitions.monster_inkwave.sense
 local yaw=atan2(f.x,f.z);local half=sense.fullAngleDeg*.5*math.pi/180
 local U=self.adapter.U;local detected=self.adapter:sense({user_instance_id='monster_inkwave_1',target_instance_id='player_local',mode='perception'}).data.visible
 local color=detected and U.Color(1,.17,.08,1)or U.Color(1,.69,.12,1);self.vision.startColor=color;self.vision.endColor=color
 self.vision:SetPosition(0,U.Vector3(p.x,.06,p.z))
 for i=0,36 do
  local angle=yaw-half+2*half*i/36;local dist=sense.rangeM
  local target={x=p.x+math.sin(angle)*dist,y=.06,z=p.z+math.cos(angle)*dist}
  if Spatial.blocked(p,target,Map.walls,0)then local lo,hi=0,dist;for j=1,10 do local mid=(lo+hi)/2;local q={x=p.x+math.sin(angle)*mid,z=p.z+math.cos(angle)*mid};if Spatial.blocked(p,q,Map.walls,0)then hi=mid else lo=mid end end;dist=lo end
  self.vision:SetPosition(i+1,U.Vector3(p.x+math.sin(angle)*dist,.06,p.z+math.cos(angle)*dist))
 end
 self.vision:SetPosition(38,U.Vector3(p.x,.06,p.z))
end
function Demo:update(elapsed)
 if not self.started then if self.pending then self:start()end;return end
 local U=self.adapter.U;self.frame=(self.frame or 0)+1
 if not self.qa then
  local keys={{U.KeyCode.E,'interact'},{U.KeyCode.F,'attack'},{U.KeyCode.B,'bag'},{U.KeyCode.H,'heal'},{U.KeyCode.Escape,'close'}}
  for _,pair in ipairs(keys)do if U.Input.GetKeyDown(pair[1])then self:dispatch(pair[2])end end
 end
 local remaining=math.max(0,elapsed or 0)
 while remaining>0 do
  local dt=math.min(.05,remaining);remaining=remaining-dt
  self.adapter:tick(dt)
  self.objects.player:update(dt);self.objects.shovel:update(dt);self.objects.heal:update(dt);self.objects.chest:update(dt);self.objects.monster:update(dt)
  self.settlement:update(dt)
  if self.qa then self:update_qa(dt)end
 end
 self:update_vision();self.ui:update(elapsed)
end
function Demo:teleport(p,face)
 local U=self.adapter.U;local rotation=face and U.Quaternion.LookRotation(U.Vector3(face.x,0,face.z))or U.Quaternion.identity
 local actor=self.adapter:actor();actor:Teleport(self.adapter:vector(p),rotation)
 if face then actor.gameObject.transform.rotation=rotation end
 self.teleport_expected=copy(p)
end
function Demo:qa_check(name,condition,detail)
 local entry={name=name,ok=condition==true,detail=tostring(detail or'')};self.qa_results[#self.qa_results+1]=entry
 self:log('QA '..(entry.ok and'PASS'or'FAIL')..' '..name..' '..entry.detail)
 if not entry.ok then self.qa_summary='验收失败：'..name..' '..entry.detail;self.qa=nil;return false end
 self.qa_summary='自动验收：'..#self.qa_results..' 项通过 · '..name;return true
end
function Demo:start_qa()
 if self.qa then return end
 if self.context.state.phase~='FINISHED'then self.context.services.Session:try_finish(self:request('qa_reset',{terminal_reason='quit'}))end
 -- Start only through the normal match flow; no HP/inventory mutation in the test driver.
 self:begin_round();self.qa_results={};self.qa_summary='自动验收：重开局，检查实际运行服务';self.qa={stage=1,t=0,elapsed=0,last=self.adapter:position('monster_inkwave_1')}
 self:log('QA START native actor teleports are test navigation only')
end
function Demo:qa_stage(stage)self.qa.stage=stage;self.qa.t=0;self.qa.frame=self.frame end
function Demo:qa_combat_position(attempt)
 local pos=self.adapter:position('monster_inkwave_1');local f=self.adapter:forward('monster_inkwave_1');local base=atan2(f.x,f.z)+(attempt or 0)*math.pi/6
 for i=0,11 do
  local a=base+i*math.pi/6;local p={x=pos.x+math.sin(a)*1.6,y=.1,z=pos.z+math.cos(a)*1.6}
  if p.x>Map.bounds.min_x+.65 and p.x<Map.bounds.max_x-.65 and p.z>Map.bounds.min_z+.65 and p.z<Map.bounds.max_z-.65 and not Spatial.blocked(p,p,Map.walls,.65)and not Spatial.blocked(p,pos,Map.walls,0)then
   self:teleport(p,{x=pos.x-p.x,z=pos.z-p.z});return true
  end
 end
 return false
end
function Demo:qa_face_monster()
 local pos=self.adapter:position('player_local');local target=self.adapter:position('monster_inkwave_1');local U=self.adapter.U
 self.adapter:actor().gameObject.transform.rotation=U.Quaternion.LookRotation(U.Vector3(target.x-pos.x,0,target.z-pos.z))
end
function Demo:update_qa(dt)
 local q=self.qa;if not q then return end;q.t=q.t+dt;q.elapsed=q.elapsed+dt
 local s=self.context.state;local p=s.entities.player_local;local m=s.entities.monster_inkwave_1
 if (self.frame or 0)-(q.frame or 0)<2 then return end
 if q.elapsed>65 then self:qa_check('全过程限时',false,'stage '..q.stage);return end
 if q.stage==1 and q.t>1.2 then
  local view=self.adapter.inkwave and self.adapter.inkwave:status()
  if not self:qa_check('GLB骨骼曲线绑定并实际更新',view and view.ready and view.changed_bone_frames>0,view and view.changed_bone_frames)then return end
  if not self:qa_check('导入蒙皮保留真实骨骼绑定',view.skin_diagnostics_available and view.skin_count>0 and view.skin_bone_count>=87,'skins='..view.skin_count..' bones='..view.skin_bone_count)then return end
  if not self:qa_check('死亡默认姿态不污染巡逻站姿',(view.head_foot_height_m or 0)>.5,view.head_foot_height_m)then return end
  if not self:qa_check('八条怪物音效完成AudioClip上传',view.audio_clips_ready==8,view.audio_clips_ready)then return end
  if not self:qa_check('初始角色100HP与怪物60HP',p.hp==100 and m.hp==60)then return end
  if not self:qa_check('墨潮怪物巡逻位移',Spatial.distance(q.last,self.adapter:position('monster_inkwave_1'))>.1)then return end
  self:teleport({x=1,y=.1,z=-2});self:qa_stage(2)
 elseif q.stage==2 and q.t>.4 then
  local r=self:dispatch('interact');if not self:qa_check('打开宝箱',r and r.ok,r and r.reason)then return end
  self:dispatch('take_all');self:close_view()
  local bag=self.bag:read_bag().data.bag;local medicine,treasure=0,0
  for _,entry in ipairs(bag.items)do if entry.entity_id=='item_heal_small'then medicine=medicine+entry.count elseif entry.entity_id=='item_treasure'then treasure=treasure+entry.count end end
  if not self:qa_check('宝物1份与药品2份进入背包',medicine==2 and treasure==1)then return end
  local r2=self:dispatch('heal');if not self:qa_check('满血用药拒绝',r2 and not r2.ok and r2.reason=='FULL_HEALTH')then return end
  self:qa_stage(3)
 elseif q.stage==3 and s.clock>3.4 then
  local pos=self.adapter:position('monster_inkwave_1');local f=self.adapter:forward('monster_inkwave_1')
  self:teleport({x=pos.x-f.x*1.8,y=.1,z=pos.z-f.z*1.8});self:qa_stage(4)
 elseif q.stage==4 and q.t>.1 then
  local sense=self.adapter:sense({user_instance_id='monster_inkwave_1',target_instance_id='player_local',mode='perception'})
  if not self:qa_check('视野背后不索敌',sense.data.angular_valid==false and sense.data.visible==false)then return end
  local pos=self.adapter:position('monster_inkwave_1');local f=self.adapter:forward('monster_inkwave_1')
  self:teleport({x=pos.x+f.x*1.8,y=.1,z=pos.z+f.z*1.8},{x=-f.x,z=-f.z});self:qa_stage(5)
 elseif q.stage==5 and p.hp<100 then
  if not self:qa_check('怪物前摇后攻击造成25伤害',p.hp==75,p.hp)then return end
  self:teleport({x=1,y=.1,z=-2});self:qa_stage(6)
 elseif q.stage==6 and q.t>.5 then
  local result=self:dispatch('heal');if not self:qa_check('受伤可开始药品读条',result and result.ok,result and result.reason)then return end
  self:qa_stage(7)
 elseif q.stage==7 and not self.objects.heal.cast then
  local r=self.objects.heal.last_result;if not self:qa_check('读条完成回血100HP',r and r.ok and p.hp==100,r and r.reason)then return end
  local n=0;for _,entry in ipairs(self.bag:read_bag().data.bag.items)do if entry.entity_id=='item_heal_small'then n=n+entry.count end end
  if not self:qa_check('只消耗一份药品',n==1,n)then return end
  self:qa_combat_position(0);self:qa_stage(8)
 elseif q.stage==8 and q.t>.25 then
  self:qa_face_monster()
  local r=self:dispatch('attack');if not self:qa_check('铲击进入前摇',r and r.ok,r and r.reason)then return end;self:qa_stage(9)
 elseif q.stage==9 and m.hp==30 then
  if not self:qa_check('首个有效窗口扣30HP',true)then return end;self:qa_stage(10)
 elseif q.stage==10 and q.t>1.4 then
  self:qa_combat_position(0);self:qa_stage(11)
 elseif q.stage==11 and q.t>.3 then
  self:qa_face_monster()
  local sense=self.adapter:sense({user_instance_id='player_local',target_instance_id='monster_inkwave_1',mode='weapon'}).data
  if not sense.visible and q.t<5 then q.attempt=(q.attempt or 0)+1;self:qa_combat_position(q.attempt);q.frame=self.frame;return end
  local r=self:dispatch('attack');local pp=self.adapter:position('player_local');local mp=self.adapter:position('monster_inkwave_1')
  local detail=tostring(r and r.reason)..' d='..tostring(sense.distance_m)..' arc='..tostring(sense.angular_valid)..' los='..tostring(sense.line_of_sight)..' p='..pp.x..','..pp.z..' m='..mp.x..','..mp.z
  if not self:qa_check('第二次铲击',r and r.ok,detail)then return end;self:qa_stage(12)
 elseif q.stage==12 and m.hp==0 then
  if not self:qa_check('怪物死亡停止行为',m.alive==false)then return end
  self:teleport(Map.exit);self:qa_stage(13)
 elseif q.stage==13 and q.t>.4 then
  local r=self:dispatch('interact');if not self:qa_check('撤离区域读条开始',r and r.ok,r and r.reason)then return end;self:qa_stage(14)
 elseif q.stage==14 and s.result then
  local view=self.adapter.inkwave:status()
  if not self:qa_check('怪物专属声音与墨枪特效触发',view.audio_events>0 and view.fx_events>=3,'sounds='..view.audio_events..' fx='..view.fx_events)then return end
  if not self:qa_check('3秒后结算成功带出宝物',s.result.success and s.result.loot_value>=250,s.result.reason..' value='..s.result.loot_value)then return end
  local id=s.result.result_id;self.context.services.Session:try_finish(self:request('qa_duplicate',{terminal_reason='extraction'}))
  if not self:qa_check('重复结束不二次结算',s.result.result_id==id)then return end
  self.qa=nil;self.qa_summary='编辑器实际验收通过 '..#self.qa_results..' 项 · 拾取 → 战斗 → 用药 → 撤离';self:log('QA COMPLETE passed='..#self.qa_results)
 end
end
function Demo:GetSnapshot()
 if not self.context then return {ready=false,pending=self.pending}end
 local s=self.context.state
 return {ready=self.started,project=self.config.projectName,run_id=s.run_id,phase=s.phase,clock=s.clock,player=copy(s.entities.player_local),monster=copy(s.entities.monster_inkwave_1),monster_state=self.objects.monster.ai_state,bag=copy(s.containers.bag_player_local),result=copy(s.result),speed_write_ok=self.adapter.speed_write_ok,speed_readback=self.adapter.speed_readback,collider_apply_ok=self.adapter.collider_apply_ok,collider_readback=copy(self.adapter.collider_readback),qa=copy(self.qa_results),qa_summary=self.qa_summary,presentation=self.adapter.inkwave and self.adapter.inkwave:status()}
end
function Demo:dispose()
 self.qa=nil;if self.setup then self.setup:dispose()end;if self.bag then self.bag:dispose()end;if self.ui then self.ui:dispose()end;if self.adapter then self.adapter:dispose()end
 self.started=false
end
return Demo
