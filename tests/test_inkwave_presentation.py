#!/usr/bin/env python3
"""Exercise the real monster presentation adapter with a strict Unity boundary.

Real runtime_bank, real G.711 decoder and real bridge methods run under Lua 5.1.
The native Unity API is a typed-array/transform/audio boundary double, so no
claim about native GLB importer, audible output or rendered particles is made.
Sampling expectations are read independently from the binary GLB accessors.
"""
from __future__ import annotations

import argparse
import bisect
import json
from pathlib import Path
import struct
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from test_demo_runtime import CollectingResult

BOUNDARY = r'''
package.path=TestProjectRoot.."/?.lua;"..package.path
local Bank=require("gameplay.packages.monsters.monster_inkwave.animations.runtime_bank")
local Audio=require("gameplay.packages.monsters.monster_inkwave.audio.pcm_bank")
local P=require("gameplay.adapters.zaizai.inkwave_presentation")
local H={assertion_count=0}
function H.check(value,reason)assert(value,reason);H.assertion_count=H.assertion_count+1 end
local V={}
V.__index=function(v,k)
 if k=="magnitude"then return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)end
 if k=="sqrMagnitude"then return v.x*v.x+v.y*v.y+v.z*v.z end
 return V[k]
end
local function vector(x,y,z)return setmetatable({x=x,y=y,z=z},V)end
V.__add=function(a,b)return vector(a.x+b.x,a.y+b.y,a.z+b.z)end
V.__sub=function(a,b)return vector(a.x-b.x,a.y-b.y,a.z-b.z)end
V.__mul=function(a,b)if type(a)=="number"then a,b=b,a end;return vector(a.x*b,a.y*b,a.z*b)end
local Q={};Q.__index=Q
local function quaternion(x,y,z,w)return setmetatable({x=x,y=y,z=z,w=w},Q)end
Q.__mul=function(a,b)return quaternion(a.w*b.x+a.x*b.w+a.y*b.z-a.z*b.y,a.w*b.y-a.x*b.z+a.y*b.w+a.z*b.x,a.w*b.z+a.x*b.y-a.y*b.x+a.z*b.w,a.w*b.w-a.x*b.x-a.y*b.y-a.z*b.z)end
local function norm(q)local d=math.sqrt(q.x*q.x+q.y*q.y+q.z*q.z+q.w*q.w);return quaternion(q.x/d,q.y/d,q.z/d,q.w/d)end
local function qdot(a,b)return a.x*b.x+a.y*b.y+a.z*b.z+a.w*b.w end
local function array(values)
 local a={Length=#values};function a:GetValue(i)assert(i>=0 and i<self.Length,"CSharp array index");return values[i+1]end;return a
end
function H.make(axis,scale,options)
 axis=axis or"none";scale=scale or 1;options=options or{}
 local t={clock=0,created={},destroyed={},audio_plays=0,typed_uploads=0,typed_arrays={},logs={},bank=Bank,audio=Audio}
 local U={Transform="Transform",Animator="Animator",Animation="Animation",Renderer="Renderer",SkinnedMeshRenderer="SkinnedMeshRenderer",Collider="Collider",LineRenderer="LineRenderer",AudioSource="AudioSource",PrimitiveType={Sphere="Sphere"},AudioRolloffMode={Linear="Linear"}}
 if options.no_skin_api then U.SkinnedMeshRenderer=nil end
 U.Vector3=setmetatable({Lerp=function(a,b,k)return a+(b-a)*k end},{__call=function(_,x,y,z)return vector(x,y,z)end})
 U.Quaternion=setmetatable({Inverse=function(q)local d=qdot(q,q);return quaternion(-q.x/d,-q.y/d,-q.z/d,q.w/d)end,
 Angle=function(a,b)return math.acos(math.min(1,math.abs(qdot(norm(a),norm(b)))))*360/math.pi end,
 Slerp=function(a,b,k)
  a,b=norm(a),norm(b);local d=qdot(a,b);if d<0 then b=quaternion(-b.x,-b.y,-b.z,-b.w);d=-d end
  local x,y
  if d>.9995 then x,y=1-k,k else local theta=math.acos(math.min(1,d));x=math.sin((1-k)*theta)/math.sin(theta);y=math.sin(k*theta)/math.sin(theta)end
  return norm(quaternion(a.x*x+b.x*y,a.y*x+b.y*y,a.z*x+b.z*y,a.w*x+b.w*y))
 end},{__call=function(_,x,y,z,w)return quaternion(x,y,z,w)end})
 U.Color=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end
 U.Shader={Find=function(name)return name end};U.Material=function(shader)return{shader=shader}end
 U.Object={Destroy=function(o)o.destroyed=true;t.destroyed[#t.destroyed+1]=o end}
 U.Debug={Log=function(s)t.logs[#t.logs+1]=s end}
 local function new_go(name)
  local go={name=name,active=true,components={}}
  go.transform={name=name,localPosition=vector(0,0,0),localRotation=quaternion(0,0,0,1),localScale=vector(1,1,1),position=vector(0,0,0),forward=vector(0,0,1)}
  function go.transform:SetParent(parent,preserve)self.parent=parent end
  function go:SetActive(v)self.active=v end
  function go:GetComponent(kind)return self.components[kind]end
  function go:AddComponent(kind)
   local c={kind=kind,enabled=true}
   if kind==U.LineRenderer then c.positions={};function c:SetPosition(i,p)assert(i==0 or i==1);self.positions[i]=p end end
   if kind==U.AudioSource then function c:Play()self.playing=true;self.isPlaying=true;t.audio_plays=t.audio_plays+1 end;function c:Stop()self.playing=false;self.isPlaying=false end end
   self.components[kind]=c;return c
  end
  t.created[#t.created+1]=go;return go
 end
 U.GameObject=setmetatable({CreatePrimitive=function(kind)local g=new_go("Sphere");g:AddComponent(U.Collider);g:AddComponent(U.Renderer);return g end},{__call=function(_,name)return new_go(name)end})
 U.AudioClip={Create=function(name,frames,channels,rate,streaming)
  assert(channels==1 and rate==Audio.sample_rate and streaming==false,"AudioClip creation contract")
  local clip={name=name,length=frames/rate,frames=frames}
  function clip:SetData(samples,offset)
   assert(samples.element_type=="Single" and samples.Length==frames and offset==0,"AudioClip must receive typed Single[] of correct length")
   assert(samples.written==frames,"complete decoded buffer must be uploaded")
   if options.fail_setdata then return false end
   self.samples=samples;t.typed_uploads=t.typed_uploads+1;return true
  end
  return clip
 end}
 typeof=function(kind)return kind end
 CS={System={Single="Single",Array={CreateInstance=function(kind,n)
  assert(kind=="Single" and type(n)=="number"and n>0 and n==math.floor(n),"typed float allocation")
  local a={element_type=kind,Length=n,values={},written=0}
  setmetatable(a,{__newindex=function(self,i,v)
   assert(type(i)=="number"and type(v)=="number"and v==v and math.abs(v)<=1 and i>=0 and i<self.Length and i==math.floor(i),"typed numeric-index Single[] bounds")
   if self.values[i]==nil then self.written=self.written+1 end;self.values[i]=v
  end,__index=function(self,i)if type(i)=="number"then return self.values[i]end end})
  t.typed_arrays[#t.typed_arrays+1]=a;return a
 end}}}
 t.go=new_go("monster_inkwave");t.go.transform.position=vector(0,0,2)
 t.transforms={};t.names={};t.originals={};t.original_names={}
 for i,n in ipairs(Bank.nodes)do
  if n.name~=options.missing then
   local x,y,z=n.position[1]*scale,n.position[2]*scale,n.position[3]*scale
   local qx,qy,qz,qw=n.rotation[1],n.rotation[2],n.rotation[3],n.rotation[4]
   if axis=="z"then z=-z;qx,qy=-qx,-qy elseif axis=="x"then x=-x;qy,qz=-qy,-qz end
   local transform
   if n.name==t.go.name then transform=t.go.transform;transform.localPosition=vector(0,0,2)
   else transform={name=n.name,localPosition=vector(x,y,z),localRotation=quaternion(qx,qy,qz,qw),localScale=vector(n.scale[1],n.scale[2],n.scale[3]),position=vector(x,y,z)}end
   t.transforms[#t.transforms+1]=transform;t.names[n.name]=transform;t.originals[i]={p=transform.localPosition,q=transform.localRotation,s=transform.localScale};t.original_names[n.name]=t.originals[i]
  end
 end
 t.native_animator={enabled=true};t.native_animation={enabled=false};t.native_material={color=U.Color(.2,.4,.7,1)}
 function t.native_animation:Stop()assert(t.native_animator.enabled==false,"disable Animator before stopping legacy auto-play");t.native_stop_calls=(t.native_stop_calls or 0)+1 end
 if options.no_stop then t.native_animation.Stop=nil end
 -- This reproduces native importer default-state playback without changing the
 -- canonical bind data; poses come independently from the binary GLB channels.
 if options.preplayed_death then
  for name,channels in pairs(AutoplayPose)do local r=t.names[name];if r then
   local p=channels.translation;if p then local x,y,z=p[1]*scale,p[2]*scale,p[3]*scale;if axis=="x"then x=-x elseif axis=="z"then z=-z end;r.localPosition=vector(x,y,z)end
   local q=channels.rotation;if q then local x,y,z,w=q[1],q[2],q[3],q[4];if axis=="x"then y,z=-y,-z elseif axis=="z"then x,y=-x,-y end;r.localRotation=quaternion(x,y,z,w)end
   local s=channels.scale;if s then r.localScale=vector(s[1],s[2],s[3])end
  end end
 end
 t.native_renderer={enabled=true,materials=array({t.native_material})}
 local bones={};for i=1,87 do bones[i]=t.transforms[i]end;t.native_skin={bones=array(bones)}
 function t.go:GetComponentsInChildren(kind,includeInactive)
  assert(includeInactive==true,"bind inactive imported nodes too")
  if kind==U.Transform then return array(t.transforms)end
  if kind==U.Animator then return array({t.native_animator})end
  if kind==U.Animation then return array({t.native_animation})end
  if kind==U.Renderer then return array({t.native_renderer})end
  if U.SkinnedMeshRenderer and kind==U.SkinnedMeshRenderer then return array({t.native_skin})end
  return array({})
 end
 t.adapter={U=U,state={clock=0,phase="EXPLORE",attacks={}},runtime_root=new_go("runtime_root")}
 t.P=P;t.presentation=P.new(t.adapter,t.go)
 function t:advance(dt)self.adapter.state.clock=self.adapter.state.clock+dt;self.presentation:update(dt)end
 function t:warm()for i=1,100 do self:advance(.02)end end
 return t
end
return H
'''


def glb_translation(clip_name, node_name, time):
    """Read independent, binary FLOAT glTF track and linearly sample it."""
    blob = (ROOT / "gameplay/packages/monsters/monster_inkwave/model/main.glb").read_bytes()
    magic, version, length = struct.unpack_from("<III", blob)
    assert magic == 0x46546C67 and version == 2 and length == len(blob)
    json_len, json_type = struct.unpack_from("<II", blob, 12)
    assert json_type == 0x4E4F534A
    doc = json.loads(blob[20:20 + json_len])
    bin_start = 20 + json_len + 8
    nodes = {i: n.get("name") for i, n in enumerate(doc["nodes"])}
    animation = next(c for c in doc["animations"] if c["name"] == clip_name)
    channel = next(c for c in animation["channels"] if c["target"]["path"] == "translation" and nodes[c["target"]["node"]] == node_name)
    sampler = animation["samplers"][channel["sampler"]]
    assert sampler.get("interpolation", "LINEAR") == "LINEAR"
    def accessor(index):
        a = doc["accessors"][index]; v = doc["bufferViews"][a["bufferView"]]
        assert a["componentType"] == 5126
        dimensions = {"SCALAR": 1, "VEC3": 3}[a["type"]]
        start = bin_start + v.get("byteOffset", 0) + a.get("byteOffset", 0)
        stride = v.get("byteStride", dimensions * 4)
        return [struct.unpack_from("<" + "f" * dimensions, blob, start + i * stride) for i in range(a["count"])]
    times = [row[0] for row in accessor(sampler["input"])]; values = accessor(sampler["output"])
    lower = max(0, min(len(times) - 1, bisect.bisect_right(times, time) - 1))
    upper = min(len(times) - 1, lower + 1)
    ratio = 0 if lower == upper else max(0, min(1, (time - times[lower]) / (times[upper] - times[lower])))
    return [a + (b - a) * ratio for a, b in zip(values[lower], values[upper])]


def glb_final_pose(clip_name):
    """Independently read all final channel values of a real GLB animation."""
    blob = (ROOT / "gameplay/packages/monsters/monster_inkwave/model/main.glb").read_bytes()
    json_len = struct.unpack_from("<I", blob, 12)[0]
    doc = json.loads(blob[20:20 + json_len]); bin_start = 20 + json_len + 8
    clip = next(c for c in doc["animations"] if c["name"] == clip_name)
    pose = {}
    for channel in clip["channels"]:
        sampler = clip["samplers"][channel["sampler"]]
        a = doc["accessors"][sampler["output"]]; v = doc["bufferViews"][a["bufferView"]]
        assert a["componentType"] == 5126
        dim = {"VEC3": 3, "VEC4": 4}[a["type"]]
        start = bin_start + v.get("byteOffset", 0) + a.get("byteOffset", 0)
        offset = start + (a["count"] - 1) * v.get("byteStride", dim * 4)
        value = list(struct.unpack_from("<" + "f" * dim, blob, offset))
        name = doc["nodes"][channel["target"]["node"]]["name"]
        pose.setdefault(name, {})[channel["target"]["path"]] = value
    return pose


class InkwavePresentationTests(unittest.TestCase):
    def setUp(self):
        from lupa import lua51
        self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        self.lua.globals().TestProjectRoot = str(ROOT)
        self.lua.globals().AutoplayPose = self.lua.table_from(glb_final_pose("death"), recursive=True)
        self.lua.globals().H = self.lua.execute(BOUNDARY)

    def run_lua(self, source):
        self.lua.execute(source)

    def test_actual_glb_sampling_and_import_axis_scale(self):
        expected = glb_translation("attack", "hips", .63)
        self.lua.globals().Expected = self.lua.table_from(expected)
        self.run_lua(r'''
local t=H.make("z",100)
H.check(t.presentation.axis=="z" and math.abs(t.presentation.translation_scale-100)<1e-6,"import reflection and centimeters detected from actual rest pose")
H.check(t.native_animator.enabled==false and t.native_animation.enabled==false,"double animation disabled while explicit curves own transforms")
H.check(t.presentation:play({clip_name="attack",restart=true,loop=false}),"real bridge selects baked attack")
t:advance(.63)
local p=t.names.hips.localPosition
H.check(math.abs(p.x-Expected[1]*100)<.001 and math.abs(p.y-Expected[2]*100)<.001 and math.abs(p.z+Expected[3]*100)<.001,"sampled bank follows binary GLB at independent non-key timestamp")
H.check(t.presentation:status().changed_bone_frames>0,"real rotation curves changed imported transforms")
''')

    def test_missing_required_joint_fails_loudly(self):
        self.run_lua(r'''
local ok,error=pcall(function()return H.make("none",1,{missing="iw_kid"})end)
H.check(not ok and tostring(error):find("INKWAVE_GLTF_JOINTS_MISSING",1,true),"missing required imported rig is rejected")
''')

    def test_preplayed_native_death_cannot_become_the_bind_pose(self):
        self.run_lua(r'''
for _,axis in ipairs({"none","x","z"})do for _,scale in ipairs({1,100})do
 local t=H.make(axis,scale,{preplayed_death=true});local p=t.presentation;local U=t.adapter.U
 H.check(p.axis==axis and math.abs(p.translation_scale-scale)<.0001,"animated input still preserves true importer handedness and units")
 H.check(t.native_stop_calls==1 and not t.native_animator.enabled,"native auto-play writers are stopped before bind-pose recovery")
 H.check(p:status().rest_source=="glb_bank" and p:status().rest_pose_corrected_nodes>0,"preplayed animation was detected and canonical GLB rest established")
 H.check((t.names.iw_kid.localPosition-t.original_names.iw_kid.p).magnitude<.0001 and U.Quaternion.Angle(t.names.iw_kid.localRotation,t.original_names.iw_kid.q)<.01,"constructor immediately removes source death's 90 degree root roll")
 H.check(t.go.transform.localPosition.z==2,"constructor preserves Movement-owned scene placement")
 for _,clip in ipairs({"idle","patrol","chase","attack"})do
  p:play({clip_name=clip,restart=true,loop=clip~="attack"});t:advance(.2)
  H.check(U.Quaternion.Angle(t.names.iw_kid.localRotation,t.original_names.iw_kid.q)<.01,"channels absent from living clips restore canonical upright root")
 end
 p:play({clip_name="death",restart=true,loop=false});t:advance(1.4)
 H.check(U.Quaternion.Angle(t.names.iw_kid.localRotation,t.original_names.iw_kid.q)>80,"real death clip can still deliberately lie down")
 p:reset();t:advance(.2)
 H.check((t.names.iw_kid.localPosition-t.original_names.iw_kid.p).magnitude<.0001 and U.Quaternion.Angle(t.names.iw_kid.localRotation,t.original_names.iw_kid.q)<.01,"restart recovers standing after death even if importer initially auto-played death")
end end
local t=H.make("z",1,{preplayed_death=true,no_stop=true,no_skin_api=true})
H.check(t.presentation:status().ready and not t.presentation:status().skin_diagnostics_available,"optional legacy Stop and skin diagnostic API absence do not block canonical pose recovery")
''')

    def test_skin_and_world_pose_diagnostics_are_observations_only(self):
        self.run_lua(r'''
local t=H.make();local U=t.adapter.U;local p=t.presentation
t.names.head.position=U.Vector3(0,1.7,2);t.names.footL.position=U.Vector3(-.1,.05,2);t.names.footR.position=U.Vector3(.1,.15,2)
t.names.weapon_shooter.position=U.Vector3(0,1.2,2);t.names.muzzle.position=U.Vector3(0,1.2,2.3)
local s=p:status()
H.check(s.skin_diagnostics_available and s.skin_count==1 and s.skin_bone_count==87,"diagnostic reports actual imported skin and referenced bone counts")
H.check(math.abs(s.head_foot_height_m-1.6)<.00001 and math.abs(s.muzzle_forward_dot-1)<.00001,"diagnostic measures upright world height and muzzle direction")
t.names.head.position=U.Vector3(1.7,.1,2);t.names.muzzle.position=U.Vector3(0,1.2,1.7)
s=p:status()
H.check(math.abs(s.head_foot_height_m)<.00001 and math.abs(s.muzzle_forward_dot+1)<.00001,"diagnostic exposes prone height or backward muzzle instead of claiming rendered acceptance")
H.check(t.go.transform.forward.z==1 and t.names.head.position.x==1.7,"diagnostics never rotate actor or rewrite observed model pose")
''')

    def test_inspector_attack_window_retimes_baked_pose_without_early_shot(self):
        before = glb_translation("attack", "hips", .4125)
        firing = glb_translation("attack", "hips", .55)
        self.lua.globals().Before = self.lua.table_from(before)
        self.lua.globals().Firing = self.lua.table_from(firing)
        self.run_lua(r'''
local t=H.make("none");t:warm();local p=t.presentation;local started=t.adapter.state.clock
t.adapter.state.attacks.test_attack={started_at=started,definition={windupSec=1,activeSec=.5,recoverySec=1.4}}
p:play({clip_name="attack",restart=true,loop=false,monster_feedback={event="monster_inkwave_windup",fx_id="charge_shooter",attack_instance_id="test_attack"}})
t:advance(.75);local hips=t.names.hips.localPosition
H.check(p.charge.enabled==true and t.audio_plays==0,"longer authoritative windup holds charge without early shot")
H.check(math.abs(hips.x-Before[1])<.00002 and math.abs(hips.y-Before[2])<.00002 and math.abs(hips.z-Before[3])<.00002,".75 authority seconds sample .4125 baked pre-fire pose")
t:advance(.25);hips=t.names.hips.localPosition
H.check(p.charge.enabled==false,"charge ends on exact Inspector windup boundary")
H.check(math.abs(hips.x-Firing[1])<.00002 and math.abs(hips.y-Firing[2])<.00002 and math.abs(hips.z-Firing[3])<.00002,"1.0 authority seconds sample baked .55 firing boundary")
''')

    def test_logic_root_is_never_overwritten_and_hit_flash_restores_material(self):
        self.run_lua(r'''
local t=H.make();t:warm();local p=t.presentation
local root=t.go.transform;root.position=t.adapter.U.Vector3(10,0,11);root.localPosition=root.position
p:play({clip_name="hit",restart=true,loop=false,monster_feedback={event="monster_inkwave_hit",fx_id="hit_spark"}})
t:advance(.04)
H.check(t.native_material.color.r==1 and t.native_material.color.g==.8,"real hit flash changes imported material")
H.check(root.localPosition.x==10 and root.localPosition.z==11,"curve update preserves Movement-owned logic root")
t:advance(.2)
H.check(t.native_material.color.r==.2 and t.native_material.color.g==.4,"flash expires to original imported color")
p:play({clip_name="death",restart=true,loop=false});t:advance(1.4);p:reset()
H.check(root.localPosition.x==10 and root.localPosition.z==11,"death and reset preserve authoritative scene placement")
''')

    def test_death_reset_restores_root_pose_before_idle(self):
        self.run_lua(r'''
local t=H.make();t.presentation:play({clip_name="death",restart=true,loop=false});t:advance(1.4)
local root=t.names.iw_kid
H.check(root.localPosition.magnitude>.2 and t.adapter.U.Quaternion.Angle(root.localRotation,t.original_names.iw_kid.q)>20,"actual death curves lie down root")
t.presentation:reset();t:advance(.2)
H.check((root.localPosition-t.original_names.iw_kid.p).magnitude<.0001 and t.adapter.U.Quaternion.Angle(root.localRotation,t.original_names.iw_kid.q)<.01,"respawn restores root channels absent from idle clip")
''')

    def test_typed_audio_upload_and_fixed_voice_particle_budget(self):
        self.run_lua(r'''
local t=H.make();t:warm();local p=t.presentation
local expected=0;for _ in pairs(t.audio.clips)do expected=expected+1 end
H.check(t.typed_uploads==expected and p:status().audio_clips_ready==expected,"all real PCM banks become typed AudioClips")
H.check(#p.voices==4 and #p.particles==16,"voice and particle pools have fixed budgets")
local created=#t.created;local arrays=#t.typed_arrays
for i=1,12 do
 H.check(p:play({clip_name="attack",restart=false,loop=false,monster_feedback={event="monster_inkwave_attack",sound_id="shoot_shooter",fx_id="muzzle_shooter",target_position_m={x=0,y=0,z=0}}}),"feedback bridge accepts shot")
end
H.check(t.audio_plays==12 and p:status().audio_events==12 and p:status().fx_events==12,"real sound aliases and FX run for shots")
H.check(#t.created==created and #t.typed_arrays==arrays,"repeated shots never allocate new objects or PCM arrays")
t:advance(.6)
H.check(p.tracer.enabled==false and p.charge.enabled==false,"short-lived lines expire")
for _,v in ipairs(p.particles)do H.check(v.go.active==false,"all droplets expire")end
''')

    def test_audio_setdata_failure_is_not_reported_success(self):
        self.run_lua(r'''
local t=H.make("none",1,{fail_setdata=true})
local ok,error=pcall(function()t:warm()end)
H.check(not ok and tostring(error):find("INKWAVE_AUDIO_SETDATA",1,true),"typed audio upload failure is visible")
H.check(t.typed_uploads==0,"failed native upload not counted as ready")
''')

    def test_hurt_and_frozen_finished_clock_cancel_transient_weapon_fx(self):
        self.run_lua(r'''
local t=H.make();t:warm();local p=t.presentation
p:play({clip_name="attack",restart=true,loop=false,monster_feedback={event="monster_inkwave_windup",fx_id="charge_shooter"}})
t:advance(.1);H.check(p.charge.enabled,"windup charge visible before cancellation")
p:play({clip_name="hit",restart=true,loop=false,monster_feedback={event="monster_inkwave_hit",fx_id="hit_spark"}});p:update(.02)
H.check(not p.charge.enabled,"hurt cancels previous charge immediately")
p:play({clip_name="attack",restart=true,loop=false,monster_feedback={event="monster_inkwave_attack",sound_id="shoot_shooter",fx_id="muzzle_shooter"}})
p:update(.01);H.check(p.tracer.enabled and p.particles[1].go.active,"shot FX active before terminal phase")
t.adapter.state.phase="FINISHED";p:play({clip_name="idle",restart=true,loop=true});p:update(.6)
H.check(not p.tracer.enabled and not p.charge.enabled,"terminal frozen clock cannot preserve weapon lines")
for _,v in ipairs(p.particles)do H.check(not v.go.active,"terminal phase clears transient droplets despite frozen clock")end
''')

    def test_attack_active_feedback_preserves_clip_clock_and_reset_stops_effects(self):
        self.run_lua(r'''
local t=H.make();t:warm();local p=t.presentation
p:play({clip_name="attack",restart=true,loop=false,monster_feedback={event="monster_inkwave_windup",fx_id="charge_shooter"}})
t:advance(.55);local time=p.time
p:play({clip_name="attack",restart=false,loop=false,monster_feedback={event="monster_inkwave_attack",sound_id="shoot_shooter",fx_id="muzzle_shooter"}})
H.check(p.time==time and p.charge_until==0 and p.tracer_until>t.adapter.state.clock,"active feedback continues same animation timeline")
p:reset();t:advance(.02)
H.check(p.clip.name=="idle" and not p.tracer.enabled and not p.charge.enabled,"reset clears previous weapon lines")
for _,v in ipairs(p.voices)do H.check(not v.source.playing,"reset stops every active voice")end
for _,v in ipairs(p.particles)do H.check(not v.go.active,"reset deactivates every droplet")end
''')

    def test_dispose_restores_disabled_native_animation_and_destroys_owned_resources(self):
        self.run_lua(r'''
local t=H.make();t:warm();local p=t.presentation;p:play({clip_name="death",restart=true,loop=false});t:advance(1.4)
p:play({clip_name="hit",restart=true,loop=false,monster_feedback={event="monster_inkwave_hit",fx_id="hit_spark"}});t:advance(.02)
H.check(t.native_material.color.r==1,"test disposes during active flash")
p:dispose()
H.check(t.native_animator.enabled==true and t.native_animation.enabled==false,"restore original native component states")
H.check((t.names.iw_kid.localPosition-t.original_names.iw_kid.p).magnitude<.0001,"dispose restores original local root")
H.check(p.fx_root.destroyed and p.fx_material.destroyed,"dispose destroys owned FX root and material")
H.check(t.native_material.color.r==.2 and t.native_material.color.g==.4,"dispose restores imported material color")
for _,clip in pairs(p.audio_clips)do H.check(clip.destroyed,"dispose destroys every owned AudioClip")end
''')


def run_tests():
    result = CollectingResult()
    unittest.defaultTestLoader.loadTestsFromTestCase(InkwavePresentationTests).run(result)
    return {"ok": result.wasSuccessful(), "testsRun": result.testsRun,
            "assertions": result.assertions, "checks": result.checks,
            "runtime": "lupa.lua51",
            "scope": "Real GLB-derived curves, decoder and presentation Lua; strict Unity boundary doubles only. No rendered or audible native acceptance."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--save-report", type=Path)
    args = parser.parse_args(); report = run_tests()
    if args.save_report:
        args.save_report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    if args.json: print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(("PASS" if report["ok"] else "FAIL") + f" — presentation: {report['testsRun']} cases / {report['assertions']} assertions")
        for check in report["checks"]:
            print(("PASS " if check["passed"] else "FAIL ") + check["name"])
            if "detail" in check: print(check["detail"], file=sys.stderr)
    return 0 if report["ok"] else 1


if __name__ == "__main__": raise SystemExit(main())
