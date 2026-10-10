-- Monster-only Unity bridge. Curves are sampled from the same baked GLB;
-- no upstream match, input, networking or ink territory code runs here.
local Bank=require('gameplay.packages.monsters.monster_inkwave.animations.runtime_bank')
local Audio=require('gameplay.packages.monsters.monster_inkwave.audio.pcm_bank')
local P={};P.__index=P
local function each(a,fn)if a then for i=0,(tonumber(a.Length)or 0)-1 do fn(a:GetValue(i))end end end
local function vec(U,v,axis) local x,y,z=v[1],v[2],v[3];if axis=='x'then x=-x elseif axis=='z'then z=-z end;return U.Vector3(x,y,z)end
local function quat(U,v,axis)if axis=='x'then return U.Quaternion(v[1],-v[2],-v[3],v[4])elseif axis=='z'then return U.Quaternion(-v[1],-v[2],v[3],v[4])end;return U.Quaternion(v[1],v[2],v[3],v[4])end
local function key(track,time)
 local times,vals,n=track.times,track.values,track.dimensions
 local lo,hi=1,#times
 while lo<hi do local m=math.floor((lo+hi+1)/2);if times[m]<=time then lo=m else hi=m-1 end end
 local nxt=math.min(lo+1,#times);local a=0
 if nxt>lo and track.interpolation~='STEP'then a=math.max(0,math.min(1,(time-times[lo])/(times[nxt]-times[lo])))end
 local x,y={},{};for k=1,n do x[k]=vals[(lo-1)*n+k];y[k]=vals[(nxt-1)*n+k]end
 return x,y,a
end
function P.new(adapter,go)
 local self=setmetatable({adapter=adapter,U=adapter.U,go=go,nodes={},components={},clips={},time=0,effect_clock=0,frames=0,changed_frames=0,fx_count=0,audio_events=0,voices={},audio_clips={},audio_queue={},audio_index=1,ready=false,errors={}},P)
 local U=self.U;local names={}
 -- The importer may auto-play the first GLB clip while Demo waits for profiles.
 -- Stop its writers before inspecting any transforms. Stop/Rebind alone cannot
 -- establish rest: an Animator's default state may itself be the death clip.
 for _,class in ipairs{U.Animator,U.Animation}do each(go:GetComponentsInChildren(typeof(class),true),function(c)
  self.components[#self.components+1]={c=c,enabled=c.enabled}
  if class==U.Animation then pcall(function()c:Stop()end)end
  c.enabled=false
 end)end
 each(go:GetComponentsInChildren(typeof(U.Transform),true),function(t)local n=tostring(t.name);names[n]=names[n]==nil and t or false end)
 local missing={}
 for i,d in ipairs(Bank.nodes)do local t=names[d.name];if t and t~=go.transform then self.nodes[i]={t=t,p=t.localPosition,q=t.localRotation,s=t.localScale}elseif d.required then missing[#missing+1]=d.name end end
 if #missing>0 then error('INKWAVE_GLTF_JOINTS_MISSING '..table.concat(missing,','))end
 self.muzzle=names.muzzle or go.transform;self.weapon=names.weapon_shooter;self.head=names.head;self.footL=names.footL;self.footR=names.footR
 local scoreBest=math.huge
 for _,axis in ipairs{'z','x','none'}do
  local ratios={};for i,r in pairs(self.nodes)do local d=Bank.nodes[i];local len=vec(U,d.position,axis).magnitude;if len>.0001 and r.p.magnitude>.0001 then ratios[#ratios+1]=r.p.magnitude/len end end
  table.sort(ratios);local scale=#ratios>0 and ratios[math.ceil(#ratios/2)]or 1;local score=0
  -- Infer importer handedness/units from the many unchanged bind offsets, not
  -- the animated armature root. Trim outlying channels already posed by death.
  local residuals={}
  for i,r in pairs(self.nodes)do local d=Bank.nodes[i];residuals[#residuals+1]=(vec(U,d.position,axis)*scale-r.p).sqrMagnitude/math.max(.000001,scale*scale)+U.Quaternion.Angle(quat(U,d.rotation,axis),r.q)/180 end
  table.sort(residuals);for i=1,math.max(1,math.floor(#residuals*.75))do score=score+residuals[i]end
  if score<scoreBest then scoreBest=score;self.axis=axis;self.translation_scale=scale end
 end
 -- The GLB-derived node table is canonical bind/rest data. Never retain the
 -- currently animated TRS as the baseline: idle/patrol omit death root tracks.
 -- The Movement-owned outer actor is excluded above and keeps its placement.
 self.rest_pose_corrected_nodes=0
 for i,r in pairs(self.nodes)do local d=Bank.nodes[i]
  local p,q,s=vec(U,d.position,self.axis)*self.translation_scale,quat(U,d.rotation,self.axis),vec(U,d.scale,'none')
  if (r.p-p).sqrMagnitude>.000001 or U.Quaternion.Angle(r.q,q)>.01 or(r.s-s).sqrMagnitude>.000001 then self.rest_pose_corrected_nodes=self.rest_pose_corrected_nodes+1 end
  r.p=p;r.q=q;r.s=s;r.t.localPosition=p;r.t.localRotation=q;r.t.localScale=s
 end
 self.skin_count=0;self.skin_bone_count=0;self.skin_diagnostics_available=false
 pcall(function()if U.SkinnedMeshRenderer then
  each(go:GetComponentsInChildren(typeof(U.SkinnedMeshRenderer),true),function(r)self.skin_count=self.skin_count+1;self.skin_bone_count=self.skin_bone_count+(r.bones and tonumber(r.bones.Length)or 0)end)
  self.skin_diagnostics_available=true
 end end)
 for _,clip in ipairs(Bank.clips)do self.clips[clip.name]=clip end
 self.renderers={};self.materials={};each(go:GetComponentsInChildren(typeof(U.Renderer),true),function(r)self.renderers[#self.renderers+1]=r;each(r.materials,function(m)local ok,c=pcall(function()return m.color end);if ok then self.materials[#self.materials+1]={m=m,color=c}end end)end)
 self:_create_fx();self:_create_audio();self.ready=true;self:play({clip_name='idle',restart=true,loop=true})
 U.Debug.Log('[INKWAVE] BOUND curves='..#Bank.clips..' joints='..#Bank.nodes..' reflection='..self.axis..' model='..tostring(Bank.sourceSha256 or Bank.source_sha256))
 return self
end
function P:_create_fx()
 local U=self.U;self.fx_root=U.GameObject('monster_inkwave_feedback');self.fx_root.transform:SetParent(self.adapter.runtime_root.transform,false)
 self.fx_material=U.Material(U.Shader.Find('Sprites/Default'))
 local function line(name,width,color)
  local go=U.GameObject(name);go.transform:SetParent(self.fx_root.transform,false);local l=go:AddComponent(typeof(U.LineRenderer));l.material=self.fx_material;l.useWorldSpace=true;l.positionCount=2;l.startWidth=width;l.endWidth=width*.45;l.startColor=color;l.endColor=color;l.enabled=false;return l
 end
 self.tracer=line('inkwave_shooter_tracer',.045,U.Color(.18,.85,1,1));self.charge=line('inkwave_shooter_charge',.07,U.Color(1,.65,.1,1))
 self.particles={}
 for i=1,16 do
  local go=U.GameObject.CreatePrimitive(U.PrimitiveType.Sphere);go.name='inkwave_ink_droplet_'..i;go.transform:SetParent(self.fx_root.transform,false)
  local collider=go:GetComponent(typeof(U.Collider));if collider then collider.enabled=false end
  local r=go:GetComponent(typeof(U.Renderer));r.material=self.fx_material;go:SetActive(false);self.particles[i]={go=go}
 end
end
function P:_create_audio()
 local U=self.U
 for id in pairs(Audio.clips)do self.audio_queue[#self.audio_queue+1]=id end;table.sort(self.audio_queue)
 for i=1,4 do
  local go=U.GameObject('inkwave_voice_'..i);go.transform:SetParent(self.fx_root.transform,false)
  local a=go:AddComponent(typeof(U.AudioSource));a.playOnAwake=false;a.loop=false;a.spatialBlend=1;a.minDistance=2;a.maxDistance=18;a.dopplerLevel=0;a.volume=.45
  a.rolloffMode=U.AudioRolloffMode.Linear;self.voices[i]={go=go,source=a,until_at=0}
 end
end
function P:_build_audio()
 local id=self.audio_queue[self.audio_index];if not id then return end
 local entry=self.audio_build
 if not entry then
  local d=Audio.clips[id];entry={id=id,data=d,decoder=Audio.new_decoder(id)}
  entry.samples=CS.System.Array.CreateInstance(typeof(CS.System.Single),d.frames);self.audio_build=entry
 end
 local done=entry.decoder:step(4096,function(index,value)entry.samples[index]=value end)
 if done then
  local d=entry.data;local clip=self.U.AudioClip.Create('inkwave_'..id,d.frames,1,Audio.sample_rate,false)
  if clip:SetData(entry.samples,0)==false then error('INKWAVE_AUDIO_SETDATA '..id)end
  self.audio_clips[id]=clip;self.audio_build=nil;self.audio_index=self.audio_index+1
 end
end
function P:_sound(id)
 local aliases={shoot_shooter='shoot_'..({'a','b','c'})[(self.audio_events%3)+1],splat='death',step_dry='step'};id=aliases[id]or id
 local clip=self.audio_clips[id];if not clip then return false end
 local now=self.effect_clock;local voice=self.voices[1]
 for _,v in ipairs(self.voices)do if v.until_at<=now then voice=v;break elseif v.until_at<voice.until_at then voice=v end end
 voice.go.transform.position=self.go.transform.position;voice.source.clip=clip;voice.source:Play();voice.until_at=now+clip.length;self.audio_events=self.audio_events+1;return true
end
function P:_burst(position,count)
 local U=self.U;local now=self.effect_clock;local total=math.min(count,#self.particles)
 for i=1,total do local p=self.particles[i];local angle=i*2.39996;p.origin=position;p.v=U.Vector3(math.cos(angle)*1.2,.8+(i%3)*.35,math.sin(angle)*1.2);p.at=now;p.life=.3+(i%4)*.05;p.go.transform.position=position;p.go.transform.localScale=U.Vector3(.055,.055,.055);p.go:SetActive(true)end
 self.fx_count=self.fx_count+1
end
function P:play(r)
 local name=r.clip_name or tostring(r.clip_id):match('clip_monster_inkwave_(.+)');local clip=self.clips[name]
 if not clip then return false,'INKWAVE_UNKNOWN_CLIP' end
 if self.clip~=clip or r.restart==true then
  self.clip=clip;self.time=0;self.loop=r.loop==true;self.blend_age=0
  for _,n in pairs(self.nodes)do n.from_p=n.t.localPosition;n.from_q=n.t.localRotation;n.from_s=n.t.localScale end
 end
 if name~='attack'then self.charge_until=0;self.tracer_until=0 end
 local f=r.monster_feedback
 if f then
  self.attack_id=f.attack_instance_id
  self.last_event=f.event
  if f.sound_id then self:_sound(f.sound_id)end
  local now=self.effect_clock
  if f.fx_id=='charge_shooter'then
   local attack=self.attack_id and self.adapter.state.attacks[self.attack_id]
   self.charge_until=now+(attack and attack.definition.windupSec or .55)
  elseif f.fx_id=='muzzle_shooter'then
   self.charge_until=0;self.tracer_until=now+.14
   local start=self.muzzle.position;local target=f.target_position_m
   self.tracer:SetPosition(0,start);self.tracer:SetPosition(1,target and self.U.Vector3(target.x,target.y+1,target.z)or(start+self.go.transform.forward*3.5));self:_burst(start,5)
  elseif f.fx_id=='hit_spark'then self:_burst(self.go.transform.position+self.U.Vector3(0,.9,0),7);self.flash_until=now+.12
  elseif f.fx_id=='ink_burst'then self:_burst(self.go.transform.position+self.U.Vector3(0,.6,0),16)end
 end
 return true,'INKWAVE_GLTF_CURVES'
end
function P:update(dt)
 if not self.ready then return end;local U=self.U;self.effect_clock=self.effect_clock+dt;local now=self.effect_clock
 self:_build_audio();self.time=self.time+dt;self.blend_age=math.min(.12,(self.blend_age or 0)+dt)
 local clip=self.clip;if clip then
  local duration=clip.duration or clip.durationSec;local time=self.loop and self.time%duration or math.min(duration,self.time);local changed=false
  -- Inspector attack timing changes authority; phase mapping keeps the muzzle
  -- at the baked .55-second firing pose without changing damage authority.
  local attack=self.attack_id and self.adapter.state.attacks[self.attack_id]
  if clip.name=='attack' and attack then
   local d=attack.definition;local age=math.max(0,self.adapter.state.clock-attack.started_at)
   if age<d.windupSec then time=.55*age/math.max(.001,d.windupSec)
   elseif age<d.windupSec+d.activeSec then time=.55+.25*(age-d.windupSec)/math.max(.001,d.activeSec)
   else time=.8+.7*math.min(1,(age-d.windupSec-d.activeSec)/math.max(.001,d.recoverySec))end
   time=math.min(duration,time)
  end
  -- A clip is a complete pose: channels absent from it use the imported rest.
  -- This prevents death / recoil / jaw channels persisting into the next action.
  for _,r in pairs(self.nodes)do r.target_p=r.p;r.target_q=r.q;r.target_s=r.s end
  for _,track in ipairs(clip.tracks)do local r=self.nodes[track.node];if r then
   local x,y,a=key(track,time);local d=Bank.nodes[track.node]
   if track.path=='rotation'then
    local v=U.Quaternion.Slerp(quat(U,x,self.axis),quat(U,y,self.axis),a)
    r.target_q=r.q*U.Quaternion.Inverse(quat(U,d.rotation,self.axis))*v
   else
    local v={};for k=1,track.dimensions do v[k]=x[k]+(y[k]-x[k])*a end
    if track.path=='translation'then r.target_p=r.p+(vec(U,v,self.axis)-vec(U,d.position,self.axis))*self.translation_scale
    elseif track.path=='scale'then r.target_s=U.Vector3(r.s.x*v[1]/d.scale[1],r.s.y*v[2]/d.scale[2],r.s.z*v[3]/d.scale[3])end
   end
  end end
  local blend=self.blend_age/.12
  for _,r in pairs(self.nodes)do
   local q=U.Quaternion.Slerp(r.from_q or r.q,r.target_q,blend)
   if U.Quaternion.Angle(r.t.localRotation,q)>.01 then changed=true end
   r.t.localRotation=q;r.t.localPosition=U.Vector3.Lerp(r.from_p or r.p,r.target_p,blend);r.t.localScale=U.Vector3.Lerp(r.from_s or r.s,r.target_s,blend)
  end
  self.frames=self.frames+1;if changed then self.changed_frames=self.changed_frames+1 end
 end
 local p=self.go.transform.position;local moved=self.previous_position and(p-self.previous_position).sqrMagnitude>.00001;self.previous_position=p
 if moved and self.loop and self.clip and self.clip.name~='idle'and now>=(self.next_step_at or 0)then self:_sound('step_dry');self.next_step_at=now+(self.clip.name=='chase'and .28 or .42)end
 local flashing=now<(self.flash_until or 0)
 if flashing~=self.flashing then self.flashing=flashing;for _,r in ipairs(self.materials)do r.m.color=flashing and U.Color(1,.8,.65,1)or r.color end end
 self.tracer.enabled=now<(self.tracer_until or 0);self.charge.enabled=now<(self.charge_until or 0)
 if self.charge.enabled then local m=self.muzzle.position;self.charge:SetPosition(0,m);self.charge:SetPosition(1,m+self.go.transform.forward*(.12+.12*math.sin(now*26)))end
 for _,r in ipairs(self.particles)do if r.at then local age=now-r.at;if age<r.life then r.go.transform.position=r.origin+r.v*age+U.Vector3(0,-3*age*age,0)else r.go:SetActive(false);r.at=nil end end end
end
function P:status()
 local count=0;for _ in pairs(self.audio_clips)do count=count+1 end
 local active=0;for _,v in ipairs(self.voices)do if v.source.isPlaying then active=active+1 end end
 local height,dot
 pcall(function()if self.head and self.footL and self.footR then height=self.head.position.y-(self.footL.position.y+self.footR.position.y)*.5 end end)
 pcall(function()if self.weapon then local v=self.muzzle.position-self.weapon.position;local f=self.go.transform.forward;local n=math.sqrt((v.x*v.x+v.z*v.z)*(f.x*f.x+f.z*f.z));if n>.000001 then dot=(v.x*f.x+v.z*f.z)/n end end end)
 return {ready=self.ready,clip=self.clip and self.clip.name,curve_frames=self.frames,changed_bone_frames=self.changed_frames,reflection=self.axis,rest_source='glb_bank',rest_pose_corrected_nodes=self.rest_pose_corrected_nodes,skin_diagnostics_available=self.skin_diagnostics_available,skin_count=self.skin_count,skin_bone_count=self.skin_bone_count,head_foot_height_m=height,muzzle_forward_dot=dot,audio_clips_ready=count,audio_events=self.audio_events,active_audio_voices=active,fx_events=self.fx_count,source_sha256=Bank.sourceSha256 or Bank.source_sha256}
end
function P:reset()
 for _,r in pairs(self.nodes)do r.t.localPosition=r.p;r.t.localRotation=r.q;r.t.localScale=r.s end
 self.next_step_at=0;self.previous_position=nil;self.flash_until=0;for _,r in ipairs(self.materials)do r.m.color=r.color end
 for _,v in ipairs(self.voices)do v.source:Stop();v.until_at=0 end
 self.charge_until=0;self.tracer_until=0;for _,p in ipairs(self.particles)do p.at=nil;p.go:SetActive(false)end
 self.go:SetActive(true);self:play({clip_name='idle',restart=true,loop=true})
end
function P:dispose()
 for _,r in pairs(self.nodes)do r.t.localPosition=r.p;r.t.localRotation=r.q;r.t.localScale=r.s end
 for _,r in ipairs(self.materials)do r.m.color=r.color end
 for _,r in ipairs(self.components)do r.c.enabled=r.enabled end
 for _,clip in pairs(self.audio_clips)do self.U.Object.Destroy(clip)end
 if self.fx_root then self.U.Object.Destroy(self.fx_root)end;if self.fx_material then self.U.Object.Destroy(self.fx_material)end
end
return P
