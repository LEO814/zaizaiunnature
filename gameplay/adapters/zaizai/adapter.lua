-- Verified Unity / Douyin bridge. SDK code stays out of object controllers.
local State=require('gameplay.core.state')
local Services=require('gameplay.core.services')
local Spatial=require('gameplay.core.spatial')
local Api=require('gameplay.core.service_api')
local InkwavePresentation=require('gameplay.adapters.zaizai.inkwave_presentation')
local Adapter={};Adapter.__index=Adapter
local function result(ok,reason,request,data)return {ok=ok,reason=reason or(ok and 'OK'or 'UNSUPPORTED'),request_id=request and request.request_id,data=data or{}}end
local function plain(v)return {x=v.x,y=v.y,z=v.z}end
local function copy(v)local t={};for k,x in pairs(v or{})do t[k]=type(x)=='table'and copy(x)or x end;return t end
function Adapter.new(options)
 options=options or{}
 local self=setmetatable({is_ready=false,services={},nodes={},native_nodes={},native_baselines={},feedback={},subscriptions={},dt=0.02,options=options},Adapter)
 self.config=options.config;self.definitions=options.definitions or{};self.map=options.map;self.registry=options.registry
 if not self.config or not self.map or not CS or not CS.UnityEngine then return self end
 self.U=CS.UnityEngine;local U=self.U
 self.state=State.new(self.config)
 self.runtime_root=U.GameObject('demo_runtime');if options.host then self.runtime_root.transform:SetParent(options.host.transform,false)end
 local spatial={distance=Spatial.distance,los=function(a,b)return not Spatial.blocked(a,b,self.map.walls,0)end,position=function(id)return self:position(id)end}
 local shared=Services.new(self.state,self.config,self.definitions,spatial)
 for name,methods in pairs(Api.operations)do
  self.services[name]=shared[name]or{}
  for _,method in ipairs(methods)do if not self.services[name][method]then self.services[name][method]=function(_,request)return result(false,'UNSUPPORTED',request)end end end
 end
 self:_install_engine_services()
 self.is_ready=true
 return self
end
function Adapter:actor()return CS.DouyinActorService.GetLocalActor()end
function Adapter:vector(p)return self.U.Vector3(p.x,p.y,p.z)end
function Adapter:position(id)
 local go=self.nodes[id]
 if id=='player_local'then local a=self:actor();if a then return plain(a.position)end end
 if go then return plain(go.transform.position)end
 local e=self.state.entities[id];return e and e.position_m or nil
end
function Adapter:forward(id)
 local go=self.nodes[id]
 if id=='player_local'then local a=self:actor();if a then go=a.gameObject end end
 if go then local f=go.transform.forward;return {x=f.x,y=0,z=f.z}end
 local e=self.state.entities[id];return e and e.forward_m or{x=0,y=0,z=1}
end
function Adapter:sense(request)
 local a,b=self:position(request.user_instance_id),self:position(request.target_instance_id)
 if not a or not b then return result(false,'MISSING_ENTITY',request)end
 local source=self.state.entities[request.user_instance_id]
 local def=source and self.definitions[source.entity_id]or{}
 local mode=request.mode or'interaction';local range,angle
 if mode=='perception'then
  local p=def.sense or def.perception or def.senses or{}
  range=p.rangeM or p.viewDistanceM or def.viewDistanceM or def.visionRangeM or 7
  angle=p.fullAngleDeg or p.fovDeg or def.fovDeg or def.visionAngleDeg or 100
 elseif mode=='weapon'then range=self.definitions.weapon_shovel.attack.rangeM;angle=self.definitions.weapon_shovel.attack.arcDeg
 else range=self.config.interaction.maxDistanceM;angle=360 end
 local dist=Spatial.distance(a,b);local f=self:forward(request.user_instance_id)
 local angular=dist<0.001 or((f.x*(b.x-a.x)+f.z*(b.z-a.z))/dist>=math.cos(angle*0.5*math.pi/180))
 if angle>=359 then angular=true end
 local los=not Spatial.blocked(a,b,self.map.walls,0)
 return result(true,'OK',request,{visible=dist<=range and angular and los,in_range=dist<=range,angular_valid=angular,line_of_sight=los,distance_m=dist,range_m=range,full_angle_deg=angle})
end
function Adapter:_install_engine_services()
 local self=self;local U=self.U
 local movement=self.services.Movement
 function movement:read_position(r)
  local p=self._adapter:position(r.instance_id);if not p then return result(false,'MISSING_ENTITY',r)end
  return result(true,'OK',r,{position_m=p,forward_m=self._adapter:forward(r.instance_id)})
 end
 function movement:move_to(r)
  local a=self._adapter;local go=a.nodes[r.instance_id];if not go or r.instance_id=='player_local'then return result(false,'UNSUPPORTED',r)end
  local p=a:position(r.instance_id);local target=r.goal_m;if not target then return result(false,'INVALID_GOAL',r)end
  local distance=Spatial.distance(p,target);if distance<0.01 then return result(true,'ARRIVED',r,{position_m=p})end
  local amount=math.min(distance,math.max(0,r.speed_mps or 0)*a.dt)
  local q={x=p.x+(target.x-p.x)*amount/distance,y=p.y,z=p.z+(target.z-p.z)*amount/distance}
  if Spatial.blocked(p,q,a.map.walls,0.35)then return result(false,'BLOCKED',r)end
  go.transform.position=a:vector(q);go.transform.rotation=U.Quaternion.LookRotation(U.Vector3(target.x-p.x,0,target.z-p.z))
  local e=a.state.entities[r.instance_id];if e then e.position_m=q;e.forward_m=a:forward(r.instance_id)end
  return result(true,'OK',r,{position_m=q})
 end
 function movement:stop(r)return result(true,'OK',r)end
 movement._adapter=self
 local navigation=self.services.Navigation
 function navigation:find_path(r)
  local a=self._adapter;local from=r.from_m or a:position(r.instance_id)
  if not from or not r.to_m then return result(false,'INVALID_GOAL',r)end
  local path,reason=Spatial.path(from,r.to_m,a.map,0.35)
  return result(path~=nil,reason or'OK',r,{waypoints=path or{},task_id=r.request_id})
 end
 function navigation:cancel_query(r)return result(true,'OK',r)end
 navigation._adapter=self
 local interaction=self.services.Interaction
 function interaction:query_target(r)return self._adapter:sense(r)end
 function interaction:try_begin(r)
  local a=self._adapter
  if a.state.phase~='EXPLORE'then return result(false,'WRONG_PHASE',r)end
  local sensed=a:sense(r)
  if not sensed.ok or not sensed.data.visible then return result(false,'OUT_OF_RANGE_OR_BLOCKED',r,sensed.data)end
  return result(true,'OK',r,{target_instance_id=r.target_instance_id,container_id=r.target_instance_id=='chest_demo'and 'chest_demo'or nil})
 end
 function interaction:cancel(r)return result(true,'OK',r)end
 interaction._adapter=self
 local assets=self.services.Assets
 function assets:resolve(r)
  local a=self._adapter
  if r.resource_id=='asset_monster_inkwave' and (a.inkwave or U.GameObject.Find('monster_inkwave_actor'))then
   return result(true,'IMPORTED_GLB',r,{path='gameplay/packages/monsters/monster_inkwave/model/main.glb',native_name='monster_inkwave_actor'})
  end
  for _,e in ipairs(a.registry.entries)do for _,resource in ipairs(e.resources)do if resource.id==r.resource_id then return result(false,'PLANNED_MODEL_NOT_IMPORTED',r,{path=resource.path})end end end
  return result(false,'UNKNOWN_RESOURCE',r)
 end
 function assets:instantiate(r)
  local a=self._adapter;local go
  if r.entity_id=='player_default'then local actor=a:actor();go=actor and actor.gameObject
  else local name=r.node_name or r.entity_id;go=a.native_nodes[name]or U.GameObject.Find(name);if go then a.native_nodes[name]=go end end
  if not go then return result(false,'NATIVE_PROXY_MISSING',r,{entity_id=r.entity_id})end
  a.nodes[r.instance_id]=go
  if r.entity_id=='monster_inkwave'then
   go:SetActive(true)
   if r.position_m then go.transform.position=a:vector(r.position_m);go.transform.rotation=U.Quaternion.identity end
   if a.inkwave then a.inkwave:reset()else a.inkwave=InkwavePresentation.new(a,go)end
   a.feedback[r.instance_id]={rigged=true,clip='idle',at=a.state.clock}
   return result(true,'IMPORTED_GLB',r,{native_name=go.name,instance_id=r.instance_id,rigged_animation=true})
  end
  local renderer=go:GetComponent(typeof(U.Renderer));local mat=renderer and renderer.material;local color=mat and mat.color or U.Color(0.95,0.48,0.16,1)
  local key=r.node_name or r.entity_id;local base=a.native_baselines[key]
  if not base then base={scale=plain(go.transform.localScale),color={r=color.r,g=color.g,b=color.b,a=color.a}};a.native_baselines[key]=base end
  go.transform.localScale=a:vector(base.scale);if mat then mat.color=U.Color(base.color.r,base.color.g,base.color.b,base.color.a)end
  a.feedback[r.instance_id]={base_scale=copy(base.scale),base_color=copy(base.color),clip='native_idle',at=a.state.clock,material=mat}
  if r.position_m then
   if r.entity_id=='player_default'then local actor=a:actor();actor:Teleport(a:vector(r.position_m),U.Quaternion.identity)
   else go.transform.position=a:vector(r.position_m);go.transform.rotation=U.Quaternion.identity end
  end
  go:SetActive(true)
  return result(true,'NATIVE_PROXY',r,{native_name=go.name,instance_id=r.instance_id})
 end
 function assets:play_clip(r)
  local a=self._adapter;local f=a.feedback[r.instance_id]
  if not f then return result(false,'MISSING_ENTITY',r)end
  if f.rigged then
   local ok,reason=a.inkwave:play(r)
   return result(ok,reason,r,{clip_id=r.clip_id,rigged_animation=true})
  end
  if r.native_action=='chest_open'or r.native_action=='chest_close'then
   local lid=U.GameObject.Find('chest_basic_lid')
   if lid then lid.transform.rotation=U.Quaternion.Euler(r.native_action=='chest_open'and -80 or 0,0,0)end
   f.clip='native_idle';return result(true,'NATIVE_DEMO_FEEDBACK',r,{skeletal_animation=false,native_action=r.native_action})
  end
  if not tostring(r.clip_id):match('^native_')then return result(false,'PLANNED_ANIMATION',r)end
  f.clip=r.clip_id;f.at=a.state.clock
  return result(true,'NATIVE_DEMO_FEEDBACK',r,{clip_id=r.clip_id,rigged_animation=false})
 end
 function assets:resolve_socket(r)
  local a=self._adapter
  if a.feedback[r.instance_id] and a.feedback[r.instance_id].rigged and (r.socket_id=='muzzle'or r.socket_name=='muzzle')then
   return result(true,'OK',r,{position_m=plain(a.inkwave.muzzle.position)})
  end
  return result(false,'UNSUPPORTED',r,{reason='Unknown socket'})
 end
 function assets:destroy(r)
  local a=self._adapter;local go=a.nodes[r.instance_id]
  if go and r.instance_id~='player_local'then go:SetActive(false)end
  a.nodes[r.instance_id]=nil;a.feedback[r.instance_id]=nil
  return result(true,'OK',r)
 end
 assets._adapter=self
 local ui=self.services.UI
 function ui:open_view(r)
  local a=self._adapter;a.state.ui_view=r.view_id
  if a.ui then a.ui:open(r.view_id,r)end
  return result(true,'OK',r)
 end
 function ui:close_view(r)
  local a=self._adapter;a.state.ui_view=nil;if a.ui then a.ui:close()end
  return result(true,'OK',r)
 end
 function ui:publish_snapshot(r)if self._adapter.ui then self._adapter.ui:update_snapshot(r)end;return result(true,'OK',r)end
 function ui:subscribe(r)local a=self._adapter;local id=r.request_id or tostring(r.callback);a.subscriptions[id]=r;return result(true,'OK',r,{subscription_id=id})end
 function ui:unsubscribe(r)self._adapter.subscriptions[r.subscription_id]=nil;return result(true,'OK',r)end
 ui._adapter=self
end
function Adapter:tick(dt)
 local U=self.U
 self.dt=math.min(dt,0.08)
 local a=self:actor()
 if a then
  if not self.collider_checked then
   self.collider_checked=true
   local ok,value=pcall(function()local go=a.gameObject;local co=go:GetComponent(typeof(U.CharacterController))or go:GetComponent(typeof(U.CapsuleCollider));if not co then return nil end;co.radius=self.config.player.colliderRadiusM;co.height=self.config.player.colliderHeightM;co.center=U.Vector3(0,self.config.player.colliderCenterY_M,0);return {radius=co.radius,height=co.height,center_y=co.center.y}end)
   self.collider_apply_ok=ok and value~=nil;self.collider_readback=ok and value or nil
  end
  local e=self.state.entities.player_local
  if e then e.position_m=plain(a.position);e.forward_m=self:forward('player_local')end
  if self.original_speed==nil then pcall(function()self.original_speed=tonumber(a.speed)end)end
  local desired=self.config.player.walkSpeedMps
  if self.U.Input.GetKey(self.U.KeyCode.LeftShift)then desired=self.config.player.sprintSpeedMps end
  if self.U.Input.GetKey(self.U.KeyCode.LeftControl)then desired=self.config.player.crouchSpeedMps end
  local ok=pcall(function()a.speed=desired end)
  self.speed_write_ok=ok
  if ok then pcall(function()self.speed_readback=tonumber(a.speed)end)end
  a:Immobilize(self.state.phase=='FINISHED'or self.state.ui_view~=nil)
 end
 for id,f in pairs(self.feedback)do
  local go=self.nodes[id]
  if go and f.rigged then self.inkwave:update(self.dt)
  elseif go and id~='player_local'then
   local age=self.state.clock-f.at;local clip=f.clip
   local scale=copy(f.base_scale);local bc=f.base_color;local color=U.Color(bc.r,bc.g,bc.b,bc.a)
   if clip=='native_death'then go:SetActive(false)
   else
    go:SetActive(true)
    if clip=='native_windup'then local k=1+0.12*math.sin(age*17);scale.x=scale.x*k;scale.z=scale.z*k;color=U.Color(1,0.25,0.12,1)
    elseif clip=='native_attack'then color=U.Color(1,0.12,0.06,1)
    elseif clip=='native_hit'or clip=='native_hurt'then if age<0.25 then color=U.Color(1,0.95,0.72,1)end end
    go.transform.localScale=self:vector(scale)
    if f.material then f.material.color=color end
   end
  end
 end
end
function Adapter:dispose()
 local actor=self:actor();if actor then actor:Immobilize(false);if self.original_speed then pcall(function()actor.speed=self.original_speed end)end end
 if self.inkwave then self.inkwave:dispose();self.inkwave=nil end
 for id,f in pairs(self.feedback)do local go=self.nodes[id];if go and id~='player_local'then go:SetActive(true);if f.base_scale then go.transform.localScale=self:vector(f.base_scale)end end end
 self.subscriptions={};if self.runtime_root then self.U.Object.Destroy(self.runtime_root)end
 self.is_ready=false
end
return Adapter
