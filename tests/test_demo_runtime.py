#!/usr/bin/env python3
"""Meaningful Lua 5.1 integration checks for the native whitebox Demo.

Runs real state/services and gameplay controllers. Only native transforms,
input-facing detection and visual SDK operations are replaced. The authored
Spatial math/path implementation is real. No editor, model, UI rendering,
networking or persistent economy acceptance is claimed.

Optional QA dependency: lupa==2.6. Run this file with --json for a report.
"""
from __future__ import annotations

import argparse
import importlib.metadata
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCOPE = (
    "Real Lua state/services, match/settlement and player/monster/shovel/heal/chest/"
    "inventory controllers; native transform/detection/visual SDK doubles only. "
    "Authored Spatial math/path is real. No editor preview, import, UI rendering, "
    "multiplayer, warehouse, shop or persistence acceptance."
)

HARNESS = r'''
package.path = TestProjectRoot .. "/?.lua;" .. package.path
local State=require("gameplay.core.state")
local Services=require("gameplay.core.services")
local Spatial=require("gameplay.core.spatial")
local Config=require("gameplay.core.config")
local Match=require("gameplay.systems.match.controller")
local Settlement=require("gameplay.systems.settlement.controller")
local Player=require("gameplay.packages.player.player_default.controller")
local Monster=require("gameplay.packages.monsters.monster_cube.controller")
local Shovel=require("gameplay.packages.weapons.weapon_shovel.controller")
local Heal=require("gameplay.packages.items.item_heal_small.controller")
local Chest=require("gameplay.packages.interactables.chest_basic.controller")
local Inventory=require("gameplay.systems.inventory_meta.controller")
local definitions={
  player_default=require("gameplay.packages.player.player_default.definition"),
  monster_cube=require("gameplay.packages.monsters.monster_cube.definition"),
  weapon_shovel=require("gameplay.packages.weapons.weapon_shovel.definition"),
  item_heal_small=require("gameplay.packages.items.item_heal_small.definition"),
  item_treasure=require("gameplay.packages.items.item_treasure.definition"),
}
local function clone(value)
  if type(value)~="table" then return value end
  local t={};for k,v in pairs(value)do t[k]=clone(v)end;return t
end
local function reply(r,ok,reason,data)
  return {ok=ok,reason=reason or(ok and"OK"or"SDK_DOUBLE_REJECTED"),request_id=r and r.request_id,data=data or{}}
end
local H={assertion_count=0}
function H.check(value,reason)
  assert(value,reason);H.assertion_count=H.assertion_count+1
end
function H.make()
  local t={state=State.new(Config),positions={},forwards={},animations={},moves=0,paths=0,
    map={walls={},bounds={min_x=-20,max_x=20,min_z=-20,max_z=20}}}
  local spatial={
    distance=Spatial.distance,
    position=function(id)return t.positions[id]end,
    los=function(a,b)return not Spatial.blocked(a,b,t.map.walls,0)end,
  }
  t.services=Services.new(t.state,Config,definitions,spatial)
  local movement={}
  function movement:read_position(r)
    local p=t.positions[r.instance_id]
    if not p then return reply(r,false,"MISSING_ENTITY")end
    return reply(r,true,nil,{position_m=clone(p),forward_m=clone(t.forwards[r.instance_id]or{x=0,y=0,z=1})})
  end
  function movement:move_to(r)
    local p,goal=t.positions[r.instance_id],r.goal_m
    if not p or not goal then return reply(r,false,"MISSING_ENTITY")end
    local d=Spatial.distance(p,goal)
    if d<=.001 then return reply(r,true,"ARRIVED",{position_m=clone(p)})end
    local amount=math.min(d,math.max(0,r.speed_mps or 0)*(r.dt_sec or .05))
    local q={x=p.x+(goal.x-p.x)*amount/d,y=p.y,z=p.z+(goal.z-p.z)*amount/d}
    if Spatial.blocked(p,q,t.map.walls,.35)then return reply(r,false,"BLOCKED")end
    t.positions[r.instance_id]=q
    if amount>0 then
      t.forwards[r.instance_id]={x=(goal.x-p.x)/d,y=0,z=(goal.z-p.z)/d}
      t.moves=t.moves+1
    end
    return reply(r,true,nil,{position_m=clone(q)})
  end
  function movement:stop(r)return reply(r,true)end
  t.services.Movement=movement
  local navigation={}
  function navigation:find_path(r)
    t.paths=t.paths+1
    local path,reason=Spatial.path(r.from_m,r.to_m,t.map,.35)
    return reply(r,path~=nil,reason,{waypoints=path or{},task_id=r.request_id})
  end
  function navigation:cancel_query(r)return reply(r,true)end
  t.services.Navigation=navigation
  local interaction={}
  function interaction:query_target(r)
    local source=r.user_instance_id or r.source_instance_id
    local a,b=t.positions[source],t.positions[r.target_instance_id]
    if not a or not b then return reply(r,false,"MISSING_ENTITY")end
    local d=Spatial.distance(a,b)
    local range=r.range_m or r.max_distance_m or Config.interaction.maxDistanceM
    local angle=r.full_angle_deg or 360
    local f=t.forwards[source]or{x=0,y=0,z=1}
    local angular=angle>=359 or d<.001 or (f.x*(b.x-a.x)+f.z*(b.z-a.z))/d>=math.cos(angle*.5*math.pi/180)
    local sight=not Spatial.blocked(a,b,t.map.walls,0)
    return reply(r,true,nil,{distance_m=d,in_range=d<=range,angular_valid=angular,
      line_of_sight=sight,visible=d<=range and angular and sight})
  end
  function interaction:try_begin(r)
    if t.state.phase~="EXPLORE" then return reply(r,false,"WRONG_PHASE")end
    local sensed=self:query_target(r)
    if not sensed.ok or not sensed.data.visible then return reply(r,false,"OUT_OF_RANGE_OR_BLOCKED",sensed.data)end
    return reply(r,true,nil,sensed.data)
  end
  function interaction:cancel(r)return reply(r,true)end
  t.services.Interaction=interaction
  local assets={}
  function assets:play_clip(r)t.animations[#t.animations+1]=clone(r);return reply(r,true,"VISUAL_SDK_DOUBLE")end
  function assets:destroy(r)return reply(r,true)end
  t.services.Assets=assets
  t.context={state=t.state,config=Config,definitions=definitions,services=t.services,is_ready=true,request_sequence=0}
  function t.context:next_request_id(prefix)
    self.request_sequence=self.request_sequence+1
    return self.state.run_id..":"..prefix..":"..self.request_sequence
  end
  t.match=Match.new(t.context)
  t.settlement=Settlement.new(t.context)
  function t:request(prefix,fields)
    fields=fields or{};fields.run_id=self.state.run_id;fields.request_id=self.context:next_request_id(prefix);return fields
  end
  function t:start_round()
    if self.objects then for _,o in pairs(self.objects)do if o.dispose then o:dispose()end end end
    H.check(self.match:start().ok,"match starts real Session")
    self.positions={player_local={x=0,y=0,z=0},monster_cube_1={x=0,y=0,z=2},chest_demo={x=0,y=0,z=.5},exit_demo={x=0,y=0,z=-1}}
    self.forwards={player_local={x=0,y=0,z=1},monster_cube_1={x=0,y=0,z=1}}
    self.map.walls={}
    H.check(self.services.Characters:spawn(self:request("spawn_player",{instance_id="player_local",entity_id="player_default",position_m=self.positions.player_local})).ok,"player spawn")
    H.check(self.services.Characters:spawn(self:request("spawn_monster",{instance_id="monster_cube_1",entity_id="monster_cube",position_m=self.positions.monster_cube_1})).ok,"monster spawn")
    H.check(self.services.Inventory:_add_item({container_id="bag_player_local",id="shovel_local",entity_id="weapon_shovel",count=1,equip_slot="weapon"}).ok,"starting shovel")
    H.check(self.services.Inventory:_create_container({id="chest_demo",owner_id="chest_demo",slots=6,position_m=self.positions.chest_demo}).ok,"chest container")
    H.check(self.services.Inventory:_add_item({container_id="chest_demo",id="medicine_chest",entity_id="item_heal_small",count=2}).ok,"medicine seed")
    H.check(self.services.Inventory:_add_item({container_id="chest_demo",id="treasure_chest",entity_id="item_treasure",count=1}).ok,"treasure seed")
    self.objects={
      player=Player.new(self.context,{id="player_local"}),
      monster=Monster.new(self.context,{id="monster_cube_1",route={{x=0,y=0,z=2},{x=0,y=0,z=5}}}),
      weapon=Shovel.new(self.context,{id="weapon_controller",owner_instance_id="player_local",item_instance_id="shovel_local"}),
      heal=Heal.new(self.context,{id="heal_controller",owner_instance_id="player_local"}),
      chest=Chest.new(self.context,{id="chest_demo",container_id="chest_demo"}),
    }
    self.objects.inventory=Inventory.new(self.context,{heal=self.objects.heal})
    for _,o in pairs(self.objects)do H.check(o:start()==true,"real object controller starts")end
  end
  function t:step(dt,ai)
    self.objects.player:update(dt)
    self.objects.chest:update(dt)
    self.objects.weapon:update(dt)
    self.objects.heal:update(dt)
    if ai~=false then self.objects.monster:update(dt)end
    self.objects.inventory:update(dt)
    return self.settlement:update(dt)
  end
  function t:time(seconds,ai)
    local left=seconds
    while left>1e-8 do local dt=math.min(.05,left);self:step(dt,ai);left=left-dt end
  end
  function t:bag()return self.objects.inventory:read_bag().data.bag end
  function t:item_count(entity_id)
    local n=0;for _,item in ipairs(self:bag().items)do if item.entity_id==entity_id then n=n+item.count end end;return n
  end
  function t:pickup_all()
    H.check(self.objects.chest:open().ok,"chest opens")
    H.check(self.objects.chest:pickup("medicine_chest",2).ok,"medicine transfer")
    H.check(self.objects.chest:pickup("treasure_chest",1).ok,"treasure transfer")
    self.objects.chest:close()
  end
  function t:wall_on()self.map.walls={{x=0,z=1,sx=40,sz=.2}}end
  function t:face_player()
    self.positions.monster_cube_1={x=0,y=0,z=2}
    self.forwards.monster_cube_1={x=0,y=0,z=-1}
  end
  function t:direct_attack(source)
    return self.services.Combat:try_begin_attack(self:request("direct_attack",{source_instance_id=source or"monster_cube_1",attack_id="primary"}))
  end
  function t:direct_hit(attack,target)
    local id=target or"player_local"
    return self.services.Combat:try_apply_damage(self:request("direct_hit",{
      attack_instance_id=attack.data.attack_instance_id,target_instance_id=id,tick_index=0,
      hit_evidence={distance_m=Spatial.distance(self.positions.monster_cube_1,self.positions[id]),angular_valid=true,line_of_sight=true}}))
  end
  t:start_round()
  return t
end
return H
'''


class DemoRuntimeTests(unittest.TestCase):
    """Each case uses fresh Lua modules/state and real object behavior."""

    def setUp(self):
        from lupa import lua51

        self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        self.lua.globals().TestProjectRoot = str(ROOT)
        self.lua.globals().H = self.lua.execute(HARNESS)

    def run_lua(self, source):
        self.lua.execute(source)

    def test_complete_search_fight_extract_restart(self):
        self.run_lua(r'''
local t=H.make();t:pickup_all()
H.check(t:item_count("item_heal_small")==2 and t:item_count("item_treasure")==1,"pickup reflected in real inventory")
t:time(3.1);t:face_player()
local deadline=t.state.clock+1.2
while t.state.entities.player_local.hp==100 and t.state.clock<deadline do t:step(.05)end
H.check(t.state.entities.player_local.hp==75,"real monster controller attacks through actual Combat")
t:wall_on()
H.check(t.objects.inventory:use_item("medicine_chest").ok,"inventory dispatch starts real heal cast")
t:time(1.3)
H.check(t.state.entities.player_local.hp==100 and t:item_count("item_heal_small")==1,"cast heals and consumes once")
t.map.walls={};t:face_player()
H.check(t.objects.weapon:use({target_instance_id="monster_cube_1"}).ok,"first real shovel attack")
t:time(.4)
H.check(t.state.entities.monster_cube_1.hp==30,"first shovel hit deals 30")
t:time(1)
H.check(t.objects.weapon:use({target_instance_id="monster_cube_1"}).ok,"second shovel attack")
t:time(.4)
H.check(t.state.entities.monster_cube_1.hp==0 and not t.state.entities.monster_cube_1.alive,"second hit kills actual HP instance")
t:time(.1)
H.check(t.objects.monster.ai_state=="dead","real monster reacts to public death")
H.check(t.services.Session:try_extract(t:request("extract",{user_instance_id="player_local",exit_instance_id="exit_demo"})).ok,"extraction starts")
t:time(3.1)
H.check(t.state.result and t.state.result.success and t.state.result.loot_value==280,"result counts treasure and remaining medicine")
local id=t.state.result.result_id
H.check(t.services.Session:try_finish(t:request("finish_again",{terminal_reason="extraction"})).data.result_id==id,"unique result")
local old_monster=t.objects.monster;local old_run=t.state.run_id
t:start_round()
H.check(t.state.run_id~=old_run and t.state.clock==0 and t.state.result==nil,"new clean run")
H.check(t.state.entities.player_local.hp==100 and t.state.entities.monster_cube_1.hp==60,"new HP instances")
H.check(#t:bag().items==0 and #t.state.containers.chest_demo.items==2,"loot resets without carried previous bag")
H.check(old_monster.disposed==true,"old controller disposed")
H.check(not t.services.Characters:read_snapshot({run_id=old_run,instance_id="player_local"}).ok,"old run rejected")
''')

    def test_monster_patrol_uses_real_path_and_movement(self):
        self.run_lua(r'''
local t=H.make();t:time(2.5)
H.check(t.paths>0 and t.moves>0 and t.positions.monster_cube_1.z>2,"patrol drives path queries and movement")
H.check(t.objects.monster.ai_state=="patrol" and next(t.state.attacks)==nil,"player behind patrol never acquired")
''')

    def test_player_behind_fov_and_wall_prevent_attacks(self):
        self.run_lua(r'''
local t=H.make();t:time(3.2)
H.check(t.state.entities.player_local.hp==100 and next(t.state.attacks)==nil,"behind FOV no attack beyond spawn protection")
t:face_player();t:wall_on();t:time(3)
H.check(t.state.entities.player_local.hp==100 and next(t.state.attacks)==nil,"front but occluded no chase attack")
''')

    def test_attack_losing_sight_does_not_hit_hidden_player(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t.objects.monster:update(0)
H.check(t.objects.monster.attack_instance_id~=nil,"windup began while visible")
t:wall_on();t.positions.player_local={x=7,y=0,z=-7};t:time(2)
H.check(t.state.entities.player_local.hp==100,"hidden target cannot be hit during active window")
H.check(t.objects.monster.last_seen_position.x==0 and t.objects.monster.last_seen_position.z==0,"search remembers visible point instead of live hidden position")
H.check(t.objects.monster.ai_state=="search" or t.objects.monster.ai_state=="return","lost sight exits attack to search or return")
''')

    def test_damage_window_dedup_and_independent_los(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player()
local a=t:direct_attack();H.check(a.ok,"begin actual primary definition")
local early=t:direct_hit(a);H.check(not early.ok and early.reason=="OUTSIDE_HIT_WINDOW","window authoritative")
t.services.Session:tick(.6);t:wall_on()
local blocked=t:direct_hit(a)
H.check(not blocked.ok and blocked.reason=="BLOCKED_LINE_OF_SIGHT" and t.state.entities.player_local.hp==100,"forged visible evidence cannot bypass spatial LOS")
t.map.walls={}
local d=t:direct_hit(a);H.check(d.ok and t.state.entities.player_local.hp==75,"legal hit")
local repeat_hit=t:direct_hit(a)
H.check(not repeat_hit.ok and repeat_hit.reason=="DUPLICATE_HIT" and t.state.entities.player_local.hp==75,"same attack target tick cannot hit twice")
''')

    def test_full_health_and_unowned_item_never_consume(self):
        self.run_lua(r'''
local t=H.make();t:pickup_all()
local full=t.objects.inventory:use_item("medicine_chest")
H.check(not full.ok and full.reason=="FULL_HEALTH" and t:item_count("item_heal_small")==2,"full HP use no cast or spend")
H.check(not t.objects.inventory:use_item("not_owned").ok and t:item_count("item_heal_small")==2,"not owned use rejects")
local forged=t.services.Inventory:try_consume(t:request("illegal_consume",{item_instance_id="medicine_chest",effect_request_id="ui_click"}))
H.check(not forged.ok and t:item_count("item_heal_small")==2,"UI cannot pre-consume")
''')

    def test_heal_movement_and_damage_cancel_without_consumption(self):
        self.run_lua(r'''
local t=H.make();t:pickup_all();t:time(3.1,false);t:face_player()
local a=t:direct_attack();t.services.Session:tick(.6);H.check(t:direct_hit(a).ok,"injure")
H.check(t.objects.inventory:use_item("medicine_chest").ok,"cast starts")
t.positions.player_local={x=.5,y=0,z=0};t:time(.1,false)
H.check(t.objects.heal.stage=="IDLE" and t.objects.heal.last_result.reason=="MOVED" and t:item_count("item_heal_small")==2,"move cancels without spend")
t.positions.player_local={x=0,y=0,z=0}
H.check(t.objects.inventory:use_item("medicine_chest").ok,"cast restarted")
t.positions.second_attacker={x=0,y=0,z=1}
H.check(t.services.Characters:spawn(t:request("second_spawn",{instance_id="second_attacker",entity_id="monster_cube",position_m=t.positions.second_attacker})).ok,"second attack source")
local b=t:direct_attack("second_attacker");t.services.Session:tick(.6)
local d=t.services.Combat:try_apply_damage(t:request("hurt_cast",{attack_instance_id=b.data.attack_instance_id,target_instance_id="player_local",hit_evidence={distance_m=1,angular_valid=true,line_of_sight=true}}))
H.check(d.ok,"hurt while casting through core")
t.objects.heal:update(0)
H.check(t.objects.heal.last_result.reason=="DAMAGED" and t:item_count("item_heal_small")==2,"hurt cancels without spend")
''')

    def test_chest_reopen_and_atomic_inventory_failures(self):
        self.run_lua(r'''
local t=H.make()
H.check(t.objects.chest:open().ok,"open")
H.check(t.objects.chest:pickup("medicine_chest",1).ok,"partial pickup")
t.objects.chest:close();H.check(t.objects.chest:open().ok,"reopen")
H.check(t.state.containers.chest_demo.items[1].count==1 and t:item_count("item_heal_small")==1,"reopen never rerolls")
local from,to=t.state.containers.chest_demo,t.state.containers.bag_player_local
local request=t:request("transfer_stale",{from_id=from.id,to_id=to.id,item_instance_id="treasure_chest",count=1,expected_versions={from=0,to=0}})
local bad=t.services.Inventory:try_transfer(request)
H.check(not bad.ok and bad.reason=="VERSION_CONFLICT" and #from.items==2 and #to.items==1,"stale version leaves both containers intact")
local owner=t.services.Inventory:try_transfer(t:request("bad_owner",{user_instance_id="monster_cube_1",from_id=from.id,to_id=to.id,item_instance_id="treasure_chest",count=1,expected_versions={from=from.version,to=to.version}}))
H.check(not owner.ok and owner.reason=="NOT_OWNER" and #from.items==2,"wrong owner cannot transfer")
t.services.Inventory:_create_container({id="full_bag",owner_id="player_local",slots=1})
t.services.Inventory:_add_item({container_id="full_bag",id="existing_treasure",entity_id="item_treasure",count=1})
local full=t.services.Inventory:try_transfer(t:request("full_transfer",{from_id=from.id,to_id="full_bag",item_instance_id="treasure_chest",count=1,expected_versions={from=from.version,to=1}}))
H.check(not full.ok and full.reason=="BAG_FULL" and #from.items==2 and #t.state.containers.full_bag.items==1,"full target is atomic failure")
''')

    def test_leaving_or_damage_cancels_extraction(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false)
H.check(t.services.Session:try_extract(t:request("exit",{user_instance_id="player_local",exit_instance_id="exit_demo"})).ok,"extract starts")
t.positions.player_local={x=8,y=0,z=0};t:time(.1,false)
H.check(t.state.phase=="EXPLORE" and t.state.extract==nil and t.state.result==nil,"walk away cancels")
t.positions.player_local={x=0,y=0,z=0};t:face_player()
H.check(t.services.Session:try_extract(t:request("exit_again",{user_instance_id="player_local",exit_instance_id="exit_demo"})).ok,"extract restarts")
local a=t:direct_attack();t.services.Session:tick(.6)
H.check(t:direct_hit(a).ok,"damage occurs during extraction")
H.check(t.state.phase=="EXPLORE" and t.state.extract==nil and t.state.result==nil,"damage cancels extraction immediately")
''')

    def test_death_beats_timeout_and_extraction_same_frame(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player()
for i=1,3 do
  local a=t:direct_attack();H.check(a.ok,"attack begins")
  t.services.Session:tick(.6);H.check(t:direct_hit(a).ok,"damage commits")
  t.services.Session:tick(1.5)
end
H.check(t.state.entities.player_local.hp==25,"HP reduced using only actual Combat")
-- Explicit clock fixture arranges simultaneous terminal conditions; no HP or
-- inventory state is faked. Combat runs before the settlement step, as in Demo.
t.state.clock=596.8
H.check(t.services.Session:try_extract(t:request("last_exit",{user_instance_id="player_local",exit_instance_id="exit_demo"})).ok,"exit countdown starts")
t.state.clock=599.3;local final=t:direct_attack();H.check(final.ok,"final attack")
t.state.clock=599.9;H.check(t:direct_hit(final).ok,"lethal actual damage")
t.settlement:update(.11)
H.check(t.state.result.reason=="death" and not t.state.result.success,"death wins even when timeout and extract are due")
H.check(#t.state.result.items==0 and t.state.result.loot_value==0,"failure awards no extraction loot")
''')

    def test_timeout_beats_due_extraction(self):
        self.run_lua(r'''
local t=H.make();t.state.clock=596.9
H.check(t.services.Session:try_extract(t:request("exit",{user_instance_id="player_local",exit_instance_id="exit_demo"})).ok,"extract starts")
t.settlement:update(3.2)
H.check(t.state.result.reason=="timeout" and not t.state.result.success,"timeout wins at extraction boundary")
''')

    def test_returned_snapshots_are_not_writable_authority(self):
        self.run_lua(r'''
local t=H.make();t:pickup_all()
local hp=t.services.Characters:read_snapshot({run_id=t.state.run_id,instance_id="player_local"});hp.data.hp=1
local bag=t.objects.inventory:read_bag();bag.data.bag.items[1].count=999
H.check(t.state.entities.player_local.hp==100 and t:item_count("item_heal_small")==2,"snapshots cannot mutate authority")
''')

    def test_authored_four_rooms_spawns_and_routes_are_reachable(self):
        self.run_lua(r'''
local Spatial=require("gameplay.core.spatial")
local map=require("gameplay.packages.environment.map_demo.definition")
local config=require("gameplay.core.config")
H.check(#map.rooms==4,"actual authored Demo has four room spaces")
local radius=config.player.colliderRadiusM
-- A room label may sit on a decorative cover. Use the actual walkable content
-- anchor in each room, not a fabricated assertion that every room centre is free.
local anchors={entry=map.spawn,supply=map.chest,monster=map.monsterSpawn}
for _,room in ipairs(map.rooms)do if room.id=="hall"then anchors.hall={x=room.x,y=0,z=room.z}end end
for name,p in pairs(anchors)do
  H.check(p and not Spatial.blocked(p,p,map.walls,radius),"spawn/content anchor is clear: "..name)
end
H.check(not Spatial.blocked(map.exit,map.exit,map.walls,radius),"exit is clear")
for _,p in ipairs(map.patrolRoute)do H.check(not Spatial.blocked(p,p,map.walls,radius),"patrol waypoint is clear")end
local route={anchors.entry,anchors.supply,anchors.monster,anchors.hall,map.exit}
for i=1,#route-1 do
  local path,reason=Spatial.path(route[i],route[i+1],map,radius)
  H.check(path and #path>0,"actual room route reachable: "..i.." / "..tostring(reason))
  local previous=route[i]
  for _,waypoint in ipairs(path)do
    H.check(not Spatial.blocked(previous,waypoint,map.walls,radius),"path segment avoids authored collision")
    previous=waypoint
  end
  H.check(Spatial.distance(previous,route[i+1])<.001,"path reaches exact room anchor")
end
''')


class CollectingResult(unittest.TestResult):
    def __init__(self):
        super().__init__()
        self.checks = []
        self.assertions = 0

    def addSuccess(self, test):
        super().addSuccess(test)
        self.assertions += int(test.lua.globals().H.assertion_count)
        self.checks.append({"name": test._testMethodName, "passed": True})

    def addFailure(self, test, err):
        super().addFailure(test, err)
        self.checks.append({"name": test._testMethodName, "passed": False, "detail": self.failures[-1][1]})

    def addError(self, test, err):
        super().addError(test, err)
        self.checks.append({"name": test._testMethodName, "passed": False, "detail": self.errors[-1][1]})


def run_tests():
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(DemoRuntimeTests)
    result = CollectingResult()
    suite.run(result)
    try:
        runtime_version = importlib.metadata.version("lupa")
    except importlib.metadata.PackageNotFoundError:
        runtime_version = None
    return {
        "ok": result.wasSuccessful(),
        "runtime": {"package": "lupa", "version": runtime_version, "module": "lupa.lua51"},
        "testsRun": result.testsRun,
        "assertions": result.assertions,
        "checks": result.checks,
        "scope": SCOPE,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    result = run_tests()
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(("PASS" if result["ok"] else "FAIL") + " — real Demo Lua integration")
        print(f"{result['testsRun']} cases, {result['assertions']} successful assertions")
        for check in result["checks"]:
            print(("PASS " if check["passed"] else "FAIL ") + check["name"])
            if not check["passed"]:
                print(check["detail"], file=sys.stderr)
        print(SCOPE)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
