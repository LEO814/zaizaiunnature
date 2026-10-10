#!/usr/bin/env python3
"""Run the INKWAVE monster through real Lua 5.1 public state/services.

Uses the existing Demo harness: native transforms/assets are SDK doubles; public
Combat, Characters, Navigation spatial geometry and round authority are real.
Does not claim GLB import, animation rendering, FX/audio or editor acceptance.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from test_demo_runtime import HARNESS, CollectingResult

INK_HARNESS = HARNESS.replace("monster_cube", "monster_inkwave")


class InkwaveMonsterTests(unittest.TestCase):
    def setUp(self):
        from lupa import lua51
        self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        self.lua.globals().TestProjectRoot = str(ROOT)
        self.lua.globals().H = self.lua.execute(INK_HARNESS)

    def run_lua(self, source):
        self.lua.execute(source)

    def test_patrol_follows_navigation_and_never_acquires_from_behind(self):
        self.run_lua(r'''
local t=H.make();t:time(2.5)
H.check(t.paths>0 and t.moves>0 and t.positions.monster_inkwave_1.z>2,"real navigation drives patrol")
H.check(t.objects.monster.ai_state=="patrol" and next(t.state.attacks)==nil,"no lock behind FOV")
H.check(t.state.entities.player_local.hp==100,"patrol never damages unseen player")
''')

    def test_occlusion_and_brief_glimpse_do_not_acquire(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t:wall_on();t:time(2)
H.check(next(t.state.attacks)==nil and t.state.entities.player_local.hp==100,"LOS blocks attack")
t.map.walls={};t:face_player();t.objects.monster:update(0)
H.check(t.objects.monster.ai_state=="alert" and not t.objects.monster.attack_instance_id,"first sight is alert")
t:wall_on();t.services.Session:tick(.1);t.objects.monster:update(.1)
H.check(t.objects.monster.ai_state=="patrol" and not t.objects.monster.last_seen_position,"glimpse before reaction does not create lock")
''')

    def test_attack_faces_only_current_visible_point_without_displacing(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t.positions.player_local={x=.8,y=0,z=0}
local original=t.services.Movement.move_to;local aimed={}
function t.services.Movement:move_to(r)
 if r.speed_mps==0 then aimed[#aimed+1]=r end
 return original(self,r)
end
local before=t.positions.monster_inkwave_1;t.objects.monster:update(0)
t.services.Session:tick(.2);t.objects.monster:update(.2)
H.check(#aimed==1 and aimed[1].goal_m.x==.8 and aimed[1].goal_m.z==0,"aim command follows FOV/LOS-confirmed current visible point")
H.check(aimed[1].dt_sec==0 and t.moves==0 and t.positions.monster_inkwave_1.x==before.x and t.positions.monster_inkwave_1.z==before.z,"zero-speed aim never displaces authoritative monster")
t:wall_on();t.positions.player_local={x=7,y=0,z=-7};t:time(3)
H.check(#aimed==1,"hidden target never receives a new facing command")
''')

    def test_reaction_delay_then_public_damage_and_scoped_feedback(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t.objects.monster:update(0)
H.check(t.objects.monster.ai_state=="alert","reaction starts")
t.services.Session:tick(.1);t.objects.monster:update(.1)
H.check(not t.objects.monster.attack_instance_id,"cannot fire before reaction ends")
t.services.Session:tick(.08);t.objects.monster:update(.08)
H.check(t.objects.monster.ai_state=="windup" and t.objects.monster.attack_instance_id,"reaction permits public attack begin")
local attack_id=t.objects.monster.attack_instance_id
t.services.Session:tick(.56);t.objects.monster:update(.56)
H.check(t.state.entities.player_local.hp==75,"one public 25 damage hit")
t.objects.monster:update(0);t.services.Session:tick(.1);t.objects.monster:update(.1)
H.check(t.state.entities.player_local.hp==75,"single window never applies repeated damage")
local windup,shot
for _,r in ipairs(t.animations)do
 if r.monster_feedback then
  H.check(r.instance_id=="monster_inkwave_1" and r.run_id==t.state.run_id,"monster feedback scoped by instance and run")
  if r.monster_feedback.event=="monster_inkwave_windup"then windup=r end
  if r.monster_feedback.event=="monster_inkwave_attack"then shot=r end
 end
end
H.check(windup and windup.clip_name=="attack" and windup.restart==true,"windup begins baked attack clip")
H.check(shot and shot.clip_name=="attack" and shot.restart==false,"active window does not restart baked clip")
H.check(shot.monster_feedback.sound_id=="shoot_shooter" and shot.monster_feedback.fx_id=="muzzle_shooter","shot requests local muzzle and shooter sound")
H.check(shot.monster_feedback.attack_instance_id==attack_id,"feedback references legal public attack")
''')

    def test_active_window_rechecks_visibility_and_tracks_only_last_seen(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t.objects.monster:update(0)
t.services.Session:tick(.2);t.objects.monster:update(.2)
H.check(t.objects.monster.attack_instance_id,"attack began while visible")
local hidden_reads=0;local original=t.services.Movement.read_position
function t.services.Movement:read_position(r)
 if r.instance_id=="player_local"then hidden_reads=hidden_reads+1 end
 return original(self,r)
end
t:wall_on();t.positions.player_local={x=7,y=0,z=-7};t:time(2)
H.check(t.state.entities.player_local.hp==100,"hidden player is not damaged")
H.check(hidden_reads==0,"AI never reads hidden target transform to follow it")
H.check(t.objects.monster.last_seen_position.x==0 and t.objects.monster.last_seen_position.z==0,"last visible point stays immutable while hidden")
H.check(t.objects.monster.ai_state=="search" or t.objects.monster.ai_state=="return","search transition follows loss")
''')

    def test_coarse_frame_skipping_whole_damage_window_never_replays_hit(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t.objects.monster:update(0)
t.services.Session:tick(.2);t.objects.monster:update(.2)
H.check(t.objects.monster.attack_instance_id,"attack starts")
t.services.Session:tick(1);t.objects.monster:update(1)
H.check(t.state.entities.player_local.hp==100 and t.objects.monster.ai_state=="recovery","expired window has no late damage")
''')

    def test_recovery_continues_attack_animation_tail_without_new_hit(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t.objects.monster:update(0)
t.services.Session:tick(.2);t.objects.monster:update(.2)
t.services.Session:tick(.56);t.objects.monster:update(.56)
H.check(t.state.entities.player_local.hp==75,"damage occurs only in active window")
t.services.Session:tick(.34);t.objects.monster:update(.34)
H.check(t.objects.monster.ai_state=="recovery" and t.objects.monster.current_feedback=="recovery","recovery selects dedicated feedback")
local r=t.animations[#t.animations]
H.check(r.clip_name=="attack" and r.restart==false and not r.monster_feedback.sound_id and not r.monster_feedback.fx_id,"attack animation tail continues without repeat shot")
H.check(t.state.entities.player_local.hp==75 and t.objects.monster.attack_instance_id,"recovery preserves timeline without applying damage")
t.services.Session:tick(.61);t.objects.monster:update(.61)
H.check(not t.objects.monster.attack_instance_id and t.objects.monster.ai_state=="chase","finished animation attack is then cancelled")
''')

    def test_hurt_cancels_attack_and_death_is_emitted_once(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t.objects.monster:update(0)
t.services.Session:tick(.2);t.objects.monster:update(.2)
local monster_attack=t.objects.monster.attack_instance_id
H.check(t.objects.weapon:use({target_instance_id="monster_inkwave_1"}).ok,"shovel starts real public damage")
t:time(.41,false);t.objects.monster:update(0)
H.check(t.state.entities.monster_inkwave_1.hp==30 and t.objects.monster.ai_state=="hurt","public HP loss triggers hit state")
H.check(t.state.attacks[monster_attack].cancelled and not t.objects.monster.attack_instance_id,"hurt cancels in-flight public attack")
t:time(1.1,false)
H.check(t.objects.weapon:use({target_instance_id="monster_inkwave_1"}).ok,"second shovel starts")
t:time(.4,false);t.objects.monster:update(0);t.objects.monster:update(0)
H.check(t.state.entities.monster_inkwave_1.hp==0 and t.objects.monster.ai_state=="dead","public death stops AI")
local n=0;for _,r in ipairs(t.animations)do if r.monster_feedback and r.monster_feedback.event=="monster_inkwave_death"then n=n+1 end end
H.check(n==1,"death animation sound FX only once")
''')

    def test_low_hp_retreat_uses_navigation_without_healing(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player()
t.positions.hurt_source={x=0,y=0,z=2.5}
H.check(t.services.Characters:spawn(t:request("spawn_hurt_source",{instance_id="hurt_source",entity_id="monster_inkwave",position_m=t.positions.hurt_source})).ok,"authority spawns damage source")
for i=1,2 do
 local a=t.services.Combat:try_begin_attack(t:request("injure",{source_instance_id="hurt_source",attack_id="primary"}))
 H.check(a.ok,"public attack begins")
 t.services.Session:tick(.56)
 H.check(t.services.Combat:try_apply_damage(t:request("hurt",{attack_instance_id=a.data.attack_instance_id,target_instance_id="monster_inkwave_1",tick_index=0,hit_evidence={distance_m=.5,angular_valid=true,line_of_sight=true}})).ok,"authority applies monster damage")
 if i==1 then t.services.Session:tick(1.5)end
end
H.check(t.state.entities.monster_inkwave_1.hp==10,"injury reaches threshold through public combat")
t.objects.monster:update(0);t.services.Session:tick(.26);t.objects.monster:update(.26)
H.check(t.objects.monster.ai_state=="retreat" and t.objects.monster.retreat_goal.z>2,"retreat goal points away from last-visible threat")
local previous_paths=t.paths;t.services.Session:tick(.2);t.objects.monster:update(.2)
H.check(t.paths>=previous_paths and t.moves>0,"retreat follows public navigation and movement")
H.check(t.state.entities.monster_inkwave_1.hp==10,"retreat never grants original ink regeneration")
''')

    def test_path_failure_stops_and_skips_unreachable_patrol_point(self):
        self.run_lua(r'''
local t=H.make();local calls=0
function t.services.Navigation:find_path(r)calls=calls+1;return{ok=false,reason="NO_PATH",request_id=r.request_id,data={}}end
local before=t.positions.monster_inkwave_1.z;t:time(2.1)
H.check(calls>=3 and t.moves==0 and t.positions.monster_inkwave_1.z==before,"failed navigation never becomes direct movement")
H.check(t.objects.monster.route_index==2,"unreachable patrol point skipped")
''')

    def test_search_returns_home_and_session_end_cancels_everything(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t.objects.monster:update(0)
t.services.Session:tick(.2);t.objects.monster:update(.2);t:wall_on();t:time(6.5)
H.check(t.objects.monster.ai_state=="return" or t.objects.monster.ai_state=="patrol","bounded search returns to route")
t.map.walls={};t:face_player();t.objects.monster:update(0);t.services.Session:tick(.2);t.objects.monster:update(.2)
local attack=t.objects.monster.attack_instance_id
t.state.phase="FINISHED";t.objects.monster:update(.1)
H.check(not t.objects.monster.attack_instance_id and not t.objects.monster.path and not t.objects.monster.last_seen_position,"round end clears attack path target")
H.check(t.objects.monster.current_feedback=="idle","ended session stops animation locomotion")
if attack then H.check(t.state.attacks[attack].cancelled,"round end cancels authority attack")end
''')

    def test_run_change_dispose_and_restart_never_leak_previous_target(self):
        self.run_lua(r'''
local t=H.make();t:time(3.1,false);t:face_player();t.objects.monster:update(0)
t.services.Session:tick(.2);t.objects.monster:update(.2)
local old=t.objects.monster;local old_run=t.state.run_id
H.check(t.services.Session:try_extract(t:request("extract",{user_instance_id="player_local",exit_instance_id="exit_demo"})).ok,"public extraction begins")
t:time(3.1,false);H.check(t.state.phase=="FINISHED","public round ends before restart")
t:start_round()
H.check(old.disposed and old.context==nil,"previous monster disposed")
H.check(t.state.run_id~=old_run and t.state.entities.monster_inkwave_1.hp==60,"new run creates fresh authority instance")
H.check(t.objects.monster.ai_state=="patrol" and not t.objects.monster.last_seen_position and not t.objects.monster.attack_instance_id,"new controller has no stale attack or target")
local current=t.objects.monster;t.state.run_id="another_run"
local ok,reason=current:update(0)
H.check(ok==false and reason=="RUN_CHANGED" and current.started==false,"stale run controller stops immediately")
''')


def run_tests():
    result = CollectingResult()
    unittest.defaultTestLoader.loadTestsFromTestCase(InkwaveMonsterTests).run(result)
    return {
        "ok": result.wasSuccessful(), "testsRun": result.testsRun,
        "assertions": result.assertions, "checks": result.checks,
        "runtime": "lupa.lua51",
        "scope": "Real public Lua state/combat and authored spatial geometry; SDK transform/assets doubles. No editor/GLB/FX/audio acceptance.",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--save-report", type=Path)
    args = parser.parse_args()
    report = run_tests()
    if args.save_report:
        args.save_report.parent.mkdir(parents=True, exist_ok=True)
        args.save_report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(("PASS" if report["ok"] else "FAIL") + f" — INKWAVE monster: {report['testsRun']} cases / {report['assertions']} assertions")
        for item in report["checks"]:
            print(("PASS " if item["passed"] else "FAIL ") + item["name"])
            if "detail" in item: print(item["detail"], file=sys.stderr)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
