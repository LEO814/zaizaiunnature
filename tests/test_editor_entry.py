#!/usr/bin/env python3
"""Regression tests for the actual generated native entry and Inspector loading.

Runs the current 57-module entry, actual profile scripts, Adapter, services,
setup and UI controllers under Lua 5.1 and 5.4. Unity/Douyin objects are SDK
doubles: this checks startup ordering and configuration propagation, not native
rendering or Inspector serialization. No production code is replaced.
"""
from __future__ import annotations

import argparse
import importlib.metadata
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from bundle_lua import bundle  # noqa: E402
sys.path.insert(0, str(ROOT / "tests"))
from test_inkwave_presentation import glb_final_pose  # noqa: E402

SCOPE = (
    "Generated native entry, profile scripts and real Demo/Adapter/services/controllers "
    "under Lua 5.1 and 5.4; only Unity/Douyin SDK objects are doubles. Checks deferred "
    "Start, all-three-profile readiness, explicit loading failure and Inspector value "
    "propagation into spawned HP/HUD. Does not claim native rendering or serialization."
)

SDK_DOUBLE = r'''
local H={checks=0,created=0,lookups=0,actor_reads=0,logs={},errors={},nodes={},actor_ready=true}
function H.check(condition,message)
  assert(condition,message);H.checks=H.checks+1
end
local V={};V.__index=function(v,k)
 if k=='magnitude'then return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)end
 if k=='sqrMagnitude'then return v.x*v.x+v.y*v.y+v.z*v.z end
 return V[k]
end
local function xyz(x,y,z)return setmetatable({x=x,y=y,z=z},V)end
V.__add=function(a,b)return xyz(a.x+b.x,a.y+b.y,a.z+b.z)end
V.__sub=function(a,b)return xyz(a.x-b.x,a.y-b.y,a.z-b.z)end
V.__mul=function(a,b)if type(a)=='number'then a,b=b,a end;return xyz(a.x*b,a.y*b,a.z*b)end
local Q={};Q.__index=Q
local function quaternion(x,y,z,w)return setmetatable({x=x,y=y,z=z,w=w},Q)end
Q.__mul=function(a,b)return quaternion(a.w*b.x+a.x*b.w+a.y*b.z-a.z*b.y,a.w*b.y-a.x*b.z+a.y*b.w+a.z*b.x,a.w*b.z+a.x*b.y-a.y*b.x+a.z*b.w,a.w*b.w-a.x*b.x-a.y*b.y-a.z*b.z)end
local function qdot(a,b)return a.x*b.x+a.y*b.y+a.z*b.z+a.w*b.w end
local function qnorm(q)local d=math.sqrt(qdot(q,q));return quaternion(q.x/d,q.y/d,q.z/d,q.w/d)end
local function array(values)local a={Length=#values};function a:GetValue(i)return values[i+1]end;return a end
local function rgba(r,g,b,a)return{r=r,g=g,b=b,a=a}end
local function new_go(name,seed)
  local go={name=name,active=true,components={},bindings={}}
  go.transform={name=name,position=xyz(0,0,0),localPosition=xyz(0,0,0),localRotation=quaternion(0,0,0,1),localScale=xyz(1,1,1),forward=xyz(0,0,1),rotation=quaternion(0,0,0,1)}
  function go.transform:SetParent(parent,keep_world)self.parent=parent end
  function go:GetDouyinScript(name)H.lookups=H.lookups+1;return self.bindings[name]end
  function go:GetComponent(kind)return self.components[kind]end
  function go:AddComponent(kind)
    local c={gameObject=self,enabled=true,material={color=rgba(1,1,1,1)},points={}}
    c.materials=array({c.material})
    c.onClick={listeners={}}
    function c.onClick:AddListener(fn)self.listeners[#self.listeners+1]=fn end
    function c:SetPosition(index,p)self.points[index]=p end
    function c:Play()self.playing=true;self.isPlaying=true end
    function c:Stop()self.playing=false;self.isPlaying=false end
    self.components[kind]=c;return c
  end
  function go:SetActive(value)self.active=value end
  function go:GetComponentsInChildren(kind,includeInactive)
    assert(includeInactive==true,'include inactive GLTF nodes')
    if kind=='Transform'then return array(self.rig or{self.transform})end
    local c=self.components[kind];return array(c and{c}or{})
  end
  go:AddComponent('Renderer')
  go:AddComponent('Collider')
  H.nodes[name]=go
  if not seed then H.created=H.created+1 end
  return go
end
local U={Vector2=function(x,y)return{x=x,y=y}end,Color=rgba,
  Renderer='Renderer',Collider='Collider',CharacterController='CharacterController',
  Transform='Transform',Animator='Animator',Animation='Animation',SkinnedMeshRenderer='SkinnedMeshRenderer',AudioSource='AudioSource',
  PrimitiveType={Sphere='Sphere'},AudioRolloffMode={Linear='Linear'},
  CapsuleCollider='CapsuleCollider',LineRenderer='LineRenderer',Canvas='Canvas',
  RectTransform='RectTransform',RenderMode={ScreenSpaceOverlay=0},
  TextAnchor={MiddleCenter=0},Time={unscaledDeltaTime=.05},
  KeyCode={E='E',F='F',B='B',H='H',Escape='Escape',LeftShift='Shift',LeftControl='Ctrl'},
  Input={GetKey=function()return false end,GetKeyDown=function()return false end},
  Debug={Log=function(m)H.logs[#H.logs+1]=m end,LogError=function(m)H.errors[#H.errors+1]=m end},
  Shader={Find=function(name)return name end},Material=function(shader)return{shader=shader}end,
  Resources={FindObjectsOfTypeAll=function()return{Length=0}end},
  Font={CreateDynamicFontFromOSFont=function(name,size)return{name=name,size=size}end},
  Object={Destroy=function(go)if go then go.destroyed=true end end},
  UI={Image='Image',Text='Text',Button='Button',GraphicRaycaster='GraphicRaycaster',
    CanvasScaler={ScaleMode={ScaleWithScreenSize=0}}}}
U.Vector3=setmetatable({Lerp=function(a,b,k)return a+(b-a)*k end},{__call=function(_,x,y,z)return xyz(x,y,z)end})
U.Quaternion=setmetatable({identity=quaternion(0,0,0,1),
 Inverse=function(q)local d=qdot(q,q);return quaternion(-q.x/d,-q.y/d,-q.z/d,q.w/d)end,
 Angle=function(a,b)return math.acos(math.min(1,math.abs(qdot(qnorm(a),qnorm(b)))))*360/math.pi end,
 Slerp=function(a,b,k)
  a,b=qnorm(a),qnorm(b);local d=qdot(a,b);if d<0 then b=quaternion(-b.x,-b.y,-b.z,-b.w);d=-d end
  local x,y;if d>.9995 then x,y=1-k,k else local theta=math.acos(math.min(1,d));x=math.sin((1-k)*theta)/math.sin(theta);y=math.sin(k*theta)/math.sin(theta)end
  return qnorm(quaternion(a.x*x+b.x*y,a.y*x+b.y*y,a.z*x+b.z*y,a.w*x+b.w*y))
 end},{__call=function(_,x,y,z,w)return quaternion(x,y,z,w)end})
function U.Quaternion.Euler(x,y,z)return{x=x,y=y,z=z}end
function U.Quaternion.LookRotation(v)return{forward=v}end
U.GameObject=setmetatable({Find=function(name)return H.nodes[name]end,CreatePrimitive=function()return new_go('primitive_'..H.created)end},{__call=function(_,name)return new_go(name)end})
U.AudioClip={Create=function(name,frames,channels,rate,streaming)
 assert(channels==1 and rate==22050 and streaming==false,'AudioClip contract')
 local c={name=name,length=frames/rate};function c:SetData(samples,offset)assert(samples.kind=='Single'and samples.Length==frames and offset==0 and samples.written==frames,'typed complete PCM upload');return true end;return c
end}
H.host=new_go('demo_root',true)
for _,name in ipairs({'player_default','monster_inkwave_actor','chest_basic','chest_basic_lid','gate_exit'})do new_go(name,true)end
local imported=H.nodes.monster_inkwave_actor;imported.rig={imported.transform};H.rig_names={}
for i,n in ipairs(ModelNodes)do
 local t
 t={name=n.name,localPosition=xyz(n.position[1],n.position[2],-n.position[3]),localRotation=quaternion(-n.rotation[1],-n.rotation[2],n.rotation[3],n.rotation[4]),localScale=xyz(n.scale[1],n.scale[2],n.scale[3]),position=xyz(n.position[1],n.position[2],-n.position[3])}
 imported.rig[#imported.rig+1]=t;H.rig_names[n.name]=t
end
imported:AddComponent('Animator');imported:AddComponent('Animation')
local skin=imported:AddComponent('SkinnedMeshRenderer');local bones={}
for i,name in ipairs(ModelSkinNames)do bones[i]=assert(H.rig_names[name],'actual GLB skin joint exists')end
skin.bones=array(bones)
function H.seed_preplayed_death()
 for name,channels in pairs(AutoplayPose)do local t=H.rig_names[name];if t then
  local p=channels.translation;if p then t.localPosition=xyz(p[1],p[2],-p[3])end
  local q=channels.rotation;if q then t.localRotation=quaternion(-q[1],-q[2],q[3],q[4])end
  local s=channels.scale;if s then t.localScale=xyz(s[1],s[2],s[3])end
 end end
end
H.actor={gameObject=new_go('native_actor',true),position=xyz(-3,0,-3),speed=3.2,immobilized=false}
H.actor.gameObject:AddComponent('CharacterController')
function H.actor:Teleport(p,q)
  self.position=p;self.gameObject.transform.position=p;self.gameObject.transform.rotation=q
  if q.forward then self.gameObject.transform.forward=q.forward end
end
function H.actor:Immobilize(value)self.immobilized=value end
CS={UnityEngine=U,System={Single='Single',Array={CreateInstance=function(kind,n)
 assert(kind=='Single'and n>0,'System.Single array')
 local a={kind=kind,Length=n,values={},written=0}
 setmetatable(a,{__newindex=function(self,index,value)
  assert(type(index)=='number'and type(value)=='number'and math.abs(value)<=1 and index>=0 and index<self.Length,'valid typed Single[] numeric-index PCM sample')
  if self.values[index]==nil then self.written=self.written+1 end;self.values[index]=value
 end,__index=function(self,index)if type(index)=='number'then return self.values[index]end end})
 return a
end}},DouyinActorService={GetLocalActor=function()
  H.actor_reads=H.actor_reads+1;return H.actor_ready and H.actor or nil
end}}
typeof=function(value)return value end
self={gameObject=H.host}
local function load_environment(source,name,values)
  local env=setmetatable(values or{},{__index=_G})
  local fn,err
  if setfenv then fn,err=loadstring(source,name);if fn then setfenv(fn,env)end
  else fn,err=load(source,name,'t',env)end
  assert(fn,err);fn();return env
end
function H.attach(kind,values)
  local name=kind..'_attributes.lua'
  local env=load_environment(ProfileSources[kind],name,values)
  local go=kind=='match'and H.host or H.nodes[kind=='player'and'player_default'or'monster_inkwave_actor']
  go.bindings[name]={script=env};return env
end
function H.detach(kind)
  local go=kind=='match'and H.host or H.nodes[kind=='player'and'player_default'or'monster_inkwave_actor']
  go.bindings[kind..'_attributes.lua']=nil
end
function H.attach_all()
  H.attach('player',{playerStartHp=90,playerWalkSpeedMps=4.2,playerBagSlots=18})
  H.attach('monster',{monsterMaxHp=70})
  H.attach('match',{matchRoundDurationSec=450,matchExtractionHoldSec=4.5})
end
return H
'''


class EditorEntryTests(unittest.TestCase):
    runtime_name = "lua51"

    def setUp(self):
        from lupa import lua51, lua54

        module = {"lua51": lua51, "lua54": lua54}[self.runtime_name]
        self.lua = module.LuaRuntime(unpack_returned_tuples=True)
        def lua_value(value):
            if isinstance(value, dict): return self.lua.table_from({k: lua_value(v) for k, v in value.items()})
            if isinstance(value, list): return self.lua.table_from([lua_value(v) for v in value])
            return value
        bank = json.loads((ROOT / "gameplay/packages/monsters/monster_inkwave/animations/runtime_bank.json").read_text())
        self.lua.globals().ModelNodes = lua_value(bank["nodes"])
        blob = (ROOT / "gameplay/packages/monsters/monster_inkwave/model/main.glb").read_bytes()
        glb = json.loads(blob[20:20 + int.from_bytes(blob[12:16], "little")])
        self.lua.globals().ModelSkinNames = lua_value([glb["nodes"][i]["name"] for i in glb["skins"][0]["joints"]])
        self.lua.globals().AutoplayPose = lua_value(glb_final_pose("death"))
        self.lua.globals().ProfileSources = self.lua.table_from({
            name: (ROOT / "scripts/modules" / f"{name}_attributes.lua").read_text(encoding="utf-8")
            for name in ("player", "monster", "match")
        })
        self.lua.globals().H = self.lua.execute(SDK_DOUBLE)
        self.entry_source = (ROOT / "scripts/modules/demo_entry.lua").read_text(encoding="utf-8")
        self.lua.globals().Entry = self.lua.execute(self.entry_source)

    def run_lua(self, source):
        self.lua.execute(source)

    def test_entry_contains_current_canonical_modules_and_loads(self):
        expected, count = bundle(ROOT, "gameplay.demo")
        expected = expected.replace(
            "-- Generated project scaffold bundle. SDK mapping and gameplay remain unimplemented.",
            "-- Generated canonical Demo bundle. Native SDK mapping is isolated in zaizai adapter.",
        )
        actual = self.entry_source.split("local Demo = (function()\n", 1)[1].rsplit("\nend)()\nlocal instance", 1)[0]
        self.assertEqual(actual, expected)
        self.assertEqual(count, 57)
        self.run_lua(r'''
H.check(type(Entry.GetStatus)=='function'and type(Entry.GetSnapshot)=='function'and type(Entry.GetQAResults)=='function','actual entry public functions loaded')
H.check(Entry.GetStatus()=='WAIT_ACTOR'and not Entry.GetSnapshot().ready,'loading entry performs no start')
H.check(H.actor_reads==0 and H.lookups==0 and H.created==0,'entry load has no native initialization')
''')

    def test_start_is_deferred_and_actor_readiness_is_retried(self):
        self.run_lua(r'''
H.attach_all();H.actor_ready=false
Start()
H.check(Entry.GetStatus()=='WAIT_ACTOR'and Entry.GetSnapshot().pending,'Start marks pending')
H.check(H.actor_reads==0 and H.lookups==0 and H.created==0,'Start does not read actor or child profiles')
for i=1,3 do Update()end
H.check(Entry.GetStatus()=='WAIT_ACTOR'and H.lookups==0 and H.created==0,'missing actor waits before profile lookup')
H.actor_ready=true;Update()
H.check(Entry.GetStatus()=='READY'and Entry.GetSnapshot().ready,'actor arrival permits delayed initialization')
H.check(#H.errors==0,'no startup error')
''')

    def test_each_of_three_missing_profiles_blocks_all_initialization(self):
        # Fresh actual entry/state for each child to avoid a prior successful run.
        total_checks = 0
        for kind in ("player", "monster", "match"):
            if kind != "player":
                self.setUp()
            self.lua.globals().MissingKind = kind
            self.run_lua(r'''
H.attach_all();H.detach(MissingKind);Start()
for i=1,3 do Update()end
H.check(Entry.GetStatus()=='WAIT_ACTOR'and not Entry.GetSnapshot().ready,'missing '..MissingKind..' profile waits')
H.check(H.created==0 and not H.nodes.demo_runtime and not H.nodes.demo_ui,'no world/UI/round initialized with missing profile')
H.check(#H.errors==0,'early waiting is not failure')
if MissingKind=='player'then H.attach('player',{playerStartHp=90,playerBagSlots=18})
elseif MissingKind=='monster'then H.attach('monster',{monsterMaxHp=70})
else H.attach('match',{matchRoundDurationSec=450,matchExtractionHoldSec=4.5})end
Update();local snap=Entry.GetSnapshot()
H.check(Entry.GetStatus()=='READY'and snap.player.hp==90 and snap.monster.hp==70,'late child readiness uses overrides without fallback')
''')
            total_checks += int(self.lua.globals().H.checks)
        self.additional_lua_assertions = total_checks - int(self.lua.globals().H.checks)

    def test_component_without_script_or_get_profile_waits(self):
        self.run_lua(r'''
H.attach_all();local go=H.nodes.monster_inkwave_actor
go.bindings['monster_attributes.lua']={};Start();Update()
H.check(Entry.GetStatus()=='WAIT_ACTOR'and H.created==0,'component without initialized script waits')
go.bindings['monster_attributes.lua']={script={}};Update()
H.check(Entry.GetStatus()=='WAIT_ACTOR'and H.created==0,'script without exported GetProfile waits')
H.attach('monster',{monsterMaxHp=70});Update()
H.check(Entry.GetStatus()=='READY'and Entry.GetSnapshot().monster.max_hp==70,'script ready later starts real round with override')
''')

    def test_throwing_or_malformed_profile_is_not_defaulted(self):
        self.run_lua(r'''
H.attach_all();local go=H.nodes.monster_inkwave_actor
go.bindings['monster_attributes.lua']={script={GetProfile=function()error('test-not-initialized')end}};Start();Update()
H.check(Entry.GetStatus()=='WAIT_ACTOR'and H.created==0,'provider error waits without default world')
go.bindings['monster_attributes.lua']={script={GetProfile=function()return 'bad-profile'end}};Update()
H.check(Entry.GetStatus()=='WAIT_ACTOR'and H.created==0,'non-table profile waits without default world')
H.attach('monster',{monsterMaxHp=70});Update()
H.check(Entry.GetStatus()=='READY'and Entry.GetSnapshot().monster.hp==70,'recovered provider starts correctly')
''')

    def test_real_globals_profiles_propagate_to_spawn_hud_and_runtime(self):
        self.run_lua(r'''
H.attach_all();Start();Update();Update()
local snap=Entry.GetSnapshot()
H.check(Entry.GetStatus()=='READY'and snap.ready,'actual entry initialized')
H.check(snap.player.hp==90 and snap.player.max_hp==100,'player startHp override reaches actual Characters instance')
H.check(snap.monster.hp==70 and snap.monster.max_hp==70,'monster maxHp override reaches actual Characters instance')
H.check(snap.bag.slots==18 and #snap.bag.items==0 and snap.player.equipment.weapon.entity_id=='weapon_shovel','inventory capacity override and equipped shovel reach actual setup')
H.check(snap.speed_write_ok and math.abs(snap.speed_readback-4.2)<.001,'movement override reaches actual Adapter actor mapping')
H.check(snap.collider_apply_ok and snap.collider_readback.height==1.8,'native collider mapping executes through SDK double')
local text=H.nodes.demo_ui_status.components.Text.text
H.check(string.find(text,'HP 90 / 100',1,true)and string.find(text,'怪物 HP 70',1,true),'real UI controller presents actual overridden HP')
H.check(string.find(text,'时间 7:29',1,true),'round duration override reaches actual HUD timer')
H.check(snap.phase=='EXPLORE'and snap.clock>.0 and snap.run_id~='','real match and clock initialize once profiles ready')
H.check(snap.presentation and snap.presentation.ready and snap.presentation.curve_frames>=1,'real presentation runs with GLTF bank')
H.check(#H.logs==2 and #H.errors==0,'one successful native entry initialization plus rig-binding log')
''')

    def test_defaults_still_work_when_ready_profile_has_no_overrides(self):
        self.run_lua(r'''
H.attach('player');H.attach('monster');H.attach('match');Start();Update();Update()
local snap=Entry.GetSnapshot()
H.check(Entry.GetStatus()=='READY'and snap.player.hp==100 and snap.player.max_hp==100,'ready default player globals are valid')
H.check(snap.monster.hp==60 and snap.monster.max_hp==60,'ready default monster globals are valid')
H.check(snap.bag.slots==12 and math.abs(snap.speed_readback-3.2)<.001,'default capacity and movement remain valid')
''')

    def test_deferred_entry_cannot_capture_importer_death_as_rest(self):
        self.run_lua(r'''
H.attach_all();H.detach('monster');Start();Update()
H.check(Entry.GetStatus()=='WAIT_ACTOR','entry remains pending before all attributes arrive')
H.seed_preplayed_death()
H.check(math.abs(H.rig_names.iw_kid.localRotation.z)>.7,'real binary death pose was applied during native loading delay')
H.attach('monster',{monsterMaxHp=70});Update();Update()
local snap=Entry.GetSnapshot();local r=H.rig_names.iw_kid
H.check(Entry.GetStatus()=='READY'and snap.presentation.rest_source=='glb_bank','actual bundled presentation establishes explicit GLB rest after delayed startup')
H.check(math.abs(r.localRotation.z)<.0001 and math.abs(r.localRotation.w-1)<.0001 and r.localPosition.magnitude<.0001,'alive rig is upright rather than preserving auto-played death offset')
H.check(snap.presentation.rest_pose_corrected_nodes>0,'actual entry reports recovery of contaminated imported pose')
H.check(snap.presentation.skin_diagnostics_available and snap.presentation.skin_count==1 and snap.presentation.skin_bone_count==87,'actual entry reads skin references matching GLB joint manifest')
H.check(snap.monster.hp==70 and snap.player.hp==90,'pose recovery does not alter Inspector HP authority')
''')

    def test_loading_timeout_fails_explicitly_without_starting_world(self):
        self.run_lua(r'''
H.attach_all();H.detach('monster');Start()
for i=1,119 do Update()end
H.check(Entry.GetStatus()=='WAIT_ACTOR'and #H.errors==0 and H.created==0,'119 profile attempts remain pending')
Update()
H.check(Entry.GetStatus()=='FAILED'and #H.errors==1 and H.created==0,'120th failed attempt reports terminal error before initialization')
H.check(string.find(H.errors[1],'Inspector profile loading failed',1,true)and string.find(H.errors[1],'monster_attributes.lua',1,true),'failure identifies unready provider')
H.attach('monster',{monsterMaxHp=70});Update()
H.check(Entry.GetStatus()=='FAILED'and #H.errors==1 and H.created==0,'failed entry cannot silently continue after terminal error')
''')

    def test_destroy_releases_real_adapter_resources(self):
        self.run_lua(r'''
H.attach_all();Start();Update();Update()
local runtime=H.nodes.demo_runtime;local ui=H.nodes.demo_ui
H.actor.immobilized=true;OnDestroy()
H.check(runtime.destroyed and ui.destroyed,'actual adapter and UI disposal release SDK resources')
H.check(not H.actor.immobilized and H.actor.speed==3.2,'actual adapter restores actor mobility')
H.check(#H.errors==0,'dispose produces no entry error')
''')


class EditorEntryLua54Tests(EditorEntryTests):
    runtime_name = "lua54"


class CollectingResult(unittest.TestResult):
    def __init__(self):
        super().__init__()
        self.checks = []
        self.assertions = 0

    def addSuccess(self, test):
        super().addSuccess(test)
        count = int(test.lua.globals().H.checks) + getattr(test, "additional_lua_assertions", 0)
        self.assertions += count
        self.checks.append({"runtime": test.runtime_name, "name": test._testMethodName, "passed": True, "luaAssertions": count})

    def addFailure(self, test, err):
        super().addFailure(test, err)
        self.checks.append({"runtime": test.runtime_name, "name": test._testMethodName, "passed": False, "detail": self.failures[-1][1]})

    def addError(self, test, err):
        super().addError(test, err)
        self.checks.append({"runtime": test.runtime_name, "name": test._testMethodName, "passed": False, "detail": self.errors[-1][1]})


def run_tests():
    suite = unittest.TestSuite([
        unittest.defaultTestLoader.loadTestsFromTestCase(EditorEntryTests),
        unittest.defaultTestLoader.loadTestsFromTestCase(EditorEntryLua54Tests),
    ])
    result = CollectingResult()
    suite.run(result)
    return {
        "ok": result.wasSuccessful(),
        "runtime": {"package": "lupa", "version": importlib.metadata.version("lupa"), "modules": ["lupa.lua51", "lupa.lua54"]},
        "entry": "scripts/modules/demo_entry.lua",
        "moduleCount": 57,
        "testsRun": result.testsRun,
        "luaAssertions": result.assertions,
        "checks": result.checks,
        "scope": SCOPE,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--save-report", type=Path)
    args = parser.parse_args(argv)
    result = run_tests()
    if args.save_report:
        args.save_report.parent.mkdir(parents=True, exist_ok=True)
        args.save_report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(("PASS" if result["ok"] else "FAIL") + " — real generated entry startup regression")
        print(f"{result['testsRun']} cases, {result['luaAssertions']} successful Lua assertions")
        for check in result["checks"]:
            print(("PASS " if check["passed"] else "FAIL ") + check["runtime"] + " " + check["name"])
            if not check["passed"]:
                print(check["detail"], file=sys.stderr)
        print(SCOPE)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
